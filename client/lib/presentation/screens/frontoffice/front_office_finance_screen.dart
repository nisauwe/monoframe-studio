import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/front_office_models.dart';
import '../../../data/providers/front_office_provider.dart';
import 'front_office_expense_form_screen.dart';
import 'front_office_income_form_screen.dart';

class FrontOfficeFinanceScreen extends StatefulWidget {
  const FrontOfficeFinanceScreen({super.key});

  @override
  State<FrontOfficeFinanceScreen> createState() =>
      _FrontOfficeFinanceScreenState();
}

class _FrontOfficeFinanceScreenState extends State<FrontOfficeFinanceScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFinance();
    });
  }

  Future<void> _fetchFinance() {
    return context.read<FrontOfficeProvider>().fetchFinanceSummary(
      startDate: _formatDate(_startDate),
      endDate: _formatDate(_endDate),
    );
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatHumanDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  String _formatHistoryDate(String value) {
    final text = value.trim();

    if (text.isEmpty) return '-';

    final normalized = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);

    if (parsed == null) return text;

    return DateFormat('d MMM yyyy', 'id_ID').format(parsed);
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.welcomeBlueDark,
              surface: AppColors.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;

    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });

    await _fetchFinance();
  }

  Future<void> _openIncomeForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FrontOfficeIncomeFormScreen()),
    );

    if (!mounted) return;
    await _fetchFinance();
  }

  Future<void> _openExpenseForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FrontOfficeExpenseFormScreen()),
    );

    if (!mounted) return;
    await _fetchFinance();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final summary = provider.financeSummary;

    final income = summary?.income ?? 0;
    final expenses = summary?.expenses ?? 0;
    final balance = summary?.balance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
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
          child: RefreshIndicator(
            color: AppColors.welcomeBlueDark,
            backgroundColor: AppColors.welcomeCardLight,
            onRefresh: _fetchFinance,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
              children: [
                _FinanceHeroCard(
                  start: _formatHumanDate(_startDate),
                  end: _formatHumanDate(_endDate),
                  balance: _formatCurrency(balance),
                  income: _formatCurrency(income),
                  expense: _formatCurrency(expenses),
                  onPickRange: _pickRange,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.remove_circle_outline_rounded,
                        title: 'Input Pengeluaran',
                        subtitle: 'Catat biaya operasional',
                        color: AppColors.danger,
                        onTap: _openExpenseForm,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Pemasukan Manual',
                        subtitle: 'Tambah pemasukan lain',
                        color: AppColors.welcomeBlueDark,
                        onTap: _openIncomeForm,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                if (provider.isLoading && summary == null)
                  const _LoadingState()
                else ...[
                  _BreakdownGrid(
                    bookingIncome: _formatCurrency(
                      summary?.bookingPaymentIncome ?? 0,
                    ),
                    printIncome: _formatCurrency(
                      summary?.printPaymentIncome ?? 0,
                    ),
                    manualIncome: _formatCurrency(summary?.manualIncome ?? 0),
                    expense: _formatCurrency(summary?.expenses ?? 0),
                  ),

                  const SizedBox(height: 20),

                  const _SectionTitle(
                    title: 'Pembayaran Sistem',
                    subtitle:
                        'Pemasukan dari payment gateway booking dan cetak.',
                  ),

                  const SizedBox(height: 12),

                  if (summary == null || summary.recentPayments.isEmpty)
                    const _EmptyStateCard(
                      icon: Icons.payments_outlined,
                      title: 'Belum ada pembayaran sistem',
                      message:
                          'Pembayaran booking dan cetak dari payment gateway akan tampil di sini.',
                    )
                  else
                    ...summary.recentPayments.map(
                      (payment) => _PaymentTile(
                        payment: payment,
                        amountText: _formatCurrency(payment.baseAmount),
                        dateText: _formatHistoryDate(payment.paidAt),
                      ),
                    ),

                  const SizedBox(height: 22),

                  const _SectionTitle(
                    title: 'Pemasukan Manual',
                    subtitle: 'Catatan pemasukan tambahan dari Front Office.',
                  ),

                  const SizedBox(height: 12),

                  if (summary == null || summary.recentIncomes.isEmpty)
                    const _EmptyStateCard(
                      icon: Icons.add_card_outlined,
                      title: 'Belum ada pemasukan manual',
                      message:
                          'Pemasukan tambahan yang dibuat Front Office akan muncul di sini.',
                    )
                  else
                    ...summary.recentIncomes.map(
                      (income) => _IncomeTile(
                        income: income,
                        amountText: _formatCurrency(income.amount),
                        dateText: _formatHistoryDate(income.incomeDate),
                      ),
                    ),

                  const SizedBox(height: 22),

                  const _SectionTitle(
                    title: 'Pengeluaran Operasional',
                    subtitle:
                        'Biaya studio, transport, cetak, dan kebutuhan lain.',
                  ),

                  const SizedBox(height: 12),

                  if (summary == null || summary.recentExpenses.isEmpty)
                    const _EmptyStateCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada pengeluaran',
                      message:
                          'Pengeluaran operasional yang dicatat akan muncul di sini.',
                    )
                  else
                    ...summary.recentExpenses.map(
                      (expense) => _ExpenseTile(
                        expense: expense,
                        amountText: _formatCurrency(expense.amount),
                        dateText: _formatHistoryDate(expense.expenseDate),
                      ),
                    ),

                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorMessageBox(message: provider.errorMessage!),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceHeroCard extends StatelessWidget {
  final String start;
  final String end;
  final String balance;
  final String income;
  final String expense;
  final VoidCallback onPickRange;

  const _FinanceHeroCard({
    required this.start,
    required this.end,
    required this.balance,
    required this.income,
    required this.expense,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.20),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -46,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 38,
            bottom: -56,
            child: Container(
              width: 114,
              height: 114,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keuangan Studio',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Pantau pemasukan, pengeluaran, dan saldo periode.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.74),
                              fontSize: 12.8,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Material(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: onPickRange,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$start - $end',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Saldo Bersih',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  balance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _HeroFinancePill(
                        icon: Icons.trending_up_rounded,
                        label: 'Pemasukan',
                        value: income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroFinancePill(
                        icon: Icons.trending_down_rounded,
                        label: 'Pengeluaran',
                        value: expense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFinancePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroFinancePill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.welcomeCardDeep),
            boxShadow: [
              BoxShadow(
                color: AppColors.welcomeBlueDark.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.14)),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color.withOpacity(0.60),
                        fontSize: 10.8,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
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

class _BreakdownGrid extends StatelessWidget {
  final String bookingIncome;
  final String printIncome;
  final String manualIncome;
  final String expense;

  const _BreakdownGrid({
    required this.bookingIncome,
    required this.printIncome,
    required this.manualIncome,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.20,
      children: [
        _BreakdownCard(
          title: 'Booking',
          value: bookingIncome,
          icon: Icons.camera_alt_rounded,
          color: AppColors.welcomeBlueDark,
        ),
        _BreakdownCard(
          title: 'Cetak Foto',
          value: printIncome,
          icon: Icons.local_printshop_rounded,
          color: AppColors.welcomeBlueMid,
        ),
        _BreakdownCard(
          title: 'Manual',
          value: manualIncome,
          icon: Icons.add_card_rounded,
          color: AppColors.success,
        ),
        _BreakdownCard(
          title: 'Keluar',
          value: expense,
          icon: Icons.receipt_long_rounded,
          color: AppColors.danger,
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _BreakdownCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.welcomeCardDeep),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.14)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withOpacity(0.66),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
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

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12.3,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final FoPaymentModel payment;
  final String amountText;
  final String dateText;

  const _PaymentTile({
    required this.payment,
    required this.amountText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return _FinanceHistoryCard(
      icon: Icons.payments_rounded,
      color: AppColors.success,
      title: payment.clientName,
      subtitle: payment.packageName,
      dateText: dateText,
      meta: payment.paymentStageLabel,
      amountText: '+$amountText',
      amountColor: AppColors.success,
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final FoIncomeModel income;
  final String amountText;
  final String dateText;

  const _IncomeTile({
    required this.income,
    required this.amountText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return _FinanceHistoryCard(
      icon: Icons.add_card_rounded,
      color: AppColors.success,
      title: income.category,
      subtitle: income.description.isEmpty
          ? 'Dibuat oleh ${income.createdBy}'
          : income.description,
      dateText: dateText,
      meta: 'Pemasukan Manual',
      amountText: '+$amountText',
      amountColor: AppColors.success,
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final FoExpenseModel expense;
  final String amountText;
  final String dateText;

  const _ExpenseTile({
    required this.expense,
    required this.amountText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return _FinanceHistoryCard(
      icon: Icons.receipt_long_rounded,
      color: AppColors.danger,
      title: expense.category,
      subtitle: expense.description.isEmpty
          ? 'Dibuat oleh ${expense.createdBy}'
          : expense.description,
      dateText: dateText,
      meta: 'Pengeluaran',
      amountText: '-$amountText',
      amountColor: AppColors.danger,
    );
  }
}

class _FinanceHistoryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String dateText;
  final String meta;
  final String amountText;
  final Color amountColor;

  const _FinanceHistoryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.meta,
    required this.amountText,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim().isEmpty ? '-' : title.trim();
    final cleanSubtitle = subtitle.trim().isEmpty ? '-' : subtitle.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.welcomeCardDeep),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.14)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  cleanSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.55),
                    fontSize: 11.8,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _SmallInfoChip(
                      icon: Icons.calendar_month_rounded,
                      label: dateText,
                      color: AppColors.welcomeBlueDark,
                    ),
                    _SmallInfoChip(
                      icon: Icons.bookmark_rounded,
                      label: meta,
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: amountColor,
              fontSize: 12.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clean = label.trim().isEmpty ? '-' : label.trim();

    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            clean,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
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
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.66),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.welcomeBlueDark, size: 35),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 110),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.welcomeBlueDark),
      ),
    );
  }
}

class _ErrorMessageBox extends StatelessWidget {
  final String message;

  const _ErrorMessageBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 11.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
