import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/editor_provider.dart';
import '../auth/auth_welcome_screen.dart';
import 'editor_task_detail_screen.dart';

class EditorDashboardScreen extends StatefulWidget {
  const EditorDashboardScreen({super.key});

  @override
  State<EditorDashboardScreen> createState() => _EditorDashboardScreenState();
}

class _EditorDashboardScreenState extends State<EditorDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().fetchEditRequests();
    });
  }

  Future<void> _refresh() {
    return context.read<EditorProvider>().fetchEditRequests();
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
      (route) => false,
    );
  }

  void _openDetail(EditorEditRequestModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorTaskDetailScreen(editRequestId: item.id),
      ),
    );
  }

  String _shortName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) return 'Editor';

    final parts = trimmed.split(' ');

    if (parts.length == 1) return parts.first;

    return '${parts.first} ${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<EditorProvider>();

    final name = _shortName(auth.user?.name ?? 'Editor');
    final waitingCount = provider.waitingTasks.length;
    final inProgressCount = provider.inProgressTasks.length;
    final completedCount = provider.completedTasks.length;
    final totalCount = provider.editRequests.length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.secondary,
            AppColors.secondary,
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
            children: [
              _TopGreetingBar(
                name: auth.user?.name ?? 'Editor',
                onLogout: () => _logout(context),
              ),

              const SizedBox(height: 14),

              _DashboardHero(
                name: name,
                waitingCount: waitingCount,
                inProgressCount: inProgressCount,
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Ringkasan Editing',
                subtitle: 'Pantau request edit yang perlu kamu kerjakan',
                trailingText: 'Live',
              ),

              const SizedBox(height: 12),

              _PriorityCard(
                waitingCount: waitingCount,
                inProgressCount: inProgressCount,
              ),

              const SizedBox(height: 14),

              _EditorShortcutGrid(
                waitingCount: waitingCount,
                inProgressCount: inProgressCount,
                completedCount: completedCount,
                totalCount: totalCount,
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'Pekerjaan Aktif',
                subtitle: 'Request edit yang sedang menunggu atau diproses',
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && provider.editRequests.isEmpty)
                const _LoadingCard()
              else if (provider.activeTasks.isEmpty)
                const _EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'Belum ada pekerjaan aktif',
                  message:
                      'Pekerjaan edit yang sudah di-assign Front Office akan muncul di sini.',
                )
              else
                ...provider.activeTasks.take(5).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EditorTaskCard(
                      item: item,
                      onTap: () => _openDetail(item),
                    ),
                  );
                }),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 8),
                _ErrorBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopGreetingBar extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const _TopGreetingBar({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Editor' : name.trim();

    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeCardGradient,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.white.withOpacity(0.76)),
            boxShadow: [
              BoxShadow(
                color: AppColors.welcomeBlueDark.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_fix_high_rounded,
            color: AppColors.welcomeBlueDark,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editor',
                style: TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.primaryDark,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String name;
  final int waitingCount;
  final int inProgressCount;

  const _DashboardHero({
    required this.name,
    required this.waitingCount,
    required this.inProgressCount,
  });

  String _dayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return days[date.weekday - 1];
  }

  String _monthName(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[date.month - 1];
  }

  String _shortMonthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fullDate =
        '${_dayName(now)}, ${now.day} ${_monthName(now)} ${now.year}';
    final shortDate = '${now.day} ${_shortMonthName(now)} ${now.year}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -34,
            child: Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -42,
            child: Container(
              height: 104,
              width: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroStatusPill(
                  icon: Icons.verified_rounded,
                  text: 'Monoframe Studio',
                  dateText: shortDate,
                ),

                const SizedBox(height: 18),

                Text(
                  'Halo, $name',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  fullDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.78),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _HeroMetricPill(
                        icon: Icons.pending_actions_rounded,
                        label: 'Belum',
                        value: '$waitingCount',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HeroMetricPill(
                        icon: Icons.auto_fix_high_rounded,
                        label: 'Proses',
                        value: '$inProgressCount',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                _HeroBalanceStrip(
                  text: 'Fokus editing',
                  value: '$waitingCount request menunggu',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final String dateText;

  const _HeroStatusPill({
    required this.icon,
    required this.text,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withOpacity(0.18)),
          ),
          child: Icon(icon, color: AppColors.white, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.white.withOpacity(0.18)),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.82),
                fontWeight: FontWeight.w700,
                fontSize: 10.8,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceStrip extends StatelessWidget {
  final String text;
  final String value;

  const _HeroBalanceStrip({required this.text, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.white,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.82),
              fontWeight: FontWeight.w700,
              fontSize: 10.8,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailingText;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailingText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 6,
                  width: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final int waitingCount;
  final int inProgressCount;

  const _PriorityCard({
    required this.waitingCount,
    required this.inProgressCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasPriority = waitingCount > 0 || inProgressCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: hasPriority
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Color(0xFFEAF5FA)],
              )
            : AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withOpacity(0.74)),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.74),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.white),
            ),
            child: Icon(
              hasPriority
                  ? Icons.notifications_active_rounded
                  : Icons.check_circle_rounded,
              color: hasPriority ? AppColors.warning : AppColors.success,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPriority ? 'Ada pekerjaan edit' : 'Tugas aman',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPriority
                      ? '$waitingCount request belum dikerjakan dan $inProgressCount sedang diedit.'
                      : 'Tidak ada request edit aktif saat ini.',
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorShortcutGrid extends StatelessWidget {
  final int waitingCount;
  final int inProgressCount;
  final int completedCount;
  final int totalCount;

  const _EditorShortcutGrid({
    required this.waitingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniActionCard(
                icon: Icons.pending_actions_rounded,
                title: 'Belum',
                subtitle: '$waitingCount request',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniActionCard(
                icon: Icons.auto_fix_high_rounded,
                title: 'Proses',
                subtitle: '$inProgressCount request',
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniActionCard(
                icon: Icons.check_circle_rounded,
                title: 'Selesai',
                subtitle: '$completedCount request',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniActionCard(
                icon: Icons.assignment_rounded,
                title: 'Total',
                subtitle: '$totalCount request',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MiniActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1.08,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorTaskCard extends StatelessWidget {
  final EditorEditRequestModel item;
  final VoidCallback onTap;

  const _EditorTaskCard({required this.item, required this.onTap});

  Color _color() {
    if (item.isCompleted) return AppColors.success;
    if (item.isInProgress) return AppColors.primaryDark;

    return AppColors.warning;
  }

  IconData _icon() {
    if (item.isCompleted) return Icons.check_circle_rounded;
    if (item.isInProgress) return Icons.auto_fix_high_rounded;

    return Icons.pending_actions_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Material(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.welcomeBlueDark.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(0.14)),
                    ),
                    child: Icon(_icon(), color: color, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName.isEmpty ? 'Klien' : item.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.welcomeBlueDark,
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.welcomeBlueDark,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatusChip(label: item.statusLabel, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusChip(
                      label: '${item.selectedFiles.length} file',
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeCardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white.withOpacity(0.76)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.timer_rounded,
                        label: 'Deadline',
                        value: item.editDeadlineAt.isEmpty
                            ? '-'
                            : item.formattedEditDeadline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'Sisa Hari',
                        value: item.remainingDays == null
                            ? '-'
                            : '${item.remainingDays} hari',
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
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.welcomeBlueDark.withOpacity(0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.welcomeBlueDark,
                  fontSize: 11.2,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.60),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.welcomeBlueDark),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const CircularProgressIndicator(color: AppColors.primaryDark),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
