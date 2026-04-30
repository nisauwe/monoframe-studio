import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
        'Belum ada editor aktif. Pastikan user role Editor sudah dibuat dan aktif.',
      );
      return;
    }

    int? selectedEditorId;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        bool modalSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.84,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _EditAssignPalette.cardDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: _EditAssignPalette.darkGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _EditAssignPalette.darkBlue.withOpacity(
                                0.14,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.20),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_fix_high_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pilih Editor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_clientName(request)} • ${_packageName(request)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.72),
                                      fontSize: 12.2,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        shrinkWrap: true,
                        children: [
                          ...editors.map((rawEditor) {
                            final editor = _asMap(rawEditor);
                            final editorId = _toInt(editor['id']);
                            final name = editor['name']?.toString() ?? '-';
                            final email = editor['email']?.toString() ?? '-';
                            final phone = editor['phone']?.toString() ?? '-';

                            final isSelected = selectedEditorId == editorId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EditorOptionCard(
                                name: name,
                                email: email,
                                phone: phone,
                                isSelected: isSelected,
                                isDisabled: modalSubmitting,
                                onTap: () {
                                  if (modalSubmitting) return;

                                  setModalState(() {
                                    selectedEditorId = editorId;
                                  });
                                },
                              ),
                            );
                          }),

                          const SizedBox(height: 6),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed:
                                  modalSubmitting || selectedEditorId == null
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
                                        _showMessage(
                                          'Editor berhasil di-assign',
                                        );
                                      } else {
                                        setModalState(() {
                                          modalSubmitting = false;
                                        });
                                      }
                                    },
                              icon: modalSubmitting
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.assignment_turned_in_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                modalSubmitting
                                    ? 'Memproses...'
                                    : 'Assign Editor',
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _EditAssignPalette.darkBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.grey
                                    .withOpacity(0.35),
                                disabledForegroundColor: Colors.white
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
                  ],
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
      return 'Status edit di database belum mendukung assigned/in_progress. Jalankan migration perbaikan enum status edit_requests.';
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
        return AppColors.warning;
      case 'assigned':
        return _EditAssignPalette.midBlue;
      case 'in_progress':
        return _EditAssignPalette.lightBlue;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.hourglass_top_rounded;
      case 'assigned':
        return Icons.assignment_turned_in_rounded;
      case 'in_progress':
        return Icons.auto_fix_high_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
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

  String _deadlineText(dynamic rawRequest) {
    final request = _asMap(rawRequest);
    final deadline = request['edit_deadline_at'];

    if (deadline == null || deadline.toString().trim().isEmpty) {
      return '-';
    }

    return deadline.toString();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _filterChip({required String label, required String value}) {
    final selected = selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: _EditAssignPalette.darkBlue,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected
              ? _EditAssignPalette.darkBlue
              : _EditAssignPalette.cardDeep,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : _EditAssignPalette.darkBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _EditAssignPalette.darkBlue,
          backgroundColor: _EditAssignPalette.cardLight,
          onRefresh: () => fetchData(showLoading: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              _EditAssignHeader(totalRequest: editRequests.length),

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

              const SizedBox(height: 18),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _EditAssignPalette.darkBlue,
                    ),
                  ),
                )
              else if (errorMessage != null)
                _ErrorState(message: errorMessage!, onRetry: () => fetchData())
              else if (editRequests.isEmpty)
                _EmptyEditRequestState(
                  message: 'Permintaan edit dari klien akan tampil di sini.',
                  onRefresh: () => fetchData(),
                )
              else
                ...editRequests.map((rawRequest) {
                  final request = _asMap(rawRequest);
                  final status = request['status']?.toString() ?? '';
                  final color = _statusColor(status);
                  final selectedFiles = _selectedFiles(request);
                  final editor = request['editor'];
                  final hasEditor = editor != null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EditRequestCard(
                      clientName: _clientName(request),
                      packageName: _packageName(request),
                      fileCount: selectedFiles.length,
                      fileText: _filesText(request),
                      requestNotes:
                          request['request_notes']?.toString().trim() ?? '',
                      statusLabel: _statusLabel(request),
                      statusColor: color,
                      statusIcon: _statusIcon(status),
                      editorName: hasEditor ? _editorName(request) : '-',
                      deadlineText: _deadlineText(request),
                      canAssign: status != 'completed' && !isSubmitting,
                      buttonLabel: hasEditor ? 'Ganti Editor' : 'Assign Editor',
                      isSubmitting: isSubmitting,
                      onAssign: () => openAssignDialog(request),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditAssignPalette {
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

class _EditAssignHeader extends StatelessWidget {
  final int totalRequest;

  const _EditAssignHeader({required this.totalRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _EditAssignPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _EditAssignPalette.darkBlue.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -34,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -48,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              const _HeaderIcon(),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Editor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Pilih editor untuk mengerjakan permintaan edit foto dari klien.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_fix_high_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$totalRequest permintaan edit',
                            style: const TextStyle(
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
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 31),
    );
  }
}

class _EditRequestCard extends StatelessWidget {
  final String clientName;
  final String packageName;
  final int fileCount;
  final String fileText;
  final String requestNotes;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String editorName;
  final String deadlineText;
  final bool canAssign;
  final String buttonLabel;
  final bool isSubmitting;
  final VoidCallback onAssign;

  const _EditRequestCard({
    required this.clientName,
    required this.packageName,
    required this.fileCount,
    required this.fileText,
    required this.requestNotes,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.editorName,
    required this.deadlineText,
    required this.canAssign,
    required this.buttonLabel,
    required this.isSubmitting,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final shownClientName = clientName.trim().isEmpty
        ? 'Klien'
        : clientName.trim();

    final shownPackageName = packageName.trim().isEmpty
        ? '-'
        : packageName.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _EditAssignPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _EditAssignPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusIconBox(icon: statusIcon, color: statusColor),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shownClientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _EditAssignPalette.darkBlue,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      shownPackageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EditAssignPalette.darkBlue.withOpacity(0.58),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatusChip(label: statusLabel, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChip(
                  label: editorName == '-' ? 'Belum Ada Editor' : editorName,
                  color: editorName == '-'
                      ? AppColors.warning
                      : _EditAssignPalette.darkBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: _EditAssignPalette.softGradient,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withOpacity(0.76)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.photo_library_rounded,
                        label: 'Jumlah File',
                        value: '$fileCount file',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.timer_rounded,
                        label: 'Deadline',
                        value: deadlineText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _WideCompactInfo(
                  icon: Icons.folder_copy_rounded,
                  label: 'File Dipilih',
                  value: fileText,
                ),
              ],
            ),
          ),

          if (requestNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _MessageBox(
              color: _EditAssignPalette.midBlue,
              icon: Icons.notes_rounded,
              text: requestNotes,
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: canAssign ? onAssign : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_ind_rounded, size: 18),
              label: Text(
                isSubmitting ? 'Memproses...' : buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _EditAssignPalette.darkBlue,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppColors.grey.withOpacity(0.35),
                disabledForegroundColor: Colors.white.withOpacity(0.86),
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
    );
  }
}

class _EditorOptionCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _EditorOptionCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.success : _EditAssignPalette.darkBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? AppColors.success
                  : _EditAssignPalette.cardDeep,
            ),
            boxShadow: [
              BoxShadow(
                color: _EditAssignPalette.darkBlue.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.12)),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.edit_rounded,
                      color: color,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.trim().isEmpty ? 'Editor' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _EditAssignPalette.darkBlue,
                            fontSize: 16,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email.trim().isEmpty ? '-' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _EditAssignPalette.darkBlue.withOpacity(
                              0.56,
                            ),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: isSelected ? 'Dipilih' : 'Editor',
                    color: color,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                decoration: BoxDecoration(
                  gradient: _EditAssignPalette.softGradient,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: Colors.white.withOpacity(0.76)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: email.trim().isEmpty ? '-' : email,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.phone_rounded,
                        label: 'Telepon',
                        value: phone.trim().isEmpty ? '-' : phone,
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

class _StatusIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Icon(icon, color: color, size: 21),
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
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
        Icon(icon, color: _EditAssignPalette.darkBlue, size: 16),
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
                  color: _EditAssignPalette.darkBlue.withOpacity(0.54),
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
                  color: _EditAssignPalette.darkBlue,
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

class _WideCompactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WideCompactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _EditAssignPalette.darkBlue, size: 16),
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
                  color: _EditAssignPalette.darkBlue.withOpacity(0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _EditAssignPalette.darkBlue,
                  fontSize: 11.2,
                  height: 1.25,
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

class _MessageBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _MessageBox({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
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

class _EmptyEditRequestState extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _EmptyEditRequestState({
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _EditAssignPalette.softGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.78)),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.60),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_outlined,
                size: 34,
                color: _EditAssignPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada permintaan edit',
              style: TextStyle(
                color: _EditAssignPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _EditAssignPalette.darkBlue.withOpacity(0.62),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _EditAssignPalette.darkBlue,
                side: const BorderSide(color: _EditAssignPalette.cardDeep),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.danger.withOpacity(0.14)),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.74),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Data gagal dimuat',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withOpacity(0.22)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
