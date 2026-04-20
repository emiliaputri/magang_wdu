import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client_model.dart';
import '../../pages/project_bpk_page.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  void _navigateToProjects(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/project_detail'),
        builder: (_) => ProjectBpkPage(client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              color: AppTheme.surfaceContainerLow,
              padding: const EdgeInsets.all(12),
              child: Builder(
                builder: (context) {
                  final url = client.imageUrl ?? client.image;
                  debugPrint(
                    '[ClientCard] ${client.clientName} - imageUrl: $url',
                  );
                  if (url != null && url.isNotEmpty) {
                    return Hero(
                      tag: 'client_${client.clientName}',
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surfaceContainerLow,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint(
                            '[ClientCard] ERROR loading image for ${client.clientName}: $error',
                          );
                          return _buildFallback(client.clientName);
                        },
                      ),
                    );
                  }
                  return _buildFallback(client.clientName);
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.alamat ?? 'No address available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToProjects(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VIEW PROJECTS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 10,
                                  color: AppTheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(String name) {
    return _imagePlaceholder(name);
  }

  Widget _imagePlaceholder(String name) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_rounded,
                size: 32,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                name,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
