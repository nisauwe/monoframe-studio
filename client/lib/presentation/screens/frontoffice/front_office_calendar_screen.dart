import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/front_office_provider.dart';
import 'front_office_manual_booking_screen.dart';

class FrontOfficeCalendarScreen extends StatefulWidget {
  const FrontOfficeCalendarScreen({super.key});

  @override
  State<FrontOfficeCalendarScreen> createState() =>
      _FrontOfficeCalendarScreenState();
}

class _FrontOfficeCalendarScreenState extends State<FrontOfficeCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _selectedPhotographer = 'Semua';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCalendar();
    });
  }

  DateTime _visibleCalendarStart(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    return firstDay.subtract(Duration(days: firstDay.weekday - 1));
  }

  DateTime _visibleCalendarEnd(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return lastDay.add(Duration(days: 7 - lastDay.weekday));
  }

  Future<void> _fetchCalendar() {
    final start = _visibleCalendarStart(_selectedMonth);
    final end = _visibleCalendarEnd(_selectedMonth);

    return context.read<FrontOfficeProvider>().fetchCalendar(
      startDate: _formatDate(start),
      endDate: _formatDate(end),
    );
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
      _selectedPhotographer = 'Semua';
    });

    _fetchCalendar();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
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

  DateTime? _eventDate(dynamic event) {
    final rawStart = event.start?.toString().trim() ?? '';

    if (rawStart.isEmpty) return null;

    final normalized = rawStart.contains('T')
        ? rawStart
        : rawStart.replaceFirst(' ', 'T');

    final parsed = DateTime.tryParse(normalized);

    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    if (rawStart.length >= 10) {
      final datePart = rawStart.substring(0, 10);
      final fallback = DateTime.tryParse(datePart);

      if (fallback != null) {
        return DateTime(fallback.year, fallback.month, fallback.day);
      }
    }

    return null;
  }

  String _eventTimeRange(dynamic event) {
    final start = _timeOnly(event.start?.toString() ?? '');
    final end = _timeOnly(event.end?.toString() ?? '');

    if (start == '-' && end == '-') return '-';
    if (end == '-') return start;

    return '$start - $end';
  }

  String _timeOnly(String raw) {
    final value = raw.trim();

    if (value.isEmpty) return '-';

    final normalized = value.contains('T')
        ? value
        : value.replaceFirst(' ', 'T');

    final parsed = DateTime.tryParse(normalized);

    if (parsed != null) {
      return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    }

    final timePattern = RegExp(r'(\d{2}):(\d{2})');
    final match = timePattern.firstMatch(value);

    if (match != null) {
      return '${match.group(1)}:${match.group(2)}';
    }

    return value;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, List<dynamic>> _eventsByDate(List<dynamic> events) {
    final grouped = <String, List<dynamic>>{};

    for (final event in events) {
      final date = _eventDate(event);

      if (date == null) continue;

      final key = _formatDate(date);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(event);
    }

    return grouped;
  }

  List<String> _photographers(List<dynamic> events) {
    final names = <String>{};

    for (final event in events) {
      final name = event.photographerName?.toString().trim() ?? '';

      if (name.isNotEmpty && name != '-') {
        names.add(name);
      }
    }

    final sorted = names.toList()..sort();

    return ['Semua', ...sorted];
  }

  List<dynamic> _eventsForSelectedDate(List<dynamic> events) {
    final selectedKey = _formatDate(_selectedDate);

    final filtered = events.where((event) {
      final date = _eventDate(event);

      if (date == null) return false;

      final sameDate = _formatDate(date) == selectedKey;
      final photographerName = event.photographerName?.toString().trim() ?? '-';

      final samePhotographer =
          _selectedPhotographer == 'Semua' ||
          photographerName == _selectedPhotographer;

      return sameDate && samePhotographer;
    }).toList();

    filtered.sort((a, b) {
      final aTime = _timeOnly(a.start?.toString() ?? '');
      final bTime = _timeOnly(b.start?.toString() ?? '');

      return aTime.compareTo(bTime);
    });

    return filtered;
  }

  int _todayTotal(List<dynamic> events) {
    final today = DateTime.now();

    return events.where((event) {
      final date = _eventDate(event);
      if (date == null) return false;

      return _sameDate(date, today);
    }).length;
  }

  Future<void> _openManualBooking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FrontOfficeManualBookingScreen()),
    );

    if (!mounted) return;
    _fetchCalendar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    final events = provider.calendarEvents;
    final groupedEvents = _eventsByDate(events);
    final selectedDateEvents = _eventsForSelectedDate(events);
    final photographers = _photographers(events);
    final todayTotal = _todayTotal(events);

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _CalendarPalette.darkBlue,
          backgroundColor: _CalendarPalette.cardLight,
          onRefresh: _fetchCalendar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
            children: [
              _CalendarHeader(
                totalMonth: events.length,
                totalToday: todayTotal,
                onAddBooking: _openManualBooking,
              ),

              const SizedBox(height: 14),

              _CalendarCard(
                selectedMonth: _selectedMonth,
                selectedDate: _selectedDate,
                groupedEvents: groupedEvents,
                monthLabel: _monthLabel(_selectedMonth),
                onPreviousMonth: () => _changeMonth(-1),
                onNextMonth: () => _changeMonth(1),
                onSelectDate: _selectDate,
              ),

              const SizedBox(height: 15),

              const _SectionTitle(
                title: 'Jadwal Per Fotografer',
                subtitle: 'Filter jadwal berdasarkan fotografer yang bertugas',
              ),

              const SizedBox(height: 9),

              _PhotographerFilter(
                photographers: photographers,
                selectedPhotographer: _selectedPhotographer,
                onSelected: (value) {
                  setState(() {
                    _selectedPhotographer = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              _SelectedDateHeader(
                dateLabel: _dayLabel(_selectedDate),
                totalSchedule: selectedDateEvents.length,
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && events.isEmpty)
                const _LoadingState()
              else if (selectedDateEvents.isEmpty)
                _EmptyScheduleState(
                  message: _selectedPhotographer == 'Semua'
                      ? 'Belum ada jadwal pada tanggal ini.'
                      : 'Belum ada jadwal $_selectedPhotographer pada tanggal ini.',
                )
              else
                ...selectedDateEvents.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(
                      title: event.title?.toString() ?? 'Booking Foto',
                      time: _eventTimeRange(event),
                      photographerName:
                          event.photographerName?.toString() ?? '-',
                      locationName: event.locationName?.toString() ?? '-',
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

class _CalendarPalette {
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

class _CalendarHeader extends StatelessWidget {
  final int totalMonth;
  final int totalToday;
  final VoidCallback onAddBooking;

  const _CalendarHeader({
    required this.totalMonth,
    required this.totalToday,
    required this.onAddBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: _CalendarPalette.darkGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _CalendarPalette.darkBlue.withOpacity(0.14),
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
                      'Kalender Booking',
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
                      'Pantau jadwal booking dan fotografer.',
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
                          label: '$totalMonth bulan ini',
                        ),
                        const SizedBox(width: 7),
                        _HeaderPill(
                          icon: Icons.today_rounded,
                          label: '$totalToday hari ini',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AddBookingButton(onTap: onAddBooking),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBookingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBookingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.17),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              SizedBox(height: 2),
              Text(
                'Tambah',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
  final Map<String, List<dynamic>> groupedEvents;
  final String monthLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const _CalendarCard({
    required this.selectedMonth,
    required this.selectedDate,
    required this.groupedEvents,
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
        border: Border.all(color: _CalendarPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _CalendarPalette.darkBlue.withOpacity(0.05),
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
                  gradient: _CalendarPalette.softGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.78)),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: _CalendarPalette.darkBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    color: _CalendarPalette.darkBlue,
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
              final totalEvents = groupedEvents[key]?.length ?? 0;
              final hasEvent = totalEvents > 0;
              final isSelected = _sameDate(date, selectedDate);
              final isToday = _sameDate(date, today);

              return _CalendarDayCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                hasEvent: hasEvent,
                totalEvents: totalEvents,
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
      color: _CalendarPalette.cardLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _CalendarPalette.cardDeep),
          ),
          child: Icon(icon, color: _CalendarPalette.darkBlue, size: 20),
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
            color: _CalendarPalette.darkBlue.withOpacity(0.48),
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
  final bool hasEvent;
  final int totalEvents;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasEvent,
    required this.totalEvents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : hasEvent
        ? _CalendarPalette.darkBlue
        : isToday
        ? _CalendarPalette.darkBlue
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
            gradient: isSelected ? _CalendarPalette.darkGradient : null,
            color: isSelected
                ? null
                : hasEvent
                ? _CalendarPalette.cardLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected
                  ? _CalendarPalette.darkBlue
                  : isToday
                  ? _CalendarPalette.cardDeep
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
              if (hasEvent)
                Container(
                  height: 5,
                  constraints: const BoxConstraints(minWidth: 5),
                  padding: totalEvents > 1
                      ? const EdgeInsets.symmetric(horizontal: 5)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : _CalendarPalette.lightBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: totalEvents > 1
                      ? Text(
                          totalEvents.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? _CalendarPalette.darkBlue
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 5,
          decoration: BoxDecoration(
            gradient: _CalendarPalette.darkGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  height: 1.25,
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

class _PhotographerFilter extends StatelessWidget {
  final List<String> photographers;
  final String selectedPhotographer;
  final ValueChanged<String> onSelected;

  const _PhotographerFilter({
    required this.photographers,
    required this.selectedPhotographer,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photographers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = photographers[index];
          final selected = selectedPhotographer == name;

          return ChoiceChip(
            label: Text(name),
            selected: selected,
            showCheckmark: false,
            selectedColor: _CalendarPalette.darkBlue,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? _CalendarPalette.darkBlue
                  : _CalendarPalette.cardDeep,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _CalendarPalette.darkBlue,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onSelected: (_) => onSelected(name),
          );
        },
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
        gradient: _CalendarPalette.softGradient,
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
              color: _CalendarPalette.darkBlue,
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
                    color: _CalendarPalette.darkBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalSchedule jadwal pada tanggal ini',
                  style: TextStyle(
                    color: _CalendarPalette.darkBlue.withOpacity(0.58),
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

class _ScheduleCard extends StatelessWidget {
  final String title;
  final String time;
  final String photographerName;
  final String locationName;

  const _ScheduleCard({
    required this.title,
    required this.time,
    required this.photographerName,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CalendarPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _CalendarPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              gradient: _CalendarPalette.darkGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _CalendarPalette.darkBlue.withOpacity(0.12),
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
                  title.trim().isEmpty ? 'Booking Foto' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CalendarPalette.darkBlue,
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                _MiniInfoLine(
                  icon: Icons.schedule_rounded,
                  text: time,
                  color: _CalendarPalette.midBlue,
                ),
                const SizedBox(height: 5),
                _MiniInfoLine(
                  icon: Icons.person_rounded,
                  text: 'Fotografer: $photographerName',
                  color: AppColors.success,
                ),
                const SizedBox(height: 5),
                _MiniInfoLine(
                  icon: Icons.location_on_rounded,
                  text: 'Lokasi: $locationName',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 90),
      child: Center(
        child: CircularProgressIndicator(color: _CalendarPalette.darkBlue),
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
        gradient: _CalendarPalette.softGradient,
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
              color: _CalendarPalette.darkBlue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Jadwal kosong',
            style: TextStyle(
              color: _CalendarPalette.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _CalendarPalette.darkBlue.withOpacity(0.62),
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
