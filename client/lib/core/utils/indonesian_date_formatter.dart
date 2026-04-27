class IndonesianDateFormatter {
  static String dateTime(String value) {
    if (value.trim().isEmpty) return '-';

    try {
      final parsed = DateTime.parse(value).toLocal();
      return '${_two(parsed.day)} ${_month(parsed.month)} ${parsed.year}, ${_two(parsed.hour)}:${_two(parsed.minute)} WIB';
    } catch (_) {
      return value;
    }
  }

  static String dateOnly(String value) {
    if (value.trim().isEmpty) return '-';

    try {
      final parsed = DateTime.parse(value).toLocal();
      return '${_two(parsed.day)} ${_month(parsed.month)} ${parsed.year}';
    } catch (_) {
      try {
        final parsed = DateTime.parse('${value}T00:00:00');
        return '${_two(parsed.day)} ${_month(parsed.month)} ${parsed.year}';
      } catch (_) {
        return value;
      }
    }
  }

  static String timeOnly(String value) {
    if (value.trim().isEmpty) return '-';

    try {
      if (value.contains('T')) {
        final parsed = DateTime.parse(value).toLocal();
        return '${_two(parsed.hour)}:${_two(parsed.minute)} WIB';
      }

      final parts = value.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }

      return value;
    } catch (_) {
      return value;
    }
  }

  static String dateTimeFromDateAndTime(String date, String time) {
    final d = dateOnly(date);
    final t = timeOnly(time);

    if (d == '-' && t == '-') return '-';
    if (d == '-') return t;
    if (t == '-') return d;

    return '$d, $t';
  }

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }

  static String _month(int value) {
    const months = [
      '',
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

    if (value < 1 || value > 12) return '';
    return months[value];
  }
}
