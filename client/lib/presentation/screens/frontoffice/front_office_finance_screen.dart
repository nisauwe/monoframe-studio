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
              primary: AppColors.primaryDark,
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

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: _fetchFinance,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              _FinanceHero(
                start: _formatHumanDate(_startDate),
                end: _formatHumanDate(_endDate),
                onPickRange: _pickRange,
              ),
              const SizedBox(height: 18),

              if (provider.isLoading && summary == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _MainBalanceCard(
                  balance: _formatCurrency(summary?.balance ?? 0),
                  income: _formatCurrency(summary?.income ?? 0),
                  expense: _formatCurrency(summary?.expenses ?? 0),
                ),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _MiniFinanceCard(
                      title: 'Booking',
                      value: _formatCurrency(
                        summary?.bookingPaymentIncome ?? 0,
                      ),
                      icon: Icons.camera_alt_outlined,
                      color: AppColors.primaryDark,
                    ),
                    _MiniFinanceCard(
                      title: 'Cetak',
                      value: _formatCurrency(summary?.printPaymentIncome ?? 0),
                      icon: Icons.print_outlined,
                      color: AppColors.accent,
                    ),
                    _MiniFinanceCard(
                      title: 'Manual',
                      value: _formatCurrency(summary?.manualIncome ?? 0),
                      icon: Icons.add_card_outlined,
                      color: AppColors.success,
                    ),
                    _MiniFinanceCard(
                      title: 'Keluar',
                      value: _formatCurrency(summary?.expenses ?? 0),
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.danger,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openExpenseForm,
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Input Pengeluaran'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openIncomeForm,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Konfirmasi Pemasukan'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _SectionTitle(
                  title: 'Pembayaran Sistem',
                  subtitle: 'Pemasukan dari payment gateway booking/cetak',
                ),
                const SizedBox(height: 10),
                if (summary == null || summary.recentPayments.isEmpty)
                  const _EmptyState(message: 'Belum ada pembayaran sistem.')
                else
                  ...summary.recentPayments.map(
                    (payment) => _PaymentTile(
                      payment: payment,
                      amountText: _formatCurrency(payment.baseAmount),
                    ),
                  ),

                const SizedBox(height: 22),

                _SectionTitle(
                  title: 'Pemasukan Manual',
                  subtitle: 'Catatan pemasukan tambahan yang dibuat FO/admin',
                ),
                const SizedBox(height: 10),
                if (summary == null || summary.recentIncomes.isEmpty)
                  const _EmptyState(message: 'Belum ada pemasukan manual.')
                else
                  ...summary.recentIncomes.map(
                    (income) => _IncomeTile(
                      income: income,
                      amountText: _formatCurrency(income.amount),
                    ),
                  ),

                const SizedBox(height: 22),

                _SectionTitle(
                  title: 'Pengeluaran Operasional',
                  subtitle:
                      'Biaya studio, transport, cetak, dan kebutuhan lain',
                ),
                const SizedBox(height: 10),
                if (summary == null || summary.recentExpenses.isEmpty)
                  const _EmptyState(message: 'Belum ada pengeluaran.')
                else
                  ...summary.recentExpenses.map(
                    (expense) => _ExpenseTile(
                      expense: expense,
                      amountText: _formatCurrency(expense.amount),
                    ),
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

class _FinanceHero extends StatelessWidget {
  final String start;
  final String end;
  final VoidCallback onPickRange;

  const _FinanceHero({
    required this.start,
    required this.end,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.white,
              ),
              SizedBox(width: 9),
              Text(
                'Manajemen Keuangan',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Akses pemasukan payment gateway, pemasukan manual, pengeluaran, dan saldo periode.',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.78),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: AppColors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPickRange,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '$start - $end',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainBalanceCard extends StatelessWidget {
  final String balance;
  final String income;
  final String expense;

  const _MainBalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Bersih',
            style: TextStyle(
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balance,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalancePill(
                  label: 'Masuk',
                  value: income,
                  color: AppColors.success,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalancePill(
                  label: 'Keluar',
                  value: expense,
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _BalancePill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFinanceCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniFinanceCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
          height: 32,
          width: 5,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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

  const _PaymentTile({required this.payment, required this.amountText});

  @override
  Widget build(BuildContext context) {
    return _FinanceListTile(
      icon: Icons.payments_outlined,
      iconColor: AppColors.success,
      title: payment.clientName,
      subtitle: '${payment.packageName} • ${payment.paymentStageLabel}',
      trailing: '+$amountText',
      trailingColor: AppColors.success,
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final FoIncomeModel income;
  final String amountText;

  const _IncomeTile({required this.income, required this.amountText});

  @override
  Widget build(BuildContext context) {
    return _FinanceListTile(
      icon: Icons.add_card_outlined,
      iconColor: AppColors.success,
      title: income.category,
      subtitle: income.description.isEmpty
          ? income.incomeDate
          : '${income.incomeDate} • ${income.description}',
      trailing: '+$amountText',
      trailingColor: AppColors.success,
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final FoExpenseModel expense;
  final String amountText;

  const _ExpenseTile({required this.expense, required this.amountText});

  @override
  Widget build(BuildContext context) {
    return _FinanceListTile(
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.danger,
      title: expense.category,
      subtitle: expense.description.isEmpty
          ? expense.expenseDate
          : '${expense.expenseDate} • ${expense.description}',
      trailing: '-$amountText',
      trailingColor: AppColors.danger,
    );
  }
}

class _FinanceListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _FinanceListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '-' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.isEmpty ? '-' : subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(color: trailingColor, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
