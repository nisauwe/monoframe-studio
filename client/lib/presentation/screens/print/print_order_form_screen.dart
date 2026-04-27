import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/print_order_model.dart';
import '../../../data/providers/print_order_provider.dart';

class PrintOrderFormScreen extends StatefulWidget {
  final int bookingId;

  const PrintOrderFormScreen({super.key, required this.bookingId});

  @override
  State<PrintOrderFormScreen> createState() => _PrintOrderFormScreenState();
}

class _PrintOrderFormScreenState extends State<PrintOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _notesController = TextEditingController();

  final List<_PrintItemController> _items = [];

  String _deliveryMethod = 'pickup';

  @override
  void initState() {
    super.initState();

    _items.add(_PrintItemController());
    _items.first.addListeners(_recalculate);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PrintOrderProvider>();

      await provider.fetchPrices();

      if (!mounted) return;

      if (provider.prices.isNotEmpty) {
        setState(() {
          for (final item in _items) {
            item.printPriceId ??= provider.prices.first.id;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose(_recalculate);
    }

    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _deliveryAddressController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  void _recalculate() {
    if (!mounted) return;
    setState(() {});
  }

  void _addItem() {
    final provider = context.read<PrintOrderProvider>();

    final item = _PrintItemController(
      printPriceId: provider.prices.isNotEmpty
          ? provider.prices.first.id
          : null,
    );

    item.addListeners(_recalculate);

    setState(() {
      _items.add(item);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;

    final item = _items[index];

    setState(() {
      _items.removeAt(index);
    });

    item.dispose(_recalculate);
  }

  PrintPriceModel? _findPrice(int? id) {
    if (id == null) return null;

    final prices = context.read<PrintOrderProvider>().prices;

    for (final price in prices) {
      if (price.id == id) return price;
    }

    return null;
  }

  int _itemQty(_PrintItemController item) {
    final qty = int.tryParse(item.qtyController.text.trim()) ?? 1;
    return qty < 1 ? 1 : qty;
  }

  int _itemTotal(_PrintItemController item) {
    final fileName = item.fileNameController.text.trim();

    if (fileName.isEmpty) return 0;

    final price = _findPrice(item.printPriceId);

    if (price == null) return 0;

    final qty = _itemQty(item);
    final framePrice = item.useFrame ? price.framePrice : 0;

    return (price.printPrice + framePrice) * qty;
  }

  int _grandTotal() {
    int total = 0;

    for (final item in _items) {
      total += _itemTotal(item);
    }

    return total;
  }

  int _totalQty() {
    int total = 0;

    for (final item in _items) {
      if (item.fileNameController.text.trim().isEmpty) continue;

      total += _itemQty(item);
    }

    return total;
  }

  List<PrintOrderItemPayload> _payloadItems() {
    final payloads = <PrintOrderItemPayload>[];

    for (final item in _items) {
      final fileName = item.fileNameController.text.trim();

      if (fileName.isEmpty) continue;
      if (item.printPriceId == null) continue;

      payloads.add(
        PrintOrderItemPayload(
          printPriceId: item.printPriceId!,
          fileName: fileName,
          qty: _itemQty(item),
          useFrame: item.useFrame,
        ),
      );
    }

    return payloads;
  }

  String _currency(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payloadItems = _payloadItems();

    if (payloadItems.isEmpty) {
      _showMessage('Minimal isi 1 cetakan.');
      return;
    }

    if (_grandTotal() <= 0) {
      _showMessage('Total cetak belum valid. Cek ukuran dan harga cetak.');
      return;
    }

    final provider = context.read<PrintOrderProvider>();

    final order = await provider.createPrintOrder(
      bookingId: widget.bookingId,
      items: payloadItems,
      deliveryMethod: _deliveryMethod,
      recipientName: _recipientNameController.text.trim(),
      recipientPhone: _recipientPhoneController.text.trim(),
      deliveryAddress: _deliveryAddressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (order == null) {
      _showMessage(provider.errorMessage ?? 'Gagal membuat pesanan cetak.');
      return;
    }

    _showMessage('Pesanan cetak berhasil dibuat. Mengarahkan ke pembayaran...');

    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPrintItemCard({
    required int index,
    required _PrintItemController item,
    required List<PrintPriceModel> prices,
  }) {
    final selectedPrice = _findPrice(item.printPriceId);
    final itemTotal = _itemTotal(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cetakan ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                onPressed: _items.length <= 1 ? null : () => _removeItem(index),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            value: item.printPriceId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Ukuran Cetak',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            selectedItemBuilder: (context) {
              return prices.map((price) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    price.sizeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            items: prices.map((price) {
              return DropdownMenuItem<int>(
                value: price.id,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.sizeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cetak ${_currency(price.printPrice)} • Bingkai ${_currency(price.framePrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                item.printPriceId = value;
              });
            },
            validator: (value) {
              if (value == null) return 'Pilih ukuran cetak';
              return null;
            },
          ),

          if (selectedPrice != null && selectedPrice.paperType.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              selectedPrice.paperType,
              style: const TextStyle(color: Colors.grey),
            ),
          ],

          const SizedBox(height: 12),

          TextFormField(
            controller: item.fileNameController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Nama File Foto',
              hintText: 'Contoh: DSC03456',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama file wajib diisi';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: item.qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah Cetak',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final qty = int.tryParse(value ?? '');

              if (qty == null || qty < 1) {
                return 'Jumlah minimal 1';
              }

              return null;
            },
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: item.useFrame,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (value) {
              setState(() {
                item.useFrame = value;
              });
            },
            title: const Text('Pakai Bingkai'),
            subtitle: selectedPrice == null
                ? const Text('Pilih ukuran terlebih dahulu')
                : Text(
                    'Tambahan ${_currency(selectedPrice.framePrice)} per cetakan',
                  ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Subtotal Cetakan ${index + 1}: ${_currency(itemTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrintOrderProvider>();
    final prices = provider.prices;
    final totalQty = _totalQty();
    final grandTotal = _grandTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Cetak Foto')),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Daftar Cetakan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Kamu bisa memilih ukuran, nama file, jumlah cetak, dan bingkai untuk setiap cetakan.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 18),

                  if (provider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (prices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'Belum ada ukuran cetak tersedia. Cek data Paket Cetak di admin server.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ...List.generate(_items.length, (index) {
                            return _buildPrintItemCard(
                              index: index,
                              item: _items[index],
                              prices: prices,
                            );
                          }),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: provider.isSubmitting
                                  ? null
                                  : _addItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Cetakan'),
                            ),
                          ),

                          const SizedBox(height: 22),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Metode Pengambilan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          RadioListTile<String>(
                            value: 'pickup',
                            groupValue: _deliveryMethod,
                            activeColor: const Color(0xFF6C63FF),
                            onChanged: provider.isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _deliveryMethod = value ?? 'pickup';
                                    });
                                  },
                            title: const Text('Jemput ke Studio'),
                            subtitle: const Text(
                              'Klien mengambil cetakan ke Studio Monoframe.',
                            ),
                          ),

                          RadioListTile<String>(
                            value: 'delivery',
                            groupValue: _deliveryMethod,
                            activeColor: const Color(0xFF6C63FF),
                            onChanged: provider.isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _deliveryMethod = value ?? 'delivery';
                                    });
                                  },
                            title: const Text('Diantar Ekspedisi'),
                            subtitle: const Text(
                              'Biaya ekspedisi ditanggung klien di luar sistem.',
                            ),
                          ),

                          if (_deliveryMethod == 'delivery') ...[
                            const SizedBox(height: 20),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Data Pengiriman',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _recipientNameController,
                              enabled: !provider.isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Nama Penerima',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_deliveryMethod == 'delivery' &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Nama penerima wajib diisi';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _recipientPhoneController,
                              enabled: !provider.isSubmitting,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Nomor HP Penerima',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_deliveryMethod == 'delivery' &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Nomor HP penerima wajib diisi';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _deliveryAddressController,
                              enabled: !provider.isSubmitting,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Alamat Pengiriman',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_deliveryMethod == 'delivery' &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Alamat pengiriman wajib diisi';
                                }

                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _notesController,
                            enabled: !provider.isSubmitting,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Catatan Tambahan',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Jumlah Cetak: $totalQty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Total Pembayaran: ${_currency(grandTotal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: provider.isSubmitting ? null : _submit,
                              icon: provider.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.payments_outlined),
                              label: Text(
                                provider.isSubmitting
                                    ? 'Memproses...'
                                    : 'Buat Pesanan & Bayar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PrintItemController {
  int? printPriceId;
  bool useFrame;
  final TextEditingController fileNameController;
  final TextEditingController qtyController;

  _PrintItemController({this.printPriceId, this.useFrame = false})
    : fileNameController = TextEditingController(),
      qtyController = TextEditingController(text: '1');

  void addListeners(VoidCallback listener) {
    fileNameController.addListener(listener);
    qtyController.addListener(listener);
  }

  void dispose(VoidCallback listener) {
    fileNameController.removeListener(listener);
    qtyController.removeListener(listener);
    fileNameController.dispose();
    qtyController.dispose();
  }
}
