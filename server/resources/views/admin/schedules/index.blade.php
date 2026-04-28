@extends('layouts/contentNavbarLayout')

@section('title', 'Jadwal & Slot')

@section('content')
  @php
    $tabs = [
        [
            'key' => 'operational',
            'label' => 'Operasional',
            'icon' => 'bx bx-cog',
            'target' => '#tab-operational',
        ],
        [
            'key' => 'daily',
            'label' => 'Jadwal Harian',
            'icon' => 'bx bx-calendar',
            'target' => '#tab-daily',
        ],
        [
            'key' => 'booking-monitoring',
            'label' => 'Monitoring Booking',
            'icon' => 'bx bx-list-check',
            'target' => '#tab-booking-monitoring',
        ],
        [
            'key' => 'manual',
            'label' => 'Booking Manual',
            'icon' => 'bx bx-edit-alt',
            'target' => '#tab-manual',
        ],
    ];

    $statCards = [
        [
            'label' => 'Hari Aktif',
            'value' => $activeDays,
            'helper' => 'Hari operasional aktif',
            'icon' => 'bx bx-calendar-check',
            'class' => '',
        ],
        [
            'label' => 'Slot Hari Ini',
            'value' => $totalSlotsToday,
            'helper' => 'Jumlah slot pada tanggal terpilih',
            'icon' => 'bx bx-time-five',
            'class' => 'info',
        ],
        [
            'label' => 'Sesi Terbooking',
            'value' => $bookedSessionsToday,
            'helper' => 'Booking masuk pada tanggal ini',
            'icon' => 'bx bx-bookmark',
            'class' => 'warning',
        ],
        [
            'label' => 'Extra Duration',
            'value' => $extraDurationMinutes . ' Menit',
            'helper' => 'Biaya Rp ' . number_format($extraDurationFee, 0, ',', '.'),
            'icon' => 'bx bx-plus-circle',
            'class' => 'success',
        ],
    ];

    $bookingMonitoringFilter = $bookingMonitoringFilter ?? request('booking_filter', 'need_payment');
    $bookingMonitoringSearch = $bookingMonitoringSearch ?? request('booking_search', '');

    $bookingMonitoringStats = $bookingMonitoringStats ?? [
        'all' => 0,
        'need_payment' => 0,
        'running' => 0,
        'completed' => 0,
    ];

    $bookingMonitoringList = collect($bookingMonitoringList ?? []);
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">

      {{-- HERO HEADER --}}
      <div class="schedule-hero-card mb-4">
        <div class="schedule-hero-left">
          <div class="schedule-hero-icon">
            <i class="bx bx-calendar-event"></i>
          </div>

          <div>
            <div class="schedule-hero-kicker">MANAJEMEN JADWAL</div>
            <h4>Jadwal & Slot</h4>
            <p>
              Kelola operasional indoor dan outdoor, atur kapasitas slot harian,
              pantau jadwal fotografer, monitoring booking klien, dan input booking manual
              dalam satu halaman yang rapi.
            </p>
          </div>
        </div>

        <div class="schedule-hero-actions">
          <div class="schedule-hero-date">
            <i class="bx bx-calendar-event"></i>
            {{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('d F Y') }}
          </div>
        </div>
      </div>

      {{-- ALERT --}}
      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <strong>Terjadi kesalahan.</strong>
          <ul class="mb-0 mt-2 ps-3">
            @foreach ($errors->all() as $error)
              <li>{{ $error }}</li>
            @endforeach
          </ul>
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        @foreach ($statCards as $card)
          <div class="col-xl-3 col-md-6">
            <div class="card stat-card h-100">
              <div class="card-body">
                <div class="d-flex justify-content-between align-items-start gap-3">
                  <div>
                    <div class="stat-label">{{ $card['label'] }}</div>
                    <div class="stat-number schedule-stat-number">{{ $card['value'] }}</div>
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

      {{-- TAB MENU --}}
      <div class="schedule-tabs-card mb-4">
        <ul class="nav schedule-tabs" role="tablist">
          @foreach ($tabs as $tab)
            <li class="nav-item">
              <button
                type="button"
                class="nav-link {{ $selectedTab === $tab['key'] ? 'active' : '' }}"
                data-bs-toggle="tab"
                data-bs-target="{{ $tab['target'] }}"
                data-schedule-tab="{{ $tab['key'] }}"
                role="tab">
                <i class="{{ $tab['icon'] }} me-1"></i>
                {{ $tab['label'] }}
              </button>
            </li>
          @endforeach
        </ul>
      </div>

      <div class="tab-content schedule-tab-content">

        {{-- TAB OPERASIONAL --}}
        <div class="tab-pane fade {{ $selectedTab === 'operational' ? 'show active' : '' }}" id="tab-operational" role="tabpanel">

          {{-- OPERASIONAL RULES --}}
          <div class="card section-card schedule-index-card mb-4">
            <div class="card-header">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                <div>
                  <h5 class="section-title">Operasional Indoor & Outdoor</h5>
                  <p class="section-subtitle mb-0">
                    Indoor dan outdoor diatur terpisah, tapi tetap memakai resource fotografer yang sama.
                  </p>
                </div>

                <div class="mf-badge-total">
                  <i class="bx bx-calendar-week"></i>
                  {{ $rules->count() }} aturan hari
                </div>
              </div>
            </div>

            <div class="card-body schedule-table-body">
              <form action="{{ route('admin.schedules.rules.update') }}" method="POST">
                @csrf
                @method('PUT')

                <div class="schedule-table-wrap">
                  <div class="table-responsive">
                    <table class="table align-middle schedule-rule-table">
                      <thead>
                        <tr>
                          <th rowspan="2" class="rule-day">Hari</th>
                          <th rowspan="2" class="rule-switch-wrap group-divider-right">Aktif</th>

                          <th colspan="4" class="text-center group-divider-right">Indoor</th>
                          <th colspan="3" class="text-center group-divider-right">Outdoor</th>
                          <th colspan="2" class="text-center">Umum</th>
                        </tr>
                        <tr>
                          <th>Jam Buka</th>
                          <th>Jam Tutup</th>
                          <th>Kapasitas Indoor</th>
                          <th class="group-divider-right">Jeda Indoor</th>

                          <th>Jam Buka</th>
                          <th>Jam Tutup</th>
                          <th class="group-divider-right">Jeda Outdoor</th>

                          <th>Extra Menit / Step</th>
                          <th>Biaya / Step</th>
                        </tr>
                      </thead>

                      <tbody>
                        @foreach ($rules as $index => $rule)
                          <tr>
                            <td class="rule-day">
                              {{ $rule->day_name }}
                              <input type="hidden" name="rules[{{ $index }}][id]" value="{{ $rule->id }}">
                            </td>

                            <td class="rule-switch-wrap group-divider-right">
                              <div class="form-check form-switch d-flex justify-content-center">
                                <input
                                  class="form-check-input"
                                  type="checkbox"
                                  name="rules[{{ $index }}][is_active]"
                                  value="1"
                                  {{ $rule->is_active ? 'checked' : '' }}>
                              </div>
                            </td>

                            <td>
                              <input
                                type="time"
                                name="rules[{{ $index }}][indoor_open_time]"
                                class="form-control rule-input"
                                value="{{ $rule->indoor_open_time }}">
                            </td>

                            <td>
                              <input
                                type="time"
                                name="rules[{{ $index }}][indoor_close_time]"
                                class="form-control rule-input"
                                value="{{ $rule->indoor_close_time }}">
                            </td>

                            <td>
                              <input
                                type="number"
                                name="rules[{{ $index }}][indoor_capacity]"
                                class="form-control rule-input"
                                value="{{ $rule->indoor_capacity }}">
                            </td>

                            <td class="group-divider-right">
                              <input
                                type="number"
                                name="rules[{{ $index }}][indoor_buffer_minutes]"
                                class="form-control rule-input"
                                value="{{ $rule->indoor_buffer_minutes }}">
                            </td>

                            <td>
                              <input
                                type="time"
                                name="rules[{{ $index }}][outdoor_open_time]"
                                class="form-control rule-input"
                                value="{{ $rule->outdoor_open_time }}">
                            </td>

                            <td>
                              <input
                                type="time"
                                name="rules[{{ $index }}][outdoor_close_time]"
                                class="form-control rule-input"
                                value="{{ $rule->outdoor_close_time }}">
                            </td>

                            <td class="group-divider-right">
                              <input
                                type="number"
                                name="rules[{{ $index }}][outdoor_buffer_minutes]"
                                class="form-control rule-input"
                                value="{{ $rule->outdoor_buffer_minutes }}">
                            </td>

                            <td>
                              <input
                                type="number"
                                name="rules[{{ $index }}][extra_duration_minutes]"
                                class="form-control rule-input"
                                value="{{ $rule->extra_duration_minutes }}">
                            </td>

                            <td>
                              <input
                                type="number"
                                name="rules[{{ $index }}][extra_duration_fee]"
                                class="form-control rule-input-fee"
                                value="{{ $rule->extra_duration_fee }}">
                            </td>
                          </tr>
                        @endforeach
                      </tbody>
                    </table>
                  </div>
                </div>

                <div class="schedule-action-footer">
                  <button type="submit" class="btn btn-primary">
                    <i class="bx bx-save me-1"></i>
                    Simpan Pengaturan
                  </button>
                </div>
              </form>
            </div>
          </div>

          {{-- ADDON SETTINGS --}}
          <div class="card section-card schedule-index-card">
            <div class="card-header">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                <div>
                  <h5 class="section-title">Pengaturan Add-on Video Cinematic</h5>
                  <p class="section-subtitle mb-0">
                    Harga add-on ini akan dipakai pada booking client dan booking manual.
                  </p>
                </div>

                <div class="mf-badge-total">
                  <i class="bx bx-video"></i>
                  Add-on
                </div>
              </div>
            </div>

            <div class="card-body schedule-form-body">
              <form action="{{ route('admin.schedules.addon-settings.update') }}" method="POST">
                @csrf
                @method('PUT')

                @php
                  $iphoneAddon = collect($videoAddons ?? [])->firstWhere('addon_key', 'iphone');
                  $cameraAddon = collect($videoAddons ?? [])->firstWhere('addon_key', 'camera');
                @endphp

                <div class="row g-3">
                  <div class="col-md-6">
                    <label class="form-label">Video Cinematic - iPhone</label>
                    <div class="input-group">
                      <span class="input-group-text">Rp</span>
                      <input
                        type="number"
                        name="addons[iphone][price]"
                        class="form-control"
                        value="{{ $iphoneAddon['price'] ?? $iphoneAddon->price ?? 0 }}"
                        min="0">
                    </div>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Video Cinematic - Camera</label>
                    <div class="input-group">
                      <span class="input-group-text">Rp</span>
                      <input
                        type="number"
                        name="addons[camera][price]"
                        class="form-control"
                        value="{{ $cameraAddon['price'] ?? $cameraAddon->price ?? 0 }}"
                        min="0">
                    </div>
                  </div>
                </div>

                <div class="schedule-action-footer">
                  <button type="submit" class="btn btn-outline-primary">
                    <i class="bx bx-save me-1"></i>
                    Simpan Harga Add-on
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>

        {{-- TAB JADWAL HARIAN --}}
        <div class="tab-pane fade {{ $selectedTab === 'daily' ? 'show active' : '' }}" id="tab-daily" role="tabpanel">

          {{-- FILTER TANGGAL --}}
          <div class="card section-card schedule-index-card mb-4">
            <div class="card-header">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                <div>
                  <h5 class="section-title">Jadwal Harian Fotografer</h5>
                  <p class="section-subtitle mb-0">
                    Pantau booking fotografer berdasarkan tanggal yang dipilih.
                  </p>
                </div>

                <div class="mf-badge-total">
                  <i class="bx bx-calendar"></i>
                  {{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('d M Y') }}
                </div>
              </div>
            </div>

            <div class="card-body schedule-filter-body">
              <form method="GET" action="{{ route('admin.schedules.index') }}" class="row g-3 align-items-end">
                <input type="hidden" name="tab" value="daily">

                <div class="col-md-5">
                  <label class="form-label">Pilih Tanggal</label>
                  <input type="date" name="date" class="form-control" value="{{ $selectedDate }}">
                </div>

                <div class="col-md-3">
                  <button type="submit" class="btn btn-primary w-100">
                    <i class="bx bx-search me-1"></i>
                    Tampilkan Jadwal
                  </button>
                </div>
              </form>
            </div>
          </div>

          {{-- LIST JADWAL --}}
          <div class="row g-4">
            @forelse ($photographers as $photographer)
              @php
                $photographerBookings = $dayBookings
                    ->where('photographer_user_id', $photographer->id)
                    ->sortBy('start_time')
                    ->values();
              @endphp

              <div class="col-12">
                <div class="schedule-photographer-card">
                  <div class="schedule-photographer-header">
                    <div class="schedule-photographer-main">
                      <div class="schedule-photographer-avatar">
                        {{ strtoupper(mb_substr($photographer->name, 0, 1)) }}
                      </div>

                      <div>
                        <div class="schedule-photographer-name">{{ $photographer->name }}</div>
                        <div class="schedule-photographer-email">{{ $photographer->email }}</div>
                      </div>
                    </div>

                    <div class="schedule-booking-count">
                      <i class="bx bx-bookmark"></i>
                      {{ $photographerBookings->count() }} booking
                    </div>
                  </div>

                  @if ($photographerBookings->count())
                    <div class="schedule-list">
                      @foreach ($photographerBookings as $booking)
                        @php
                          $start = \Carbon\Carbon::parse($booking->start_time)->format('H:i');
                          $end = \Carbon\Carbon::parse($booking->end_time)->format('H:i');
                          $duration =
                              (int) ($booking->duration_minutes ?? 0) +
                              (int) ($booking->extra_duration_minutes ?? 0);
                        @endphp

                        <div class="schedule-event-row">
                          <div class="schedule-time-pill">
                            {{ $start }} - {{ $end }}
                          </div>

                          <button
                            type="button"
                            class="schedule-event-card js-booking-detail"
                            data-package="{{ $booking->package->name ?? 'Paket Foto' }}"
                            data-time="{{ $start }} - {{ $end }}"
                            data-date="{{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('l, d F Y') }}"
                            data-location="{{ $booking->location_name ?: '-' }}"
                            data-location-type="{{ ucfirst($booking->location_type ?? '-') }}"
                            data-client="{{ $booking->client_name ?: '-' }}"
                            data-phone="{{ $booking->client_phone ?: '-' }}"
                            data-photographer="{{ $booking->photographer_name ?: '-' }}"
                            data-duration="{{ $duration > 0 ? $duration . ' menit' : '-' }}"
                            data-notes="{{ $booking->notes ?: '-' }}">
                            <div class="schedule-event-title">
                              {{ $booking->package->name ?? 'Paket Foto' }}
                            </div>
                            <div class="schedule-event-meta">
                              {{ $booking->client_name }} • {{ ucfirst($booking->location_type ?? '-') }} •
                              {{ $booking->location_name ?: '-' }}
                            </div>
                          </button>
                        </div>
                      @endforeach
                    </div>
                  @else
                    <div class="schedule-empty-state">
                      <i class="bx bx-calendar-x"></i>
                      <h6>Belum ada booking</h6>
                      <p>
                        Belum ada booking untuk fotografer ini pada tanggal
                        {{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('d F Y') }}.
                      </p>
                    </div>
                  @endif
                </div>
              </div>
            @empty
              <div class="col-12">
                <div class="card section-card">
                  <div class="card-body">
                    <div class="schedule-empty-state">
                      <i class="bx bx-user-x"></i>
                      <h6>Belum ada fotografer aktif</h6>
                      <p>Data fotografer aktif akan tampil di sini.</p>
                    </div>
                  </div>
                </div>
              </div>
            @endforelse
          </div>
        </div>

        {{-- TAB MONITORING BOOKING --}}
        <div class="tab-pane fade {{ $selectedTab === 'booking-monitoring' ? 'show active' : '' }}"
          id="tab-booking-monitoring"
          role="tabpanel">

          <div class="card section-card schedule-index-card mb-4">
            <div class="card-header">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                <div>
                  <h5 class="section-title">Monitoring Booking</h5>
                  <p class="section-subtitle mb-0">
                    Pantau seluruh booking klien, status pembayaran, status pengerjaan, dan tracking progres layanan.
                  </p>
                </div>

                <div class="mf-badge-total">
                  <i class="bx bx-list-check"></i>
                  {{ $bookingMonitoringStats['all'] ?? 0 }} total booking
                </div>
              </div>
            </div>

            <div class="card-body schedule-form-body">
              <div class="booking-monitoring-filter mb-4">
                <a href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => 'need_payment', 'booking_search' => $bookingMonitoringSearch]) }}"
                  class="btn {{ $bookingMonitoringFilter === 'need_payment' ? 'btn-primary' : 'btn-outline-primary' }}">
                  <i class="bx bx-wallet me-1"></i>
                  Belum Pelunasan
                  <span class="ms-1">({{ $bookingMonitoringStats['need_payment'] ?? 0 }})</span>
                </a>

                <a href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => 'running', 'booking_search' => $bookingMonitoringSearch]) }}"
                  class="btn {{ $bookingMonitoringFilter === 'running' ? 'btn-primary' : 'btn-outline-primary' }}">
                  <i class="bx bx-loader-circle me-1"></i>
                  Sedang Berjalan
                  <span class="ms-1">({{ $bookingMonitoringStats['running'] ?? 0 }})</span>
                </a>

                <a href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => 'completed', 'booking_search' => $bookingMonitoringSearch]) }}"
                  class="btn {{ $bookingMonitoringFilter === 'completed' ? 'btn-primary' : 'btn-outline-primary' }}">
                  <i class="bx bx-check-circle me-1"></i>
                  Selesai
                  <span class="ms-1">({{ $bookingMonitoringStats['completed'] ?? 0 }})</span>
                </a>

                <a href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => 'all', 'booking_search' => $bookingMonitoringSearch]) }}"
                  class="btn {{ $bookingMonitoringFilter === 'all' ? 'btn-primary' : 'btn-outline-secondary' }}">
                  <i class="bx bx-grid-alt me-1"></i>
                  Semua
                  <span class="ms-1">({{ $bookingMonitoringStats['all'] ?? 0 }})</span>
                </a>
              </div>

              <form method="GET" action="{{ route('admin.schedules.index') }}" class="row g-3 align-items-end mb-4">
                <input type="hidden" name="tab" value="booking-monitoring">
                <input type="hidden" name="booking_filter" value="{{ $bookingMonitoringFilter }}">

                <div class="col-lg-8">
                  <label class="form-label">Cari Booking</label>
                  <input type="text"
                    name="booking_search"
                    class="form-control"
                    value="{{ $bookingMonitoringSearch }}"
                    placeholder="Cari nama klien, no HP, nama fotografer, atau nama paket...">
                </div>

                <div class="col-lg-2">
                  <button type="submit" class="btn btn-primary w-100">
                    <i class="bx bx-search me-1"></i>
                    Cari
                  </button>
                </div>

                <div class="col-lg-2">
                  <a href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => $bookingMonitoringFilter]) }}"
                    class="btn btn-outline-secondary w-100">
                    Reset
                  </a>
                </div>
              </form>

              <div class="row g-4">
                @forelse ($bookingMonitoringList as $item)
                  @php
                    $booking = $item['booking'];
                    $timeline = collect($item['timeline'] ?? []);
                    $currentTracking = $item['current_tracking'] ?? null;
                    $progressPercent = $item['progress_percent'] ?? 0;

                    $bookingDateLabel = $booking->booking_date
                      ? \Carbon\Carbon::parse($booking->booking_date)->translatedFormat('d F Y')
                      : '-';

                    $startTime = $booking->start_time
                      ? \Carbon\Carbon::parse($booking->start_time)->format('H:i')
                      : '-';

                    $endTime = $booking->end_time
                      ? \Carbon\Carbon::parse($booking->end_time)->format('H:i')
                      : '-';

                    $clientInitial = strtoupper(mb_substr($booking->client_name ?: 'K', 0, 1));
                    $modalId = 'bookingTrackingModal' . $booking->id;
                  @endphp

                  <div class="col-12">
                    <div class="booking-monitoring-card">
                      <div class="booking-monitoring-top">
                        <div class="booking-monitoring-client">
                          <div class="booking-monitoring-avatar">
                            {{ $clientInitial }}
                          </div>

                          <div>
                            <div class="booking-monitoring-name">
                              {{ $booking->client_name ?: 'Klien' }}
                            </div>
                            <div class="booking-monitoring-package">
                              {{ $booking->package->name ?? 'Paket Foto' }}
                            </div>
                          </div>
                        </div>

                        <div class="d-flex flex-wrap gap-2">
                          <span class="badge bg-label-{{ $item['category_badge'] ?? 'secondary' }}">
                            {{ $item['category_label'] ?? '-' }}
                          </span>

                          <span class="badge bg-label-{{ $item['payment_badge'] ?? 'secondary' }}">
                            {{ $item['payment_label'] ?? '-' }}
                          </span>
                        </div>
                      </div>

                      <div class="booking-monitoring-meta">
                        <div class="booking-monitoring-meta-item">
                          <span class="booking-monitoring-meta-label">Tanggal</span>
                          <div class="booking-monitoring-meta-value">{{ $bookingDateLabel }}</div>
                        </div>

                        <div class="booking-monitoring-meta-item">
                          <span class="booking-monitoring-meta-label">Jam</span>
                          <div class="booking-monitoring-meta-value">{{ $startTime }} - {{ $endTime }}</div>
                        </div>

                        <div class="booking-monitoring-meta-item">
                          <span class="booking-monitoring-meta-label">Fotografer</span>
                          <div class="booking-monitoring-meta-value">
                            {{ $booking->photographerUser->name ?? $booking->photographer_name ?? 'Belum ditentukan' }}
                          </div>
                        </div>

                        <div class="booking-monitoring-meta-item">
                          <span class="booking-monitoring-meta-label">Lokasi</span>
                          <div class="booking-monitoring-meta-value">
                            {{ ucfirst($booking->location_type ?? '-') }} - {{ $booking->location_name ?: '-' }}
                          </div>
                        </div>
                      </div>

                      <div class="booking-progress-wrap">
                        <div class="booking-progress-head">
                          <span>Progress Tracking</span>
                          <span>{{ $progressPercent }}%</span>
                        </div>

                        <div class="booking-progress">
                          <div class="booking-progress-bar" style="width: {{ $progressPercent }}%;"></div>
                        </div>
                      </div>

                      <div class="booking-monitoring-footer">
                        <div class="booking-current-stage">
                          Status sekarang:
                          <strong>
                            {{ $currentTracking->stage_name ?? 'Tracking selesai / belum ada status aktif' }}
                          </strong>
                        </div>

                        <button type="button"
                          class="btn btn-primary"
                          data-bs-toggle="modal"
                          data-bs-target="#{{ $modalId }}">
                          <i class="bx bx-show me-1"></i>
                          Lihat Tracking
                        </button>
                      </div>
                    </div>
                  </div>

                  {{-- MODAL TRACKING READ ONLY --}}
                  <div class="modal fade booking-tracking-modal" id="{{ $modalId }}" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog modal-xl modal-dialog-scrollable">
                      <div class="modal-content">
                        <div class="modal-header">
                          <div>
                            <h5 class="modal-title">
                              Tracking Booking - {{ $booking->client_name ?: 'Klien' }}
                            </h5>
                            <small class="text-white opacity-75">
                              Admin hanya dapat memantau status tracking. Tidak ada aksi edit di halaman ini.
                            </small>
                          </div>

                          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>

                        <div class="modal-body">
                          <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-4">
                            <div>
                              <h5 class="mb-1">{{ $booking->package->name ?? 'Paket Foto' }}</h5>
                              <p class="text-muted mb-0">
                                {{ $bookingDateLabel }} • {{ $startTime }} - {{ $endTime }}
                              </p>
                            </div>

                            <span class="tracking-readonly-note">
                              <i class="bx bx-lock-alt"></i>
                              Mode Pantau Saja
                            </span>
                          </div>

                          <div class="admin-tracking-summary">
                            <div class="admin-tracking-summary-item">
                              <div class="admin-tracking-summary-label">Klien</div>
                              <div class="admin-tracking-summary-value">
                                {{ $booking->client_name ?: '-' }}
                                <br>
                                <span class="text-muted">{{ $booking->client_phone ?: '-' }}</span>
                              </div>
                            </div>

                            <div class="admin-tracking-summary-item">
                              <div class="admin-tracking-summary-label">Pembayaran</div>
                              <div class="admin-tracking-summary-value">
                                {{ $item['payment_label'] ?? '-' }}
                                <br>
                                <span class="text-muted">
                                  Dibayar Rp {{ number_format($booking->paid_booking_amount ?? 0, 0, ',', '.') }}
                                </span>
                              </div>
                            </div>

                            <div class="admin-tracking-summary-item">
                              <div class="admin-tracking-summary-label">Sisa Tagihan</div>
                              <div class="admin-tracking-summary-value">
                                Rp {{ number_format($booking->remaining_booking_amount ?? 0, 0, ',', '.') }}
                                <br>
                                <span class="text-muted">
                                  Total Rp {{ number_format($booking->total_booking_amount ?? 0, 0, ',', '.') }}
                                </span>
                              </div>
                            </div>

                            <div class="admin-tracking-summary-item">
                              <div class="admin-tracking-summary-label">Fotografer</div>
                              <div class="admin-tracking-summary-value">
                                {{ $booking->photographerUser->name ?? $booking->photographer_name ?? 'Belum ditentukan' }}
                              </div>
                            </div>

                            <div class="admin-tracking-summary-item">
                              <div class="admin-tracking-summary-label">Lokasi</div>
                              <div class="admin-tracking-summary-value">
                                {{ ucfirst($booking->location_type ?? '-') }}
                                <br>
                                <span class="text-muted">{{ $booking->location_name ?: '-' }}</span>
                              </div>
                            </div>

                            <div class="admin-tracking-summary-item">
                              <div class="admin-tracking-summary-label">Kategori</div>
                              <div class="admin-tracking-summary-value">
                                {{ $item['category_label'] ?? '-' }}
                              </div>
                            </div>
                          </div>

                          <div class="admin-tracking-timeline">
                            @forelse ($timeline as $tracking)
                              @php
                                $trackingStatusLabel = match ($tracking->status) {
                                  'done' => 'Selesai',
                                  'current' => 'Sedang Berjalan',
                                  'skipped' => 'Dilewati',
                                  default => 'Menunggu',
                                };

                                $trackingIcon = match ($tracking->status) {
                                  'done' => 'bx bx-check',
                                  'current' => 'bx bx-loader-circle',
                                  'skipped' => 'bx bx-minus',
                                  default => 'bx bx-time-five',
                                };

                                $trackingBadge = match ($tracking->status) {
                                  'done' => 'success',
                                  'current' => 'primary',
                                  'skipped' => 'secondary',
                                  default => 'warning',
                                };
                              @endphp

                              <div class="admin-tracking-step {{ $tracking->status }}">
                                <div class="admin-tracking-dot">
                                  <i class="{{ $trackingIcon }}"></i>
                                </div>

                                <div class="admin-tracking-box">
                                  <div class="d-flex justify-content-between align-items-start flex-wrap gap-2">
                                    <div>
                                      <div class="admin-tracking-step-title">
                                        {{ $tracking->stage_order }}. {{ $tracking->stage_name }}
                                      </div>

                                      <p class="admin-tracking-step-desc">
                                        {{ $tracking->description ?: 'Belum ada keterangan.' }}
                                      </p>
                                    </div>

                                    <span class="badge bg-label-{{ $trackingBadge }}">
                                      {{ $trackingStatusLabel }}
                                    </span>
                                  </div>

                                  @if ($tracking->occurred_at)
                                    <span class="admin-tracking-step-time">
                                      {{ $tracking->occurred_at->translatedFormat('d F Y H:i') }}
                                    </span>
                                  @endif
                                </div>
                              </div>
                            @empty
                              <div class="schedule-empty-state">
                                <i class="bx bx-time-five"></i>
                                <h6>Tracking belum tersedia</h6>
                                <p>Timeline tracking untuk booking ini belum dibuat.</p>
                              </div>
                            @endforelse
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
                @empty
                  <div class="col-12">
                    <div class="card section-card">
                      <div class="card-body">
                        <div class="schedule-empty-state">
                          <i class="bx bx-calendar-x"></i>
                          <h6>Tidak ada booking</h6>
                          <p>
                            Tidak ada booking pada kategori ini. Coba ubah filter kategori atau pencarian.
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                @endforelse
              </div>
            </div>
          </div>
        </div>

        {{-- TAB BOOKING MANUAL --}}
        <div class="tab-pane fade {{ $selectedTab === 'manual' ? 'show active' : '' }}" id="tab-manual" role="tabpanel">
          <div class="row g-4">
            <div class="col-xl-8 col-lg-7">
              <div class="card section-card schedule-index-card">
                <div class="card-header">
                  <div>
                    <h5 class="section-title">Tambah Booking Manual</h5>
                    <p class="section-subtitle mb-0">
                      Pilih paket dan tanggal dulu, lalu pilih jadwal, baru pilih fotografer yang tersedia.
                    </p>
                  </div>
                </div>

                <div class="card-body schedule-form-body">
                  <form
                    action="{{ route('admin.schedules.manual-request.store') }}"
                    method="POST"
                    id="manualBookingForm"
                    enctype="multipart/form-data">
                    @csrf

                    {{-- DATA PAKET --}}
                    <div class="manual-section">
                      <div class="manual-section-title">
                        <i class="bx bx-package"></i>
                        Data Paket
                      </div>

                      <div class="row g-3">
                        <div class="col-md-12">
                          <label class="form-label">Paket Foto</label>
                          <select name="package_id" id="packageSelect" class="form-select" required>
                            <option value="">Pilih Paket</option>
                            @foreach ($packages as $package)
                              <option
                                value="{{ $package->id }}"
                                data-duration="{{ $package->duration_minutes }}"
                                data-location="{{ strtolower(trim($package->location_type)) }}">
                                {{ $package->name }} ({{ $package->duration_minutes }} menit)
                              </option>
                            @endforeach
                          </select>
                        </div>

                        <div class="col-md-6">
                          <label class="form-label">Add-on Video Cinematic</label>
                          <select name="video_addon_type" id="videoAddonType" class="form-select">
                            <option value="">Tanpa add-on video</option>
                            @foreach (($videoAddons ?? []) as $addon)
                              @php
                                $addonKey = is_array($addon) ? ($addon['addon_key'] ?? $addon['key'] ?? null) : $addon->addon_key;
                                $addonName = is_array($addon) ? ($addon['addon_name'] ?? $addon['name'] ?? null) : $addon->addon_name;
                                $addonPrice = is_array($addon) ? ($addon['price'] ?? 0) : $addon->price;
                              @endphp

                              @if ($addonKey)
                                <option value="{{ $addonKey }}" data-price="{{ $addonPrice }}">
                                  {{ $addonName }} - Rp {{ number_format($addonPrice, 0, ',', '.') }}
                                </option>
                              @endif
                            @endforeach
                          </select>
                        </div>

                        <div class="col-md-6">
                          <label class="form-label">Extra Duration</label>
                          <select name="extra_duration_units" id="extraDurationUnits" class="form-select">
                            <option value="0">Tidak ada extra durasi</option>
                            <option value="1">+ 30 menit</option>
                            <option value="2">+ 60 menit</option>
                            <option value="3">+ 90 menit</option>
                            <option value="4">+ 120 menit</option>
                            <option value="5">+ 150 menit</option>
                          </select>
                          <small class="text-muted d-block mt-1">
                            Biaya Rp {{ number_format($extraDurationFee, 0, ',', '.') }} per {{ $extraDurationMinutes }} menit
                          </small>
                        </div>
                      </div>

                      <div class="summary-card mt-3">
                        <div>
                          <small>Durasi total</small>
                          <strong id="summaryDuration">-</strong>
                        </div>

                        <div>
                          <small>Biaya extra durasi</small>
                          <strong id="summaryExtraFee">Rp 0</strong>
                        </div>

                        <div>
                          <small>Biaya add-on video</small>
                          <strong id="summaryVideoFee">Rp 0</strong>
                        </div>
                      </div>
                    </div>

                    {{-- DATA KLIEN --}}
                    <div class="manual-section">
                      <div class="manual-section-title">
                        <i class="bx bx-user"></i>
                        Data Klien
                      </div>

                      <div class="row g-3">
                        <div class="col-12">
                          <label class="form-label">Email Klien</label>
                          <select name="client_user_id" id="clientSelect" class="form-select" required>
                            <option value="">Pilih Email Klien</option>
                            @foreach ($clients as $client)
                              <option
                                value="{{ $client->id }}"
                                data-name="{{ $client->name }}"
                                data-phone="{{ $client->phone }}">
                                {{ $client->email }}
                              </option>
                            @endforeach
                          </select>
                        </div>

                        <div class="col-md-6">
                          <label class="form-label">Nama Klien</label>
                          <input type="text" id="clientName" class="form-control" readonly>
                        </div>

                        <div class="col-md-6">
                          <label class="form-label">No. HP Klien</label>
                          <input type="text" id="clientPhone" class="form-control" readonly>
                        </div>
                      </div>
                    </div>

                    {{-- JADWAL --}}
                    <div class="manual-section">
                      <div class="manual-section-title">
                        <i class="bx bx-calendar"></i>
                        Jadwal
                      </div>

                      <div class="row g-3">
                        <div class="col-md-6">
                          <label class="form-label">Tanggal Booking</label>
                          <input type="date" name="booking_date" id="bookingDate" class="form-control" value="{{ $selectedDate }}" required>
                        </div>

                        <div class="col-md-6">
                          <label class="form-label">Pilih Fotografer yang Ready</label>
                          <select name="photographer_user_id" id="photographerSelect" class="form-select" required disabled>
                            <option value="">Pilih jadwal dulu</option>
                          </select>
                        </div>

                        <div class="col-12">
                          <label class="form-label">Pilih Jadwal Tersedia</label>
                          <input type="hidden" name="start_time" id="selectedStartTime" required>

                          <div id="slotButtons" class="slot-button-grid">
                            <div class="text-muted small">Pilih paket dan tanggal terlebih dahulu.</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {{-- LOKASI --}}
                    <div class="manual-section">
                      <div class="manual-section-title">
                        <i class="bx bx-map"></i>
                        Lokasi
                      </div>

                      <div class="row g-3">
                        <div class="col-md-6">
                          <label class="form-label">Tipe Lokasi</label>
                          <input type="text" id="locationTypeDisplay" class="form-control" readonly>
                        </div>

                        <div class="col-md-6" id="locationManualWrapper" style="display: none;">
                          <label class="form-label">Lokasi Foto</label>
                          <input
                            type="text"
                            name="location_name"
                            id="locationName"
                            class="form-control"
                            placeholder="Masukkan lokasi outdoor">
                        </div>

                        <div class="col-md-6" id="locationIndoorWrapper" style="display: none;">
                          <label class="form-label">Lokasi Foto</label>
                          <input type="text" class="form-control" value="Indoor Studio Monoframe" readonly>
                        </div>
                      </div>
                    </div>

                    {{-- MOODBOARD --}}
                    <div class="manual-section">
                      <div class="manual-section-title">
                        <i class="bx bx-image"></i>
                        Moodboard & Catatan
                      </div>

                      <div class="row g-3">
                        <div class="col-12">
                          <label class="form-label">Moodboard (Opsional, maksimal 10 file)</label>
                          <input
                            type="file"
                            name="moodboards[]"
                            id="moodboardsInput"
                            class="form-control"
                            accept=".jpg,.jpeg,.png,.webp"
                            multiple>
                          <div class="moodboard-helper" id="moodboardsInfo">
                            Upload referensi foto bila ada. Maksimal 10 file.
                          </div>
                        </div>

                        <div class="col-12">
                          <label class="form-label">Catatan</label>
                          <textarea name="notes" class="form-control" rows="4"></textarea>
                        </div>
                      </div>
                    </div>

                    <button type="submit" class="btn btn-primary w-100">
                      <i class="bx bx-save me-1"></i>
                      Simpan Booking Manual
                    </button>
                  </form>
                </div>
              </div>
            </div>

            {{-- GUIDE CARD --}}
            <div class="col-xl-4 col-lg-5">
              <div class="manual-guide-card">
                <div class="manual-guide-icon">
                  <i class="bx bx-info-circle"></i>
                </div>

                <h5>Cara Pakai Booking Manual</h5>
                <p>
                  Gunakan fitur ini untuk membantu admin membuat booking langsung dari server.
                </p>

                <ol>
                  <li>Pilih paket foto.</li>
                  <li>Pilih add-on video jika perlu.</li>
                  <li>Pilih jumlah extra duration.</li>
                  <li>Pilih klien.</li>
                  <li>Pilih tanggal booking.</li>
                  <li>Pilih jadwal yang tersedia.</li>
                  <li>Pilih fotografer yang ready.</li>
                  <li>Isi lokasi jika paket outdoor.</li>
                  <li>Upload moodboard bila ada.</li>
                  <li>Simpan booking.</li>
                </ol>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- MODAL DETAIL BOOKING --}}
  <div class="modal" id="dailyBookingDetailModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content border-0 shadow-lg schedule-detail-modal">
        <div class="modal-header border-0 pb-0">
          <h4 class="modal-title fw-bold" id="detailPackage">Detail Booking</h4>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body pt-3">
          <div class="schedule-detail-row">
            <div class="schedule-detail-icon">
              <i class="bx bx-time-five"></i>
            </div>
            <div>
              <div class="schedule-detail-label">Jadwal Foto</div>
              <div class="schedule-detail-value" id="detailTime">-</div>
              <div class="schedule-detail-subvalue" id="detailDate">-</div>
            </div>
          </div>

          <div class="schedule-detail-row">
            <div class="schedule-detail-icon">
              <i class="bx bx-map"></i>
            </div>
            <div>
              <div class="schedule-detail-label">Lokasi</div>
              <div class="schedule-detail-value" id="detailLocation">-</div>
              <div class="schedule-detail-subvalue" id="detailLocationType">-</div>
            </div>
          </div>

          <div class="schedule-detail-row">
            <div class="schedule-detail-icon">
              <i class="bx bx-user"></i>
            </div>
            <div>
              <div class="schedule-detail-label">Klien</div>
              <div class="schedule-detail-value" id="detailClient">-</div>
              <div class="schedule-detail-subvalue" id="detailPhone">-</div>
            </div>
          </div>

          <div class="schedule-detail-row">
            <div class="schedule-detail-icon">
              <i class="bx bx-camera"></i>
            </div>
            <div>
              <div class="schedule-detail-label">Fotografer</div>
              <div class="schedule-detail-value" id="detailPhotographer">-</div>
              <div class="schedule-detail-subvalue" id="detailDuration">-</div>
            </div>
          </div>

          <div class="schedule-detail-row mb-0">
            <div class="schedule-detail-icon">
              <i class="bx bx-note"></i>
            </div>
            <div>
              <div class="schedule-detail-label">Catatan</div>
              <div class="schedule-detail-value" id="detailNotes">-</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <style>
    .schedule-hero-card {
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

    .schedule-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .schedule-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .schedule-hero-icon {
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

    .schedule-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .schedule-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .schedule-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .schedule-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .schedule-hero-date {
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

    .schedule-hero-date i {
      font-size: 20px;
    }

    .schedule-stat-number {
      font-size: 30px !important;
    }

    .schedule-tabs-card {
      padding: 10px;
      border-radius: 26px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow-x: auto;
    }

    .schedule-tabs {
      display: flex;
      flex-wrap: nowrap;
      gap: 10px;
      min-width: max-content;
      border: 0;
    }

    .schedule-tabs .nav-link {
      border: 0 !important;
      border-radius: 18px !important;
      padding: 12px 18px;
      color: var(--mf-muted);
      font-weight: 800;
      display: inline-flex;
      align-items: center;
      white-space: nowrap;
      transition: 0.18s ease;
    }

    .schedule-tabs .nav-link:hover {
      background: var(--mf-primary-soft);
      color: var(--mf-primary);
    }

    .schedule-tabs .nav-link.active {
      color: #fff !important;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue)) !important;
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.24);
    }

    .schedule-tab-content {
      background: transparent !important;
      box-shadow: none !important;
      padding: 0 !important;
    }

    .schedule-index-card .card-header {
      padding: 30px 34px 22px !important;
    }

    .schedule-table-body,
    .schedule-form-body,
    .schedule-filter-body {
      padding: 26px 34px 30px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.14), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .schedule-table-wrap {
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      overflow: hidden;
      background: #ffffff;
    }

    .schedule-rule-table {
      width: 100%;
      min-width: 1650px;
      table-layout: auto;
      border-collapse: separate;
      border-spacing: 0;
    }

    .schedule-rule-table th {
      white-space: nowrap;
      font-size: 12px !important;
      color: #6e7f96 !important;
      text-align: center;
      font-weight: 900 !important;
    }

    .schedule-rule-table th,
    .schedule-rule-table td {
      vertical-align: middle;
      padding: 18px !important;
    }

    .rule-input,
    .rule-input-fee {
      width: 100%;
      min-width: 150px;
    }

    .rule-day {
      min-width: 120px;
      font-weight: 900;
      color: var(--mf-ink);
    }

    .rule-switch-wrap {
      min-width: 80px;
      text-align: center;
    }

    .group-divider-right {
      border-right: 2px solid #e6e9ef !important;
    }

    .group-divider-left {
      border-left: 2px solid #e6e9ef !important;
    }

    .schedule-action-footer {
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 22px;
    }

    .slot-button-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      padding: 18px;
      border: 1px dashed var(--mf-sky);
      border-radius: 22px;
      background: #ffffff;
    }

    .slot-btn {
      border: 1px solid var(--mf-border);
      background: #fff;
      color: var(--mf-muted);
      border-radius: 999px;
      padding: 11px 15px;
      font-size: 13px;
      font-weight: 800;
      transition: 0.18s ease;
      cursor: pointer;
    }

    .slot-btn:hover {
      border-color: rgba(88, 115, 220, 0.35);
      background: var(--mf-primary-soft);
      color: var(--mf-primary);
      transform: translateY(-2px);
    }

    .slot-btn.active {
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #fff;
      border-color: transparent;
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.24);
    }

    .schedule-photographer-card {
      border: 0;
      border-radius: 28px;
      overflow: hidden;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      transition: 0.22s ease;
    }

    .schedule-photographer-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 54px rgba(52, 79, 165, 0.16);
    }

    .schedule-photographer-header {
      padding: 22px 26px;
      border-bottom: 1px solid var(--mf-border);
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .schedule-photographer-main {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .schedule-photographer-avatar {
      width: 48px;
      height: 48px;
      border-radius: 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-weight: 900;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
    }

    .schedule-photographer-name {
      font-size: 18px;
      font-weight: 900;
      color: var(--mf-ink);
      margin-bottom: 2px;
    }

    .schedule-photographer-email {
      font-size: 13px;
      color: var(--mf-muted);
      font-weight: 600;
    }

    .schedule-booking-count {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 13px;
      font-weight: 900;
      border-radius: 999px;
      padding: 10px 14px;
    }

    .schedule-list {
      padding: 22px 26px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .schedule-event-row {
      display: grid;
      grid-template-columns: 138px 1fr;
      gap: 14px;
      align-items: stretch;
    }

    .schedule-time-pill {
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      padding: 12px 14px;
      background: #fff;
      color: var(--mf-ink);
      font-weight: 900;
      font-size: 13px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      box-shadow: var(--mf-shadow-soft);
    }

    .schedule-event-card {
      width: 100%;
      text-align: left;
      border: 0;
      border-radius: 20px;
      padding: 18px 20px;
      background: linear-gradient(135deg, var(--mf-deep), var(--mf-primary) 58%, var(--mf-blue));
      color: #fff;
      box-shadow: 0 16px 32px rgba(88, 115, 220, 0.18);
      transition: 0.2s ease;
      cursor: pointer;
    }

    .schedule-event-card:hover {
      transform: translateY(-3px);
      box-shadow: 0 22px 44px rgba(88, 115, 220, 0.28);
    }

    .schedule-event-title {
      font-size: 17px;
      font-weight: 900;
      margin-bottom: 6px;
      line-height: 1.35;
    }

    .schedule-event-meta {
      font-size: 13px;
      opacity: 0.96;
      line-height: 1.6;
      font-weight: 600;
    }

    .schedule-empty-state {
      padding: 42px 24px;
      color: var(--mf-muted);
      text-align: center;
      background: #fff;
    }

    .schedule-empty-state i {
      display: block;
      font-size: 48px;
      color: var(--mf-primary);
      margin-bottom: 12px;
    }

    .schedule-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .schedule-empty-state p {
      max-width: 460px;
      margin: 0 auto;
      line-height: 1.7;
      font-weight: 600;
    }

    .manual-section {
      margin-bottom: 32px;
    }

    .manual-section-title {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      color: var(--mf-ink);
      font-size: 15px;
      font-weight: 900;
      margin-bottom: 16px;
    }

    .manual-section-title i {
      color: var(--mf-primary);
      font-size: 19px;
    }

    .summary-card {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
    }

    .summary-card div {
      padding: 16px;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      background: #ffffff;
    }

    .summary-card small {
      display: block;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 800;
      margin-bottom: 5px;
    }

    .summary-card strong {
      color: var(--mf-ink);
      font-weight: 900;
      font-size: 14px;
    }

    .moodboard-helper {
      font-size: 12px;
      color: var(--mf-muted);
      margin-top: 6px;
      font-weight: 600;
    }

    .manual-guide-card {
      position: sticky;
      top: 105px;
      padding: 30px;
      border-radius: 30px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.22), transparent 38%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-shadow: var(--mf-shadow-soft);
    }

    .manual-guide-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      font-size: 28px;
      box-shadow: 0 16px 32px rgba(88, 115, 220, 0.22);
      margin-bottom: 18px;
    }

    .manual-guide-card h5 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 8px;
    }

    .manual-guide-card p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.7;
      margin-bottom: 18px;
    }

    .manual-guide-card ol {
      padding-left: 18px;
      margin-bottom: 0;
      color: var(--mf-ink);
      font-weight: 700;
      line-height: 1.8;
    }

    .schedule-detail-modal {
      border-radius: 28px !important;
      background: #fff !important;
      box-shadow: 0 30px 70px rgba(52, 79, 165, 0.22) !important;
    }

    .schedule-detail-row {
      display: grid;
      grid-template-columns: 46px 1fr;
      gap: 14px;
      align-items: start;
      margin-bottom: 20px;
    }

    .schedule-detail-icon {
      width: 46px;
      height: 46px;
      border-radius: 16px;
      background: rgba(88, 115, 220, 0.10);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: var(--mf-primary);
      font-size: 20px;
    }

    .schedule-detail-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: .04em;
      color: var(--mf-muted);
      font-weight: 900;
      margin-bottom: 3px;
    }

    .schedule-detail-value {
      font-size: 16px;
      font-weight: 900;
      color: var(--mf-ink);
      line-height: 1.5;
    }

    .schedule-detail-subvalue {
      font-size: 13px;
      color: var(--mf-muted);
      line-height: 1.6;
      font-weight: 600;
    }

    .booking-monitoring-filter {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }

    .booking-monitoring-filter .btn {
      min-height: 42px;
    }

    .booking-monitoring-card {
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background: #ffffff;
      padding: 22px;
      box-shadow: var(--mf-shadow-soft);
      transition: 0.22s ease;
    }

    .booking-monitoring-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 48px rgba(52, 79, 165, 0.16);
    }

    .booking-monitoring-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 14px;
      margin-bottom: 16px;
    }

    .booking-monitoring-client {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .booking-monitoring-avatar {
      width: 48px;
      height: 48px;
      border-radius: 17px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-weight: 900;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.2);
    }

    .booking-monitoring-name {
      font-weight: 900;
      color: var(--mf-ink);
      line-height: 1.25;
    }

    .booking-monitoring-package {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-top: 4px;
    }

    .booking-monitoring-meta {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 12px;
      margin-bottom: 16px;
    }

    .booking-monitoring-meta-item {
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      padding: 13px 14px;
      background: #f7fbfd;
    }

    .booking-monitoring-meta-label {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 4px;
    }

    .booking-monitoring-meta-value {
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 800;
      line-height: 1.45;
    }

    .booking-progress-wrap {
      margin-top: 14px;
    }

    .booking-progress-head {
      display: flex;
      justify-content: space-between;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 800;
      margin-bottom: 8px;
    }

    .booking-progress {
      height: 9px;
      border-radius: 999px;
      overflow: hidden;
      background: #edf3fb;
    }

    .booking-progress-bar {
      height: 100%;
      border-radius: 999px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
    }

    .booking-monitoring-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      margin-top: 18px;
    }

    .booking-current-stage {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
    }

    .tracking-readonly-note {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      border-radius: 999px;
      padding: 9px 13px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 12px;
      font-weight: 900;
    }

    .admin-tracking-summary {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
      margin-bottom: 22px;
    }

    .admin-tracking-summary-item {
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      padding: 14px;
      background: #ffffff;
    }

    .admin-tracking-summary-label {
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 5px;
    }

    .admin-tracking-summary-value {
      color: var(--mf-ink);
      font-size: 14px;
      font-weight: 900;
      line-height: 1.45;
    }

    .admin-tracking-timeline {
      position: relative;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }

    .admin-tracking-step {
      display: grid;
      grid-template-columns: 44px 1fr;
      gap: 14px;
      position: relative;
    }

    .admin-tracking-step:not(:last-child)::after {
      content: "";
      position: absolute;
      left: 21px;
      top: 44px;
      width: 2px;
      height: calc(100% - 20px);
      background: var(--mf-border);
    }

    .admin-tracking-dot {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: #edf3fb;
      color: var(--mf-muted);
      position: relative;
      z-index: 2;
    }

    .admin-tracking-step.done .admin-tracking-dot {
      background: rgba(47, 177, 140, 0.14);
      color: #167a64;
    }

    .admin-tracking-step.current .admin-tracking-dot {
      background: rgba(88, 115, 220, 0.14);
      color: var(--mf-primary);
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.15);
    }

    .admin-tracking-step.skipped .admin-tracking-dot {
      background: rgba(107, 124, 147, 0.14);
      color: #607086;
    }

    .admin-tracking-box {
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      padding: 15px 16px;
      background: #ffffff;
    }

    .admin-tracking-step-title {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 4px;
    }

    .admin-tracking-step-desc {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.65;
      margin-bottom: 0;
    }

    .admin-tracking-step-time {
      display: block;
      color: #526b7f;
      font-size: 12px;
      font-weight: 800;
      margin-top: 8px;
    }

    .modal-backdrop.show {
      opacity: 0.35 !important;
      z-index: 1050 !important;
    }

    #dailyBookingDetailModal {
      z-index: 1060 !important;
    }

    #dailyBookingDetailModal .modal-dialog {
      z-index: 1061 !important;
      position: relative;
    }

    .booking-tracking-modal {
      z-index: 1060 !important;
    }

    .booking-tracking-modal .modal-dialog {
      z-index: 1061 !important;
      position: relative;
    }

    @media (max-width: 991px) {
      .schedule-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .schedule-hero-actions,
      .schedule-hero-date {
        width: 100%;
      }

      .manual-guide-card {
        position: static;
      }

      .summary-card {
        grid-template-columns: 1fr;
      }

      .booking-monitoring-meta,
      .admin-tracking-summary {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }

    @media (max-width: 768px) {
      .schedule-hero-card {
        padding: 26px 22px;
      }

      .schedule-hero-left {
        flex-direction: column;
      }

      .schedule-hero-date {
        min-height: 50px;
      }

      .schedule-index-card .card-header,
      .schedule-table-body,
      .schedule-form-body,
      .schedule-filter-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .schedule-event-row {
        grid-template-columns: 1fr;
      }

      .schedule-time-pill {
        justify-content: flex-start;
      }

      .schedule-action-footer {
        justify-content: flex-start;
      }

      .booking-monitoring-meta,
      .admin-tracking-summary {
        grid-template-columns: 1fr;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      document.querySelectorAll('[data-schedule-tab]').forEach(tabButton => {
        tabButton.addEventListener('shown.bs.tab', function () {
          const tab = this.dataset.scheduleTab;
          const url = new URL(window.location.href);
          url.searchParams.set('tab', tab);
          history.replaceState({}, '', url.toString());
        });
      });

      const detailModalEl = document.getElementById('dailyBookingDetailModal');

      if (detailModalEl && detailModalEl.parentElement !== document.body) {
        document.body.appendChild(detailModalEl);
      }

      document.querySelectorAll('.booking-tracking-modal').forEach(modal => {
        if (modal.parentElement !== document.body) {
          document.body.appendChild(modal);
        }
      });

      document.addEventListener('click', function (e) {
        const button = e.target.closest('.js-booking-detail');
        if (!button) return;

        document.getElementById('detailPackage').textContent = button.dataset.package || '-';
        document.getElementById('detailTime').textContent = button.dataset.time || '-';
        document.getElementById('detailDate').textContent = button.dataset.date || '-';
        document.getElementById('detailLocation').textContent = button.dataset.location || '-';
        document.getElementById('detailLocationType').textContent = button.dataset.locationType || '-';
        document.getElementById('detailClient').textContent = button.dataset.client || '-';
        document.getElementById('detailPhone').textContent = button.dataset.phone || '-';
        document.getElementById('detailPhotographer').textContent = button.dataset.photographer || '-';
        document.getElementById('detailDuration').textContent = button.dataset.duration || '-';
        document.getElementById('detailNotes').textContent = button.dataset.notes || '-';

        const modal = new bootstrap.Modal(detailModalEl);
        modal.show();
      });

      const clientSelect = document.getElementById('clientSelect');
      const clientName = document.getElementById('clientName');
      const clientPhone = document.getElementById('clientPhone');

      const packageSelect = document.getElementById('packageSelect');
      const bookingDate = document.getElementById('bookingDate');
      const extraDurationUnits = document.getElementById('extraDurationUnits');
      const videoAddonType = document.getElementById('videoAddonType');
      const moodboardsInput = document.getElementById('moodboardsInput');
      const moodboardsInfo = document.getElementById('moodboardsInfo');

      const selectedStartTime = document.getElementById('selectedStartTime');
      const slotButtons = document.getElementById('slotButtons');

      const photographerSelect = document.getElementById('photographerSelect');

      const locationTypeDisplay = document.getElementById('locationTypeDisplay');
      const locationManualWrapper = document.getElementById('locationManualWrapper');
      const locationIndoorWrapper = document.getElementById('locationIndoorWrapper');
      const locationName = document.getElementById('locationName');

      const summaryDuration = document.getElementById('summaryDuration');
      const summaryExtraFee = document.getElementById('summaryExtraFee');
      const summaryVideoFee = document.getElementById('summaryVideoFee');

      const extraDurationStepMinutes = {{ (int) $extraDurationMinutes }};
      const extraDurationStepFee = {{ (int) $extraDurationFee }};

      function formatRupiah(value) {
        return 'Rp ' + Number(value || 0).toLocaleString('id-ID');
      }

      function populateClient() {
        if (!clientSelect || !clientName || !clientPhone) return;

        const selected = clientSelect.options[clientSelect.selectedIndex];

        clientName.value = selected?.dataset?.name || '';
        clientPhone.value = selected?.dataset?.phone || '';
      }

      function updateMoodboardInfo() {
        if (!moodboardsInput || !moodboardsInfo) return;

        const totalFiles = moodboardsInput.files ? moodboardsInput.files.length : 0;

        if (totalFiles > 10) {
          moodboardsInfo.textContent = 'File melebihi batas maksimal 10. Silakan kurangi jumlah file.';
          moodboardsInfo.classList.add('text-danger');
        } else if (totalFiles > 0) {
          moodboardsInfo.textContent = `${totalFiles} file dipilih. Maksimal 10 file.`;
          moodboardsInfo.classList.remove('text-danger');
        } else {
          moodboardsInfo.textContent = 'Upload referensi foto bila ada. Maksimal 10 file.';
          moodboardsInfo.classList.remove('text-danger');
        }
      }

      function handlePackageLocation() {
        if (!packageSelect || !summaryDuration || !summaryExtraFee || !summaryVideoFee) return;

        const selected = packageSelect.options[packageSelect.selectedIndex];
        const duration = parseInt(selected?.dataset?.duration || '0', 10);
        const rawLocation = (selected?.dataset?.location || '').toLowerCase().trim();
        const extraUnits = parseInt(extraDurationUnits?.value || '0', 10);
        const extra = extraUnits * extraDurationStepMinutes;
        const totalDuration = duration + extra;

        const selectedVideoOption = videoAddonType?.options?.[videoAddonType.selectedIndex];
        const videoFee = parseInt(selectedVideoOption?.dataset?.price || '0', 10);

        summaryDuration.textContent = totalDuration > 0 ? totalDuration + ' menit' : '-';
        summaryExtraFee.textContent = formatRupiah(extraUnits * extraDurationStepFee);
        summaryVideoFee.textContent = formatRupiah(videoFee);

        let locationType = '';

        if (rawLocation.includes('outdoor')) {
          locationType = 'outdoor';
        } else if (rawLocation.includes('indoor')) {
          locationType = 'indoor';
        }

        if (locationTypeDisplay) {
          locationTypeDisplay.value = locationType ? locationType.toUpperCase() : '';
        }

        if (locationType === 'indoor') {
          if (locationIndoorWrapper) locationIndoorWrapper.style.display = 'block';
          if (locationManualWrapper) locationManualWrapper.style.display = 'none';

          if (locationName) {
            locationName.value = '';
          }
        } else if (locationType === 'outdoor') {
          if (locationIndoorWrapper) locationIndoorWrapper.style.display = 'none';
          if (locationManualWrapper) locationManualWrapper.style.display = 'block';
        } else {
          if (locationIndoorWrapper) locationIndoorWrapper.style.display = 'none';
          if (locationManualWrapper) locationManualWrapper.style.display = 'none';
        }
      }

      function resetPhotographers() {
        if (!photographerSelect) return;

        photographerSelect.innerHTML = '<option value="">Pilih jadwal dulu</option>';
        photographerSelect.disabled = true;
      }

      function resetSlotSelection() {
        if (selectedStartTime) {
          selectedStartTime.value = '';
        }

        resetPhotographers();
      }

      function renderSlotButtons(slots) {
        if (!slotButtons) return;

        slotButtons.innerHTML = '';
        resetSlotSelection();

        if (!slots.length) {
          slotButtons.innerHTML = '<div class="text-muted small">Tidak ada jadwal kosong untuk pilihan ini.</div>';
          return;
        }

        slots.forEach(slot => {
          const btn = document.createElement('button');

          btn.type = 'button';
          btn.className = 'slot-btn';

          const suffix = slot.remaining_capacity === null
            ? `ready ${slot.ready_photographers_count} fotografer`
            : `sisa indoor ${slot.remaining_capacity} | ready ${slot.ready_photographers_count} fotografer`;

          btn.textContent = `${slot.label} | ${suffix}`;

          btn.addEventListener('click', function () {
            document.querySelectorAll('.slot-btn').forEach(el => el.classList.remove('active'));
            btn.classList.add('active');

            selectedStartTime.value = slot.start_time;
            loadAvailablePhotographers();
          });

          slotButtons.appendChild(btn);
        });
      }

      async function loadAvailableSlots() {
        if (!slotButtons || !packageSelect || !bookingDate) return;

        const packageId = packageSelect.value;
        const date = bookingDate.value;
        const extraUnits = extraDurationUnits?.value || 0;

        slotButtons.innerHTML = '<div class="text-muted small">Memuat jadwal...</div>';
        resetSlotSelection();

        if (!packageId || !date) {
          slotButtons.innerHTML = '<div class="text-muted small">Pilih paket dan tanggal terlebih dahulu.</div>';
          return;
        }

        try {
          const params = new URLSearchParams({
            package_id: packageId,
            booking_date: date,
            extra_duration_units: extraUnits
          });

          const response = await fetch(`{{ route('admin.schedules.available-slots') }}?${params.toString()}`);
          const data = await response.json();

          renderSlotButtons(data);
        } catch (error) {
          slotButtons.innerHTML = '<div class="text-danger small">Gagal memuat jadwal tersedia.</div>';
        }
      }

      async function loadAvailablePhotographers() {
        if (!photographerSelect || !packageSelect || !bookingDate || !selectedStartTime.value) return;

        const packageId = packageSelect.value;
        const date = bookingDate.value;
        const startTime = selectedStartTime.value;
        const extraUnits = extraDurationUnits?.value || 0;

        photographerSelect.disabled = true;
        photographerSelect.innerHTML = '<option value="">Memuat fotografer...</option>';

        try {
          const params = new URLSearchParams({
            package_id: packageId,
            booking_date: date,
            start_time: startTime,
            extra_duration_units: extraUnits
          });

          const response = await fetch(`{{ route('admin.schedules.available-photographers') }}?${params.toString()}`);
          const data = await response.json();

          photographerSelect.innerHTML = '';

          if (!data.length) {
            photographerSelect.innerHTML = '<option value="">Tidak ada fotografer yang ready</option>';
            photographerSelect.disabled = true;
            return;
          }

          photographerSelect.innerHTML = '<option value="">Pilih Fotografer</option>';

          data.forEach(item => {
            const option = document.createElement('option');

            option.value = item.id;
            option.textContent = `${item.name} - ${item.email}`;

            photographerSelect.appendChild(option);
          });

          photographerSelect.disabled = false;
        } catch (error) {
          photographerSelect.innerHTML = '<option value="">Gagal memuat fotografer</option>';
          photographerSelect.disabled = true;
        }
      }

      if (clientSelect) {
        clientSelect.addEventListener('change', populateClient);
      }

      if (packageSelect) {
        packageSelect.addEventListener('change', function () {
          handlePackageLocation();
          loadAvailableSlots();
        });
      }

      if (bookingDate) {
        bookingDate.addEventListener('change', loadAvailableSlots);
      }

      if (extraDurationUnits) {
        extraDurationUnits.addEventListener('change', function () {
          handlePackageLocation();
          loadAvailableSlots();
        });
      }

      if (videoAddonType) {
        videoAddonType.addEventListener('change', handlePackageLocation);
      }

      if (moodboardsInput) {
        moodboardsInput.addEventListener('change', updateMoodboardInfo);
      }

      const manualBookingForm = document.getElementById('manualBookingForm');

      if (manualBookingForm) {
        manualBookingForm.addEventListener('submit', function (e) {
          const totalFiles = moodboardsInput?.files?.length || 0;

          if (totalFiles > 10) {
            e.preventDefault();
            alert('Moodboard maksimal 10 file.');
          }
        });
      }

      populateClient();
      handlePackageLocation();
      updateMoodboardInfo();
      loadAvailableSlots();
    });
  </script>
@endsection