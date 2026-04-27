import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/editor_provider.dart';
import 'editor_task_detail_screen.dart';

class EditorTaskListScreen extends StatefulWidget {
  const EditorTaskListScreen({super.key});

  @override
  State<EditorTaskListScreen> createState() => _EditorTaskListScreenState();
}

class _EditorTaskListScreenState extends State<EditorTaskListScreen> {
  String _filter = 'active';

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final list = _filtered(provider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchEditRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Pekerjaan Edit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daftar edit foto yang sudah di-assign oleh Front Office.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 18),

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

            const SizedBox(height: 20),

            if (provider.isLoading && provider.editRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: Text('Belum ada pekerjaan edit.')),
              )
            else
              ...list.map((item) {
                return _EditorTaskCard(
                  item: item,
                  onTap: () => _openDetail(item),
                );
              }),

            if (provider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: value == selectedValue,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

class _EditorTaskCard extends StatelessWidget {
  final EditorEditRequestModel item;
  final VoidCallback onTap;

  const _EditorTaskCard({required this.item, required this.onTap});

  Color _color() {
    if (item.isCompleted) return Colors.green;
    if (item.isInProgress) return Colors.blue;
    return Colors.orange;
  }

  IconData _icon() {
    if (item.isCompleted) return Icons.check_circle_outline;
    if (item.isInProgress) return Icons.edit_outlined;
    return Icons.pending_actions_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(_icon(), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Paket: ${item.packageName}'),
                    Text('Jumlah file: ${item.selectedFiles.length}'),
                    if (item.editDeadlineAt.isNotEmpty)
                      Text('Deadline: ${item.formattedEditDeadline}'),
                    const SizedBox(height: 8),
                    _Badge(text: item.statusLabel, color: color),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
