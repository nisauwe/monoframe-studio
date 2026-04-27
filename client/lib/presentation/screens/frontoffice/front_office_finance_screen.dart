import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/front_office_provider.dart';
import 'front_office_expense_form_screen.dart';

class FrontOfficeFinanceScreen extends StatefulWidget {
  const FrontOfficeFinanceScreen({super.key});

  @override
  State<FrontOfficeFinanceScreen> createState() =>
      _FrontOfficeFinanceScreenState();
}

class _FrontOfficeFinanceScreenState extends State<FrontOfficeFinanceScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchFinanceSummary();
    });
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final summary = provider.financeSummary;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchFinanceSummary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Keuangan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ringkasan pemasukan, pengeluaran, dan saldo operasional.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              if (provider.isLoading && summary == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _FinanceSummaryCard(
                  title: 'Pemasukan',
                  value: formatCurrency(summary?.income ?? 0),
                  color: Colors.green,
                ),
                _FinanceSummaryCard(
                  title: 'Pengeluaran',
                  value: formatCurrency(summary?.expenses ?? 0),
                  color: Colors.red,
                ),
                _FinanceSummaryCard(
                  title: 'Saldo',
                  value: formatCurrency(summary?.balance ?? 0),
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FrontOfficeExpenseFormScreen(),
                        ),
                      );

                      if (!mounted) return;
                      context.read<FrontOfficeProvider>().fetchFinanceSummary();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Input Pengeluaran'),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Pembayaran Terbaru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                if (summary?.recentPayments.isEmpty ?? true)
                  const Text('Belum ada pembayaran.')
                else
                  ...summary!.recentPayments.map((payment) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(payment.clientName),
                        subtitle: Text(
                          '${payment.packageName} • ${payment.paymentStage}',
                        ),
                        trailing: Text(
                          formatCurrency(payment.baseAmount),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                const Text(
                  'Pengeluaran Terbaru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                if (summary?.recentExpenses.isEmpty ?? true)
                  const Text('Belum ada pengeluaran.')
                else
                  ...summary!.recentExpenses.map((expense) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(expense.category),
                        subtitle: Text(expense.description),
                        trailing: Text(
                          formatCurrency(expense.amount),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _FinanceSummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet_outlined, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
