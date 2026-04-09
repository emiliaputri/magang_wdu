import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage.dart';

class CameraCapturePage extends StatefulWidget {
  final String surveySlug;
  final String clientSlug;
  final String projectSlug;
  final Map<String, dynamic>? biodata;
  final String surveyTitle;

  const CameraCapturePage({
    super.key,
    required this.surveySlug,
    required this.clientSlug,
    required this.projectSlug,
    required this.biodata,
    required this.surveyTitle,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  File? _imageFile;
  Position? _position;
  DateTime? _timestamp;
  bool _isLoading = false;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDraftPhoto();
  }

  Future<void> _loadDraftPhoto() async {
    final draftPhoto = await StorageHelper.getDraftPhoto(widget.surveySlug);
    if (draftPhoto != null && mounted) {
      final photoPath = draftPhoto['photo_path'] as String?;
      if (photoPath != null && File(photoPath).existsSync()) {
        final lat = draftPhoto['latitude'] as double?;
        final lng = draftPhoto['longitude'] as double?;
        setState(() {
          _imageFile = File(photoPath);
          if (lat != null && lng != null) {
            _position = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }
          _timestamp = DateTime.tryParse(draftPhoto['capture_time'] as String? ?? '');
        });
      }
    }
  }

  Future<void> _checkPermissionsAndCapture() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Request Permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.locationWhenInUse,
      ].request();

      final cameraStatus = statuses[Permission.camera];
      final locationStatus = statuses[Permission.locationWhenInUse];

      if (cameraStatus != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Izin kamera ditolak. Tidak bisa mengambil foto.';
          _isLoading = false;
        });
        return;
      }

      if (locationStatus != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Izin lokasi ditolak. Tidak bisa mencatat koordinat.';
          _isLoading = false;
        });
        return;
      }

      // 2. Cek apakah GPS aktif
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        setState(() {
          _errorMessage = 'GPS tidak aktif. Mohon aktifkan GPS device Anda.';
          _isLoading = false; //
        });
        return;
      }

      // 3. Ambil Foto
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Kompres sedikit agar tidak terlalu besar
      );

      if (photo == null) {
        setState(() {
          _isLoading = false; //
          // User canceled camera
        });
        return;
      }

      // 4. Dapatkan Lokasi (Latitude, Longitude)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // 5. Simpan file ke Local Storage (App Documents)
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_capture.jpg';
      final String localPath = '${directory.path}/$fileName';
      
      final File localFile = await File(photo.path).copy(localPath);

      await StorageHelper.saveDraftPhoto(
        surveySlug: widget.surveySlug,
        photoPath: localFile.path,
        latitude: position.latitude,
        longitude: position.longitude,
        captureTime: DateTime.now().toIso8601String(),
      );

      setState(() {
        _imageFile = localFile;
        _position = position;
        _timestamp = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _lanjutkan() async {
    // Memasukkan data foto & lokasi ke biodata jika perlu
    final updatedBiodata = Map<String, dynamic>.from(widget.biodata ?? {});
    
    if (_imageFile != null) {
      updatedBiodata['photo_path'] = _imageFile!.path;
    }
    if (_position != null) {
      updatedBiodata['latitude'] = _position!.latitude;
      updatedBiodata['longitude'] = _position!.longitude;
    }
    if (_timestamp != null) {
      updatedBiodata['capture_time'] = _timestamp!.toIso8601String();
    }

    final result = await Navigator.pushNamed(
      context,
      '/submission',
      arguments: {
        'surveySlug': widget.surveySlug,
        'clientSlug': widget.clientSlug,
        'projectSlug': widget.projectSlug,
        'biodata': updatedBiodata,
        'surveyTitle': widget.surveyTitle,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.monBgColor,
      appBar: AppBar(
        title: const Text(
          'Ambil Foto',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: AppTheme.monGreenMid,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.monGreenMid),
                  SizedBox(height: 16),
                  Text('Sedang mengambil data & lokasi...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),

                  // Area Tampilan Foto
                  if (_imageFile == null)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('Belum ada foto', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _imageFile!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                  // Informasi Keterangan
                  if (_imageFile != null && _position != null && _timestamp != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KETERANGAN OBJEK',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.monTextDark,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade200, thickness: 1),
                          const SizedBox(height: 8),

                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Nama Responden',
                            value: widget.biodata?['name'] ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.business_outlined,
                            label: 'Instansi',
                            value: widget.biodata?['instansi'] ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Koordinat Lokasi',
                            value: '${_position!.latitude}, ${_position!.longitude}',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.access_time_outlined,
                            label: 'Waktu Tercatat',
                            value: DateFormat('dd MMMM yyyy, HH:mm:ss').format(_timestamp!),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Tombol Aksi
                  if (_imageFile == null)
                    ElevatedButton.icon(
                      onPressed: _checkPermissionsAndCapture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.monGreenMid,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Jepret Foto Sekarang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _lanjutkan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.monGreenMid,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Lanjutkan ke Form Kuisioner',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: TextButton.icon(
                            onPressed: _checkPermissionsAndCapture,
                            icon: const Icon(Icons.refresh, color: AppTheme.monGreenMid),
                            label: const Text(
                              'Ulangi Foto',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w600,
                                color: AppTheme.monGreenMid,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.monGreenMid),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.monTextDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
