import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/editor_provider.dart';
import 'editor_task_detail_screen.dart';

class EditorTaskListScreen extends StatefulWidget {
  final String initialFilter;
  final String title;
  final String subtitle;

  const EditorTaskListScreen({
    super.key,
    this.initialFilter = 'active',
    this.title = 'Pekerjaan Edit',
    this.subtitle = 'Daftar edit foto yang sudah di-assign oleh Front Office.',
  });

  @override
  State<EditorTaskListScreen> createState() => _EditorTaskListScreenState();
}

class _EditorTaskListScreenState extends State<EditorTaskListScreen> {
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().fetchEditRequests();
    });
  }

  List<EditorEditRequestModel> _filtered(EditorProvider provider) {
    if (_filter == 'assigned') return provider.waitingTasks;
    if (_filter == 'in_progress') return provider.inProgressTasks;
    if (_filter == 'completed') return provider.completedTasks;
    if (_filter == 'all') return provider.editRequests;

    return provider.activeTasks;
  }

  void _openDetail(EditorEditRequestModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorTaskDetailScreen(editRequestId: item.id),
      ),
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final list = _filtered(provider);

    return Container(
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
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          backgroundColor: AppColors.light,
          onRefresh: provider.fetchEditRequests,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              _TaskListHeader(
                title: widget.title,
                subtitle: widget.subtitle,
                activeCount: provider.activeTasks.length,
                completedCount: provider.completedTasks.length,
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Filter Pekerjaan',
                subtitle: 'Pilih status pekerjaan edit yang ingin dilihat.',
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Aktif',
                      value: 'active',
                      selectedValue: _filter,
                      onSelected: _setFilter,
                    ),
                    _FilterChip(
                      label: 'Belum',
                      value: 'assigned',
                      selectedValue: _filter,
                      onSelected: _setFilter,
                    ),
                    _FilterChip(
                      label: 'Proses',
                      value: 'in_progress',
                      selectedValue: _filter,
                      onSelected: _setFilter,
                    ),
                    _FilterChip(
                      label: 'Selesai',
                      value: 'completed',
                      selectedValue: _filter,
                      onSelected: _setFilter,
                    ),
                    _FilterChip(
                      label: 'Semua',
                      value: 'all',
                      selectedValue: _filter,
                      onSelected: _setFilter,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Daftar Request Edit',
                subtitle: 'Pekerjaan edit foto yang masuk ke akun editor.',
                trailingText: 'Live',
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && provider.editRequests.isEmpty)
                const _LoadingCard()
              else if (list.isEmpty)
                const _EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'Belum ada pekerjaan edit',
                  message:
                      'Request edit yang sesuai filter akan tampil di sini.',
                )
              else
                ...list.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EditorTaskCard(
                      item: item,
                      onTap: () => _openDetail(item),
                    ),
                  );
                }),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 8),
                _ErrorBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int activeCount;
  final int completedCount;

  const _TaskListHeader({
    required this.title,
    required this.subtitle,
    required this.activeCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.16),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.72),
                        fontSize: 12.4,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderPill(
                          icon: Icons.assignment_rounded,
                          text: '$activeCount aktif',
                        ),
                        _HeaderPill(
                          icon: Icons.check_circle_rounded,
                          text: '$completedCount selesai',
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

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primaryDark,
        backgroundColor: AppColors.light,
        side: BorderSide(
          color: selected ? AppColors.primaryDark : AppColors.border,
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.white : AppColors.primaryDark,
          fontSize: 11.3,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailingText;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailingText,
  });

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
        if (trailingText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 6,
                  width: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EditorTaskCard extends StatelessWidget {
  final EditorEditRequestModel item;
  final VoidCallback onTap;

  const _EditorTaskCard({required this.item, required this.onTap});

  Color _color() {
    if (item.isCompleted) return AppColors.success;
    if (item.isInProgress) return AppColors.primaryDark;

    return AppColors.warning;
  }

  IconData _icon() {
    if (item.isCompleted) return Icons.check_circle_rounded;
    if (item.isInProgress) return Icons.auto_fix_high_rounded;

    return Icons.pending_actions_rounded;
  }

  String _deadlineDateOnly() {
    final formatted = item.formattedEditDeadline.trim();

    if (formatted.isEmpty || formatted == '-') return '-';

    if (formatted.contains(',')) {
      final dateOnly = formatted.split(',').first.trim();
      return dateOnly.isEmpty ? '-' : dateOnly;
    }

    if (formatted.contains(' WIB')) {
      return formatted.replaceAll(RegExp(r'\s+\d{1,2}:\d{2}.*'), '').trim();
    }

    final raw = item.editDeadlineAt.trim();

    if (raw.isNotEmpty) {
      if (raw.contains('T')) {
        final date = raw.split('T').first.trim();
        return date.isEmpty ? formatted : date;
      }

      if (raw.contains(' ')) {
        final date = raw.split(' ').first.trim();
        return date.isEmpty ? formatted : date;
      }
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final deadlineDate = _deadlineDateOnly();
    final remainingText = item.remainingDays == null
        ? '-'
        : '${item.remainingDays} hari';

    return Material(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.welcomeBlueDark.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(0.14)),
                    ),
                    child: Icon(_icon(), color: color, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName.isEmpty ? 'Klien' : item.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.welcomeBlueDark,
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.packageName.isEmpty ? '-' : item.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryDark,
                      size: 23,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatusChip(label: item.statusLabel, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusChip(
                      label: '${item.selectedFiles.length} file',
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeCardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white.withOpacity(0.76)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.calendar_month_rounded,
                        label: 'Deadline',
                        value: deadlineDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'Sisa Hari',
                        value: remainingText,
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
        ),
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
        Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
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
                  color: AppColors.welcomeBlueDark.withOpacity(0.54),
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
                  color: AppColors.welcomeBlueDark,
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.60),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.welcomeBlueDark),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const CircularProgressIndicator(color: AppColors.primaryDark),
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
        border: Border.all(color: AppColors.danger.withOpacity(0.20)),
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
