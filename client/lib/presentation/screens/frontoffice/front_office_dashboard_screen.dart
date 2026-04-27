import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/front_office_provider.dart';
import '../auth/login_screen.dart';
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
    final auth = context.watch<AuthProvider>();
    final finance = provider.financeSummary;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Front Office',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            Text(
              'Halo, ${auth.user?.name ?? 'Front Office'}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            if (provider.isLoading && finance == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _SummaryCard(
                    title: 'Perlu Assign',
                    value: provider.assignableBookings.length.toString(),
                    icon: Icons.assignment_ind,
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    title: 'Jadwal Bulan Ini',
                    value: provider.calendarEvents.length.toString(),
                    icon: Icons.calendar_month,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    title: 'Monitoring',
                    value: provider.progressList.length.toString(),
                    icon: Icons.track_changes,
                    color: Colors.purple,
                  ),
                  _SummaryCard(
                    title: 'Pesanan Cetak',
                    value: provider.printOrders.length.toString(),
                    icon: Icons.print,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Booking Manual'),
                  subtitle: const Text(
                    'Input booking klien yang datang langsung/offline',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FrontOfficeManualBookingScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Ringkasan Keuangan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 12),

              _FinanceCard(
                title: 'Pemasukan',
                value: formatCurrency(finance?.income ?? 0),
                color: Colors.green,
              ),
              _FinanceCard(
                title: 'Pengeluaran',
                value: formatCurrency(finance?.expenses ?? 0),
                color: Colors.red,
              ),
              _FinanceCard(
                title: 'Saldo',
                value: formatCurrency(finance?.balance ?? 0),
                color: Colors.blue,
              ),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: color,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _FinanceCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.payments_outlined, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
