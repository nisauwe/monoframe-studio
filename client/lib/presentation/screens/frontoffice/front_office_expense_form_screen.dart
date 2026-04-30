import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/front_office_provider.dart';

class FrontOfficeExpenseFormScreen extends StatefulWidget {
  const FrontOfficeExpenseFormScreen({super.key});

  @override
  State<FrontOfficeExpenseFormScreen> createState() =>
      _FrontOfficeExpenseFormScreenState();
}

class _FrontOfficeExpenseFormScreenState
    extends State<FrontOfficeExpenseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _categoryController = TextEditingController(
    text: 'Pengeluaran Studio',
  );
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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

  String _formatHumanDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  int _parseAmount(String text) {
    return int.tryParse(text.replaceAll('.', '').replaceAll(',', '').trim()) ??
        0;
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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

    if (result == null) return;

    setState(() {
      _expenseDate = result;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.storeExpense(
      expenseDate: _formatDate(_expenseDate),
      category: _categoryController.text.trim(),
      amount: _parseAmount(_amountController.text),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      _showMessage('Pengeluaran berhasil disimpan');
      Navigator.pop(context);
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal menyimpan pengeluaran');
    }
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      labelStyle: TextStyle(
        color: AppColors.welcomeBlueDark.withOpacity(0.68),
        fontWeight: FontWeight.w800,
        fontSize: 12.5,
      ),
      hintStyle: const TextStyle(
        color: AppColors.grey,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      prefixIconColor: AppColors.welcomeBlueDark,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.welcomeCardDeep),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.welcomeBlueDark,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final amount = _parseAmount(_amountController.text);

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
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _TopBar(
                title: 'Input Pengeluaran',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),

              const _ExpenseHeroCard(),

              const SizedBox(height: 16),

              _ExpensePreviewCard(
                dateText: _formatHumanDate(_expenseDate),
                amountText: _formatCurrency(amount),
                category: _categoryController.text.trim(),
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Data Pengeluaran',
                subtitle:
                    'Isi detail biaya operasional agar laporan keuangan tetap sinkron.',
              ),

              const SizedBox(height: 12),

              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.welcomeCardDeep),
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
                      _DateSelectorCard(
                        title: 'Tanggal Pengeluaran',
                        value: _formatHumanDate(_expenseDate),
                        onPick: _pickDate,
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _categoryController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Kategori',
                          hint: 'Contoh: Pengeluaran Studio',
                          icon: Icons.category_rounded,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kategori wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Nominal',
                          hint: 'Contoh: 150000',
                          icon: Icons.payments_rounded,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final amount = _parseAmount(value ?? '');

                          if (amount <= 0) {
                            return 'Nominal wajib valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          label: 'Keterangan',
                          hint: 'Contoh: Beli kertas foto',
                          icon: Icons.notes_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const _InfoWarningBox(),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: provider.isSubmitting ? null : _submit,
                          icon: provider.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 19),
                          label: Text(
                            provider.isSubmitting
                                ? 'Menyimpan...'
                                : 'Simpan Pengeluaran',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.welcomeBlueDark,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.welcomeBlueDark
                                .withOpacity(0.42),
                            disabledForegroundColor: Colors.white.withOpacity(
                              0.74,
                            ),
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
              ),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorMessageBox(message: provider.errorMessage!),
              ],
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
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.welcomeBlueDark,
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseHeroCard extends StatelessWidget {
  const _ExpenseHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -44,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -54,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catat Pengeluaran',
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
                        'Input biaya studio, transport, cetak, dan kebutuhan operasional lainnya.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.74),
                          fontSize: 12.8,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Keuangan Front Office',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ExpensePreviewCard extends StatelessWidget {
  final String dateText;
  final String amountText;
  final String category;

  const _ExpensePreviewCard({
    required this.dateText,
    required this.amountText,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final categoryText = category.trim().isEmpty
        ? 'Kategori belum diisi'
        : category;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.danger.withOpacity(0.14)),
            ),
            child: const Icon(
              Icons.trending_down_rounded,
              color: AppColors.danger,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview Pengeluaran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  categoryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.58),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _MiniChip(
                      icon: Icons.calendar_month_rounded,
                      label: dateText,
                      color: AppColors.welcomeBlueDark,
                    ),
                    _MiniChip(
                      icon: Icons.payments_rounded,
                      label: amountText,
                      color: AppColors.danger,
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

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clean = label.trim().isEmpty ? '-' : label.trim();

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
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
              fontSize: 10.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelectorCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onPick;

  const _DateSelectorCard({
    required this.title,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.welcomeCardLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.welcomeCardDeep),
          ),
          child: Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: AppColors.welcomeBlueDark.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.welcomeBlueDark.withOpacity(0.13),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.welcomeBlueDark,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.welcomeBlueDark.withOpacity(0.54),
                        fontSize: 9.8,
                        height: 1,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.welcomeBlueDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.welcomeBlueDark.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.welcomeBlueDark.withOpacity(0.13),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Pilih',
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _InfoWarningBox extends StatelessWidget {
  const _InfoWarningBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pastikan nominal dan kategori sudah benar sebelum disimpan ke laporan keuangan.',
              style: TextStyle(
                color: AppColors.warning.withOpacity(0.92),
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
