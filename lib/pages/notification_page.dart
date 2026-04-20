import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';
import '../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppTheme.primary),
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
            tooltip: 'Tandai semua dibaca',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () {
              context.read<NotificationProvider>().clearNotifications();
            },
            tooltip: 'Hapus semua',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.outline.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: GoogleFonts.inter(color: AppTheme.outline),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return Dismissible(
                key: Key(notification.id),
                onDismissed: (direction) {
                  // Not implemented in provider yet, but good for UI
                },
                child: GestureDetector(
                  onTap: () => provider.markAsRead(notification.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notification.isRead ? AppTheme.surface : AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notification.isRead 
                          ? AppTheme.outlineVariant.withOpacity(0.1) 
                          : AppTheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        if (!notification.isRead)
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: notification.isRead 
                                ? AppTheme.outlineVariant.withOpacity(0.1)
                                : AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notification.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                            color: notification.isRead ? AppTheme.outline : AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(notification.timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
