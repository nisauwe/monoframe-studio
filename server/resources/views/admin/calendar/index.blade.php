@extends('layouts/contentNavbarLayout')

@section('title', 'Kalender')

@section('content')
  @php
    use Carbon\Carbon;

    $weekHourRowHeight = 52;
    $dayHourRowHeight = $hourRowHeight;

    $weekHeaderHeight = 70;
    $dayHeaderHeight = 84;

    $weekTimelineHeight = ($dayEndHour - $dayStartHour) * $weekHourRowHeight;
    $dayTimelineHeight = ($dayEndHour - $dayStartHour) * $dayHourRowHeight;

    $timelineHeight = $dayTimelineHeight;
    $weekViewDate = $anchorDate->copy();

    $prepareTimelineEvents = function ($events, $activeHourRowHeight = null) use ($dayStartHour, $hourRowHeight) {
        $activeHourRowHeight = $activeHourRowHeight ?: $hourRowHeight;

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

            $prepared[$i]['top'] = max(0, ($minutesFromStart / 60) * $activeHourRowHeight);
            $prepared[$i]['height'] = max(42, ($durationMinutes / 60) * $activeHourRowHeight - 5);
            $prepared[$i]['width'] = 100 / $prepared[$i]['columns'];
            $prepared[$i]['left'] = $item['lane'] * $prepared[$i]['width'];
        }

        return collect($prepared)->values();
    };

    $statCards = [
        [
            'label' => 'Jadwal Bulan Ini',
            'value' => $totalSchedules,
            'helper' => 'Total sesi di ' . $anchorDate->translatedFormat('F Y'),
            'icon' => 'bx bx-calendar-check',
            'class' => '',
        ],
        [
            'label' => 'Hari Terisi',
            'value' => $totalBookedDays,
            'helper' => 'Tanggal dengan jadwal pemotretan',
            'icon' => 'bx bx-calendar-event',
            'class' => 'warning',
        ],
        [
            'label' => 'Bulan Aktif',
            'value' => $anchorDate->translatedFormat('F'),
            'helper' => 'Bisa cek bulan sebelumnya dan sesudahnya',
            'icon' => 'bx bx-calendar-star',
            'class' => 'success',
        ],
    ];
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">

      {{-- HERO HEADER --}}
      <div class="calendar-hero-card mb-4">
        <div class="calendar-hero-left">
          <div class="calendar-hero-icon">
            <i class="bx bx-calendar-event"></i>
          </div>

          <div>
            <div class="calendar-hero-kicker">KALENDER STUDIO</div>
            <h4>Kalender Monoframe</h4>
            <p>
              Pantau jadwal studio berdasarkan tampilan bulan, minggu, dan hari.
              Semua jadwal diambil langsung dari database booking agar admin bisa
              melihat agenda pemotretan dengan lebih rapi dan mudah dipahami.
            </p>
          </div>
        </div>

        <div class="calendar-hero-actions">
          <div class="calendar-hero-date">
            <i class="bx bx-calendar-event"></i>
            {{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('d F Y') }}
          </div>
        </div>
      </div>

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        @foreach ($statCards as $card)
          <div class="col-md-4">
            <div class="card stat-card h-100 calendar-stat-card">
              <div class="card-body">
                <div class="d-flex justify-content-between align-items-start gap-3">
                  <div>
                    <div class="stat-label">{{ $card['label'] }}</div>
                    <div class="stat-number calendar-stat-number">{{ $card['value'] }}</div>
                    <div class="stat-helper">{{ $card['helper'] }}</div>
                  </div>

                  <div class="stat-icon {{ $card['class'] }}">
                    <i class="{{ $card['icon'] }}"></i>
                  </div>
                </div>
              </div>
            </div>
          </div>
        @endforeach
      </div>

      {{-- CALENDAR LAYOUT --}}
      <div class="calendar-shell">

        {{-- MAIN CALENDAR --}}
        <div class="calendar-main-card">

          {{-- TOOLBAR --}}
          <div class="calendar-toolbar">
            <div class="calendar-toolbar-left">
              <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => now()->toDateString(), 'selected_date' => now()->toDateString()]) }}"
                class="btn btn-outline-primary">
                <i class="bx bx-calendar-check me-1"></i>
                Hari ini
              </a>

              <div class="calendar-nav-group">
                <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $prevDate->toDateString(), 'selected_date' => $prevDate->toDateString()]) }}"
                  class="btn btn-outline-secondary btn-icon-only">
                  <i class="bx bx-chevron-left"></i>
                </a>

                <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $nextDate->toDateString(), 'selected_date' => $nextDate->toDateString()]) }}"
                  class="btn btn-outline-secondary btn-icon-only">
                  <i class="bx bx-chevron-right"></i>
                </a>
              </div>

              <h3 class="calendar-title">{{ $title }}</h3>
            </div>

            <div class="calendar-toolbar-right">
              <div class="btn-group view-switch">
                <a href="{{ route('admin.calendar.index', ['view' => 'month', 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate]) }}"
                  class="btn {{ $viewMode === 'month' ? 'btn-primary active' : 'btn-outline-secondary' }}">
                  Bulan
                </a>

                <a href="{{ route('admin.calendar.index', ['view' => 'week', 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate]) }}"
                  class="btn {{ $viewMode === 'week' ? 'btn-primary active' : 'btn-outline-secondary' }}">
                  Minggu
                </a>

                <a href="{{ route('admin.calendar.index', ['view' => 'day', 'date' => $anchorDate->toDateString(), 'selected_date' => $selectedDate]) }}"
                  class="btn {{ $viewMode === 'day' ? 'btn-primary active' : 'btn-outline-secondary' }}">
                  Hari
                </a>
              </div>
            </div>
          </div>

          {{-- MONTH VIEW --}}
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
                  $isToday = $dateKey === now()->toDateString();
                @endphp

                <div class="month-cell {{ !$isCurrentMonth ? 'other-month' : '' }} {{ $isSelected ? 'selected' : '' }} {{ $isToday ? 'today' : '' }}">
                  <a href="{{ route('admin.calendar.index', ['view' => 'month', 'date' => $anchorDate->toDateString(), 'selected_date' => $dateKey]) }}"
                    class="text-decoration-none text-reset">
                    <div class="month-date">
                      <span>{{ $day->day }}</span>

                      @if ($isToday)
                        <small>Hari ini</small>
                      @endif
                    </div>
                  </a>

                  @foreach ($events->take(3) as $booking)
                    @php
                      $eventClass =
                          ($booking->location_type ?? 'indoor') === 'outdoor' ? 'event-outdoor' : 'event-indoor';

                      $durationMinutes =
                          (int) ($booking->duration_minutes ?? 0) +
                          (int) ($booking->extra_duration_minutes ?? 0);
                    @endphp

                    <button type="button"
                      class="month-event {{ $eventClass }} js-calendar-booking-popup"
                      data-package="{{ $booking->package->name ?? 'Paket' }}"
                      data-client="{{ $booking->client_name ?: '-' }}"
                      data-phone="{{ $booking->client_phone ?: '-' }}"
                      data-date="{{ Carbon::parse($dateKey)->translatedFormat('l, d F Y') }}"
                      data-time="{{ Carbon::parse($booking->start_time)->format('H:i') }} - {{ Carbon::parse($booking->end_time)->format('H:i') }}"
                      data-photographer="{{ $booking->photographer_name ?: '-' }}"
                      data-location="{{ $booking->location_name ?: '-' }}"
                      data-location-type="{{ ucfirst($booking->location_type ?? '-') }}"
                      data-duration="{{ $durationMinutes > 0 ? $durationMinutes . ' menit' : '-' }}"
                      data-notes="{{ $booking->notes ?: '-' }}">
                      <span class="event-time">
                        {{ Carbon::parse($booking->start_time)->format('H:i') }}
                      </span>
                      <span class="event-title">
                        {{ $booking->package->name ?? 'Paket' }}
                      </span>
                    </button>
                  @endforeach

                  @if ($events->count() > 3)
                    <div class="month-more">
                      + {{ $events->count() - 3 }} lainnya
                    </div>
                  @endif
                </div>
              @endforeach
            </div>

          {{-- WEEK VIEW --}}
          @elseif ($viewMode === 'week')
            <div class="timeline-shell week-timeline-shell"
              style="
                --timeline-height: {{ $weekTimelineHeight }}px;
                --calendar-hour-height: {{ $weekHourRowHeight }}px;
                --calendar-header-height: {{ $weekHeaderHeight }}px;
              ">

              <div class="time-labels week-time-labels"
                style="height: {{ $weekHeaderHeight + $weekTimelineHeight }}px;">
                @for ($hour = $dayStartHour; $hour <= $dayEndHour; $hour++)
                  <div class="time-label"
                    style="top: {{ $weekHeaderHeight + (($hour - $dayStartHour) * $weekHourRowHeight) }}px;">
                    {{ sprintf('%02d:00', $hour) }}
                  </div>
                @endfor
              </div>

              <div class="week-grid">
                @foreach ($weekDays as $day)
                  @php
                    $dateKey = $day->toDateString();
                    $events = collect($bookingsByDate->get($dateKey, collect()))->sortBy('start_time')->values();
                    $preparedEvents = $prepareTimelineEvents($events, $weekHourRowHeight);
                    $isSelected = $selectedDate === $dateKey;
                    $isToday = $dateKey === now()->toDateString();
                  @endphp

                  <div class="week-column">
                    <div class="week-header {{ $isSelected ? 'selected' : '' }} {{ $isToday ? 'today' : '' }}">
                      <a href="{{ route('admin.calendar.index', ['view' => 'week', 'date' => $anchorDate->toDateString(), 'selected_date' => $dateKey]) }}"
                        class="text-decoration-none text-reset">
                        <div class="week-day-name">{{ $day->translatedFormat('D') }}</div>
                        <div class="week-day-number">{{ $day->day }}</div>

                        @if ($isToday)
                          <div class="week-today-label">Hari ini</div>
                        @endif
                      </a>
                    </div>

                    <div class="week-track"
                      style="
                        --timeline-height: {{ $weekTimelineHeight }}px;
                        --calendar-hour-height: {{ $weekHourRowHeight }}px;
                      ">
                      @foreach ($preparedEvents as $entry)
                        @php
                          $booking = $entry['booking'];
                          $eventClass =
                              ($booking->location_type ?? 'indoor') === 'outdoor' ? 'event-outdoor' : 'event-indoor';

                          $durationMinutes =
                              (int) ($booking->duration_minutes ?? 0) +
                              (int) ($booking->extra_duration_minutes ?? 0);
                        @endphp

                        <button type="button"
                          class="timeline-event {{ $eventClass }} {{ $selectedBooking && $selectedBooking->id === $booking->id ? 'selected' : '' }} js-calendar-booking-popup"
                          data-package="{{ $booking->package->name ?? 'Paket' }}"
                          data-client="{{ $booking->client_name ?: '-' }}"
                          data-phone="{{ $booking->client_phone ?: '-' }}"
                          data-date="{{ Carbon::parse($dateKey)->translatedFormat('l, d F Y') }}"
                          data-time="{{ Carbon::parse($booking->start_time)->format('H:i') }} - {{ Carbon::parse($booking->end_time)->format('H:i') }}"
                          data-photographer="{{ $booking->photographer_name ?: '-' }}"
                          data-location="{{ $booking->location_name ?: '-' }}"
                          data-location-type="{{ ucfirst($booking->location_type ?? '-') }}"
                          data-duration="{{ $durationMinutes > 0 ? $durationMinutes . ' menit' : '-' }}"
                          data-notes="{{ $booking->notes ?: '-' }}"
                          style="
                            top: {{ $entry['top'] }}px;
                            height: {{ $entry['height'] }}px;
                            left: calc({{ $entry['left'] }}% + 6px);
                            width: calc({{ $entry['width'] }}% - 10px);
                            z-index: {{ 2 + $entry['lane'] }};
                          ">
                          <div class="title">{{ $booking->package->name ?? 'Paket' }}</div>
                          <div class="meta">
                            {{ Carbon::parse($booking->start_time)->format('H:i') }}
                            -
                            {{ Carbon::parse($booking->end_time)->format('H:i') }}
                            <br>
                            {{ $booking->client_name }}
                          </div>
                        </button>
                      @endforeach
                    </div>
                  </div>
                @endforeach
              </div>
            </div>

          {{-- DAY VIEW --}}
          @else
            <div class="day-grid"
              style="
                --timeline-height: {{ $dayTimelineHeight }}px;
                --calendar-hour-height: {{ $dayHourRowHeight }}px;
                --calendar-header-height: {{ $dayHeaderHeight }}px;
              ">

              <div class="time-labels day-time-labels"
                style="height: {{ $dayHeaderHeight + $dayTimelineHeight }}px;">
                @for ($hour = $dayStartHour; $hour <= $dayEndHour; $hour++)
                  <div class="time-label"
                    style="top: {{ $dayHeaderHeight + (($hour - $dayStartHour) * $dayHourRowHeight) }}px;">
                    {{ sprintf('%02d:00', $hour) }}
                  </div>
                @endfor
              </div>

              <div class="day-column">
                <div class="day-header">
                  <small>{{ Carbon::parse($selectedDate)->translatedFormat('l') }}</small>
                  <h4>{{ Carbon::parse($selectedDate)->translatedFormat('d F Y') }}</h4>
                </div>

                @php
                  $dayEvents = collect($bookingsByDate->get($selectedDate, collect()))->sortBy('start_time')->values();
                  $preparedDayEvents = $prepareTimelineEvents($dayEvents, $dayHourRowHeight);
                @endphp

                <div class="day-track"
                  style="
                    --timeline-height: {{ $dayTimelineHeight }}px;
                    --calendar-hour-height: {{ $dayHourRowHeight }}px;
                  ">
                  @foreach ($preparedDayEvents as $entry)
                    @php
                      $booking = $entry['booking'];
                      $eventClass =
                          ($booking->location_type ?? 'indoor') === 'outdoor' ? 'event-outdoor' : 'event-indoor';

                      $durationMinutes =
                          (int) ($booking->duration_minutes ?? 0) +
                          (int) ($booking->extra_duration_minutes ?? 0);
                    @endphp

                    <button type="button"
                      class="timeline-event {{ $eventClass }} {{ $selectedBooking && $selectedBooking->id === $booking->id ? 'selected' : '' }} js-calendar-booking-popup"
                      data-package="{{ $booking->package->name ?? 'Paket' }}"
                      data-client="{{ $booking->client_name ?: '-' }}"
                      data-phone="{{ $booking->client_phone ?: '-' }}"
                      data-date="{{ Carbon::parse($selectedDate)->translatedFormat('l, d F Y') }}"
                      data-time="{{ Carbon::parse($booking->start_time)->format('H:i') }} - {{ Carbon::parse($booking->end_time)->format('H:i') }}"
                      data-photographer="{{ $booking->photographer_name ?: '-' }}"
                      data-location="{{ $booking->location_name ?: '-' }}"
                      data-location-type="{{ ucfirst($booking->location_type ?? '-') }}"
                      data-duration="{{ $durationMinutes > 0 ? $durationMinutes . ' menit' : '-' }}"
                      data-notes="{{ $booking->notes ?: '-' }}"
                      style="
                        top: {{ $entry['top'] }}px;
                        height: {{ $entry['height'] }}px;
                        left: calc({{ $entry['left'] }}% + 8px);
                        width: calc({{ $entry['width'] }}% - 12px);
                        z-index: {{ 2 + $entry['lane'] }};
                      ">
                      <div class="title">{{ $booking->package->name ?? 'Paket' }}</div>
                      <div class="meta">
                        {{ Carbon::parse($booking->start_time)->format('H:i') }}
                        -
                        {{ Carbon::parse($booking->end_time)->format('H:i') }}
                        <br>
                        {{ $booking->client_name }} • {{ $booking->photographer_name }}
                      </div>
                    </button>
                  @endforeach
                </div>
              </div>
            </div>
          @endif
        </div>

        {{-- RIGHT SIDEBAR --}}
        <div class="calendar-side-card">

          {{-- MINI CALENDAR --}}
          <div class="calendar-mini-card">
            <div class="calendar-mini-head">
              <h6 class="calendar-mini-title">
                {{ $anchorDate->translatedFormat('F Y') }}
              </h6>

              <div class="calendar-mini-nav">
                <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $prevDate->toDateString(), 'selected_date' => $prevDate->toDateString()]) }}">
                  <i class="bx bx-chevron-left"></i>
                </a>

                <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $nextDate->toDateString(), 'selected_date' => $nextDate->toDateString()]) }}">
                  <i class="bx bx-chevron-right"></i>
                </a>
              </div>
            </div>

            <div class="mini-calendar-grid">
              <div class="mini-day-name">Min</div>
              <div class="mini-day-name">Sen</div>
              <div class="mini-day-name">Sel</div>
              <div class="mini-day-name">Rab</div>
              <div class="mini-day-name">Kam</div>
              <div class="mini-day-name">Jum</div>
              <div class="mini-day-name">Sab</div>

              @foreach ($monthDays as $day)
                @php
                  $miniDateKey = $day->toDateString();
                  $miniEvents = $bookingsByDate->get($miniDateKey, collect());
                  $miniIsCurrentMonth = $day->month === $anchorDate->month;
                  $miniIsSelected = $selectedDate === $miniDateKey;
                @endphp

                <a href="{{ route('admin.calendar.index', ['view' => $viewMode, 'date' => $anchorDate->toDateString(), 'selected_date' => $miniDateKey]) }}"
                  class="mini-day {{ !$miniIsCurrentMonth ? 'other-month' : '' }} {{ $miniIsSelected ? 'selected' : '' }} {{ $miniEvents->count() > 0 ? 'has-event' : '' }}">
                  {{ $day->day }}
                </a>
              @endforeach
            </div>
          </div>

          {{-- TODAY SCHEDULE --}}
          <div class="calendar-today-card">
            <div class="today-card-head">
              <div>
                <h6 class="today-card-title">Jadwal Tanggal Ini</h6>
                <small class="text-muted">
                  {{ Carbon::parse($selectedDate)->translatedFormat('d F Y') }}
                </small>
              </div>

              <a href="{{ route('admin.calendar.index', ['view' => 'day', 'date' => $selectedDate, 'selected_date' => $selectedDate]) }}">
                Lihat Hari
              </a>
            </div>

            @if ($selectedDateBookings->count() > 0)
              @foreach ($selectedDateBookings as $booking)
                @php
                  $sideEventClass = ($booking->location_type ?? 'indoor') === 'outdoor' ? 'side-outdoor' : 'side-indoor';

                  $durationMinutes =
                      (int) ($booking->duration_minutes ?? 0) +
                      (int) ($booking->extra_duration_minutes ?? 0);
                @endphp

                <button type="button"
                  class="side-booking-link {{ $sideEventClass }} {{ $selectedBooking && $selectedBooking->id === $booking->id ? 'active' : '' }} js-calendar-booking-popup"
                  data-package="{{ $booking->package->name ?? 'Paket' }}"
                  data-client="{{ $booking->client_name ?: '-' }}"
                  data-phone="{{ $booking->client_phone ?: '-' }}"
                  data-date="{{ Carbon::parse($selectedDate)->translatedFormat('l, d F Y') }}"
                  data-time="{{ Carbon::parse($booking->start_time)->format('H:i') }} - {{ Carbon::parse($booking->end_time)->format('H:i') }}"
                  data-photographer="{{ $booking->photographer_name ?: '-' }}"
                  data-location="{{ $booking->location_name ?: '-' }}"
                  data-location-type="{{ ucfirst($booking->location_type ?? '-') }}"
                  data-duration="{{ $durationMinutes > 0 ? $durationMinutes . ' menit' : '-' }}"
                  data-notes="{{ $booking->notes ?: '-' }}">
                  <div class="side-booking-icon">
                    <i class="bx bx-calendar-event"></i>
                  </div>

                  <div class="side-booking-time">
                    {{ Carbon::parse($booking->start_time)->format('H:i') }}
                    -
                    {{ Carbon::parse($booking->end_time)->format('H:i') }}
                  </div>

                  <div class="side-booking-title">
                    {{ $booking->package->name ?? '-' }}
                  </div>

                  <div class="side-booking-meta">
                    {{ $booking->client_name }} • {{ $booking->photographer_name }}
                  </div>
                </button>
              @endforeach
            @else
              <div class="calendar-empty-detail">
                <i class="bx bx-calendar-x"></i>
                <h6>Belum ada jadwal</h6>
                <p>Tidak ada booking pada tanggal yang dipilih.</p>
              </div>
            @endif
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- MODAL RINGKASAN BOOKING --}}
  <div class="modal fade" id="calendarBookingSummaryModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h5 class="modal-title">Ringkasan Jadwal Booking</h5>
            <small class="text-white opacity-75">
              Detail paket, klien, jam foto, fotografer, dan lokasi pemotretan.
            </small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="booking-summary-hero">
            <div class="booking-summary-icon">
              <i class="bx bx-camera"></i>
            </div>

            <div>
              <div class="booking-summary-title" id="summaryPackage">
                Paket Foto
              </div>
              <div class="booking-summary-subtitle" id="summaryClient">
                Nama Klien
              </div>
            </div>
          </div>

          <div class="booking-summary-grid">
            <div class="booking-summary-item">
              <div class="booking-summary-label">Tanggal Foto</div>
              <div class="booking-summary-value" id="summaryDate">-</div>
            </div>

            <div class="booking-summary-item">
              <div class="booking-summary-label">Jam Foto</div>
              <div class="booking-summary-value" id="summaryTime">-</div>
            </div>

            <div class="booking-summary-item">
              <div class="booking-summary-label">Klien</div>
              <div class="booking-summary-value">
                <span id="summaryClientName">-</span>
                <br>
                <span class="text-muted" id="summaryPhone">-</span>
              </div>
            </div>

            <div class="booking-summary-item">
              <div class="booking-summary-label">Fotografer</div>
              <div class="booking-summary-value" id="summaryPhotographer">-</div>
            </div>

            <div class="booking-summary-item">
              <div class="booking-summary-label">Lokasi</div>
              <div class="booking-summary-value">
                <span id="summaryLocation">-</span>
                <br>
                <span class="text-muted" id="summaryLocationType">-</span>
              </div>
            </div>

            <div class="booking-summary-item">
              <div class="booking-summary-label">Durasi</div>
              <div class="booking-summary-value" id="summaryDuration">-</div>
            </div>

            <div class="booking-summary-item booking-summary-note">
              <div class="booking-summary-label">Catatan</div>
              <div class="booking-summary-value" id="summaryNotes">-</div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
            Tutup
          </button>
        </div>
      </div>
    </div>
  </div>

  {{-- MODAL TAMBAH JADWAL --}}
  <div class="modal fade" id="addCalendarEventModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <form method="POST" action="{{ route('admin.calendar.store') }}">
          @csrf

          <div class="modal-header">
            <div>
              <h5 class="modal-title">Tambah Jadwal Manual</h5>
              <small class="text-white opacity-75">
                Tambahkan jadwal booking langsung dari kalender admin.
              </small>
            </div>

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
                <div class="calendar-check-card">
                  <div class="form-check mb-0">
                    <input class="form-check-input" type="checkbox" name="add_extra_duration" value="1"
                      id="calendarAddExtra">
                    <label class="form-check-label" for="calendarAddExtra">
                      Tambah durasi ekstra
                    </label>
                  </div>
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
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
              Batal
            </button>
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i>
              Simpan Jadwal
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <style>
    .calendar-hero-card {
      position: relative;
      overflow: hidden;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 24px;
      padding: 32px 34px;
      border-radius: 32px;
      background:
        radial-gradient(circle at top right, rgba(255, 255, 255, 0.36), transparent 32%),
        linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 24px 54px rgba(52, 79, 165, 0.24);
      color: #ffffff;
    }

    .calendar-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .calendar-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .calendar-hero-icon {
      width: 76px;
      height: 76px;
      border-radius: 26px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: rgba(255, 255, 255, 0.18);
      color: #ffffff;
      font-size: 38px;
      box-shadow: 0 16px 32px rgba(22, 43, 77, 0.16);
    }

    .calendar-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .calendar-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .calendar-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .calendar-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .calendar-hero-date {
      min-height: 54px;
      border: 0;
      border-radius: 18px;
      background: rgba(255, 255, 255, 0.92);
      color: var(--mf-primary);
      font-weight: 900;
      padding: 0 22px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 9px;
      white-space: nowrap;
      box-shadow: 0 16px 30px rgba(22, 43, 77, 0.16);
    }

    .calendar-hero-date i {
      font-size: 20px;
    }

    .calendar-stat-card {
      min-height: 140px;
    }

    .calendar-stat-number {
      font-size: 30px !important;
    }

    .calendar-shell {
      display: grid;
      grid-template-columns: minmax(0, 1fr) 340px;
      gap: 24px;
      align-items: start;
    }

    .calendar-main-card,
    .calendar-side-card {
      border: 0;
      border-radius: 30px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
    }

    .calendar-main-card {
      min-width: 0;
      overflow: hidden;
    }

    .calendar-toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 14px;
      flex-wrap: wrap;
      padding: 20px 24px;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .calendar-toolbar-left,
    .calendar-toolbar-right {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .calendar-nav-group {
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }

    .btn-icon-only {
      width: 42px;
      height: 42px;
      padding: 0 !important;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .calendar-title {
      color: var(--mf-ink);
      font-size: 24px;
      font-weight: 900;
      letter-spacing: -0.02em;
      margin: 0 4px;
    }

    .view-switch {
      gap: 8px;
    }

    .view-switch .btn {
      border-radius: 14px !important;
      box-shadow: none !important;
    }

    .view-switch .btn.active {
      color: #ffffff !important;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue)) !important;
      border-color: transparent !important;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.22) !important;
    }

    .month-grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      border-top: 1px solid var(--mf-border);
      border-left: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .month-day-name {
      padding: 11px 8px;
      text-align: center;
      color: #6e7f96;
      background: #f4f7fb;
      border-right: 1px solid var(--mf-border);
      border-bottom: 1px solid var(--mf-border);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.045em;
    }

    .month-cell {
      min-height: 118px;
      padding: 9px;
      border-right: 1px solid var(--mf-border);
      border-bottom: 1px solid var(--mf-border);
      background: #ffffff;
      color: inherit;
      transition: 0.2s ease;
      position: relative;
    }

    .month-cell:hover {
      background: #f7fbfd;
      transform: translateY(-2px);
      box-shadow: inset 0 0 0 1px rgba(88, 115, 220, 0.12);
    }

    .month-cell.other-month {
      background: #f8fafc;
      color: #aab4c2;
    }

    .month-cell.selected {
      background: rgba(88, 115, 220, 0.06);
      box-shadow: inset 0 0 0 2px var(--mf-primary);
    }

    .month-cell.today:not(.selected) {
      box-shadow: inset 0 0 0 2px rgba(13, 111, 168, 0.24);
    }

    .month-date {
      display: flex;
      align-items: center;
      justify-content: space-between;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
      margin-bottom: 7px;
    }

    .month-date small,
    .week-today-label {
      display: inline-flex;
      align-items: center;
      border-radius: 999px;
      padding: 3px 6px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 9px;
      font-weight: 900;
    }

    .month-event {
      width: 100%;
      border: 1px solid transparent;
      display: flex;
      align-items: center;
      gap: 6px;
      text-align: left;
      font-size: 11px;
      padding: 6px 8px;
      border-radius: 11px;
      margin-bottom: 5px;
      text-decoration: none;
      font-weight: 800;
      cursor: pointer;
      transition: 0.18s ease;
    }

    .month-event:hover {
      transform: translateX(3px);
    }

    .month-event .event-time {
      flex-shrink: 0;
      font-weight: 900;
    }

    .month-event .event-title {
      min-width: 0;
      overflow: hidden;
      white-space: nowrap;
      text-overflow: ellipsis;
    }

    .event-indoor {
      background: rgba(242, 169, 59, 0.15);
      color: #9c6b12;
      border-color: rgba(242, 169, 59, 0.28);
    }

    .event-outdoor {
      background: rgba(13, 111, 168, 0.13);
      color: var(--mf-blue);
      border-color: rgba(13, 111, 168, 0.22);
    }

    .month-more {
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 800;
      margin-top: 4px;
    }

    .timeline-shell {
      display: grid;
      grid-template-columns: 64px minmax(0, 1fr);
      min-height: 300px;
      overflow-x: auto;
      background: #ffffff;
    }

    .week-timeline-shell {
      grid-template-columns: 58px minmax(0, 1fr);
      min-height: auto;
      overflow-x: hidden;
    }

    .time-labels {
      position: relative;
      border-right: 1px solid var(--mf-border);
      background: #f8fbfd;
    }

    .time-label {
      position: absolute;
      left: 0;
      width: 100%;
      transform: translateY(-50%);
      text-align: center;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 900;
    }

    .week-time-labels::before,
    .day-time-labels::before {
      content: "";
      position: absolute;
      left: 0;
      top: 0;
      width: 100%;
      height: var(--calendar-header-height);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      border-bottom: 1px solid var(--mf-border);
    }

    .week-grid {
      display: grid;
      grid-template-columns: repeat(7, minmax(0, 1fr));
      min-width: 0;
    }

    .week-column {
      border-right: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .week-column:last-child {
      border-right: 0;
    }

    .week-header {
      height: var(--calendar-header-height, 70px);
      min-height: var(--calendar-header-height, 70px);
      padding: 11px 8px;
      border-bottom: 1px solid var(--mf-border);
      text-align: center;
      background: #ffffff;
      position: sticky;
      top: 0;
      z-index: 2;
      box-sizing: border-box;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .week-header.selected {
      background: rgba(88, 115, 220, 0.07);
    }

    .week-header.today:not(.selected) {
      background: rgba(13, 111, 168, 0.06);
    }

    .week-day-name {
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      margin-bottom: 5px;
    }

    .week-day-number {
      color: var(--mf-ink);
      font-size: 22px;
      font-weight: 900;
      line-height: 1;
      margin-bottom: 4px;
    }

    .week-track,
    .day-track {
      position: relative;
      height: var(--timeline-height);
      background:
        linear-gradient(
          to bottom,
          transparent calc(var(--calendar-hour-height, 72px) - 1px),
          var(--mf-border) var(--calendar-hour-height, 72px)
        );
      background-size: 100% var(--calendar-hour-height, 72px);
    }

    .day-grid {
      display: grid;
      grid-template-columns: 76px minmax(0, 1fr);
      overflow-x: auto;
      background: #ffffff;
    }

    .day-column {
      background: #ffffff;
      min-width: 720px;
    }

    .day-header {
      height: var(--calendar-header-height, 84px);
      min-height: var(--calendar-header-height, 84px);
      padding: 18px 24px;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 34%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }

    .day-header small {
      display: block;
      color: var(--mf-primary);
      font-weight: 900;
      margin-bottom: 6px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }

    .day-header h4 {
      color: var(--mf-ink);
      font-weight: 900;
      margin: 0;
    }

    .timeline-event {
      position: absolute;
      border-width: 1px;
      border-style: solid;
      border-radius: 16px;
      padding: 11px 13px;
      text-align: left;
      text-decoration: none;
      box-shadow: 0 12px 24px rgba(52, 79, 165, 0.12);
      overflow: hidden;
      box-sizing: border-box;
      transition: 0.18s ease;
      cursor: pointer;
    }

    .timeline-event:hover {
      transform: translateY(-2px);
      box-shadow: 0 18px 32px rgba(52, 79, 165, 0.18);
    }

    .timeline-event .title {
      font-size: 13px;
      font-weight: 900;
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
      font-weight: 700;
    }

    .week-timeline-shell .time-label {
      font-size: 11px;
    }

    .week-timeline-shell .timeline-event {
      border-radius: 13px;
      padding: 7px 9px;
      box-shadow: 0 8px 18px rgba(52, 79, 165, 0.10);
    }

    .week-timeline-shell .timeline-event .title {
      font-size: 12px;
      line-height: 1.25;
      margin-bottom: 2px;
    }

    .week-timeline-shell .timeline-event .meta {
      font-size: 11px;
      line-height: 1.35;
    }

    .timeline-event.selected {
      box-shadow:
        inset 0 0 0 2px var(--mf-ink),
        0 18px 32px rgba(52, 79, 165, 0.18);
      z-index: 3;
    }

    .calendar-side-card {
      position: sticky;
      top: 105px;
      padding: 22px;
    }

    .calendar-mini-card,
    .calendar-today-card {
      border-radius: 24px;
      background: #ffffff;
    }

    .calendar-mini-head,
    .today-card-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
    }

    .calendar-mini-title,
    .today-card-title {
      color: var(--mf-ink);
      font-weight: 900;
      margin: 0;
    }

    .calendar-mini-nav {
      display: inline-flex;
      gap: 8px;
    }

    .calendar-mini-nav a {
      width: 34px;
      height: 34px;
      border-radius: 12px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: var(--mf-primary);
      background: rgba(88, 115, 220, 0.10);
      text-decoration: none;
    }

    .mini-calendar-grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      gap: 7px;
      margin-bottom: 26px;
    }

    .mini-day-name {
      text-align: center;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
    }

    .mini-day {
      height: 34px;
      border-radius: 12px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 800;
      text-decoration: none;
      position: relative;
    }

    .mini-day:hover {
      background: var(--mf-primary-soft);
      color: var(--mf-primary);
    }

    .mini-day.other-month {
      color: #b8c1cf;
    }

    .mini-day.selected {
      color: #ffffff;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
    }

    .mini-day.has-event::after {
      content: "";
      position: absolute;
      bottom: 5px;
      width: 4px;
      height: 4px;
      border-radius: 999px;
      background: var(--mf-blue);
    }

    .mini-day.selected.has-event::after {
      background: #ffffff;
    }

    .today-card-head {
      margin-top: 10px;
    }

    .today-card-head a {
      color: var(--mf-primary);
      font-size: 12px;
      font-weight: 900;
      text-decoration: none;
    }

    .side-booking-link {
      width: 100%;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      padding: 15px;
      margin-bottom: 12px;
      text-align: left;
      background: #ffffff;
      color: inherit;
      cursor: pointer;
      transition: 0.18s ease;
      position: relative;
      overflow: hidden;
    }

    .side-booking-link::before {
      content: "";
      position: absolute;
      left: 0;
      top: 0;
      width: 5px;
      height: 100%;
      background: var(--mf-primary);
    }

    .side-booking-link.side-outdoor::before {
      background: var(--mf-blue);
    }

    .side-booking-link.side-indoor::before {
      background: #f2a93b;
    }

    .side-booking-link:hover {
      background: #f8fbfd;
      transform: translateY(-2px);
      box-shadow: var(--mf-shadow-soft);
    }

    .side-booking-link.active {
      border-color: rgba(88, 115, 220, 0.45);
      background: rgba(88, 115, 220, 0.06);
    }

    .side-booking-icon {
      width: 38px;
      height: 38px;
      border-radius: 14px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      margin-bottom: 12px;
    }

    .side-booking-title {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 4px;
    }

    .side-booking-time {
      color: var(--mf-primary);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .side-booking-meta {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.5;
    }

    .calendar-empty-detail {
      border: 1px dashed var(--mf-sky);
      border-radius: 22px;
      padding: 34px 20px;
      background: #ffffff;
      text-align: center;
      color: var(--mf-muted);
    }

    .calendar-empty-detail i {
      display: block;
      font-size: 44px;
      color: var(--mf-primary);
      margin-bottom: 10px;
    }

    .calendar-empty-detail h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .calendar-empty-detail p {
      max-width: 260px;
      margin: 0 auto;
      line-height: 1.6;
      font-weight: 600;
    }

    .booking-summary-hero {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 18px;
      border-radius: 24px;
      margin-bottom: 20px;
      background: linear-gradient(135deg, var(--mf-deep), var(--mf-primary) 58%, var(--mf-blue));
      color: #ffffff;
    }

    .booking-summary-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: rgba(255, 255, 255, 0.16);
      font-size: 28px;
    }

    .booking-summary-title {
      color: #ffffff;
      font-weight: 900;
      font-size: 18px;
      margin-bottom: 4px;
    }

    .booking-summary-subtitle {
      color: rgba(255, 255, 255, 0.82);
      font-size: 13px;
      font-weight: 700;
    }

    .booking-summary-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 14px;
    }

    .booking-summary-item {
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      padding: 15px;
      background: #ffffff;
    }

    .booking-summary-label {
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 6px;
    }

    .booking-summary-value {
      color: var(--mf-ink);
      font-size: 15px;
      font-weight: 900;
      line-height: 1.5;
    }

    .booking-summary-note {
      grid-column: 1 / -1;
    }

    .calendar-check-card {
      min-height: 45px;
      border: 1px solid var(--mf-border);
      border-radius: 14px;
      padding: 11px 14px;
      background: #ffffff;
      display: flex;
      align-items: center;
    }

    .modal .form-text {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
    }

    @media (max-width: 1200px) {
      .calendar-shell {
        grid-template-columns: 1fr;
      }

      .calendar-side-card {
        position: static;
      }
    }

    @media (max-width: 992px) {
      .calendar-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .calendar-hero-actions,
      .calendar-hero-date {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .calendar-hero-card {
        padding: 26px 22px;
      }

      .calendar-hero-left {
        flex-direction: column;
      }

      .calendar-hero-date {
        min-height: 50px;
      }

      .calendar-title {
        width: 100%;
        font-size: 24px;
      }

      .calendar-toolbar {
        padding: 22px;
      }

      .month-grid {
        grid-template-columns: repeat(2, 1fr);
      }

      .month-day-name {
        display: none;
      }

      .timeline-shell,
      .day-grid {
        grid-template-columns: 56px minmax(0, 1fr);
      }

      .booking-summary-grid {
        grid-template-columns: 1fr;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      const packageSelect = document.getElementById('calendarPackageSelect');
      const locationWrap = document.getElementById('calendarLocationWrap');
      const locationName = document.getElementById('calendarLocationName');

      function toggleLocationField() {
        if (!packageSelect) {
          return;
        }

        const selected = packageSelect.options[packageSelect.selectedIndex];
        const location = (selected?.dataset?.location || '').toLowerCase().trim();

        if (location.includes('outdoor')) {
          locationWrap.style.display = 'block';
        } else {
          locationWrap.style.display = 'none';

          if (locationName) {
            locationName.value = '';
          }
        }
      }

      if (packageSelect) {
        packageSelect.addEventListener('change', toggleLocationField);
        toggleLocationField();
      }

      document.addEventListener('click', function(event) {
        const trigger = event.target.closest('.js-calendar-booking-popup');

        if (!trigger) {
          return;
        }

        const modalElement = document.getElementById('calendarBookingSummaryModal');

        if (!modalElement) {
          return;
        }

        document.getElementById('summaryPackage').textContent = trigger.dataset.package || '-';
        document.getElementById('summaryClient').textContent = trigger.dataset.client || '-';
        document.getElementById('summaryClientName').textContent = trigger.dataset.client || '-';
        document.getElementById('summaryPhone').textContent = trigger.dataset.phone || '-';
        document.getElementById('summaryDate').textContent = trigger.dataset.date || '-';
        document.getElementById('summaryTime').textContent = trigger.dataset.time || '-';
        document.getElementById('summaryPhotographer').textContent = trigger.dataset.photographer || '-';
        document.getElementById('summaryLocation').textContent = trigger.dataset.location || '-';
        document.getElementById('summaryLocationType').textContent = trigger.dataset.locationType || '-';
        document.getElementById('summaryDuration').textContent = trigger.dataset.duration || '-';
        document.getElementById('summaryNotes').textContent = trigger.dataset.notes || '-';

        const modal = new bootstrap.Modal(modalElement);
        modal.show();
      });
    });
  </script>
@endsection
