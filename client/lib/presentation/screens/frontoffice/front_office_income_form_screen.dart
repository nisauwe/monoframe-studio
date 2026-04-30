import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/front_office_provider.dart';

class FrontOfficeIncomeFormScreen extends StatefulWidget {
  const FrontOfficeIncomeFormScreen({super.key});

  @override
  State<FrontOfficeIncomeFormScreen> createState() =>
      _FrontOfficeIncomeFormScreenState();
}

class _FrontOfficeIncomeFormScreenState
    extends State<FrontOfficeIncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController(text: 'Pemasukan Manual');
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _incomeDate = DateTime.now();

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int _parseAmount(String text) {
    return int.tryParse(text.replaceAll('.', '').replaceAll(',', '').trim()) ??
        0;
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _incomeDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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

    if (result != null) {
      setState(() => _incomeDate = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.storeIncome(
      incomeDate: _formatDate(_incomeDate),
      category: _categoryController.text.trim(),
      amount: _parseAmount(_amountController.text),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemasukan berhasil disimpan')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('Konfirmasi Pemasukan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: AppColors.welcomeCardGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_card_outlined, color: AppColors.primaryDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gunakan form ini untuk mencatat pemasukan manual, misalnya pembayaran offline, tambahan jasa, atau koreksi kas.',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _DateCard(
                    title: 'Tanggal Pemasukan',
                    value: _formatDate(_incomeDate),
                    onPick: _pickDate,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kategori wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      hintText: 'Contoh: 250000',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      final amount = _parseAmount(value ?? '');
                      if (amount <= 0) return 'Nominal wajib valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      hintText: 'Contoh: Pelunasan offline booking #12',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: provider.isSubmitting ? null : _submit,
                    icon: provider.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      provider.isSubmitting
                          ? 'Menyimpan...'
                          : 'Simpan Pemasukan',
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

class _DateCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onPick;

  const _DateCard({
    required this.title,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPick, child: const Text('Pilih')),
        ],
      ),
    );
  }
}
