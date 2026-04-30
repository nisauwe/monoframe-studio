import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/front_office_provider.dart';
import '../auth/auth_welcome_screen.dart';
import 'front_office_manual_booking_screen.dart';

class FrontOfficeDashboardScreen extends StatefulWidget {
  const FrontOfficeDashboardScreen({super.key});

  @override
  State<FrontOfficeDashboardScreen> createState() =>
      _FrontOfficeDashboardScreenState();
}

class _FrontOfficeDashboardScreenState
    extends State<FrontOfficeDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchDashboardData();
    });
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

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _todayLabel() {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
  }

  String _shortDateLabel() {
    return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.now());
  }

  String _paymentStageLabel(String value) {
    final stage = value.toLowerCase();

    if (stage == 'dp') return 'DP Booking';
    if (stage == 'full') return 'Pelunasan';
    if (stage == 'print') return 'Cetak Foto';
    if (stage == 'print_order') return 'Cetak Foto';

    return value.isEmpty ? 'Pembayaran' : value;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final auth = context.watch<AuthProvider>();
    final finance = provider.financeSummary;

    final assignCount = provider.assignableBookings.length;
    final calendarCount = provider.calendarEvents.length;
    final progressCount = provider.progressList.length;
    final printCount = provider.printOrders.length;
    final reviewCount = provider.reviewCount;

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
          onRefresh: provider.fetchDashboardData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
            children: [
              _TopGreetingBar(
                name: auth.user?.name ?? 'Front Office',
                onLogout: () => _logout(context),
              ),

              const SizedBox(height: 14),

              _DashboardHero(
                name: auth.user?.name ?? 'Front Office',
                dateLabel: _todayLabel(),
                shortDateLabel: _shortDateLabel(),
                assignCount: assignCount,
                todayScheduleCount: calendarCount,
                balance: _formatCurrency(finance?.balance ?? 0),
              ),

              const SizedBox(height: 18),

              if (provider.isLoading && finance == null)
                const _LoadingCard()
              else ...[
                const _SectionTitle(
                  title: 'Ringkasan Operasional',
                  subtitle: 'Pantau pekerjaan Front Office hari ini',
                  trailingText: 'Live',
                ),

                const SizedBox(height: 12),

                _PriorityCard(
                  assignCount: assignCount,
                  progressCount: progressCount,
                  printCount: printCount,
                ),

                const SizedBox(height: 14),

                _OperationalShortcutGrid(
                  reviewCount: reviewCount,
                  calendarCount: calendarCount,
                  progressCount: progressCount,
                  printCount: printCount,
                ),

                const SizedBox(height: 20),

                const _SectionTitle(
                  title: 'Aksi Cepat',
                  subtitle: 'Shortcut pekerjaan yang paling sering dipakai',
                ),

                const SizedBox(height: 12),

                _QuickBookingCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FrontOfficeManualBookingScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                const _SectionTitle(
                  title: 'Keuangan Studio',
                  subtitle: 'Pemasukan, pengeluaran, dan saldo periode ini',
                ),

                const SizedBox(height: 12),

                _FinanceOverviewCard(
                  income: _formatCurrency(finance?.income ?? 0),
                  expense: _formatCurrency(finance?.expenses ?? 0),
                  balance: _formatCurrency(finance?.balance ?? 0),
                ),

                const SizedBox(height: 20),

                const _SectionTitle(
                  title: 'Aktivitas Terbaru',
                  subtitle: 'Transaksi masuk dan catatan operasional',
                ),

                const SizedBox(height: 12),

                _RecentActivityTabs(
                  payments:
                      finance?.recentPayments
                          .take(4)
                          .map(
                            (payment) => _ActivityItemData(
                              icon: Icons.payments_outlined,
                              title: payment.clientName,
                              subtitle:
                                  '${payment.packageName} • ${_paymentStageLabel(payment.paymentStage)}',
                              amount: '+${_formatCurrency(payment.baseAmount)}',
                              color: AppColors.success,
                            ),
                          )
                          .toList() ??
                      [],
                  expenses:
                      finance?.recentExpenses
                          .take(4)
                          .map(
                            (expense) => _ActivityItemData(
                              icon: Icons.receipt_long_outlined,
                              title: expense.category,
                              subtitle: expense.description.isEmpty
                                  ? expense.expenseDate
                                  : expense.description,
                              amount: '-${_formatCurrency(expense.amount)}',
                              color: AppColors.danger,
                            ),
                          )
                          .toList() ??
                      [],
                ),

                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBox(message: provider.errorMessage!),
                ],
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
    final firstName = name.trim().isEmpty ? 'Front Office' : name.trim();

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
            Icons.storefront_rounded,
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
                'Front Office',
                style: TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
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
  final String dateLabel;
  final String shortDateLabel;
  final int assignCount;
  final int todayScheduleCount;
  final String balance;

  const _DashboardHero({
    required this.name,
    required this.dateLabel,
    required this.shortDateLabel,
    required this.assignCount,
    required this.todayScheduleCount,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Front Office' : name.trim();

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
                  dateText: shortDateLabel,
                ),

                const SizedBox(height: 18),

                Text(
                  'Halo, $displayName',
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
                  dateLabel,
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
                        icon: Icons.assignment_ind_rounded,
                        label: 'Assign',
                        value: '$assignCount',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HeroMetricPill(
                        icon: Icons.event_available_rounded,
                        label: 'Jadwal',
                        value: '$todayScheduleCount',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                _HeroBalanceStrip(balance: balance),
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
  final String balance;

  const _HeroBalanceStrip({required this.balance});

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
            Icons.account_balance_wallet_rounded,
            color: AppColors.white,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            'Saldo periode',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.82),
              fontWeight: FontWeight.w700,
              fontSize: 10.8,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              balance,
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
  final int assignCount;
  final int progressCount;
  final int printCount;

  const _PriorityCard({
    required this.assignCount,
    required this.progressCount,
    required this.printCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasPriority = assignCount > 0 || printCount > 0;

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
                  hasPriority
                      ? 'Ada pekerjaan yang perlu dicek'
                      : 'Operasional aman',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPriority
                      ? '$assignCount booking perlu assign, $printCount pesanan cetak perlu dipantau.'
                      : '$progressCount booking sedang berjalan dan belum ada prioritas mendesak.',
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

class _QuickBookingCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickBookingCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.17),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Manual',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Input booking klien offline langsung dari front office.',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.78),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationalShortcutGrid extends StatelessWidget {
  final int reviewCount;
  final int calendarCount;
  final int progressCount;
  final int printCount;

  const _OperationalShortcutGrid({
    required this.reviewCount,
    required this.calendarCount,
    required this.progressCount,
    required this.printCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniActionCard(
                icon: Icons.rate_review_rounded,
                title: 'Review',
                subtitle: '$reviewCount ulasan',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniActionCard(
                icon: Icons.calendar_month_rounded,
                title: 'Jadwal Bulan Ini',
                subtitle: '$calendarCount agenda',
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
                icon: Icons.track_changes_rounded,
                title: 'Progress',
                subtitle: '$progressCount booking berjalan',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniActionCard(
                icon: Icons.photo_filter_outlined,
                title: 'Cetak',
                subtitle: '$printCount order',
                color: AppColors.success,
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

class _FinanceOverviewCard extends StatelessWidget {
  final String income;
  final String expense;
  final String balance;

  const _FinanceOverviewCard({
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              gradient: AppColors.welcomeCardGradient,
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.welcomeBlueDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Periode Ini',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        balance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.welcomeBlueDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _FinancePill(
                    label: 'Pemasukan',
                    value: income,
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FinancePill(
                    label: 'Pengeluaran',
                    value: expense,
                    icon: Icons.trending_down_rounded,
                    color: AppColors.danger,
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

class _FinancePill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FinancePill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  const _ActivityItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });
}

class _RecentActivityTabs extends StatefulWidget {
  final List<_ActivityItemData> payments;
  final List<_ActivityItemData> expenses;

  const _RecentActivityTabs({required this.payments, required this.expenses});

  @override
  State<_RecentActivityTabs> createState() => _RecentActivityTabsState();
}

class _RecentActivityTabsState extends State<_RecentActivityTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = _selectedIndex == 0 ? widget.payments : widget.expenses;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActivityTabButton(
                  label: 'Pembayaran',
                  active: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActivityTabButton(
                  label: 'Pengeluaran',
                  active: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyMiniCard(
              message: _selectedIndex == 0
                  ? 'Belum ada pembayaran terbaru.'
                  : 'Belum ada pengeluaran terbaru.',
            )
          else
            ...items.map((item) => _ActivityTile(item: item)),
        ],
      ),
    );
  }
}

class _ActivityTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActivityTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primaryDark : AppColors.primarySoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppColors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItemData item;

  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? '-' : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle.isEmpty ? '-' : item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.amount,
            style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMiniCard extends StatelessWidget {
  final String message;

  const _EmptyMiniCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.grey,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
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
      child: const CircularProgressIndicator(),
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
