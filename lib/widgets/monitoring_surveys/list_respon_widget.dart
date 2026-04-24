import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/monitoring_provider.dart';
import '../../pages/lihat_monitor_page.dart';
import '../../core/theme/app_theme.dart';

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
        // Compact List
        if (_paged.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Belum ada data respon',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paged.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.outlineVariant.withOpacity(0.05),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) => _ListItemWidget(
                response: _paged[index],
                onDeleteResponse: onDeleteResponse,
                onEditResponse: onEditResponse,
              ),
            ),
          ),
        const SizedBox(height: 24),
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

class _ListItemWidget extends StatelessWidget {
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

  const _ListItemWidget({
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

    final waktu = _fmtDate(response['updated_at'] ?? response['created_at'] ?? '');
    final nama = user?['name'] ?? '-';
    final token = user?['email'] ?? '';

    final responseId = int.tryParse((response['id'] ?? response['response_id'] ?? 0).toString()) ?? 0;
    final identity = token.isNotEmpty ? token : nama;

    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Response #$responseId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        waktu,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                      if (identity.isNotEmpty && identity != '-') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            identity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: _getModerationStatus(response)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEditResponse != null)
                      _miniAction(
                        icon: Icons.edit_outlined,
                        color: AppTheme.primary,
                        onTap: () => onEditResponse!(
                          responseId,
                          provider.surveySlug,
                          clientSlug,
                          projectSlug,
                          response,
                        ),
                      ),
                    if (onEditResponse != null && onDeleteResponse != null) const SizedBox(width: 8),
                    if (onDeleteResponse != null)
                      _miniAction(
                        icon: Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        onTap: () {
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
      ),
    );
  }

  Widget _miniAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
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
      return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month]} ${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
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

    Color color = const Color(0xFFF59E0B); // Pending (Amber)
    if (s.contains('REVISION')) {
      s = 'REVISION';
      color = const Color(0xFFEF4444); // Revision (Red)
    } else if (s.contains('APPROVE') || s.contains('ACCEPTED')) {
      s = 'ACCEPTED';
      color = const Color(0xFF10B981); // Approved (Emerald)
    } else if (s.contains('DECLINE')) {
      s = 'DECLINE';
      color = const Color(0xFF6366F1); // Declined (Indigo)
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            s,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PBtn(
          child: const Icon(Icons.chevron_left, size: 20, color: AppTheme.onSurfaceVariant),
          onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        const SizedBox(width: 8),
        ..._pages.map((p) {
          if (p == -1) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
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
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? Colors.white : AppTheme.onSurface,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _PBtn(
          child: const Icon(Icons.chevron_right, size: 20, color: AppTheme.onSurfaceVariant),
          onTap: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    ),
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.ijoGelap : Colors.white,
        shape: BoxShape.circle,
        border: isActive ? null : Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        boxShadow: isActive ? [BoxShadow(color: AppTheme.ijoGelap.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: Center(child: child),
    ),
  );
}
