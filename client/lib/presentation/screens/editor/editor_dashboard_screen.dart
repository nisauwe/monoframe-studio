import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/editor_provider.dart';
import 'editor_task_detail_screen.dart';

class EditorDashboardScreen extends StatefulWidget {
  const EditorDashboardScreen({super.key});

  @override
  State<EditorDashboardScreen> createState() => _EditorDashboardScreenState();
}

class _EditorDashboardScreenState extends State<EditorDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().fetchEditRequests();
    });
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
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<EditorProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchEditRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Dashboard Editor',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Halo, ${auth.user?.name ?? 'Editor'}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            if (provider.isLoading && provider.editRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _SummaryCard(
                    title: 'Belum Dikerjakan',
                    value: provider.waitingTasks.length.toString(),
                    icon: Icons.pending_actions_outlined,
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    title: 'Sedang Diedit',
                    value: provider.inProgressTasks.length.toString(),
                    icon: Icons.edit_outlined,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    title: 'Selesai',
                    value: provider.completedTasks.length.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    title: 'Total',
                    value: provider.editRequests.length.toString(),
                    icon: Icons.assignment_outlined,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Pekerjaan Aktif',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 12),

              if (provider.activeTasks.isEmpty)
                const _EmptyCard(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada pekerjaan aktif',
                  message:
                      'Pekerjaan edit yang sudah di-assign Front Office akan muncul di sini.',
                )
              else
                ...provider.activeTasks.take(5).map((item) {
                  return _TaskCard(item: item, onTap: () => _openDetail(item));
                }),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final EditorEditRequestModel item;
  final VoidCallback onTap;

  const _TaskCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.isInProgress ? Colors.blue : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            item.isInProgress ? Icons.edit_outlined : Icons.pending_actions,
            color: color,
          ),
        ),
        title: Text(
          item.clientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.packageName),
              Text('${item.selectedFiles.length} file edit'),
              Text(
                item.statusLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              if (item.editDeadlineAt.isNotEmpty)
                Text('Deadline: ${item.formattedEditDeadline}'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
