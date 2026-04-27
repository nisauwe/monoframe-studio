import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/package_model.dart';

class PackageCard extends StatelessWidget {
  final PackageModel package;
  final bool compact;
  final VoidCallback? onTap;
  final bool showActionButton;
  final String buttonText;

  const PackageCard({
    super.key,
    required this.package,
    this.compact = false,
    this.onTap,
    this.showActionButton = true,
    this.buttonText = 'Pilih Paket',
  });

  String formatRupiah(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: compact ? _buildCompact() : _buildNormal(),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryChip(),
        const SizedBox(height: 12),
        _buildTitle(),
        const SizedBox(height: 8),
        _buildDescription(maxLines: 2),
        const Spacer(),
        const SizedBox(height: 12),
        _buildStats(),
        const SizedBox(height: 12),
        _buildPriceSection(),
        if (showActionButton) ...[const SizedBox(height: 12), _buildButton()],
      ],
    );
  }

  Widget _buildNormal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryChip(),
        const SizedBox(height: 12),
        _buildTitle(),
        const SizedBox(height: 8),
        _buildDescription(maxLines: 3),
        const SizedBox(height: 12),
        _buildStats(),
        const SizedBox(height: 12),
        _buildPriceSection(),
        if (showActionButton) ...[const SizedBox(height: 16), _buildButton()],
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        package.categoryName,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      package.name,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.dark,
      ),
    );
  }

  Widget _buildDescription({required int maxLines}) {
    return Text(
      package.description.isEmpty ? '-' : package.description,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.grey, height: 1.4),
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _infoChip(Icons.location_on_outlined, package.locationTypeLabel),
        _infoChip(Icons.schedule_outlined, '${package.durationMinutes} menit'),
        _infoChip(Icons.edit_outlined, '${package.photoCount} foto edit'),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.dark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.dark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    final discount = package.activeDiscount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (package.hasDiscount)
          Text(
            formatRupiah(package.price),
            style: const TextStyle(
              color: AppColors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 13,
            ),
          ),
        Text(
          formatRupiah(package.finalPrice),
          style: const TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        if (discount != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Diskon ${discount.discountPercent}%',
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onTap, child: Text(buttonText)),
    );
  }
}
