import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/front_office_provider.dart';

class FrontOfficePrintOrderDetailScreen extends StatefulWidget {
  final int printOrderId;

  const FrontOfficePrintOrderDetailScreen({
    super.key,
    required this.printOrderId,
  });

  @override
  State<FrontOfficePrintOrderDetailScreen> createState() =>
      _FrontOfficePrintOrderDetailScreenState();
}

class _FrontOfficePrintOrderDetailScreenState
    extends State<FrontOfficePrintOrderDetailScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchPrintOrderDetail(
        printOrderId: widget.printOrderId,
      );
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _confirm() async {
    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.confirmPrintOrder(
      printOrderId: widget.printOrderId,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pesanan cetak dikonfirmasi'
              : provider.errorMessage ?? 'Gagal konfirmasi',
        ),
      ),
    );
  }

  Future<void> _ready() async {
    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.markPrintOrderReady(
      printOrderId: widget.printOrderId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pesanan ditandai siap'
              : provider.errorMessage ?? 'Gagal update',
        ),
      ),
    );
  }

  Future<void> _complete() async {
    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.completePrintOrder(
      printOrderId: widget.printOrderId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pesanan cetak selesai'
              : provider.errorMessage ?? 'Gagal menyelesaikan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final order = provider.selectedPrintOrder;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Cetak')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return context.read<FrontOfficeProvider>().fetchPrintOrderDetail(
              printOrderId: widget.printOrderId,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (provider.isLoading && order == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (order == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: Text('Data tidak ditemukan')),
                )
              else ...[
                Text(
                  'Order Cetak #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.statusLabel,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                _InfoTile(title: 'Klien', value: order.clientName),
                _InfoTile(title: 'Paket', value: order.packageName),
                _InfoTile(title: 'Metode', value: order.deliveryMethod),
                _InfoTile(title: 'Alamat', value: order.deliveryAddress),
                _InfoTile(
                  title: 'Total',
                  value: formatCurrency(order.totalAmount),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Item Cetak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                ...order.items.map((item) {
                  return Card(
                    child: ListTile(
                      title: Text(item.fileName),
                      subtitle: Text('${item.sizeLabel} • ${item.quantity}x'),
                      trailing: Text(formatCurrency(item.subtotal)),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Front Office',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                if (order.status == 'requested')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _confirm,
                      child: const Text('Konfirmasi Pesanan'),
                    ),
                  ),

                if (order.status == 'processing' ||
                    order.status == 'awaiting_payment')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _ready,
                      child: const Text('Tandai Siap Diambil/Dikirim'),
                    ),
                  ),

                if (order.status == 'ready_for_pickup' ||
                    order.status == 'ready_for_delivery')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _complete,
                      child: const Text('Selesaikan Pesanan'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}
