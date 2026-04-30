import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _categoryController = TextEditingController(
    text: 'Pemasukan Manual',
  );
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _incomeDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
  }

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

  String _displayDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _parseAmount(String text) {
    return int.tryParse(
          text
              .replaceAll('Rp', '')
              .replaceAll('.', '')
              .replaceAll(',', '')
              .replaceAll(' ', '')
              .trim(),
        ) ??
        0;
  }

  String _formatCurrency(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;

      buffer.write(raw[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
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
              primary: _IncomePalette.darkBlue,
              surface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    setState(() => _incomeDate = result);
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
      _showMessage('Pemasukan berhasil disimpan');
      Navigator.pop(context, true);
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal menyimpan pemasukan');
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
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      labelStyle: TextStyle(
        color: _IncomePalette.darkBlue.withOpacity(0.68),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      hintStyle: TextStyle(
        color: _IncomePalette.darkBlue.withOpacity(0.38),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      prefixIconColor: _IncomePalette.darkBlue,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _IncomePalette.cardDeep),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: _IncomePalette.darkBlue,
          width: 1.4,
        ),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final amount = _parseAmount(_amountController.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              _TopBar(
                title: 'Tambah Pemasukan',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),

              _IncomeHeader(
                dateText: _displayDate(_incomeDate),
                amountText: amount <= 0 ? 'Rp 0' : _formatCurrency(amount),
              ),

              const SizedBox(height: 16),

              const _SectionTitle(
                title: 'Informasi Pemasukan',
                subtitle: 'Catat pemasukan manual untuk kas studio.',
              ),

              const SizedBox(height: 12),

              _IncomeGuideCard(),

              const SizedBox(height: 16),

              const _SectionTitle(
                title: 'Form Pemasukan',
                subtitle:
                    'Lengkapi tanggal, kategori, nominal, dan keterangan.',
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _IncomePalette.cardDeep),
                  boxShadow: [
                    BoxShadow(
                      color: _IncomePalette.darkBlue.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _DatePickerCard(
                        title: 'Tanggal Pemasukan',
                        value: _displayDate(_incomeDate),
                        technicalValue: _formatDate(_incomeDate),
                        onPick: provider.isSubmitting ? null : _pickDate,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _categoryController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Kategori',
                          hint: 'Contoh: Pembayaran Offline',
                          icon: Icons.category_rounded,
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
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          label: 'Nominal',
                          hint: 'Contoh: 250000',
                          icon: Icons.payments_rounded,
                        ),
                        validator: (value) {
                          final parsedAmount = _parseAmount(value ?? '');

                          if (parsedAmount <= 0) {
                            return 'Nominal wajib valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: _inputDecoration(
                          label: 'Keterangan',
                          hint: 'Contoh: Pelunasan offline booking klien',
                          icon: Icons.notes_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _AmountPreviewCard(
                        category: _categoryController.text.trim(),
                        dateText: _formatDate(_incomeDate),
                        amountText: amount <= 0
                            ? 'Belum diisi'
                            : _formatCurrency(amount),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: provider.isSubmitting ? null : _submit,
                          icon: provider.isSubmitting
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            provider.isSubmitting
                                ? 'Menyimpan...'
                                : 'Simpan Pemasukan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _IncomePalette.darkBlue,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.grey.withOpacity(
                              0.35,
                            ),
                            disabledForegroundColor: AppColors.white
                                .withOpacity(0.86),
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const _FinanceNoticeCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomePalette {
  static const Color darkBlue = Color(0xFF233B93);
  static const Color midBlue = Color(0xFF344FA5);
  static const Color lightBlue = Color(0xFF5E7BDA);

  static const Color cardLight = Color(0xFFF0FAFF);
  static const Color cardMid = Color(0xFFD9F0FA);
  static const Color cardDeep = Color(0xFFC5E4F2);

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, midBlue, lightBlue],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardLight, cardMid, cardDeep],
  );
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _IncomePalette.cardDeep),
                boxShadow: [
                  BoxShadow(
                    color: _IncomePalette.darkBlue.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _IncomePalette.darkBlue,
                size: 22,
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
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomeHeader extends StatelessWidget {
  final String dateText;
  final String amountText;

  const _IncomeHeader({required this.dateText, required this.amountText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _IncomePalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _IncomePalette.darkBlue.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -56,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.07),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
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
                      'Konfirmasi Pemasukan',
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
                      'Catat pembayaran offline, tambahan jasa, atau koreksi kas studio.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.72),
                        fontSize: 12.8,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroPill(
                          icon: Icons.calendar_month_rounded,
                          text: dateText,
                        ),
                        _HeroPill(
                          icon: Icons.payments_rounded,
                          text: amountText,
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
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            gradient: _IncomePalette.darkGradient,
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

class _IncomeGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        gradient: _IncomePalette.softGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
        boxShadow: [
          BoxShadow(
            color: _IncomePalette.darkBlue.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.white),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _IncomePalette.darkBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Gunakan form ini hanya untuk pemasukan manual seperti pembayaran offline, tambahan jasa, atau koreksi kas. Pemasukan dari payment gateway tetap mengikuti data transaksi otomatis.',
              style: TextStyle(
                color: _IncomePalette.darkBlue.withOpacity(0.78),
                height: 1.42,
                fontWeight: FontWeight.w700,
                fontSize: 11.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String title;
  final String value;
  final String technicalValue;
  final VoidCallback? onPick;

  const _DatePickerCard({
    required this.title,
    required this.value,
    required this.technicalValue,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _IncomePalette.cardDeep),
          ),
          child: Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: _IncomePalette.cardLight,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _IncomePalette.cardDeep),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: _IncomePalette.darkBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _IncomePalette.darkBlue.withOpacity(0.56),
                        fontWeight: FontWeight.w800,
                        fontSize: 10.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _IncomePalette.darkBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      technicalValue,
                      style: TextStyle(
                        color: _IncomePalette.darkBlue.withOpacity(0.42),
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _IncomePalette.cardLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _IncomePalette.cardDeep),
                ),
                child: const Text(
                  'Pilih',
                  style: TextStyle(
                    color: _IncomePalette.darkBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.8,
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

class _AmountPreviewCard extends StatelessWidget {
  final String category;
  final String dateText;
  final String amountText;

  const _AmountPreviewCard({
    required this.category,
    required this.dateText,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        gradient: _IncomePalette.softGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  icon: Icons.category_rounded,
                  label: 'Kategori',
                  value: category.isEmpty ? '-' : category,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactInfo(
                  icon: Icons.calendar_month_rounded,
                  label: 'Tanggal',
                  value: dateText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WideInfo(
            icon: Icons.payments_rounded,
            label: 'Nominal Pemasukan',
            value: amountText,
          ),
        ],
      ),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _IncomePalette.darkBlue, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _IncomePalette.darkBlue.withOpacity(0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _IncomePalette.darkBlue,
                  fontSize: 11.2,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WideInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WideInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _IncomePalette.darkBlue, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _IncomePalette.darkBlue.withOpacity(0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _IncomePalette.darkBlue,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinanceNoticeCard extends StatelessWidget {
  const _FinanceNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pastikan nominal pemasukan manual tidak dobel dengan pembayaran yang sudah otomatis tercatat dari payment gateway.',
              style: TextStyle(
                color: AppColors.warning.withOpacity(0.96),
                fontSize: 11.5,
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
