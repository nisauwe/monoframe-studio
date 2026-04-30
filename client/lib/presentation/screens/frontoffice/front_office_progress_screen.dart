import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/dio_client.dart';
import 'front_office_progress_detail_screen.dart';

class FrontOfficeProgressScreen extends StatefulWidget {
  const FrontOfficeProgressScreen({super.key});

  @override
  State<FrontOfficeProgressScreen> createState() =>
      _FrontOfficeProgressScreenState();
}

class _FrontOfficeProgressScreenState extends State<FrontOfficeProgressScreen> {
  final Dio _dio = DioClient().dio;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _progressList = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProgress();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProgress({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }

    try {
      final response = await _dio.get(
        '/front-office/progress',
        queryParameters: {
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        _progressList = _extractList(
          response.data,
        ).map<Map<String, dynamic>>((item) => _asMap(item)).toList();
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _messageFromDio(e, 'Gagal mengambil data progress');
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditSheet(Map<String, dynamic> booking) async {
    final packages = await _fetchPackages();

    if (!mounted) return;

    if (packages.isEmpty) {
      _showMessage('Belum ada paket aktif.');
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _EditBookingSheet(
          booking: booking,
          packages: packages,
          fetchSlots: _fetchAvailableSlots,
          fetchPhotographers: _fetchAvailablePhotographers,
          onSave: _updateBooking,
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPackages() async {
    try {
      final response = await _dio.get('/front-office/packages');

      return _extractList(
        response.data,
      ).map<Map<String, dynamic>>((item) => _asMap(item)).toList();
    } on DioException catch (e) {
      _showMessage(_messageFromDio(e, 'Gagal mengambil paket'));
      return <Map<String, dynamic>>[];
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableSlots({
    required int bookingId,
    required int packageId,
    required String bookingDate,
    required int extraDurationUnits,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/progress/$bookingId/available-slots',
        queryParameters: {
          'package_id': packageId,
          'booking_date': bookingDate,
          'extra_duration_units': extraDurationUnits,
        },
      );

      return _extractList(
        response.data,
      ).map<Map<String, dynamic>>((item) => _asMap(item)).toList();
    } on DioException catch (e) {
      _showMessage(_messageFromDio(e, 'Gagal mengambil slot tersedia'));
      return <Map<String, dynamic>>[];
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailablePhotographers({
    required int bookingId,
    required String bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/progress/$bookingId/available-photographers',
        queryParameters: {
          'booking_date': bookingDate,
          'start_time': startTime,
          'end_time': endTime,
        },
      );

      return _extractList(
        response.data,
      ).map<Map<String, dynamic>>((item) => _asMap(item)).toList();
    } on DioException catch (e) {
      _showMessage(_messageFromDio(e, 'Gagal mengambil fotografer tersedia'));
      return <Map<String, dynamic>>[];
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      return <Map<String, dynamic>>[];
    }
  }

  Future<bool> _updateBooking(_EditBookingPayload payload) async {
    try {
      await _dio.patch(
        '/front-office/progress/${payload.bookingId}/booking',
        data: payload.toJson(),
      );

      if (!mounted) return true;

      _showMessage('Detail booking berhasil diperbarui');
      await _fetchProgress(showLoading: false);

      return true;
    } on DioException catch (e) {
      _showMessage(_messageFromDio(e, 'Gagal memperbarui booking'));
      return false;
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }

    if (data is Map && data['data'] is Map) {
      final dataMap = Map<String, dynamic>.from(data['data']);

      if (dataMap['data'] is List) {
        return dataMap['data'] as List;
      }
    }

    return <dynamic>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message']
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
      }

      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }

          return firstError.toString();
        }
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (map['message'] != null) {
        return map['message'].toString().replaceFirst('Exception: ', '').trim();
      }
    }

    final message = e.message;

    if (message != null && message.trim().isNotEmpty) {
      return message;
    }

    return fallback;
  }

  String _paymentLabel(Map<String, dynamic> booking) {
    final explicit = booking['payment_status_label']?.toString().trim();

    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    if (booking['is_fully_paid'] == true) return 'Lunas';
    if (booking['is_dp_paid'] == true) return 'DP Terbayar';

    final status = booking['payment_status']?.toString().toLowerCase() ?? '';

    switch (status) {
      case 'dp_paid':
      case 'partially_paid':
        return 'DP Terbayar';
      case 'paid':
      case 'fully_paid':
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'failed':
        return 'Pembayaran Gagal';
      default:
        return 'Belum Bayar';
    }
  }

  Color _paymentColor(Map<String, dynamic> booking) {
    final label = _paymentLabel(booking).toLowerCase();

    if (label.contains('lunas')) return AppColors.success;
    if (label.contains('dp')) return AppColors.warning;
    if (label.contains('gagal')) return AppColors.danger;
    if (label.contains('menunggu')) return AppColors.warning;

    return AppColors.grey;
  }

  Map<String, dynamic> _currentStage(Map<String, dynamic> booking) {
    return _asMap(booking['current_stage']);
  }

  String _stageLabel(Map<String, dynamic> booking) {
    final stage = _currentStage(booking);
    final label = stage['stage_name']?.toString().trim() ?? '';

    return label.isEmpty ? 'Assign Fotografer' : label;
  }

  Color _stageColor(Map<String, dynamic> booking) {
    final label = _stageLabel(booking).toLowerCase();

    if (label.contains('assign')) return _ProgressPalette.midBlue;
    if (label.contains('foto') || label.contains('photo')) {
      return _ProgressPalette.midBlue;
    }
    if (label.contains('edit')) return _ProgressPalette.lightBlue;
    if (label.contains('cetak')) return AppColors.warning;
    if (label.contains('review') || label.contains('selesai')) {
      return AppColors.success;
    }

    return _ProgressPalette.darkBlue;
  }

  IconData _stageIcon(Map<String, dynamic> booking) {
    final label = _stageLabel(booking).toLowerCase();

    if (label.contains('assign')) return Icons.assignment_ind_rounded;
    if (label.contains('foto') || label.contains('photo')) {
      return Icons.photo_camera_rounded;
    }
    if (label.contains('edit')) return Icons.auto_fix_high_rounded;
    if (label.contains('cetak')) return Icons.print_rounded;
    if (label.contains('review') || label.contains('selesai')) {
      return Icons.check_circle_rounded;
    }

    return Icons.track_changes_rounded;
  }

  String _packageName(Map<String, dynamic> booking) {
    final package = _asMap(booking['package']);
    return _text(package['name'], 'Paket Foto');
  }

  String _photographerName(Map<String, dynamic> booking) {
    final photographer = _asMap(booking['photographer']);

    return _text(
      photographer['name'] ?? booking['photographer_name'],
      'Belum di-assign',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _ProgressPalette.darkBlue,
          backgroundColor: _ProgressPalette.cardLight,
          onRefresh: () => _fetchProgress(showLoading: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              _ProgressHeader(totalProgress: _progressList.length),
              const SizedBox(height: 16),

              _SearchBox(
                controller: _searchController,
                onSearch: () => _fetchProgress(),
                onClear: () {
                  _searchController.clear();
                  _fetchProgress();
                },
              ),

              const SizedBox(height: 18),

              if (_isLoading && _progressList.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _ProgressPalette.darkBlue,
                    ),
                  ),
                )
              else if (_errorMessage != null && _progressList.isEmpty)
                _ErrorState(
                  message: _errorMessage!,
                  onRetry: () => _fetchProgress(),
                )
              else if (_progressList.isEmpty)
                _EmptyProgressState(
                  message: 'Data progress booking klien akan tampil di sini.',
                  onRefresh: () => _fetchProgress(),
                )
              else
                ..._progressList.map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProgressCard(
                      clientName: _text(booking['client_name'], 'Klien'),
                      packageName: _packageName(booking),
                      photographerName: _photographerName(booking),
                      bookingDate: _text(booking['booking_date']),
                      timeRange:
                          '${_text(booking['start_time'])} - ${_text(booking['end_time'])}',
                      stageLabel: _stageLabel(booking),
                      stageColor: _stageColor(booking),
                      stageIcon: _stageIcon(booking),
                      paymentLabel: _paymentLabel(booking),
                      paymentColor: _paymentColor(booking),
                      editStatus: _text(booking['edit_request_status']),
                      onDetail: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FrontOfficeProgressDetailScreen(
                              bookingId: _toInt(booking['id']),
                              title: _text(booking['client_name'], 'Klien'),
                            ),
                          ),
                        );
                      },
                      onEdit: () => _openEditSheet(booking),
                    ),
                  );
                }),

              if (_errorMessage != null && _progressList.isNotEmpty) ...[
                const SizedBox(height: 4),
                _ErrorMessageBox(message: _errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditBookingPayload {
  final int bookingId;
  final int packageId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String blockedUntil;
  final int extraDurationUnits;
  final int extraDurationMinutes;
  final int extraDurationFee;
  final int photographerUserId;
  final String locationName;
  final String notes;

  _EditBookingPayload({
    required this.bookingId,
    required this.packageId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.blockedUntil,
    required this.extraDurationUnits,
    required this.extraDurationMinutes,
    required this.extraDurationFee,
    required this.photographerUserId,
    required this.locationName,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'blocked_until': blockedUntil,
      'extra_duration_units': extraDurationUnits,
      'extra_duration_minutes': extraDurationMinutes,
      'extra_duration_fee': extraDurationFee,
      'photographer_user_id': photographerUserId,
      'location_name': locationName,
      'notes': notes,
    };
  }
}

class _EditBookingSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  final List<Map<String, dynamic>> packages;
  final Future<List<Map<String, dynamic>>> Function({
    required int bookingId,
    required int packageId,
    required String bookingDate,
    required int extraDurationUnits,
  })
  fetchSlots;
  final Future<List<Map<String, dynamic>>> Function({
    required int bookingId,
    required String bookingDate,
    required String startTime,
    required String endTime,
  })
  fetchPhotographers;
  final Future<bool> Function(_EditBookingPayload payload) onSave;

  const _EditBookingSheet({
    required this.booking,
    required this.packages,
    required this.fetchSlots,
    required this.fetchPhotographers,
    required this.onSave,
  });

  @override
  State<_EditBookingSheet> createState() => _EditBookingSheetState();
}

class _EditBookingSheetState extends State<_EditBookingSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late int _selectedPackageId;
  late DateTime _selectedDate;
  late int _extraUnits;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoadingSlots = false;
  bool _isLoadingPhotographers = false;
  bool _isSaving = false;

  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _photographers = [];

  Map<String, dynamic>? _selectedSlot;
  int? _selectedPhotographerId;

  @override
  void initState() {
    super.initState();

    _selectedPackageId = _toInt(
      widget.booking['package_id'] ?? _asMap(widget.booking['package'])['id'],
    );

    final packageExists = widget.packages.any(
      (item) => _toInt(item['id']) == _selectedPackageId,
    );

    if (!packageExists && widget.packages.isNotEmpty) {
      _selectedPackageId = _toInt(widget.packages.first['id']);
    }

    _selectedDate =
        DateTime.tryParse(widget.booking['booking_date']?.toString() ?? '') ??
        DateTime.now();

    _extraUnits = _toInt(widget.booking['extra_duration_units']);

    if (_extraUnits < 0) _extraUnits = 0;
    if (_extraUnits > 10) _extraUnits = 10;

    _locationController.text =
        widget.booking['location_name']?.toString() ?? '';
    _notesController.text = widget.booking['notes']?.toString() ?? '';

    final photographer = _asMap(widget.booking['photographer']);

    _selectedPhotographerId = _toInt(
      widget.booking['photographer_user_id'] ?? photographer['id'],
    );

    if (_selectedPhotographerId == 0) {
      _selectedPhotographerId = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _normalizeTime(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) return '';

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  Map<String, dynamic> get _selectedPackage {
    return widget.packages.firstWhere(
      (item) => _toInt(item['id']) == _selectedPackageId,
      orElse: () => <String, dynamic>{},
    );
  }

  bool get _isOutdoor {
    return _selectedPackage['location_type']?.toString().toLowerCase() ==
        'outdoor';
  }

  Future<void> _loadSlots() async {
    if (_selectedPackageId == 0) return;

    setState(() {
      _isLoadingSlots = true;
      _slots = [];
      _selectedSlot = null;
      _photographers = [];
    });

    final result = await widget.fetchSlots(
      bookingId: _toInt(widget.booking['id']),
      packageId: _selectedPackageId,
      bookingDate: _formatDate(_selectedDate),
      extraDurationUnits: _extraUnits,
    );

    if (!mounted) return;

    setState(() {
      _slots = result;

      final currentStart = _normalizeTime(widget.booking['start_time']);

      _selectedSlot = _slots.firstWhere(
        (slot) => _normalizeTime(slot['start_time']) == currentStart,
        orElse: () => _slots.isNotEmpty ? _slots.first : <String, dynamic>{},
      );

      if (_selectedSlot != null && _selectedSlot!.isEmpty) {
        _selectedSlot = null;
      }
    });

    if (_selectedSlot != null) {
      await _loadPhotographers();
    }

    if (mounted) {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _loadPhotographers() async {
    if (_selectedSlot == null) return;

    setState(() {
      _isLoadingPhotographers = true;
      _photographers = [];
    });

    final result = await widget.fetchPhotographers(
      bookingId: _toInt(widget.booking['id']),
      bookingDate: _formatDate(_selectedDate),
      startTime: _selectedSlot!['start_time']?.toString() ?? '',
      endTime: _selectedSlot!['end_time']?.toString() ?? '',
    );

    if (!mounted) return;

    setState(() {
      _photographers = result;

      final selectedStillExists = _photographers.any(
        (item) => _toInt(item['id']) == _selectedPhotographerId,
      );

      if (!selectedStillExists) {
        _selectedPhotographerId = _photographers.isNotEmpty
            ? _toInt(_photographers.first['id'])
            : null;
      }

      _isLoadingPhotographers = false;
    });
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _ProgressPalette.darkBlue,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    setState(() => _selectedDate = result);
    await _loadSlots();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSlot == null) {
      _showSheetMessage('Pilih slot jadwal terlebih dahulu.');
      return;
    }

    if (_selectedPhotographerId == null) {
      _showSheetMessage('Pilih fotografer terlebih dahulu.');
      return;
    }

    setState(() => _isSaving = true);

    final ok = await widget.onSave(
      _EditBookingPayload(
        bookingId: _toInt(widget.booking['id']),
        packageId: _selectedPackageId,
        bookingDate: _formatDate(_selectedDate),
        startTime: _selectedSlot!['start_time']?.toString() ?? '',
        endTime: _selectedSlot!['end_time']?.toString() ?? '',
        blockedUntil:
            _selectedSlot!['blocked_until']?.toString() ??
            _selectedSlot!['end_time']?.toString() ??
            '',
        extraDurationUnits: _toInt(_selectedSlot!['extra_duration_units']),
        extraDurationMinutes: _toInt(_selectedSlot!['extra_duration_minutes']),
        extraDurationFee: _toInt(_selectedSlot!['extra_duration_fee']),
        photographerUserId: _selectedPhotographerId!,
        locationName: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop();
    }
  }

  void _showSheetMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _slotLabel(Map<String, dynamic> slot) {
    final label = slot['label']?.toString();

    if (label != null && label.isNotEmpty) {
      return label;
    }

    return '${_normalizeTime(slot['start_time'])} - ${_normalizeTime(slot['end_time'])}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                color: _ProgressPalette.cardDeep,
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
                  gradient: _ProgressPalette.darkGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _ProgressPalette.darkBlue.withOpacity(0.14),
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
                        Icons.edit_calendar_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Detail Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ubah paket, tanggal, slot, dan fotografer sesuai ketersediaan.',
                            style: TextStyle(
                              color: Colors.white70,
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _ProgressPalette.cardDeep),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            value: _selectedPackageId == 0
                                ? null
                                : _selectedPackageId,
                            decoration: const InputDecoration(
                              labelText: 'Paket Foto',
                              prefixIcon: Icon(Icons.photo_library_rounded),
                            ),
                            items: widget.packages.map((package) {
                              return DropdownMenuItem<int>(
                                value: _toInt(package['id']),
                                child: Text(package['name']?.toString() ?? '-'),
                              );
                            }).toList(),
                            onChanged: _isSaving
                                ? null
                                : (value) async {
                                    if (value == null) return;

                                    setState(() => _selectedPackageId = value);
                                    await _loadSlots();
                                  },
                            validator: (value) {
                              if (value == null || value == 0) {
                                return 'Paket wajib dipilih';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          _PickerField(
                            icon: Icons.calendar_month_rounded,
                            label: 'Tanggal Booking',
                            value: _formatDate(_selectedDate),
                            onTap: _isSaving ? null : _pickDate,
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<int>(
                            value: _extraUnits,
                            decoration: const InputDecoration(
                              labelText: 'Extra Durasi',
                              prefixIcon: Icon(Icons.timer_rounded),
                            ),
                            items: List.generate(11, (index) {
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Text(
                                  index == 0
                                      ? 'Tidak tambah extra durasi'
                                      : '+$index sesi extra durasi',
                                ),
                              );
                            }),
                            onChanged: _isSaving
                                ? null
                                : (value) async {
                                    setState(() => _extraUnits = value ?? 0);
                                    await _loadSlots();
                                  },
                          ),

                          const SizedBox(height: 14),

                          _SectionMiniTitle(
                            title: 'Pilih Slot Tersedia',
                            subtitle:
                                'Slot ini diambil dari jadwal server dan kapasitas studio.',
                            loading: _isLoadingSlots,
                          ),

                          const SizedBox(height: 10),

                          if (_isLoadingSlots)
                            const _MiniLoadingBox(text: 'Mengambil slot...')
                          else if (_slots.isEmpty)
                            const _MiniEmptyBox(
                              text:
                                  'Tidak ada slot tersedia pada tanggal dan paket ini.',
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _slots.map((slot) {
                                final selected =
                                    _selectedSlot != null &&
                                    _normalizeTime(
                                          _selectedSlot!['start_time'],
                                        ) ==
                                        _normalizeTime(slot['start_time']);

                                return ChoiceChip(
                                  label: Text(_slotLabel(slot)),
                                  selected: selected,
                                  showCheckmark: false,
                                  selectedColor: _ProgressPalette.darkBlue,
                                  backgroundColor: AppColors.light,
                                  side: BorderSide(
                                    color: selected
                                        ? _ProgressPalette.darkBlue
                                        : _ProgressPalette.cardDeep,
                                  ),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : _ProgressPalette.darkBlue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  onSelected: _isSaving
                                      ? null
                                      : (_) async {
                                          setState(() => _selectedSlot = slot);
                                          await _loadPhotographers();
                                        },
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 14),

                          _SectionMiniTitle(
                            title: 'Pilih Fotografer Tersedia',
                            subtitle:
                                'Fotografer dicek berdasarkan slot yang dipilih.',
                            loading: _isLoadingPhotographers,
                          ),

                          const SizedBox(height: 10),

                          if (_isLoadingPhotographers)
                            const _MiniLoadingBox(
                              text: 'Mengambil fotografer...',
                            )
                          else if (_selectedSlot == null)
                            const _MiniEmptyBox(
                              text: 'Pilih slot terlebih dahulu.',
                            )
                          else if (_photographers.isEmpty)
                            const _MiniEmptyBox(
                              text:
                                  'Tidak ada fotografer tersedia pada slot ini.',
                            )
                          else
                            ..._photographers.map((photographer) {
                              final id = _toInt(photographer['id']);
                              final selected = _selectedPhotographerId == id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: selected
                                      ? _ProgressPalette.cardLight
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: _isSaving
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedPhotographerId = id;
                                            });
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected
                                              ? _ProgressPalette.darkBlue
                                              : _ProgressPalette.cardDeep,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected
                                                ? Icons.check_circle_rounded
                                                : Icons.photo_camera_rounded,
                                            color: selected
                                                ? AppColors.success
                                                : _ProgressPalette.darkBlue,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  photographer['name']
                                                          ?.toString() ??
                                                      'Fotografer',
                                                  style: const TextStyle(
                                                    color: _ProgressPalette
                                                        .darkBlue,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  photographer['email']
                                                          ?.toString() ??
                                                      '-',
                                                  style: TextStyle(
                                                    color: _ProgressPalette
                                                        .darkBlue
                                                        .withOpacity(0.55),
                                                    fontSize: 12,
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
                                ),
                              );
                            }),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: _isOutdoor
                                  ? 'Lokasi Outdoor'
                                  : 'Lokasi',
                              hintText: _isOutdoor
                                  ? 'Contoh: Taman, cafe, pantai'
                                  : 'Indoor Studio Monoframe',
                              prefixIcon: const Icon(Icons.location_on_rounded),
                            ),
                            validator: (value) {
                              if (_isOutdoor &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Lokasi outdoor wajib diisi';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Catatan Perubahan',
                              hintText: 'Contoh: Klien minta ubah tanggal/jam',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),

                          const SizedBox(height: 14),

                          _MessageBox(
                            color: AppColors.warning,
                            icon: Icons.info_outline_rounded,
                            text:
                                'Kalau paket berubah dan harga berbeda, cek kembali status pembayaran/keuangan agar nominal tetap sesuai.',
                          ),

                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _ProgressPalette.darkBlue,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPalette {
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

class _ProgressHeader extends StatelessWidget {
  final int totalProgress;

  const _ProgressHeader({required this.totalProgress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _ProgressPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ProgressPalette.darkBlue.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: const Icon(
              Icons.timeline_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoring Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Pantau tracking klien dan edit booking sesuai ketersediaan.',
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
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Text(
                    '$totalProgress booking dipantau',
                    style: const TextStyle(
                      color: Colors.white,
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
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ProgressPalette.cardDeep),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _ProgressPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: (_) => onSearch(),
        style: const TextStyle(
          color: _ProgressPalette.darkBlue,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama klien, paket, fotografer...',
          hintStyle: TextStyle(
            color: _ProgressPalette.darkBlue.withOpacity(0.45),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _ProgressPalette.darkBlue,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, color: AppColors.grey),
              ),
              IconButton(
                onPressed: onSearch,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: _ProgressPalette.darkBlue,
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String clientName;
  final String packageName;
  final String photographerName;
  final String bookingDate;
  final String timeRange;
  final String stageLabel;
  final Color stageColor;
  final IconData stageIcon;
  final String paymentLabel;
  final Color paymentColor;
  final String editStatus;
  final VoidCallback onDetail;
  final VoidCallback onEdit;

  const _ProgressCard({
    required this.clientName,
    required this.packageName,
    required this.photographerName,
    required this.bookingDate,
    required this.timeRange,
    required this.stageLabel,
    required this.stageColor,
    required this.stageIcon,
    required this.paymentLabel,
    required this.paymentColor,
    required this.editStatus,
    required this.onDetail,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProgressPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _ProgressPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatusIconBox(icon: stageIcon, color: stageColor),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProgressPalette.darkBlue,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ProgressPalette.darkBlue.withOpacity(0.58),
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
                child: _StatusChip(label: stageLabel, color: stageColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChip(label: paymentLabel, color: paymentColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: _ProgressPalette.softGradient,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withOpacity(0.76)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.calendar_month_rounded,
                        label: 'Tanggal',
                        value: bookingDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.schedule_rounded,
                        label: 'Jam',
                        value: timeRange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.photo_camera_rounded,
                        label: 'Fotografer',
                        value: photographerName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.auto_fix_high_rounded,
                        label: 'Edit',
                        value: editStatus,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Detail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ProgressPalette.darkBlue,
                    side: const BorderSide(color: _ProgressPalette.cardDeep),
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
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('Edit Booking'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _ProgressPalette.darkBlue,
                    foregroundColor: Colors.white,
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
        ],
      ),
    );
  }
}

class _SectionMiniTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool loading;

  const _SectionMiniTitle({
    required this.title,
    required this.subtitle,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ProgressPalette.darkBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: _ProgressPalette.darkBlue.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _ProgressPalette.darkBlue,
            ),
          ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: _ProgressPalette.darkBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: _ProgressPalette.darkBlue.withOpacity(0.54),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _ProgressPalette.darkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _ProgressPalette.darkBlue,
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
        Icon(icon, color: _ProgressPalette.darkBlue, size: 16),
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
                  color: _ProgressPalette.darkBlue.withOpacity(0.54),
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
                  color: _ProgressPalette.darkBlue,
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

class _MiniLoadingBox extends StatelessWidget {
  final String text;

  const _MiniLoadingBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return _MiniInfoBox(
      icon: Icons.hourglass_top_rounded,
      text: text,
      color: _ProgressPalette.darkBlue,
    );
  }
}

class _MiniEmptyBox extends StatelessWidget {
  final String text;

  const _MiniEmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return _MiniInfoBox(
      icon: Icons.info_outline_rounded,
      text: text,
      color: AppColors.grey,
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniInfoBox({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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

class _EmptyProgressState extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _EmptyProgressState({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _ProgressPalette.softGradient,
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
                Icons.timeline_outlined,
                size: 34,
                color: _ProgressPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada progress',
              style: TextStyle(
                color: _ProgressPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProgressPalette.darkBlue.withOpacity(0.62),
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
                foregroundColor: _ProgressPalette.darkBlue,
                side: const BorderSide(color: _ProgressPalette.cardDeep),
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
        borderRadius: BorderRadius.circular(14),
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
