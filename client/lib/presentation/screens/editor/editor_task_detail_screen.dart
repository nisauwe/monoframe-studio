import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/editor_provider.dart';
import 'editor_complete_form_screen.dart';

class EditorTaskDetailScreen extends StatefulWidget {
  final int editRequestId;

  const EditorTaskDetailScreen({super.key, required this.editRequestId});

  @override
  State<EditorTaskDetailScreen> createState() => _EditorTaskDetailScreenState();
}

class _EditorTaskDetailScreenState extends State<EditorTaskDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().fetchEditRequestDetail(
        editRequestId: widget.editRequestId,
      );
    });
  }

  Future<void> _refresh() {
    return context.read<EditorProvider>().fetchEditRequestDetail(
      editRequestId: widget.editRequestId,
    );
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) {
      _showMessage('Link belum tersedia');
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showMessage('Link tidak valid');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      _showMessage('Tidak bisa membuka link');
    }
  }

  Future<void> _startEdit(EditorEditRequestModel item) async {
    final provider = context.read<EditorProvider>();

    final ok = await provider.startEdit(editRequestId: item.id);

    if (!mounted) return;

    if (ok) {
      _showMessage('Pekerjaan edit dimulai');
      _refresh();
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal memulai pekerjaan edit');
    }
  }

  Future<void> _openCompleteForm(EditorEditRequestModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorCompleteFormScreen(editRequest: item),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(EditorEditRequestModel item) {
    if (item.isCompleted) return Colors.green;
    if (item.isInProgress) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final item = provider.selectedEditRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Edit')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (provider.isLoading && item == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (item == null)
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ??
                            'Detail pekerjaan tidak ditemukan',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  item.clientName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Permintaan Edit #${item.id}',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 14),

                _StatusBanner(
                  text: item.statusLabel,
                  color: _statusColor(item),
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Informasi Klien'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      title: 'Nama Klien',
                      value: item.clientName,
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      title: 'Nomor HP',
                      value: item.clientPhone,
                    ),
                    if (item.client?.email.isNotEmpty == true)
                      _InfoRow(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: item.client!.email,
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Informasi Booking'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.photo_camera_outlined,
                      title: 'Paket',
                      value: item.packageName,
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tanggal Foto',
                      value: item.booking?.bookingDate ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.access_time_outlined,
                      title: 'Jam Foto',
                      value:
                          '${item.booking?.startTime ?? '-'} - ${item.booking?.endTime ?? '-'}',
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi',
                      value: item.booking?.locationName ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      title: 'Deadline Edit',
                      value: item.formattedEditDeadline,
                    ),
                    if (item.remainingDays != null)
                      _InfoRow(
                        icon: Icons.hourglass_bottom_outlined,
                        title: 'Sisa Hari',
                        value: '${item.remainingDays} hari',
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Link Foto Original'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.link_outlined,
                      title: item.originalPhotoDriveLabel,
                      value: item.originalPhotoDriveUrl.isEmpty
                          ? 'Link foto belum tersedia'
                          : item.originalPhotoDriveUrl,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: item.originalPhotoDriveUrl.isEmpty
                            ? null
                            : () => _openUrl(item.originalPhotoDriveUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka Link Foto Original'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Daftar File yang Harus Diedit'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.selectedFiles.length} file dipilih klien',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...item.selectedFiles.map((file) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.image_outlined, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(file)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                if (item.requestNotes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Catatan Klien'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(item.requestNotes),
                  ),
                ],

                if (item.isCompleted) ...[
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Hasil Edit'),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.link_outlined,
                        title: item.resultDriveLabel.isEmpty
                            ? 'Link Hasil Edit'
                            : item.resultDriveLabel,
                        value: item.resultDriveUrl,
                      ),
                      if (item.editorNotes.isNotEmpty)
                        _InfoRow(
                          icon: Icons.notes_outlined,
                          title: 'Catatan Editor',
                          value: item.editorNotes,
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: item.resultDriveUrl.isEmpty
                              ? null
                              : () => _openUrl(item.resultDriveUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Buka Link Hasil Edit'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                if (item.canStart)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _startEdit(item),
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: const Text('Mulai Editing'),
                    ),
                  ),

                if (item.canComplete) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _openCompleteForm(item),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload Hasil Edit / Selesaikan'),
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.trim().isEmpty ? '-' : value),
    );
  }
}
