import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
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
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  Position? _position;
  DateTime? _timestamp;

  bool _isLoading = false;
  String _errorMessage = '';

  bool isCameraEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDraftPhoto();
  }

  Future<void> _loadDraftPhoto() async {
    final draft = await StorageHelper.getDraftPhoto(widget.surveySlug);

    if (draft != null && mounted) {
      final path = draft['photo_path'];

      if (path != null) {
        setState(() {
          _imageFile = XFile(path);
          _timestamp =
              DateTime.tryParse(draft['capture_time'] ?? '');
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final statuses = await [
        Permission.camera,
        Permission.locationWhenInUse,
      ].request();

      if (statuses[Permission.camera] !=
          PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Izin kamera ditolak';
          _isLoading = false;
        });
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo == null) {
        setState(() => _isLoading = false);
        return;
      }

      Position? position;

      try {
        bool gps =
            await Geolocator.isLocationServiceEnabled();

        if (gps) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      } catch (_) {}

      await StorageHelper.saveDraftPhoto(
        surveySlug: widget.surveySlug,
        photoPath: photo.path,
        latitude: position?.latitude ?? 0,
        longitude: position?.longitude ?? 0,
        captureTime: DateTime.now().toIso8601String(),
      );

      setState(() {
        _imageFile = photo;
        _position = position;
        _timestamp = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _lanjutkan() async {
    final biodata =
        Map<String, dynamic>.from(widget.biodata ?? {});

    if (_imageFile != null) {
      biodata['photo_path'] = _imageFile!.path;
    }

    if (_position != null) {
      biodata['latitude'] = _position!.latitude;
      biodata['longitude'] = _position!.longitude;
    }

    if (_timestamp != null) {
      biodata['capture_time'] =
          _timestamp!.toIso8601String();
    }

    final result = await Navigator.pushNamed(
      context,
      '/submission',
      arguments: {
        'surveySlug': widget.surveySlug,
        'clientSlug': widget.clientSlug,
        'projectSlug': widget.projectSlug,
        'biodata': biodata,
        'surveyTitle': widget.surveyTitle,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildPreview() {
    if (!isCameraEnabled) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.no_photography,
            size: 90,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    if (_imageFile == null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.camera_alt,
            size: 90,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: kIsWeb
          ? Image.network(
              _imageFile!.path,
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(_imageFile!.path),
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildInfoCard() {
    if (_imageFile == null) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "KETERANGAN OBJEK",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),

          const SizedBox(height: 18),

          _rowInfo(
            Icons.person_outline,
            "Nama Responden",
            widget.biodata?['name'] ?? '-',
          ),

          const SizedBox(height: 16),

          _rowInfo(
            Icons.business_outlined,
            "Instansi",
            widget.biodata?['instansi'] ?? '-',
          ),

          const SizedBox(height: 16),

          _rowInfo(
            Icons.location_on_outlined,
            "Koordinat Lokasi",
            _position == null
                ? '-'
                : '${_position!.latitude}, ${_position!.longitude}',
          ),

          const SizedBox(height: 16),

          _rowInfo(
            Icons.access_time_outlined,
            "Waktu Tercatat",
            _timestamp == null
                ? '-'
                : DateFormat(
                    'dd MMMM yyyy, HH:mm:ss',
                  ).format(_timestamp!),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.monGreenMid,
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isCameraEnabled = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCameraEnabled
                      ? AppTheme.monGreenMid
                      : Colors.grey.shade300,
              foregroundColor:
                  isCameraEnabled
                      ? Colors.white
                      : Colors.black87,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child:
                const Text("Aktifkan Kamera"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isCameraEnabled = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  !isCameraEnabled
                      ? Colors.red.shade400
                      : Colors.grey.shade300,
              foregroundColor:
                  !isCameraEnabled
                      ? Colors.white
                      : Colors.black87,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child:
                const Text("Nonaktifkan"),
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    if (isCameraEnabled) {
      if (_imageFile == null) {
        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _capturePhoto,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.monGreenMid,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child:
                const Text("Jepret Foto"),
          ),
        );
      }

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _lanjutkan,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.monGreenMid,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          18),
                ),
                elevation: 0,
              ),
              child: const Text(
                  "Lanjutkan ke Form Kuisioner"),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _capturePhoto,
            child: const Text(
              "Ulangi Foto",
              style: TextStyle(
                color:
                    AppTheme.monGreenMid,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _lanjutkan,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppTheme.monGreenMid,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    18),
          ),
          elevation: 0,
        ),
        child: const Text(
            "Lanjutkan ke Kuisioner"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            AppTheme.monGreenMid,
        title: const Text(
          "Ambil Foto Objek",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                      20),
              child: Column(
                children: [
                  if (_errorMessage
                      .isNotEmpty)
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(14),
                      margin:
                          const EdgeInsets
                              .only(
                              bottom:
                                  18),
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .red.shade50,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    16),
                      ),
                      child: Text(
                          _errorMessage),
                    ),

                  _buildPreview(),

                  const SizedBox(
                      height: 18),

                  _toggleButtons(),

                  _buildInfoCard(),

                  const SizedBox(
                      height: 24),

                  _actionButtons(),
                ],
              ),
            ),
    );
  }
}