import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage.dart';
import '../../models/submission_model.dart';
import '../../service/submission_service.dart';

class BiodataPage extends StatefulWidget {
  final String surveySlug;
  final String clientSlug;
  final String projectSlug;

  const BiodataPage({
    super.key,
    required this.surveySlug,
    required this.clientSlug,
    required this.projectSlug,
  });

  @override
  State<BiodataPage> createState() => _BiodataPageState();
}

class _BiodataPageState extends State<BiodataPage> {
  final SubmissionService _service = SubmissionService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ProvinceTarget> _provinceTargets = [];
  String _surveyTitle = '';

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noHpController = TextEditingController();
  final _instansiController = TextEditingController();

  int? _selectedProvinceId;
  String? _selectedProvinceName;

  // Static fallback provinces (38 provinces of Indonesia)
  static const _fallbackProvinces = [
    {'id': 1, 'name': 'Nanggroe Aceh Darussalam'},
    {'id': 2, 'name': 'Sumatera Utara'},
    {'id': 3, 'name': 'Sumatera Selatan'},
    {'id': 4, 'name': 'Sumatera Barat'},
    {'id': 5, 'name': 'Bengkulu'},
    {'id': 6, 'name': 'Riau'},
    {'id': 7, 'name': 'Kepulauan Riau'},
    {'id': 8, 'name': 'Jambi'},
    {'id': 9, 'name': 'Lampung'},
    {'id': 10, 'name': 'Bangka Belitung'},
    {'id': 11, 'name': 'Kalimantan Barat'},
    {'id': 12, 'name': 'Kalimantan Timur'},
    {'id': 13, 'name': 'Kalimantan Selatan'},
    {'id': 14, 'name': 'Kalimantan Tengah'},
    {'id': 15, 'name': 'Kalimantan Utara'},
    {'id': 16, 'name': 'Banten'},
    {'id': 17, 'name': 'DKI Jakarta'},
    {'id': 18, 'name': 'Jawa Barat'},
    {'id': 19, 'name': 'Jawa Tengah'},
    {'id': 20, 'name': 'Daerah Istimewa Yogyakarta'},
    {'id': 21, 'name': 'Jawa Timur'},
    {'id': 22, 'name': 'Bali'},
    {'id': 23, 'name': 'Nusa Tenggara Timur'},
    {'id': 24, 'name': 'Nusa Tenggara Barat'},
    {'id': 25, 'name': 'Gorontalo'},
    {'id': 26, 'name': 'Sulawesi Barat'},
    {'id': 27, 'name': 'Sulawesi Tengah'},
    {'id': 28, 'name': 'Sulawesi Utara'},
    {'id': 29, 'name': 'Sulawesi Tenggara'},
    {'id': 30, 'name': 'Sulawesi Selatan'},
    {'id': 31, 'name': 'Maluku Utara'},
    {'id': 32, 'name': 'Maluku'},
    {'id': 33, 'name': 'Papua Barat'},
    {'id': 34, 'name': 'Papua'},
    {'id': 35, 'name': 'Papua Tengah'},
    {'id': 36, 'name': 'Papua Pegunungan'},
    {'id': 37, 'name': 'Papua Selatan'},
    {'id': 38, 'name': 'Papua Barat Daya'},
  ];

  List<Map<String, dynamic>> get _provinces {
    // Use API data if available, otherwise use fallback
    if (_provinceTargets.isNotEmpty) {
      return _provinceTargets
          .map((p) => {'id': p.provinceId, 'name': p.provinceName})
          .toList();
    }
    return _fallbackProvinces;
  }

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      _loadDraftIfExists();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getSubmission(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
      );

      if (data != null) {
        debugPrint(
          'DEBUG: data.provinceTargets: ${data.provinceTargets.length}',
        );
        debugPrint(
          'DEBUG: data.provinceTargets sample: ${data.provinceTargets.isNotEmpty ? data.provinceTargets.first.provinceName : "empty"}',
        );
        setState(() {
          _provinceTargets = data.provinceTargets;
          _surveyTitle = data.survey?.title ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Data tidak ditemukan";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat data: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDraftIfExists() async {
    final draft = await StorageHelper.getDraftBiodata(widget.surveySlug);
    if (draft != null && mounted) {
      setState(() {
        _namaController.text = draft['name'] ?? '';
        _alamatController.text = draft['address'] ?? '';
        _noHpController.text = draft['phone'] ?? '';
        _instansiController.text = draft['instansi'] ?? '';
        _selectedProvinceId = draft['province_id'];
        _selectedProvinceName = draft['province_name'];
      });
    }
  }

  Future<void> _saveDraftBiodata() async {
    final biodata = {
      'name': _namaController.text.trim(),
      'address': _alamatController.text.trim(),
      'province_id': _selectedProvinceId,
      'province_name': _selectedProvinceName,
      'phone': _noHpController.text.trim(),
      'instansi': _instansiController.text.trim(),
    };
    await StorageHelper.saveDraftBiodata(
      surveySlug: widget.surveySlug,
      biodata: biodata,
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    _instansiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.monBgColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.monGreenMid,
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorUI()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(),
                          const SizedBox(height: 20),
                          _buildBiodataForm(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? "Terjadi kesalahan"),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.monGreenDark, AppTheme.monGreenMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Text(
                'Biodata Responden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Diri Responden',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mohon isi data diri Anda dengan benar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data ini diperlukan untuk mengidentifikasi responden dan memastikan keabsahan data survei.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFF57C00),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiodataForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FORM BIODATA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.monTextDark,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: AppTheme.monGreenMid,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _namaController,
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap Anda',
            icon: Icons.person_outline,
            isRequired: true,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _alamatController,
            label: 'Alamat',
            hint: 'Masukkan alamat lengkap Anda',
            icon: Icons.home_outlined,
            isRequired: true,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          _buildDropdownProvince(),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _noHpController,
            label: 'Nomor Handphone',
            hint: 'Masukkan nomor HP Anda',
            icon: Icons.phone_outlined,
            isRequired: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _instansiController,
            label: 'Instansi',
            hint: 'Masukkan nama instansi Anda',
            icon: Icons.business_outlined,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isRequired,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.monTextDark,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            prefixIcon: Icon(icon, color: AppTheme.monGreenMid, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.monGreenMid,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label wajib diisi';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownProvince() {
    final provinces = _provinces;

    if (provinces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data provinsi belum tersedia. Silakan coba lagi nanti.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Provinsi Asal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.monTextDark,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedProvinceId,
          decoration: InputDecoration(
            hintText: 'Pilih provinsi',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppTheme.monGreenMid,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.monGreenMid,
                width: 2,
              ),
            ),
          ),
          items: provinces.map((province) {
            return DropdownMenuItem<int>(
              value: province['id'] as int,
              child: Text(
                province['name'] as String,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvinceId = value;
              if (value != null) {
                _selectedProvinceName =
                    provinces.firstWhere((p) => p['id'] == value)['name']
                        as String;
              }
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Provinsi wajib dipilih';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _submitBiodata,
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
                  'Lanjutkan ke Kuisioner',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          height: 48,
          child: OutlinedButton(
            onPressed: _saveDraft,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              side: BorderSide(color: Colors.orange.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Simpan Draft',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitBiodata() async {
    if (_formKey.currentState!.validate()) {
      final biodata = {
        'name': _namaController.text.trim(),
        'address': _alamatController.text.trim(),
        'province_id': _selectedProvinceId,
        'province_name': _selectedProvinceName,
        'phone': _noHpController.text.trim(),
        'instansi': _instansiController.text.trim(),
      };

      await StorageHelper.saveDraftBiodata(
        surveySlug: widget.surveySlug,
        biodata: biodata,
      );

      if (mounted) {
        final result = await Navigator.pushReplacementNamed(
          context,
          '/camera_capture',
          arguments: {
            'surveySlug': widget.surveySlug,
            'clientSlug': widget.clientSlug,
            'projectSlug': widget.projectSlug,
            'biodata': biodata,
            'surveyTitle': _surveyTitle,
          },
        );

        // If result is true, means user submitted successfully - go back to survey list
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  void _saveDraft() async {
    final biodata = {
      'name': _namaController.text.trim(),
      'address': _alamatController.text.trim(),
      'province_id': _selectedProvinceId,
      'province_name': _selectedProvinceName,
      'phone': _noHpController.text.trim(),
      'instansi': _instansiController.text.trim(),
    };

    await StorageHelper.saveDraftBiodata(
      surveySlug: widget.surveySlug,
      biodata: biodata,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft biodata berhasil disimpan!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
