import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';
import 'photographer_booking_detail_screen.dart';

class PhotographerScheduleScreen extends StatefulWidget {
  const PhotographerScheduleScreen({super.key});

  @override
  State<PhotographerScheduleScreen> createState() =>
      _PhotographerScheduleScreenState();
}

class _PhotographerScheduleScreenState
    extends State<PhotographerScheduleScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchBookings();
    });
  }

  Future<void> _refresh() {
    return context.read<PhotographerProvider>().fetchBookings();
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );

    setState(() {
      _selectedMonth = nextMonth;
      _selectedDate = DateTime(nextMonth.year, nextMonth.month, 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _openDetail(PhotographerBookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotographerBookingDetailScreen(bookingId: booking.id),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _monthLabel(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  String _dayLabel(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime? _bookingDate(PhotographerBookingModel booking) {
    final raw = booking.bookingDate.trim();

    if (raw.isEmpty) return null;

    final parsed = DateTime.tryParse(raw);

    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    if (raw.length >= 10) {
      final fallback = DateTime.tryParse(raw.substring(0, 10));

      if (fallback != null) {
        return DateTime(fallback.year, fallback.month, fallback.day);
      }
    }

    return null;
  }

  String _shortTime(String value) {
    final text = value.trim();

    if (text.isEmpty) return '-';

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  String _timeRange(PhotographerBookingModel booking) {
    return '${_shortTime(booking.startTime)} - ${_shortTime(booking.endTime)}';
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, List<PhotographerBookingModel>> _bookingsByDate(
    List<PhotographerBookingModel> bookings,
  ) {
    final grouped = <String, List<PhotographerBookingModel>>{};

    for (final booking in bookings) {
      final date = _bookingDate(booking);

      if (date == null) continue;

      final key = _formatDate(date);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(booking);
    }

    return grouped;
  }

  List<PhotographerBookingModel> _bookingsForSelectedDate(
    List<PhotographerBookingModel> bookings,
  ) {
    final selectedKey = _formatDate(_selectedDate);

    final filtered = bookings.where((booking) {
      final date = _bookingDate(booking);

      if (date == null) return false;

      return _formatDate(date) == selectedKey;
    }).toList();

    filtered.sort((a, b) {
      return _shortTime(a.startTime).compareTo(_shortTime(b.startTime));
    });

    return filtered;
  }

  int _todayTotal(List<PhotographerBookingModel> bookings) {
    final today = DateTime.now();

    return bookings.where((booking) {
      final date = _bookingDate(booking);

      if (date == null) return false;

      return _sameDate(date, today);
    }).length;
  }

  int _needUploadTotal(List<PhotographerBookingModel> bookings) {
    return bookings.where((booking) => !booking.hasPhotoLink).length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();

    final bookings = provider.bookings;
    final groupedBookings = _bookingsByDate(bookings);
    final selectedDateBookings = _bookingsForSelectedDate(bookings);

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _SchedulePalette.darkBlue,
          backgroundColor: _SchedulePalette.cardLight,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
            children: [
              _ScheduleHeader(
                totalMonth: bookings.length,
                totalToday: _todayTotal(bookings),
                needUploadTotal: _needUploadTotal(bookings),
              ),

              const SizedBox(height: 14),

              _CalendarCard(
                selectedMonth: _selectedMonth,
                selectedDate: _selectedDate,
                groupedBookings: groupedBookings,
                monthLabel: _monthLabel(_selectedMonth),
                onPreviousMonth: () => _changeMonth(-1),
                onNextMonth: () => _changeMonth(1),
                onSelectDate: _selectDate,
              ),

              const SizedBox(height: 15),

              _SelectedDateHeader(
                dateLabel: _dayLabel(_selectedDate),
                totalSchedule: selectedDateBookings.length,
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && bookings.isEmpty)
                const _LoadingState()
              else if (selectedDateBookings.isEmpty)
                const _EmptyScheduleState(
                  message: 'Belum ada jadwal pemotretan pada tanggal ini.',
                )
              else
                ...selectedDateBookings.map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleBookingCard(
                      booking: booking,
                      timeRange: _timeRange(booking),
                      onTap: () => _openDetail(booking),
                    ),
                  );
                }),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 4),
                _ErrorMessageBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulePalette {
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

class _ScheduleHeader extends StatelessWidget {
  final int totalMonth;
  final int totalToday;
  final int needUploadTotal;

  const _ScheduleHeader({
    required this.totalMonth,
    required this.totalToday,
    required this.needUploadTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: _SchedulePalette.darkGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _SchedulePalette.darkBlue.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -42,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -46,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Pemotretan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Lihat jadwal foto yang sudah di-assign untukmu.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _HeaderPill(
                          icon: Icons.event_available_rounded,
                          label: '$totalToday hari ini',
                        ),
                        const SizedBox(width: 7),
                        _HeaderPill(
                          icon: Icons.cloud_upload_rounded,
                          label: '$needUploadTotal upload',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalMonth',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime selectedDate;
  final Map<String, List<PhotographerBookingModel>> groupedBookings;
  final String monthLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const _CalendarCard({
    required this.selectedMonth,
    required this.selectedDate,
    required this.groupedBookings,
    required this.monthLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime?> _calendarCells() {
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final leadingEmpty = firstDay.weekday - 1;
    final totalDays = lastDay.day;

    final cells = <DateTime?>[];

    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }

    for (int day = 1; day <= totalDays; day++) {
      cells.add(DateTime(selectedMonth.year, selectedMonth.month, day));
    }

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final cells = _calendarCells();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _SchedulePalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _SchedulePalette.darkBlue.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: _SchedulePalette.softGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.78)),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: _SchedulePalette.darkBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    color: _SchedulePalette.darkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MonthButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousMonth,
              ),
              const SizedBox(width: 6),
              _MonthButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextMonth,
              ),
            ],
          ),

          const SizedBox(height: 13),

          const Row(
            children: [
              _WeekLabel('Sen'),
              _WeekLabel('Sel'),
              _WeekLabel('Rab'),
              _WeekLabel('Kam'),
              _WeekLabel('Jum'),
              _WeekLabel('Sab'),
              _WeekLabel('Min'),
            ],
          ),

          const SizedBox(height: 6),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];

              if (date == null) {
                return const SizedBox.shrink();
              }

              final key = _formatDate(date);
              final totalBookings = groupedBookings[key]?.length ?? 0;
              final hasBooking = totalBookings > 0;
              final isSelected = _sameDate(date, selectedDate);
              final isToday = _sameDate(date, today);

              return _CalendarDayCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                hasBooking: hasBooking,
                totalBookings: totalBookings,
                onTap: () => onSelectDate(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _SchedulePalette.cardLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _SchedulePalette.cardDeep),
          ),
          child: Icon(icon, color: _SchedulePalette.darkBlue, size: 20),
        ),
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String label;

  const _WeekLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: _SchedulePalette.darkBlue.withOpacity(0.48),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasBooking;
  final int totalBookings;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasBooking,
    required this.totalBookings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : hasBooking
        ? _SchedulePalette.darkBlue
        : isToday
        ? _SchedulePalette.darkBlue
        : AppColors.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: isSelected ? _SchedulePalette.darkGradient : null,
            color: isSelected
                ? null
                : hasBooking
                ? _SchedulePalette.cardLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected
                  ? _SchedulePalette.darkBlue
                  : isToday
                  ? _SchedulePalette.cardDeep
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              if (hasBooking)
                Container(
                  height: 5,
                  constraints: const BoxConstraints(minWidth: 5),
                  padding: totalBookings > 1
                      ? const EdgeInsets.symmetric(horizontal: 5)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : _SchedulePalette.lightBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: totalBookings > 1
                      ? Text(
                          totalBookings.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? _SchedulePalette.darkBlue
                                : Colors.white,
                            fontSize: 7,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                )
              else
                const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDateHeader extends StatelessWidget {
  final String dateLabel;
  final int totalSchedule;

  const _SelectedDateHeader({
    required this.dateLabel,
    required this.totalSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        gradient: _SchedulePalette.softGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.62),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: _SchedulePalette.darkBlue,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: _SchedulePalette.darkBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalSchedule jadwal pemotretan',
                  style: TextStyle(
                    color: _SchedulePalette.darkBlue.withOpacity(0.58),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _ScheduleBookingCard extends StatelessWidget {
  final PhotographerBookingModel booking;
  final String timeRange;
  final VoidCallback onTap;

  const _ScheduleBookingCard({
    required this.booking,
    required this.timeRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhotoLink = booking.hasPhotoLink;
    final uploadColor = hasPhotoLink ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _SchedulePalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _SchedulePalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: _SchedulePalette.darkGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _SchedulePalette.darkBlue.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName.trim().isEmpty
                            ? 'Klien'
                            : booking.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _SchedulePalette.darkBlue,
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        booking.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _SchedulePalette.darkBlue.withOpacity(0.58),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _MiniInfoLine(
                        icon: Icons.schedule_rounded,
                        text: timeRange,
                        color: _SchedulePalette.midBlue,
                      ),
                      const SizedBox(height: 5),
                      _MiniInfoLine(
                        icon: Icons.location_on_rounded,
                        text:
                            '${booking.locationTypeLabel} • ${booking.locationName}',
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _SmallBadge(
                            text: booking.statusLabel,
                            color: _SchedulePalette.darkBlue,
                          ),
                          _SmallBadge(
                            text: hasPhotoLink
                                ? 'Foto Terupload'
                                : 'Perlu Upload',
                            color: uploadColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _SchedulePalette.darkBlue.withOpacity(0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniInfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.trim().isEmpty ? '-' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        text.trim().isEmpty ? '-' : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 90),
      child: Center(
        child: CircularProgressIndicator(color: _SchedulePalette.darkBlue),
      ),
    );
  }
}

class _EmptyScheduleState extends StatelessWidget {
  final String message;

  const _EmptyScheduleState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        gradient: _SchedulePalette.softGradient,
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
              Icons.event_busy_rounded,
              size: 34,
              color: _SchedulePalette.darkBlue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Jadwal kosong',
            style: TextStyle(
              color: _SchedulePalette.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _SchedulePalette.darkBlue.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
