import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/services/dio_client.dart';

class FrontOfficeEditAssignmentScreen extends StatefulWidget {
  const FrontOfficeEditAssignmentScreen({super.key});

  @override
  State<FrontOfficeEditAssignmentScreen> createState() =>
      _FrontOfficeEditAssignmentScreenState();
}

class _FrontOfficeEditAssignmentScreenState
    extends State<FrontOfficeEditAssignmentScreen> {
  final Dio _dio = DioClient().dio;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  List<dynamic> editRequests = [];
  List<dynamic> editors = [];

  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = null;
      });
    }

    try {
      final queryParameters = <String, dynamic>{};

      if (selectedStatus != 'all') {
        queryParameters['status'] = selectedStatus;
      }

      final editResponse = await _dio.get(
        '/front-office/edit-requests',
        queryParameters: queryParameters,
      );

      final editorResponse = await _dio.get('/front-office/editors');

      if (!mounted) return;

      setState(() {
        editRequests = _extractList(editResponse.data);
        editors = _extractList(editorResponse.data);
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = _messageFromDio(e, 'Gagal mengambil data assign editor');
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = _cleanMessage(e.toString());
      });
    } finally {
      if (mounted && showLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool> assignEditor({
    required int editRequestId,
    required int editorUserId,
  }) async {
    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      await _dio.patch(
        '/front-office/edit-requests/$editRequestId/assign-editor',
        data: {'editor_user_id': editorUserId},
      );

      await fetchData(showLoading: false);
      return true;
    } on DioException catch (e) {
      final message = _messageFromDio(e, 'Gagal assign editor');

      if (mounted) {
        setState(() {
          errorMessage = message;
        });
        _showMessage(message);
      }

      return false;
    } catch (e) {
      final message = _cleanMessage(e.toString());

      if (mounted) {
        setState(() {
          errorMessage = message;
        });
        _showMessage(message);
      }

      return false;
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> openAssignDialog(dynamic rawRequest) async {
    final request = _asMap(rawRequest);

    if (editors.isEmpty) {
      _showMessage(
        'Belum ada editor aktif. Pastikan user role Editor sudah dibuat dan is_active = 1.',
      );
      return;
    }

    int? selectedEditorId;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (modalContext) {
        bool modalSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const Text(
                        'Pilih Editor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_clientName(request)} • ${_packageName(request)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      ...editors.map((rawEditor) {
                        final editor = _asMap(rawEditor);
                        final editorId = _toInt(editor['id']);
                        final name = editor['name']?.toString() ?? '-';
                        final email = editor['email']?.toString() ?? '-';
                        final phone = editor['phone']?.toString() ?? '-';

                        final isSelected = selectedEditorId == editorId;

                        return Card(
                          child: RadioListTile<int>(
                            value: editorId,
                            groupValue: selectedEditorId,
                            onChanged: modalSubmitting
                                ? null
                                : (value) {
                                    setModalState(() {
                                      selectedEditorId = value;
                                    });
                                  },
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('$email\n$phone'),
                            isThreeLine: true,
                            secondary: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.edit_outlined,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: modalSubmitting || selectedEditorId == null
                              ? null
                              : () async {
                                  setModalState(() {
                                    modalSubmitting = true;
                                  });

                                  final ok = await assignEditor(
                                    editRequestId: _toInt(request['id']),
                                    editorUserId: selectedEditorId!,
                                  );

                                  if (!mounted) return;

                                  if (ok) {
                                    Navigator.of(modalContext).pop();
                                    _showMessage('Editor berhasil di-assign');
                                  } else {
                                    setModalState(() {
                                      modalSubmitting = false;
                                    });
                                  }
                                },
                          icon: modalSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.assignment_ind_outlined),
                          label: Text(
                            modalSubmitting ? 'Memproses...' : 'Assign Editor',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }

    if (data is Map && data['data'] is Map) {
      final dataMap = Map<String, dynamic>.from(data['data']);

      if (dataMap['data'] is List) {
        return dataMap['data'] as List<dynamic>;
      }
    }

    return [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return _cleanMessage(data['message'].toString());
      }

      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final first = errors.values.first;

          if (first is List && first.isNotEmpty) {
            return _cleanMessage(first.first.toString());
          }

          return _cleanMessage(first.toString());
        }
      }
    }

    return _cleanMessage(fallback);
  }

  String _cleanMessage(String message) {
    final text = message.replaceFirst('Exception: ', '').trim();

    if (text.contains('SQLSTATE') ||
        text.contains('Data truncated') ||
        text.contains("column 'status'")) {
      return 'Status edit di database belum mendukung assigned/in_progress. Jalankan migration fix_edit_requests_status_enum di Laravel.';
    }

    if (text.isEmpty) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }

    return text;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  List<dynamic> _selectedFiles(dynamic rawRequest) {
    final request = _asMap(rawRequest);
    final files = request['selected_files'];

    if (files is List) return files;

    if (files is String && files.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(files);
        if (decoded is List) return decoded;
      } catch (_) {
        return [files];
      }
    }

    return [];
  }

  String _filesText(dynamic request) {
    final files = _selectedFiles(request);

    if (files.isEmpty) {
      return '-';
    }

    return files.map((item) => item.toString()).join(', ');
  }

  String _clientName(dynamic rawRequest) {
    final request = _asMap(rawRequest);

    final booking = request['booking'] is Map
        ? Map<String, dynamic>.from(request['booking'])
        : <String, dynamic>{};

    final client = request['client'] is Map
        ? Map<String, dynamic>.from(request['client'])
        : booking['client_user'] is Map
        ? Map<String, dynamic>.from(booking['client_user'])
        : <String, dynamic>{};

    return client['name']?.toString() ??
        booking['client_name']?.toString() ??
        'Klien';
  }

  String _packageName(dynamic rawRequest) {
    final request = _asMap(rawRequest);

    final booking = request['booking'] is Map
        ? Map<String, dynamic>.from(request['booking'])
        : <String, dynamic>{};

    final package = booking['package'] is Map
        ? Map<String, dynamic>.from(booking['package'])
        : <String, dynamic>{};

    return package['name']?.toString() ?? '-';
  }

  String _editorName(dynamic rawRequest) {
    final request = _asMap(rawRequest);

    final editor = request['editor'] is Map
        ? Map<String, dynamic>.from(request['editor'])
        : null;

    return editor?['name']?.toString() ?? '-';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(dynamic rawRequest) {
    final request = _asMap(rawRequest);
    final label = request['status_label']?.toString();

    if (label != null && label.isNotEmpty) {
      return label;
    }

    final status = request['status']?.toString() ?? '';

    switch (status) {
      case 'submitted':
        return 'Menunggu Assign Editor';
      case 'assigned':
        return 'Sudah Dikirim ke Editor';
      case 'in_progress':
        return 'Sedang Diedit';
      case 'completed':
        return 'Edit Selesai';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _filterChip({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedStatus == value,
        onSelected: (_) {
          setState(() => selectedStatus = value);
          fetchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: fetchData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Assign Editor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih editor untuk mengerjakan daftar foto edit dari klien.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(label: 'Semua', value: 'all'),
                  _filterChip(label: 'Menunggu', value: 'submitted'),
                  _filterChip(label: 'Assigned', value: 'assigned'),
                  _filterChip(label: 'Diproses', value: 'in_progress'),
                  _filterChip(label: 'Selesai', value: 'completed'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: fetchData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (editRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: Text('Belum ada permintaan edit.')),
              )
            else
              ...editRequests.map((rawRequest) {
                final request = _asMap(rawRequest);
                final status = request['status']?.toString() ?? '';
                final color = _statusColor(status);
                final editor = request['editor'];
                final selectedFiles = _selectedFiles(request);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _clientName(request),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text('Paket: ${_packageName(request)}'),
                        Text('Jumlah file: ${selectedFiles.length}'),
                        Text('File: ${_filesText(request)}'),

                        if (request['request_notes'] != null &&
                            request['request_notes'].toString().isNotEmpty)
                          Text('Catatan: ${request['request_notes']}'),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(request),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (editor != null)
                          Text(
                            'Editor: ${_editorName(request)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                        if (request['edit_deadline_at'] != null)
                          Text('Deadline: ${request['edit_deadline_at']}'),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: status == 'completed' || isSubmitting
                                ? null
                                : () => openAssignDialog(request),
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.assignment_ind_outlined),
                            label: Text(
                              editor == null ? 'Assign Editor' : 'Ganti Editor',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
