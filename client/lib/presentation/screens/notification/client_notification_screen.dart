import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/client_notification_model.dart';
import '../../../data/providers/client_notification_provider.dart';
import '../package/package_detail_screen.dart';
import '../tracking/tracking_detail_screen.dart';

class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() =>
      _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientNotificationProvider>().fetchNotifications();
    });
  }

  IconData _icon(String icon) {
    switch (icon) {
      case 'discount':
        return Icons.local_offer_outlined;
      case 'booking':
        return Icons.event_available_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'paid':
        return Icons.verified_outlined;
      case 'camera':
        return Icons.photo_camera_outlined;
      case 'calendar':
        return Icons.calendar_month_outlined;
      case 'photo':
        return Icons.photo_library_outlined;
      case 'edit':
        return Icons.edit_note_outlined;
      case 'print':
        return Icons.print_outlined;
      case 'review':
        return Icons.star_outline_rounded;
      case 'heart':
        return Icons.favorite_border_rounded;
      case 'done':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date.toLocal());
  }

  void _openAction(ClientNotificationModel item) {
    if (item.actionType == 'package' && item.actionId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PackageDetailScreen(packageId: item.actionId!),
        ),
      );
      return;
    }

    if (item.actionType == 'booking' && item.actionId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingDetailScreen(bookingId: item.actionId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientNotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('Notifikasi')),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: provider.isLoading && provider.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (provider.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (provider.notifications.isEmpty)
                    const _EmptyNotification()
                  else
                    ...provider.notifications.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: () => _openAction(item),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withOpacity(
                                    0.05,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    _icon(item.icon),
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.body,
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          height: 1.45,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _dateLabel(item.createdAt),
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyNotification extends StatelessWidget {
  const _EmptyNotification();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primaryDark,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Promo, booking, pembayaran, tracking, edit, cetak, dan review akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
