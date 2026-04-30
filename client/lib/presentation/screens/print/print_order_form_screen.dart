import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.light,
      contentPadding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
      labelStyle: TextStyle(
        color: AppColors.welcomeBlueDark.withOpacity(0.66),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: const TextStyle(
        color: AppColors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: AppColors.primaryDark,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.3),
      ),
    );
  }

  Widget _buildPrintItemCard({
    required int index,
    required _PrintItemController item,
    required List<PrintPriceModel> prices,
  }) {
    final selectedPrice = _findPrice(item.printPriceId);
    final itemTotal = _itemTotal(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeCardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white.withOpacity(0.76)),
                ),
                child: const Icon(
                  Icons.photo_size_select_actual_rounded,
                  color: AppColors.welcomeBlueDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetakan ${index + 1}',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      itemTotal <= 0
                          ? 'Lengkapi data cetakan'
                          : _currency(itemTotal),
                      style: TextStyle(
                        color: AppColors.welcomeBlueDark.withOpacity(0.60),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (_items.length > 1)
                Material(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => _removeItem(index),
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 21,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<int>(
            value: item.printPriceId,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'Ukuran Cetak',
              hint: 'Pilih ukuran cetak',
              icon: Icons.straighten_rounded,
            ),
            selectedItemBuilder: (context) {
              return prices.map((price) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    price.sizeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.welcomeBlueDark,
                      fontWeight: FontWeight.w900,
                    ),
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
                      style: const TextStyle(
                        color: AppColors.welcomeBlueDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cetak ${_currency(price.printPrice)} • Bingkai ${_currency(price.framePrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
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
            const SizedBox(height: 10),
            _SoftNotice(
              icon: Icons.description_rounded,
              text: selectedPrice.paperType,
              color: AppColors.primaryDark,
            ),
          ],

          const SizedBox(height: 12),

          TextFormField(
            controller: item.fileNameController,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              label: 'Nama File Foto',
              hint: 'Contoh: DSC03456',
              icon: Icons.image_rounded,
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
            decoration: _inputDecoration(
              label: 'Jumlah Cetak',
              hint: 'Contoh: 1',
              icon: Icons.format_list_numbered_rounded,
            ),
            validator: (value) {
              final qty = int.tryParse(value ?? '');

              if (qty == null || qty < 1) {
                return 'Jumlah minimal 1';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          _FrameSwitchCard(
            value: item.useFrame,
            framePrice: selectedPrice == null ? null : selectedPrice.framePrice,
            currency: _currency,
            onChanged: (value) {
              setState(() {
                item.useFrame = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _SubtotalCard(
            title: 'Subtotal Cetakan ${index + 1}',
            value: _currency(itemTotal),
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
          child: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDark,
                  ),
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  children: [
                    _TopBar(
                      title: 'Pesan Cetak Foto',
                      onBack: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 14),

                    _PrintHero(
                      totalQty: totalQty,
                      grandTotal: _currency(grandTotal),
                    ),

                    const SizedBox(height: 18),

                    const _SectionTitle(
                      title: 'Daftar Cetakan',
                      subtitle:
                          'Pilih ukuran, nama file, jumlah cetak, dan bingkai.',
                    ),

                    const SizedBox(height: 12),

                    if (provider.errorMessage != null) ...[
                      _ErrorBox(message: provider.errorMessage!),
                      const SizedBox(height: 12),
                    ],

                    if (prices.isEmpty)
                      const _EmptyPriceCard()
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
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: provider.isSubmitting
                                    ? null
                                    : _addItem,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Tambah Cetakan'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryDark,
                                  backgroundColor: AppColors.light.withOpacity(
                                    0.70,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            const _SectionTitle(
                              title: 'Metode Pengambilan',
                              subtitle: 'Pilih bagaimana hasil cetak diterima.',
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _DeliveryMethodCard(
                                    selected: _deliveryMethod == 'pickup',
                                    icon: Icons.store_rounded,
                                    title: 'Pickup',
                                    subtitle: 'Ambil studio',
                                    onTap: provider.isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _deliveryMethod = 'pickup';
                                            });
                                          },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DeliveryMethodCard(
                                    selected: _deliveryMethod == 'delivery',
                                    icon: Icons.local_shipping_rounded,
                                    title: 'Delivery',
                                    subtitle: 'Ekspedisi',
                                    onTap: provider.isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _deliveryMethod = 'delivery';
                                            });
                                          },
                                  ),
                                ),
                              ],
                            ),

                            if (_deliveryMethod == 'delivery') ...[
                              const SizedBox(height: 18),
                              const _SectionTitle(
                                title: 'Data Pengiriman',
                                subtitle:
                                    'Lengkapi alamat dan kontak penerima.',
                              ),
                              const SizedBox(height: 12),
                              _InfoFormCard(
                                children: [
                                  TextFormField(
                                    controller: _recipientNameController,
                                    enabled: !provider.isSubmitting,
                                    decoration: _inputDecoration(
                                      label: 'Nama Penerima',
                                      hint: 'Contoh: Anisa Risma',
                                      icon: Icons.person_rounded,
                                    ),
                                    validator: (value) {
                                      if (_deliveryMethod == 'delivery' &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
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
                                    decoration: _inputDecoration(
                                      label: 'Nomor HP Penerima',
                                      hint: 'Contoh: 08123456789',
                                      icon: Icons.phone_rounded,
                                    ),
                                    validator: (value) {
                                      if (_deliveryMethod == 'delivery' &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
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
                                    decoration: _inputDecoration(
                                      label: 'Alamat Pengiriman',
                                      hint: 'Tulis alamat lengkap pengiriman',
                                      icon: Icons.location_on_rounded,
                                    ),
                                    validator: (value) {
                                      if (_deliveryMethod == 'delivery' &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'Alamat pengiriman wajib diisi';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  const _SoftNotice(
                                    icon: Icons.info_outline_rounded,
                                    text:
                                        'Biaya ekspedisi ditanggung klien di luar sistem.',
                                    color: AppColors.warning,
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 18),

                            const _SectionTitle(
                              title: 'Catatan Tambahan',
                              subtitle:
                                  'Tambahkan catatan jika ada permintaan khusus.',
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _notesController,
                              enabled: !provider.isSubmitting,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                label: 'Catatan',
                                hint: 'Contoh: Tolong cetak glossy',
                                icon: Icons.notes_rounded,
                              ),
                            ),

                            const SizedBox(height: 18),

                            _TotalPaymentCard(
                              totalQty: totalQty,
                              totalPayment: _currency(grandTotal),
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: provider.isSubmitting
                                    ? null
                                    : _submit,
                                icon: provider.isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.payments_rounded,
                                        size: 19,
                                      ),
                                label: Text(
                                  provider.isSubmitting
                                      ? 'Memproses...'
                                      : 'Buat Pesanan & Bayar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: AppColors.white,
                                  disabledBackgroundColor: AppColors.grey
                                      .withOpacity(0.35),
                                  disabledForegroundColor: AppColors.white
                                      .withOpacity(0.86),
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.welcomeBlueDark.withOpacity(0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryDark,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 21,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrintHero extends StatelessWidget {
  final int totalQty;
  final String grandTotal;

  const _PrintHero({required this.totalQty, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -42,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -58,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.print_rounded,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesan Cetak Foto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Pilih file foto, ukuran cetak, jumlah, dan bingkai.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.74),
                        fontSize: 12.8,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroPill(
                            icon: Icons.format_list_numbered_rounded,
                            text: '$totalQty cetak',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeroPill(
                            icon: Icons.payments_rounded,
                            text: grandTotal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
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

  const _SectionTitle({required this.title, required this.subtitle});

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
      ],
    );
  }
}

class _FrameSwitchCard extends StatelessWidget {
  final bool value;
  final int? framePrice;
  final String Function(int value) currency;
  final ValueChanged<bool> onChanged;

  const _FrameSwitchCard({
    required this.value,
    required this.framePrice,
    required this.currency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = framePrice == null
        ? 'Pilih ukuran terlebih dahulu'
        : 'Tambahan ${currency(framePrice!)} per cetakan';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.white),
            ),
            child: const Icon(
              Icons.crop_original_rounded,
              color: AppColors.welcomeBlueDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pakai Bingkai',
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.58),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primaryDark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SubtotalCard extends StatelessWidget {
  final String title;
  final String value;

  const _SubtotalCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDark.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primaryDark,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primaryDark.withOpacity(0.72),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryMethodCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DeliveryMethodCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.grey;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryDark.withOpacity(0.08)
                : AppColors.light,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primaryDark.withOpacity(0.20)
                  : AppColors.border,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoFormCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoFormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SoftNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SoftNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.4,
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

class _TotalPaymentCard extends StatelessWidget {
  final int totalQty;
  final String totalPayment;

  const _TotalPaymentCard({required this.totalQty, required this.totalPayment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          _SummaryLine(
            icon: Icons.format_list_numbered_rounded,
            label: 'Total Jumlah Cetak',
            value: '$totalQty cetakan',
          ),
          const SizedBox(height: 11),
          _SummaryLine(
            icon: Icons.payments_rounded,
            label: 'Total Pembayaran',
            value: totalPayment,
            isBig: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBig;

  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
    this.isBig = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.welcomeBlueDark, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.62),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.welcomeBlueDark,
            fontSize: isBig ? 16 : 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
        border: Border.all(color: AppColors.danger.withOpacity(0.18)),
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

class _EmptyPriceCard extends StatelessWidget {
  const _EmptyPriceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.65),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.print_disabled_rounded,
              color: AppColors.welcomeBlueDark,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada ukuran cetak',
            style: TextStyle(
              color: AppColors.welcomeBlueDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cek data Paket Cetak di admin server terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.62),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
