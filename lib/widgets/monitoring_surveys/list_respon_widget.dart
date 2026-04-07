import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../pages/lihat_monitor_page.dart';

class ListResponWidget extends StatelessWidget {
  final List<Map<String, dynamic>> responses;
  final int currentPage;
  final int totalData;
  final int perPage;
  final ValueChanged<int> onPageChanged;
  final void Function(
    int responseId,
    String surveySlug,
    String clientSlug,
    String projectSlug,
  )? onDeleteResponse;
  final void Function(
    int responseId,
    String surveySlug,
    String clientSlug,
    String projectSlug,
    Map<String, dynamic> responseData,
  )? onEditResponse;

  const ListResponWidget({
    super.key,
    required this.responses,
    required this.currentPage,
    required this.totalData,
    required this.perPage,
    required this.onPageChanged,
    this.onDeleteResponse,
    this.onEditResponse,
  });

  int get totalPages => totalData == 0 ? 1 : (totalData / perPage).ceil();

  List<Map<String, dynamic>> get _paged {
    final start = (currentPage - 1) * perPage;
    final end = (start + perPage).clamp(0, responses.length);
    if (start >= responses.length) return [];
    return responses.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Box Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F2), // surface-container-low
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Cari survey atau provinsi...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6F7A6B)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF6F7A6B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Cards List
        if (_paged.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Belum ada data respon',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6F7A6B),
                ),
              ),
            ),
          )
        else
          ..._paged.map(
            (r) => _CardWidget(
              response: r,
              onDeleteResponse: onDeleteResponse,
              onEditResponse: onEditResponse,
            ),
          ),
        const SizedBox(height: 16),
        // Pagination
        Align(
          alignment: Alignment.center,
          child: _Pagination(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
        ),
      ],
    );
  }
}

class _CardWidget extends StatelessWidget {
  final Map<String, dynamic> response;
  final void Function(
    int responseId,
    String surveySlug,
    String clientSlug,
    String projectSlug,
  )? onDeleteResponse;
  final void Function(
    int responseId,
    String surveySlug,
    String clientSlug,
    String projectSlug,
    Map<String, dynamic> responseData,
  )? onEditResponse;

  const _CardWidget({
    required this.response,
    this.onDeleteResponse,
    this.onEditResponse,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MonitoringProvider>();
    final clientSlug = provider.clientSlug;
    final projectSlug = provider.projectSlug;

    final user = response['user'] as Map<String, dynamic>?;
    final biodata = user?['biodata'] as Map<String, dynamic>?;

    final waktu = _fmtDate(response['created_at'] ?? '');
    final nama = user?['name'] ?? '-';
    final token = user?['email'] ?? '';
    final provinsi = _provinsi(biodata);
    final role = _role(user);

    final responseId = int.tryParse((response['id'] ?? response['response_id'] ?? 0).toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E3E1).withValues(alpha: 0.3)), // outline-variant
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000), // 0.02 opacity
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOURCE & TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6F7A6B),
                        letterSpacing: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      token.isNotEmpty ? token : nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1B),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      waktu,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6F7A6B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: _getModerationStatus(response)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEditResponse != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF006B1B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => onEditResponse!(
                            responseId,
                            provider.surveySlug,
                            clientSlug,
                            projectSlug,
                            response,
                          ),
                        ),
                      if (onEditResponse != null && onDeleteResponse != null) const SizedBox(width: 8),
                      if (onDeleteResponse != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFBA1A1A)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Data'),
                                content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      onDeleteResponse!(responseId, provider.surveySlug, clientSlug, projectSlug);
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider Replacement (border-y)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: const Color(0xFFE1E3E1).withValues(alpha: 0.5)),
                bottom: BorderSide(color: const Color(0xFFE1E3E1).withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROVINCE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6F7A6B), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Color(0xFF7DDC7A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              provinsi,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3F4A3D)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROLE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6F7A6B), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Color(0xFF7DDC7A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              role,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3F4A3D)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Full width button
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(
                      name: '/lihat_monitor',
                      arguments: {
                        'surveySlug': provider.surveySlug,
                        'clientSlug': clientSlug,
                        'projectSlug': projectSlug,
                        'responseId': responseId,
                      },
                    ),
                    builder: (_) => LihatMonitorPage(
                      responseId: responseId,
                      surveySlug: provider.surveySlug,
                      clientSlug: clientSlug,
                      projectSlug: projectSlug,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F2), // surface-container-low
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006B1B),
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModerationStatus(Map<String, dynamic> r) {
    final dynamic s =
        r['supervision_status'] ??
        r['moderation_status'] ??
        r['status_review'] ??
        r['review_status'] ??
        r['status_moderasi'] ??
        r['status'];

    if (s == null) return 'PENDING';

    final str = s.toString().toLowerCase();

    if (str == 'pending' || str.isEmpty) return 'PENDING';
    if (str == 'revision_needed' || str == 'revision') return 'REVISION';
    if (str == 'approve' || str == 'approved') return 'APPROVE';
    if (str == 'decline' || str == 'declined') return 'DECLINE';

    if (s is int) {
      switch (s) {
        case 0:
          return 'PENDING';
        case 1:
          return 'REVISION';
        case 2:
          return 'APPROVE';
        case 3:
          return 'DECLINE';
        default:
          return 'PENDING';
      }
    }

    if (s is bool) {
      if (r['is_approved'] == true) return 'APPROVE';
      if (r['is_revision'] == true) return 'REVISION';
      return (s == true) ? 'PENDING' : 'DRAFT';
    }

    return 'PENDING';
  }

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final m = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month]} ${dt.year} • '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
    } catch (_) {
      return raw;
    }
  }

  String _provinsi(Map<String, dynamic>? b) {
    if (b == null) return 'Tidak ada';
    final name = b['province_name'];
    if (name != null && name.toString().isNotEmpty) return name.toString();
    final id = b['province_id'];
    if (id == null) return 'Tidak ada';
    return 'Prov. $id';
  }

  String _role(Map<String, dynamic>? u) {
    if (u == null) return 'Lainnya';
    switch ((u['usertype'] as String? ?? '').toLowerCase()) {
      case 'superadmin':
        return 'S.Admin';
      case 'admin':
        return 'Admin';
      case 'enumerator':
        return 'Enum.';
      default:
        return 'Lainnya';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String s = status.toUpperCase();

    if (s == 'TRUE' || s == '1') {
      s = 'PENDING';
    } else if (s == 'FALSE' || s == '0' || s == 'NULL' || s.isEmpty) {
      s = 'PENDING';
    }

    Color bgColor = const Color(0xFFFEF9C3); // yellow-50
    Color textColor = const Color(0xFFA16207); // yellow-700
    Color borderColor = const Color(0xFFFEF08A); // yellow-200
    Color dotColor = const Color(0xFFEAB308); // yellow-500

    if (s.contains('REVISION')) {
      s = 'REVISION';
      bgColor = const Color(0xFFFEF2F2); // red-50
      textColor = const Color(0xFFBA1A1A); // error
      borderColor = const Color(0xFFFEE2E2); // red-100
      dotColor = const Color(0xFFBA1A1A); // error
    } else if (s.contains('APPROVE') || s.contains('ACCEPTED')) {
      s = 'ACCEPTED';
      bgColor = const Color(0xFFF0FDF4); // green-50
      textColor = const Color(0xFF006B1B); // primary
      borderColor = const Color(0xFFDCFCE7); // green-100
      dotColor = const Color(0xFF006B1B); // primary
    } else if (s.contains('DECLINE')) {
      s = 'DECLINE';
      bgColor = const Color(0xFFFEF2F2); // red-50
      textColor = const Color(0xFFBA1A1A); // error
      borderColor = const Color(0xFFFEE2E2); // red-100
      dotColor = const Color(0xFFBA1A1A); // error
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            s,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<int> get _pages {
    if (totalPages <= 5) return List.generate(totalPages, (i) => i + 1);
    final r = <int>[1];
    if (currentPage > 3) r.add(-1);
    for (var i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i > 1 && i < totalPages) r.add(i);
    }
    if (currentPage < totalPages - 2) r.add(-1);
    r.add(totalPages);
    return r;
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _PBtn(
        child: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF6F7A6B)),
        onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
      ),
      const SizedBox(width: 8),
      ..._pages.map((p) {
        if (p == -1) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(fontSize: 14, color: Color(0xFF6F7A6B))),
          );
        }
        final active = p == currentPage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _PBtn(
            isActive: active,
            onTap: () => onPageChanged(p),
            child: Text(
              '$p',
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.white : const Color(0xFF3F4A3D),
              ),
            ),
          ),
        );
      }),
      const SizedBox(width: 8),
      _PBtn(
        child: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF6F7A6B)),
        onTap: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
      ),
    ],
  );
}

class _PBtn extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback? onTap;
  const _PBtn({required this.child, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF006B1B) : const Color(0xFFFFFFFF),
        shape: BoxShape.circle,
        boxShadow: isActive ? [BoxShadow(color: const Color(0xFF006B1B).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: Center(child: child),
    ),
  );
}
