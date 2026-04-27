@extends('layouts/contentNavbarLayout')

@section('title', 'Kalender')

@section('content')
  @php
    use Carbon\Carbon;

    $timelineHeight = ($dayEndHour - $dayStartHour) * $hourRowHeight;
    $weekViewDate = $anchorDate->copy();

    $prepareTimelineEvents = function ($events) use ($dayStartHour, $hourRowHeight) {
        $sorted = collect($events)
            ->sortBy(function ($booking) {
                return sprintf('%s-%s', $booking->start_time, $booking->end_time);
            })
            ->values();

        $prepared = [];

        foreach ($sorted as $booking) {
            $start = Carbon::parse($booking->start_time);
            $end = Carbon::parse($booking->end_time);

            $startMin = $start->hour * 60 + $start->minute;
            $endMin = $end->hour * 60 + $end->minute;

            if ($endMin <= $startMin) {
                $endMin = $startMin + 30;
            }

            $lane = 0;

            while (true) {
                $blocked = false;

                foreach ($prepared as $prev) {
                    if ($prev['lane'] === $lane && $prev['start_min'] < $endMin && $prev['end_min'] > $startMin) {
                        $blocked = true;
                        break;
                    }
                }

                if (!$blocked) {
                    break;
                }

                $lane++;
            }

            $prepared[] = [
                'booking' => $booking,
                'start_min' => $startMin,
                'end_min' => $endMin,
                'lane' => $lane,
            ];
        }

        foreach ($prepared as $i => $item) {
            $maxConcurrent = 1;

            for ($minute = $item['start_min']; $minute < $item['end_min']; $minute += 5) {
                $concurrent = 0;

                foreach ($prepared as $other) {
                    if ($other['start_min'] < $minute + 5 && $other['end_min'] > $minute) {
                        $concurrent++;
                    }
                }

                $maxConcurrent = max($maxConcurrent, $concurrent);
            }

            $prepared[$i]['columns'] = max($maxConcurrent, $item['lane'] + 1);

            $minutesFromStart = $item['start_min'] - $dayStartHour * 60;
            $durationMinutes = max(30, $item['end_min'] - $item['start_min']);

            $prepared[$i]['top'] = max(0, ($minutesFromStart / 60) * $hourRowHeight);
            $prepared[$i]['height'] = max(52, ($durationMinutes / 60) * $hourRowHeight - 6);
            $prepared[$i]['width'] = 100 / $prepared[$i]['columns'];
            $prepared[$i]['left'] = $item['lane'] * $prepared[$i]['width'];
        }

        return collect($prepared)->values();
    };
  @endphp

  <style>
    .calendar-shell {
      display: grid;
      grid-template-columns: 1fr 380px;
      gap: 1.5rem;
      align-items: start;
    }

    .calendar-main-card,
    .calendar-side-card {
      background: #fff;
      border: 1px solid #eceef1;
      border-radius: 22px;
      overflow: hidden;
    }

    .calendar-toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
      padding: 20px 24px;
      border-bottom: 1px solid #eceef1;
    }

    .calendar-toolbar-left,
    .calendar-toolbar-right {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .calendar-title {
      font-size: 30px;
      font-weight: 700;
      color: #384551;
      margin: 0 8px;
    }

    .view-switch .btn.active {
      background: #696cff;
      border-color: #696cff;
      color: #fff;
    }

    .month-grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      border-top: 1px solid #eceef1;
      border-left: 1px solid #eceef1;
    }

    .month-day-name {
      padding: 14px 12px;
      text-align: center;
      font-weight: 700;
      color: #566a7f;
      background: #fff;
      border-right: 1px solid #eceef1;
      border-bottom: 1px solid #eceef1;
    }

    .month-cell {
      min-height: 150px;
      border-right: 1px solid #eceef1;
      border-bottom: 1px solid #eceef1;
      padding: 10px;
      background: #fff;
      text-decoration: none;
      color: inherit;
      transition: .2s ease;
    }

    .month-cell:hover {
      background: #f8f9fb;
    }

    .month-cell.other-month {
      background: #fafbfc;
      color: #b0b7c3;
    }

    .month-cell.selected {
      box-shadow: inset 0 0 0 2px #696cff;
      background: rgba(105, 108, 255, 0.05);
    }

    .month-date {
      font-size: 15px;
      font-weight: 700;
      color: #566a7f;
      margin-bottom: 8px;
    }

    .month-event {
      display: block;
      font-size: 12px;
      padding: 6px 8px;
      border-radius: 8px;
      margin-bottom: 6px;
      text-decoration: none;
      font-weight: 600;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .event-indoor {
      background: #fff3c4;
      color: #8a6500;
      border: 1px solid #f2d46d;
    }

    .event-outdoor {
      background: #d9efff;
      color: #0f5c99;
      border: 1px solid #7ec7ff;
    }

    .month-event.event-indoor {
      background: #fff3c4;
      color: #8a6500;
    }

    .month-event.event-outdoor {
      background: #d9efff;
      color: #0f5c99;
    }

    .month-more {
      font-size: 12px;
      color: #8592a3;
      font-weight: 600;
      margin-top: 4px;
    }

    .timeline-shell {
      display: grid;
      grid-template-columns: 72px 1fr;
      min-height: 300px;
    }

    .time-labels {
      position: relative;
      border-right: 1px solid #eceef1;
      background: #fff;
    }

    .time-label {
      position: absolute;
      left: 0;
      width: 100%;
      transform: translateY(-50%);
      text-align: center;
      font-size: 12px;
      font-weight: 700;
      color: #8592a3;
    }

    .week-grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
    }

    .week-column {
      border-right: 1px solid #eceef1;
      background: #fff;
    }

    .week-column:last-child {
      border-right: 0;
    }

    .week-header {
      padding: 14px 10px;
      border-bottom: 1px solid #eceef1;
      text-align: center;
      background: #fff;
      position: sticky;
      top: 0;
      z-index: 2;
    }

    .week-header.selected {
      background: rgba(105, 108, 255, 0.06);
    }

    .week-day-name {
      font-size: 12px;
      font-weight: 700;
      color: #8592a3;
      text-transform: uppercase;
      margin-bottom: 6px;
    }

    .week-day-number {
      font-size: 24px;
      font-weight: 700;
      color: #384551;
      line-height: 1;
    }

    .week-track {
      position: relative;
      height: var(--timeline-height);
      background:
        linear-gradient(to bottom, transparent 71px, #eceef1 72px);
      background-size: 100% 72px;
    }

    .day-grid {
      display: grid;
      grid-template-columns: 72px 1fr;
    }

    .day-column {
      background: #fff;
    }

    .day-header {
      padding: 16px 18px;
      border-bottom: 1px solid #eceef1;
      background: rgba(105, 108, 255, 0.04);
    }

    .day-header small {
      display: block;
      font-weight: 700;
      color: #8592a3;
      margin-bottom: 6px;
    }

    .day-header h4 {
      margin: 0;
      font-weight: 700;
      color: #384551;
    }

    .day-track {
      position: relative;
      height: var(--timeline-height);
      background:
        linear-gradient(to bottom, transparent 71px, #eceef1 72px);
      background-size: 100% 72px;
    }

    .timeline-event {
      position: absolute;
      border-radius: 14px;
      padding: 10px 12px;
      text-decoration: none;
      box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08);
      overflow: hidden;
      box-sizing: border-box;
      transition: .18s ease;
    }

    .timeline-event:hover {
      transform: translateY(-1px);
      box-shadow: 0 12px 24px rgba(0, 0, 0, 0.12);
    }

    .timeline-event .title {
      font-size: 13px;
      font-weight: 700;
      line-height: 1.35;
      margin-bottom: 4px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .timeline-event .meta {
      font-size: 12px;
      line-height: 1.5;
      opacity: 0.95;
      overflow: hidden;
    }

    .timeline-event.selected {
      box-shadow: inset 0 0 0 2px #384551, 0 12px 22px rgba(0, 0, 0, 0.12);
      z-index: 3;
    }

    .calendar-side-card {
      position: sticky;
      top: 90px;
    }

    .detail-head {
      padding: 22px 22px 14px;
      border-bottom: 1px solid #eceef1;
    }

    .detail-head h5 {
      margin-bottom: 4px;
      font-weight: 700;
    }

    .detail-body {
      padding: 20px 22px 22px;
    }

    .detail-block {
      border: 1px solid #eceef1;
      border-radius: 16px;
      padding: 14px;
      margin-bottom: 14px;
    }

    .detail-label {
      font-size: 12px;
      color: #8592a3;
      display: block;
      margin-bottom: 4px;
      text-transform: uppercase;
      letter-spacing: .03em;
    }

    .detail-value {
      font-size: 15px;
      font-weight: 700;
      color: #384551;
      line-height: 1.5;
    }

    .detail-sub {
      font-size: 13px;
      color: #8592a3;
      line-height: 1.6;
    }

    .side-booking-link {
      display: block;
      border: 1px solid #eceef1;
      border-radius: 14px;
      padding: 12px;
      margin-bottom: 10px;
      text-decoration: none;
      color: inherit;
      transition: .2s ease;
    }

    .side-booking-link:hover {
      background: #f8f9fb;
    }

    .side-booking-link.active {
      border-color: #696cff;
      background: rgba(105, 108, 255, 0.05);
    }

    .modal .form-text {
      font-size: 12px;
    }

    @media (max-width: 1200px) {
      .calendar-shell {
        grid-template-columns: 1fr;
      }

      .calendar-side-card {
        position: static;
      }
    }

    @media (max-width: 768px) {
      .week-grid {
        grid-template-columns: 1fr;
      }

      .timeline-shell,
      .day-grid {
        grid-template-columns: 50px 1fr;
      }

      .calendar-title {
        font-size: 24px;
      }

      .month-grid {
        grid-template-columns: repeat(2, 1fr);
      }

      .month-day-name {
        display: none;
      }
    }
  </style>

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Kalender</h4>
        <p class="text-muted mb-0">Pantau jadwal studio per bulan, minggu, dan hari langsung dari database booking.</p>
      </div>

      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addCalendarEventModal">
        <i class="bx bx-plus me-1"></i> Tambah Jadwal
      </button>
    </div>

    <div class="row mb-4">
      <div class="col-md-4 mb-3 mb-md-0">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Jadwal Bulan Ini</span>
            <h3 class="mb-1">{{ $totalSchedules }}</h3>
            <small class="text-primary fw-semibold">Total sesi di {{ $anchorDate->translatedFormat('F Y') }}</small>
          </div>
        </div>
      </div>

      <div class="col-md-4 mb-3 mb-md-0">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Hari Terisi</span>
            <h3 class="mb-1">{{ $totalBookedDays }}</h3>
            <small class="text-danger fw-semibold">Tanggal dengan jadwal pemotretan</small>
          </div>
        </div>
      </div>

      <div class="col-md-4">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Bulan Aktif</span>
            <h3 class="mb-1">{{ $anchorDate->translatedFormat('F') }}</h3>
            <small class="text-success fw-semibold">Bisa cek bulan sebelumnya dan sesudahnya</small>
          </div>
        </div>
      </div>
    </div>

    <div class="calendar-shell">
      <div class="calendar-main-card">
        <div class="calendar-toolbar">
          <div class="calendar-toolbar-left">
            <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => now()->toDateString(), 'selected_date' => now()->toDateString()]) }}"
              class="btn btn-outline-secondary">
              Hari ini
            </a>

            <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $prevDate->toDateString(), 'selected_date' => $prevDate->toDateString()]) }}"
              class="btn btn-outline-secondary btn-sm">
              <i class="bx bx-chevron-left"></i>
            </a>

            <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $nextDate->toDateString(), 'selected_date' => $nextDate->toDateString()]) }}"
              class="btn btn-outline-secondary btn-sm">
              <i class="bx bx-chevron-right"></i>
            </a>

            <h3 class="calendar-title">{{ $title }}</h3>
          </div>

          <div class="calendar-toolbar-right">
            <div class="btn-group view-switch">
              <a href="{{ route('admin.calendar.index', ['view' => 'month', 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate]) }}"
                class="btn btn-outline-secondary {{ $viewMode === 'month' ? 'active' : '' }}">
                Bulan
              </a>
              <a href="{{ route('admin.calendar.index', ['view' => 'week', 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate]) }}"
                class="btn btn-outline-secondary {{ $viewMode === 'week' ? 'active' : '' }}">
                Minggu
              </a>
              <a href="{{ route('admin.calendar.index', ['view' => 'day', 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate]) }}"
                class="btn btn-outline-secondary {{ $viewMode === 'day' ? 'active' : '' }}">
                Hari
              </a>
            </div>
          </div>
        </div>

        @if ($viewMode === 'month')
          <div class="month-grid">
            <div class="month-day-name">Min</div>
            <div class="month-day-name">Sen</div>
            <div class="month-day-name">Sel</div>
            <div class="month-day-name">Rab</div>
            <div class="month-day-name">Kam</div>
            <div class="month-day-name">Jum</div>
            <div class="month-day-name">Sab</div>

            @foreach ($monthDays as $day)
              @php
                $dateKey = $day->toDateString();
                $events = $bookingsByDate->get($dateKey, collect());
                $isCurrentMonth = $day->month === $anchorDate->month;
                $isSelected = $selectedDate === $dateKey;
              @endphp

              <div class="month-cell {{ !$isCurrentMonth ? 'other-month' : '' }} {{ $isSelected ? 'selected' : '' }}">
                <a href="{{ route('admin.calendar.index', ['view' => 'month', 'date' => $anchorDate->toDateString(), 'selected_date' => $dateKey]) }}"
                  class="text-decoration-none text-reset">
                  <div class="month-date">{{ $day->day }}</div>
                </a>

                @foreach ($events->take(3) as $booking)
                  @php
                    $eventClass =
                        ($booking->location_type ?? 'indoor') === 'outdoor' ? 'event-outdoor' : 'event-indoor';
                  @endphp

                  <a href="{{ route('admin.calendar.index', ['view' => 'month', 'date' => $anchorDate->toDateString(), 'selected_date' => $dateKey, 'selected_booking_id' => $booking->id]) }}"
                    class="month-event {{ $eventClass }}">
                    {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                    {{ $booking->package->name ?? 'Paket' }}
                  </a>
                @endforeach

                @if ($events->count() > 3)
                  <div class="month-more">+ {{ $events->count() - 3 }} lainnya</div>
                @endif
              </div>
            @endforeach
          </div>
        @elseif ($viewMode === 'week')
          <div class="timeline-shell" style="--timeline-height: {{ $timelineHeight }}px;">
            <div class="time-labels" style="height: {{ $timelineHeight }}px;">
              @for ($hour = $dayStartHour; $hour <= $dayEndHour; $hour++)
                <div class="time-label" style="top: {{ ($hour - $dayStartHour) * $hourRowHeight }}px;">
                  {{ sprintf('%02d:00', $hour) }}
                </div>
              @endfor
            </div>

            <div class="week-grid">
              @foreach ($weekDays as $day)
                @php
                  $dateKey = $day->toDateString();
                  $events = collect($bookingsByDate->get($dateKey, collect()))->sortBy('start_time')->values();
                  $preparedEvents = $prepareTimelineEvents($events);
                  $isSelected = $selectedDate === $dateKey;
                @endphp

                <div class="week-column">
                  <div class="week-header {{ $isSelected ? 'selected' : '' }}">
                    <a href="{{ route('admin.calendar.index', ['view' => 'week', 'date' => $anchorDate->toDateString(), 'selected_date' => $dateKey]) }}"
                      class="text-decoration-none text-reset">
                      <div class="week-day-name">{{ $day->translatedFormat('D') }}</div>
                      <div class="week-day-number">{{ $day->day }}</div>
                    </a>
                  </div>

                  <div class="week-track" style="--timeline-height: {{ $timelineHeight }}px;">
                    @foreach ($preparedEvents as $entry)
                      @php
                        $booking = $entry['booking'];
                        $eventClass =
                            ($booking->location_type ?? 'indoor') === 'outdoor' ? 'event-outdoor' : 'event-indoor';
                      @endphp

                      <a href="{{ route('admin.calendar.index', ['view' => 'week', 'date' => $anchorDate->toDateString(), 'selected_date' => $dateKey, 'selected_booking_id' => $booking->id]) }}"
                        class="timeline-event {{ $eventClass }} {{ $selectedBooking && $selectedBooking->id === $booking->id ? 'selected' : '' }}"
                        style="
                          top: {{ $entry['top'] }}px;
                          height: {{ $entry['height'] }}px;
                          left: calc({{ $entry['left'] }}% + 6px);
                          width: calc({{ $entry['width'] }}% - 10px);
                          z-index: {{ 2 + $entry['lane'] }};
                        ">
                        <div class="title">{{ $booking->package->name ?? 'Paket' }}</div>
                        <div class="meta">
                          {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                          -
                          {{ \Carbon\Carbon::parse($booking->end_time)->format('H:i') }}<br>
                          {{ $booking->client_name }}
                        </div>
                      </a>
                    @endforeach
                  </div>
                </div>
              @endforeach
            </div>
          </div>
        @else
          <div class="day-grid" style="--timeline-height: {{ $timelineHeight }}px;">
            <div class="time-labels" style="height: {{ $timelineHeight }}px;">
              @for ($hour = $dayStartHour; $hour <= $dayEndHour; $hour++)
                <div class="time-label" style="top: {{ ($hour - $dayStartHour) * $hourRowHeight }}px;">
                  {{ sprintf('%02d:00', $hour) }}
                </div>
              @endfor
            </div>

            <div class="day-column">
              <div class="day-header">
                <small>{{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('l') }}</small>
                <h4>{{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('d F Y') }}</h4>
              </div>

              @php
                $dayEvents = collect($bookingsByDate->get($selectedDate, collect()))->sortBy('start_time')->values();
                $preparedDayEvents = $prepareTimelineEvents($dayEvents);
              @endphp

              <div class="day-track" style="--timeline-height: {{ $timelineHeight }}px;">
                @foreach ($preparedDayEvents as $entry)
                  @php
                    $booking = $entry['booking'];
                    $eventClass =
                        ($booking->location_type ?? 'indoor') === 'outdoor' ? 'event-outdoor' : 'event-indoor';
                  @endphp

                  <a href="{{ route('admin.calendar.index', ['view' => 'day', 'date' => $selectedDate, 'selected_date' => $selectedDate, 'selected_booking_id' => $booking->id]) }}"
                    class="timeline-event {{ $eventClass }} {{ $selectedBooking && $selectedBooking->id === $booking->id ? 'selected' : '' }}"
                    style="
        top: {{ $entry['top'] }}px;
        height: {{ $entry['height'] }}px;
        left: calc({{ $entry['left'] }}% + 8px);
        width: calc({{ $entry['width'] }}% - 12px);
        z-index: {{ 2 + $entry['lane'] }};
      ">
                    <div class="title">{{ $booking->package->name ?? 'Paket' }}</div>
                    <div class="meta">
                      {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                      -
                      {{ \Carbon\Carbon::parse($booking->end_time)->format('H:i') }}<br>
                      {{ $booking->client_name }} • {{ $booking->photographer_name }}
                    </div>
                  </a>
                @endforeach
              </div>
            </div>
          </div>
        @endif
      </div>

      <div class="calendar-side-card">
        <div class="detail-head">
          <h5 class="mb-1">Detail Jadwal</h5>
          <div class="text-muted">
            {{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('l, d F Y') }}
          </div>
        </div>

        <div class="detail-body">
          @if ($selectedBooking)
            <div class="detail-block">
              <span class="detail-label">Paket Foto</span>
              <div class="detail-value">{{ $selectedBooking->package->name ?? '-' }}</div>
            </div>

            <div class="detail-block">
              <span class="detail-label">Jam Foto</span>
              <div class="detail-value">
                {{ \Carbon\Carbon::parse($selectedBooking->start_time)->format('H:i') }}
                -
                {{ \Carbon\Carbon::parse($selectedBooking->end_time)->format('H:i') }}
              </div>
              <div class="detail-sub">
                Durasi:
                {{ (int) ($selectedBooking->duration_minutes ?? 0) + (int) ($selectedBooking->extra_duration_minutes ?? 0) }}
                menit
              </div>
            </div>

            <div class="detail-block">
              <span class="detail-label">Lokasi</span>
              <div class="detail-value">{{ $selectedBooking->location_name ?: '-' }}</div>
              <div class="detail-sub">{{ ucfirst($selectedBooking->location_type ?? '-') }}</div>
            </div>

            <div class="detail-block">
              <span class="detail-label">Klien</span>
              <div class="detail-value">{{ $selectedBooking->client_name ?: '-' }}</div>
              <div class="detail-sub">{{ $selectedBooking->client_phone ?: '-' }}</div>
            </div>

            <div class="detail-block">
              <span class="detail-label">Fotografer</span>
              <div class="detail-value">{{ $selectedBooking->photographer_name ?: '-' }}</div>
            </div>

            <div class="detail-block">
              <span class="detail-label">Catatan</span>
              <div class="detail-value">{{ $selectedBooking->notes ?: '-' }}</div>
            </div>
          @else
            <div class="alert alert-secondary mb-3">
              Belum ada jadwal pada tanggal ini.
            </div>
          @endif

          @if ($selectedDateBookings->count() > 0)
            <h6 class="fw-bold mt-4 mb-3">Semua Jadwal di Tanggal Ini</h6>

            @foreach ($selectedDateBookings as $booking)
              <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate, 'selected_booking_id' => $booking->id]) }}"
                class="side-booking-link {{ $selectedBooking && $selectedBooking->id === $booking->id ? 'active' : '' }}">
                <div class="fw-bold mb-1">{{ $booking->package->name ?? '-' }}</div>
                <div class="small text-muted">
                  {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                  -
                  {{ \Carbon\Carbon::parse($booking->end_time)->format('H:i') }}
                </div>
                <div class="small text-muted">
                  {{ $booking->client_name }} • {{ $booking->photographer_name }}
                </div>
              </a>
            @endforeach
          @endif
        </div>
      </div>
    </div>
  </div>

  <div class="modal fade" id="addCalendarEventModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <form method="POST" action="{{ route('admin.calendar.store') }}">
          @csrf

          <div class="modal-header">
            <h5 class="modal-title">Tambah Jadwal Manual</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>

          <div class="modal-body">
            <input type="hidden" name="view" value="{{ $viewMode }}">

            <div class="row">
              <div class="col-md-6 mb-3">
                <label class="form-label">Paket Foto</label>
                <select class="form-select" name="package_id" id="calendarPackageSelect" required>
                  <option value="">Pilih paket</option>
                  @foreach ($packages as $package)
                    <option value="{{ $package->id }}"
                      data-location="{{ strtolower(trim($package->location_type)) }}"
                      data-duration="{{ $package->duration_minutes }}">
                      {{ $package->name }} ({{ $package->duration_minutes }} menit)
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="col-md-6 mb-3">
                <label class="form-label">Klien</label>
                <select class="form-select" name="client_user_id" required>
                  <option value="">Pilih klien</option>
                  @foreach ($clients as $client)
                    <option value="{{ $client->id }}">
                      {{ $client->email }} - {{ $client->name }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="col-md-6 mb-3">
                <label class="form-label">Tanggal Pemotretan</label>
                <input type="date" name="booking_date" class="form-control" value="{{ $selectedDate }}" required>
              </div>

              <div class="col-md-6 mb-3">
                <label class="form-label">Jam Mulai</label>
                <input type="time" name="start_time" class="form-control" required>
              </div>

              <div class="col-md-6 mb-3">
                <label class="form-label">Fotografer</label>
                <select class="form-select" name="photographer_user_id" required>
                  <option value="">Pilih fotografer</option>
                  @foreach ($photographers as $photographer)
                    <option value="{{ $photographer->id }}">
                      {{ $photographer->name }} - {{ $photographer->email }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="col-md-6 mb-3">
                <label class="form-label d-block">Durasi Tambahan</label>
                <div class="form-check mt-2">
                  <input class="form-check-input" type="checkbox" name="add_extra_duration" value="1"
                    id="calendarAddExtra">
                  <label class="form-check-label" for="calendarAddExtra">
                    Tambah durasi ekstra
                  </label>
                </div>
              </div>

              <div class="col-12 mb-3" id="calendarLocationWrap" style="display:none;">
                <label class="form-label">Lokasi Outdoor</label>
                <input type="text" name="location_name" id="calendarLocationName" class="form-control"
                  placeholder="Masukkan lokasi outdoor">
                <div class="form-text">Field ini wajib diisi kalau paket outdoor.</div>
              </div>

              <div class="col-12">
                <label class="form-label">Catatan</label>
                <textarea class="form-control" name="notes" rows="3" placeholder="Tambahkan catatan jika perlu..."></textarea>
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Batal</button>
            <button type="submit" class="btn btn-primary">Simpan Jadwal</button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      const packageSelect = document.getElementById('calendarPackageSelect');
      const locationWrap = document.getElementById('calendarLocationWrap');
      const locationName = document.getElementById('calendarLocationName');

      function toggleLocationField() {
        if (!packageSelect) return;

        const selected = packageSelect.options[packageSelect.selectedIndex];
        const location = (selected?.dataset?.location || '').toLowerCase().trim();

        if (location.includes('outdoor')) {
          locationWrap.style.display = 'block';
        } else {
          locationWrap.style.display = 'none';
          if (locationName) locationName.value = '';
        }
      }

      if (packageSelect) {
        packageSelect.addEventListener('change', toggleLocationField);
        toggleLocationField();
      }
    });
  </script>
@endsection
