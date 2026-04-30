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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
    });
  }

  Future<void> fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      setState(() => errorMessage = null);
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
        setState(() => errorMessage = message);
        _showMessage(message);
      }

      return false;
    } catch (e) {
      final message = _cleanMessage(e.toString());

      if (mounted) {
        setState(() => errorMessage = message);
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
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                        color: _AssignPalette.cardDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _AssignEditorSheetHeader(
                        clientName: _clientName(request),
                        packageName: _packageName(request),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        shrinkWrap: true,
                        children: [
                          const _SheetSectionTitle(
                            title: 'Daftar Editor',
                            subtitle:
                                'Pilih editor yang akan mengerjakan request ini.',
                          ),

                          const SizedBox(height: 12),

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
                            height: 46,
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
                                        color: AppColors.white,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _AssignPalette.darkBlue,
                                foregroundColor: AppColors.white,
                                disabledBackgroundColor: AppColors.grey
                                    .withOpacity(0.35),
                                disabledForegroundColor: AppColors.white
                                    .withOpacity(0.86),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (map['message'] != null) {
        return _cleanMessage(map['message'].toString());
      }
    }

    final message = e.message;

    if (message != null && message.trim().isNotEmpty) {
      return _cleanMessage(message);
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

  List<String> _selectedFiles(dynamic rawRequest) {
    final request = _asMap(rawRequest);
    final files = request['selected_files'];

    if (files is List) {
      return files.map((item) => item.toString()).toList();
    }

    if (files is String && files.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(files);

        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {
        return [files];
      }
    }

    return [];
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
        return _AssignPalette.darkBlue;
      case 'assigned':
        return _AssignPalette.midBlue;
      case 'in_progress':
        return _AssignPalette.lightBlue;
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
        return 'Menunggu Editor';
      case 'assigned':
        return 'Sudah Di-assign';
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

  String _requestNotes(dynamic rawRequest) {
    final request = _asMap(rawRequest);
    return request['request_notes']?.toString().trim() ?? '';
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
        selectedColor: _AssignPalette.darkBlue,
        backgroundColor: AppColors.light,
        side: BorderSide(
          color: selected ? _AssignPalette.darkBlue : _AssignPalette.cardDeep,
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.white : _AssignPalette.darkBlue,
          fontSize: 11.3,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        onSelected: (_) {
          setState(() => selectedStatus = value);
          fetchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waitingCount = editRequests.where((item) {
      final request = _asMap(item);
      return (request['status']?.toString() ?? '') == 'submitted';
    }).length;

    final assignedCount = editRequests.where((item) {
      final request = _asMap(item);
      final status = request['status']?.toString() ?? '';
      return status == 'assigned' || status == 'in_progress';
    }).length;

    final completedCount = editRequests.where((item) {
      final request = _asMap(item);
      return (request['status']?.toString() ?? '') == 'completed';
    }).length;

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _AssignPalette.darkBlue,
          backgroundColor: _AssignPalette.cardLight,
          onRefresh: () => fetchData(showLoading: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              _EditAssignHeader(
                totalRequest: editRequests.length,
                waitingCount: waitingCount,
                assignedCount: assignedCount,
                completedCount: completedCount,
              ),

              const SizedBox(height: 16),

              const _SectionTitle(
                title: 'Filter Request',
                subtitle: 'Pilih status request edit yang ingin dipantau.',
              ),

              const SizedBox(height: 12),

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

              const _SectionTitle(
                title: 'Daftar Request Edit',
                subtitle: 'Assign atau ganti editor untuk request klien.',
                trailingText: 'Live',
              ),

              const SizedBox(height: 12),

              if (isLoading)
                const _LoadingCard()
              else if (errorMessage != null)
                _ErrorState(message: errorMessage!, onRetry: () => fetchData())
              else if (editRequests.isEmpty)
                _EmptyEditRequestState(
                  message: 'Request edit dari klien akan tampil di sini.',
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
                      selectedFiles: selectedFiles,
                      requestNotes: _requestNotes(request),
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

class _AssignPalette {
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
  final int waitingCount;
  final int assignedCount;
  final int completedCount;

  const _EditAssignHeader({
    required this.totalRequest,
    required this.waitingCount,
    required this.assignedCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _AssignPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _AssignPalette.darkBlue.withOpacity(0.16),
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
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
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
                          'Assign Editor',
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
                          'Kelola request edit dan pilih editor yang bertugas.',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            '$totalRequest request masuk',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _HeaderMetric(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Menunggu',
                      value: '$waitingCount',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _HeaderMetric(
                      icon: Icons.assignment_turned_in_rounded,
                      label: 'Proses',
                      value: '$assignedCount',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _HeaderMetric(
                      icon: Icons.check_circle_rounded,
                      label: 'Selesai',
                      value: '$completedCount',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.white.withOpacity(0.20), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.88),
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignEditorSheetHeader extends StatelessWidget {
  final String clientName;
  final String packageName;

  const _AssignEditorSheetHeader({
    required this.clientName,
    required this.packageName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _AssignPalette.darkGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _AssignPalette.darkBlue.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -28,
            child: Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: AppColors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.white,
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
                        color: AppColors.white,
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$clientName • $packageName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.72),
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
        ],
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
            gradient: _AssignPalette.darkGradient,
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
              color: _AssignPalette.cardLight,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _AssignPalette.cardDeep),
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
                    color: _AssignPalette.darkBlue,
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

class _SheetSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SheetSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 28,
          width: 5,
          decoration: BoxDecoration(
            gradient: _AssignPalette.darkGradient,
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
                  color: _AssignPalette.darkBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _AssignPalette.darkBlue.withOpacity(0.55),
                  fontSize: 11,
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

class _EditRequestCard extends StatelessWidget {
  final String clientName;
  final String packageName;
  final List<String> selectedFiles;
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
    required this.selectedFiles,
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

    final hasEditor = editorName.trim().isNotEmpty && editorName != '-';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AssignPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _AssignPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                        color: _AssignPalette.darkBlue,
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
                        color: _AssignPalette.darkBlue.withOpacity(0.58),
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
                  label: hasEditor ? editorName : 'Belum Ada Editor',
                  color: hasEditor ? _AssignPalette.darkBlue : AppColors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _RequestInfoPanel(
            selectedFiles: selectedFiles,
            deadlineText: deadlineText,
          ),

          if (requestNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _MessageBox(
              color: _AssignPalette.darkBlue,
              icon: Icons.notes_rounded,
              text: requestNotes,
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canAssign ? onAssign : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
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
                backgroundColor: _AssignPalette.darkBlue,
                foregroundColor: AppColors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppColors.grey.withOpacity(0.35),
                disabledForegroundColor: AppColors.white.withOpacity(0.86),
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

class _RequestInfoPanel extends StatelessWidget {
  final List<String> selectedFiles;
  final String deadlineText;

  const _RequestInfoPanel({
    required this.selectedFiles,
    required this.deadlineText,
  });

  @override
  Widget build(BuildContext context) {
    final previewFiles = selectedFiles.take(6).toList();
    final remaining = selectedFiles.length - previewFiles.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        gradient: _AssignPalette.softGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  icon: Icons.photo_library_rounded,
                  label: 'Jumlah File',
                  value: '${selectedFiles.length} file',
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
          _FilePreviewWrap(files: previewFiles, remaining: remaining),
        ],
      ),
    );
  }
}

class _FilePreviewWrap extends StatelessWidget {
  final List<String> files;
  final int remaining;

  const _FilePreviewWrap({required this.files, required this.remaining});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const _SmallInfoBox(
        icon: Icons.folder_off_rounded,
        text: 'Belum ada file dipilih',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SmallInfoTitle(
          icon: Icons.folder_copy_rounded,
          text: 'File Dipilih',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            ...files.map((file) => _FileChip(label: file)),
            if (remaining > 0) _FileChip(label: '+$remaining file'),
          ],
        ),
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  final String label;

  const _FileChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white),
      ),
      child: Text(
        label.trim().isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _AssignPalette.darkBlue,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallInfoTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfoTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _AssignPalette.darkBlue, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: _AssignPalette.darkBlue.withOpacity(0.58),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
    final color = isSelected ? AppColors.success : _AssignPalette.darkBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.success : _AssignPalette.cardDeep,
            ),
            boxShadow: [
              BoxShadow(
                color: _AssignPalette.darkBlue.withOpacity(0.05),
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
                            color: _AssignPalette.darkBlue,
                            fontSize: 15,
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
                            color: _AssignPalette.darkBlue.withOpacity(0.58),
                            fontSize: 11.5,
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
                  gradient: _AssignPalette.softGradient,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: AppColors.white.withOpacity(0.76)),
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
        Icon(icon, color: _AssignPalette.darkBlue, size: 16),
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
                  color: _AssignPalette.darkBlue.withOpacity(0.54),
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
                  color: _AssignPalette.darkBlue,
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
          gradient: _AssignPalette.softGradient,
          borderRadius: BorderRadius.circular(24),
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
              child: const Icon(
                Icons.edit_note_outlined,
                size: 34,
                color: _AssignPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada request edit',
              style: TextStyle(
                color: _AssignPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AssignPalette.darkBlue.withOpacity(0.62),
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
                foregroundColor: _AssignPalette.darkBlue,
                side: const BorderSide(color: _AssignPalette.cardDeep),
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AssignPalette.cardDeep),
      ),
      child: const CircularProgressIndicator(color: _AssignPalette.darkBlue),
    );
  }
}
