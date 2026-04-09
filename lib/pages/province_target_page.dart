import 'package:flutter/material.dart';
import '../models/provinsi_model.dart';

class ProvinceTargetPage extends StatefulWidget {
  final String surveyName;
  final List<ProvinceTarget> provinces;

  const ProvinceTargetPage({
    super.key,
    required this.surveyName,
    required this.provinces,
  });

  @override
  State<ProvinceTargetPage> createState() => _ProvinceTargetPageState();
}

class _ProvinceTargetPageState extends State<ProvinceTargetPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ProvinceTarget> _filtered = [];

  static const _green      = Color(0xFF4CAF50);
  static const _greenLight = Color(0xFFF0FAF3);
  static const _greenMid   = Color(0xFFDDF2E4);
  static const _greenText  = Color(0xFF2E7D32);
  static const _bg         = Color(0xFFF5F7F6);

  @override
  void initState() {
    super.initState();
    _filtered = widget.provinces;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = widget.provinces
          .where((p) => p.name.toLowerCase().contains(query)) // ✅ province → name
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTarget = widget.provinces.fold<int>(
      0,
      (sum, p) => sum + p.targetResponse,
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        title: const Text(
          'Target Provinsi',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: widget.provinces.isEmpty
          ? const Center(child: Text('Tidak ada target provinsi'))
          : Column(
              children: [
                // ── Header Card ──────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _greenMid,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: _greenText,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.surveyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOTAL TARGET',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF999999),
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalTarget.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Search Bar ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari provinsi...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFAAAAAA),
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Color(0xFFAAAAAA), size: 18),
                              onPressed: _searchController.clear,
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── List ─────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Provinsi tidak ditemukan.',
                            style: TextStyle(color: Color(0xFFBBBBBB)),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = _filtered[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.04),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Nomor urut
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _greenLight,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _greenText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Nama provinsi
                                  Expanded(
                                    child: Text(
                                      p.name, // ✅ provinceName → name
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Badge target
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _greenMid,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Target: ${p.targetResponse}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _greenText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}