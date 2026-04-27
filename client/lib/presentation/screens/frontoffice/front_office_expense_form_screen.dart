import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/front_office_provider.dart';

class FrontOfficeExpenseFormScreen extends StatefulWidget {
  const FrontOfficeExpenseFormScreen({super.key});

  @override
  State<FrontOfficeExpenseFormScreen> createState() =>
      _FrontOfficeExpenseFormScreenState();
}

class _FrontOfficeExpenseFormScreenState
    extends State<FrontOfficeExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _expenseDate = DateTime.now();

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

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (result != null) {
      setState(() => _expenseDate = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.storeExpense(
      expenseDate: _formatDate(_expenseDate),
      category: _categoryController.text.trim(),
      amount: int.tryParse(_amountController.text.trim()) ?? 0,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran berhasil disimpan')),
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
      appBar: AppBar(title: const Text('Input Pengeluaran')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Tanggal Pengeluaran'),
                    subtitle: Text(_formatDate(_expenseDate)),
                    trailing: TextButton(
                      onPressed: _pickDate,
                      child: const Text('Pilih'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = int.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Nominal wajib valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _submit,
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan Pengeluaran'),
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
