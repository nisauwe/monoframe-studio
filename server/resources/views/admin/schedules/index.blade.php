@extends('layouts/contentNavbarLayout')

@section('title', 'Jadwal & Slot')

@section('content')
  <style>
    .slot-button-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }

    .slot-btn {
      border: 1px solid #d9dee3;
      background: #fff;
      color: #566a7f;
      border-radius: 12px;
      padding: 10px 14px;
      font-size: 13px;
      font-weight: 600;
      transition: all 0.2s ease;
      cursor: pointer;
    }

    .slot-btn:hover {
      border-color: #696cff;
      color: #696cff;
    }

    .slot-btn.active {
      background: #696cff;
      color: #fff;
      border-color: #696cff;
    }

    .daily-toolbar-card {
      border: 1px solid #eceef1;
      border-radius: 16px;
      padding: 16px;
      background: #fff;
    }

    .schedule-rule-table {
      width: 100%;
      min-width: 1650px;
      table-layout: auto;
      border-collapse: separate;
      border-spacing: 0;
    }

    .schedule-rule-table th,
    .schedule-rule-table td {
      vertical-align: middle;
    }

    .schedule-rule-table th {
      white-space: nowrap;
      font-size: 13px;
      color: #566a7f;
      text-align: center;
    }

    .rule-input,
    .rule-input-fee {
      width: 100%;
      min-width: 150px;
    }

    .rule-day {
      min-width: 120px;
      font-weight: 600;
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

    .board-legend {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }

    .board-legend-item {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: #566a7f;
    }

    .board-legend-dot {
      width: 12px;
      height: 12px;
      border-radius: 999px;
      display: inline-block;
    }

    .dot-available {
      background: #f5f5f9;
      border: 1px solid #d9dee3;
    }

    .dot-booking {
      background: #e7f1ff;
      border: 1px solid #cfe2ff;
    }

    .dot-buffer {
      background: #fff4e5;
      border: 1px solid #ffe0a3;
    }

    .booking-list-card {
      border: 1px solid #eceef1;
      border-radius: 16px;
      padding: 14px;
      margin-bottom: 14px;
      background: #fff;
    }

    .booking-list-title {
      font-weight: 700;
      color: #384551;
    }

    .booking-list-meta {
      font-size: 12px;
      color: #8592a3;
      line-height: 1.6;
    }

    .gcal-photographer-card {
      border: 1px solid #eceef1;
      border-radius: 20px;
      overflow: hidden;
      background: #fff;
    }

    .gcal-photographer-header {
      padding: 18px 20px;
      border-bottom: 1px solid #eceef1;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .gcal-photographer-name {
      font-size: 18px;
      font-weight: 700;
      color: #384551;
      margin-bottom: 2px;
    }

    .gcal-photographer-email {
      font-size: 13px;
      color: #8592a3;
    }

    .gcal-booking-count {
      background: #f5f5f9;
      color: #566a7f;
      font-size: 12px;
      font-weight: 600;
      border-radius: 999px;
      padding: 8px 12px;
    }

    .gcal-schedule-list {
      padding: 18px 20px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }

    .gcal-event-row {
      display: grid;
      grid-template-columns: 120px 1fr;
      gap: 14px;
      align-items: stretch;
    }

    .gcal-time-pill {
      border: 1px solid #d9dee3;
      border-radius: 14px;
      padding: 12px 14px;
      background: #f8f9fb;
      color: #384551;
      font-weight: 700;
      font-size: 13px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
    }

    .gcal-event-card {
      width: 100%;
      text-align: left;
      border: 0;
      border-radius: 16px;
      padding: 16px 18px;
      background: linear-gradient(135deg, #7c83fd 0%, #6977e3 100%);
      color: #fff;
      box-shadow: 0 8px 18px rgba(105, 119, 227, 0.18);
      transition: all 0.2s ease;
      cursor: pointer;
    }

    .gcal-event-card:hover {
      transform: translateY(-1px);
      box-shadow: 0 12px 22px rgba(105, 119, 227, 0.24);
    }

    .gcal-event-title {
      font-size: 17px;
      font-weight: 700;
      margin-bottom: 6px;
      line-height: 1.35;
    }

    .gcal-event-meta {
      font-size: 13px;
      opacity: 0.96;
      line-height: 1.6;
    }

    .gcal-empty-state {
      padding: 24px 20px;
      color: #8592a3;
      text-align: center;
      font-size: 14px;
    }

    .gcal-detail-icon {
      width: 42px;
      height: 42px;
      border-radius: 12px;
      background: #f5f5f9;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: #6977e3;
      font-size: 18px;
    }

    .gcal-detail-row {
      display: grid;
      grid-template-columns: 42px 1fr;
      gap: 14px;
      align-items: start;
      margin-bottom: 18px;
    }

    .gcal-detail-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: .04em;
      color: #8592a3;
      margin-bottom: 3px;
    }

    .gcal-detail-value {
      font-size: 16px;
      font-weight: 600;
      color: #384551;
      line-height: 1.5;
    }

    .gcal-detail-subvalue {
      font-size: 13px;
      color: #8592a3;
      line-height: 1.6;
    }

    .addon-setting-card {
      border: 1px solid #eceef1;
      border-radius: 18px;
      background: #fff;
    }

    .manual-section-title {
      font-size: 15px;
      font-weight: 700;
      color: #384551;
      margin-bottom: 12px;
    }

    .moodboard-helper {
      font-size: 12px;
      color: #8592a3;
      margin-top: 6px;
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

    #dailyBookingDetailModal .modal-content {
      background: #fff !important;
      opacity: 1 !important;
      box-shadow: 0 18px 50px rgba(0, 0, 0, 0.18) !important;
      border-radius: 24px !important;
      border: none !important;
    }

    @media (max-width: 768px) {
      .gcal-event-row {
        grid-template-columns: 1fr;
      }

      .gcal-time-pill {
        justify-content: flex-start;
      }
    }
  </style>

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Jadwal & Slot</h4>
        <p class="text-muted mb-0">
          Kelola operasional indoor dan outdoor, pantau jadwal harian, dan input booking manual.
        </p>
      </div>
    </div>

    @if (session('success'))
      <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    @if ($errors->any())
      <div class="alert alert-danger">
        <ul class="mb-0 ps-3">
          @foreach ($errors->all() as $error)
            <li>{{ $error }}</li>
          @endforeach
        </ul>
      </div>
    @endif

    <div class="row mb-4">
      <div class="col-md-3 mb-3 mb-md-0">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Hari Aktif</span>
            <h3 class="mb-1">{{ $activeDays }}</h3>
            <small class="text-success fw-semibold">Hari operasional aktif</small>
          </div>
        </div>
      </div>

      <div class="col-md-3 mb-3 mb-md-0">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Slot Jadwal Hari Ini</span>
            <h3 class="mb-1">{{ $totalSlotsToday }}</h3>
            <small class="text-primary fw-semibold">Jumlah slot waktu pada tanggal terpilih</small>
          </div>
        </div>
      </div>

      <div class="col-md-3 mb-3 mb-md-0">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Sesi Terbooking</span>
            <h3 class="mb-1">{{ $bookedSessionsToday }}</h3>
            <small class="text-danger fw-semibold">Booking masuk pada tanggal ini</small>
          </div>
        </div>
      </div>

      <div class="col-md-3">
        <div class="card">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Extra Duration</span>
            <h3 class="mb-1">{{ $extraDurationMinutes }} Menit</h3>
            <small class="text-warning fw-semibold">
              Biaya Rp {{ number_format($extraDurationFee, 0, ',', '.') }}
            </small>
          </div>
        </div>
      </div>
    </div>

    <div class="nav-align-top">
      <ul class="nav nav-tabs" role="tablist">
        <li class="nav-item">
          <button type="button"
            class="nav-link {{ $selectedTab === 'operational' ? 'active' : '' }}"
            data-bs-toggle="tab"
            data-bs-target="#tab-operational"
            data-schedule-tab="operational">
            Operasional
          </button>
        </li>

        <li class="nav-item">
          <button type="button"
            class="nav-link {{ $selectedTab === 'daily' ? 'active' : '' }}"
            data-bs-toggle="tab"
            data-bs-target="#tab-daily"
            data-schedule-tab="daily">
            Jadwal Harian
          </button>
        </li>

        <li class="nav-item">
          <button type="button"
            class="nav-link {{ $selectedTab === 'manual' ? 'active' : '' }}"
            data-bs-toggle="tab"
            data-bs-target="#tab-manual"
            data-schedule-tab="manual">
            Booking Manual
          </button>
        </li>
      </ul>

      <div class="tab-content">
        {{-- TAB OPERASIONAL --}}
        <div class="tab-pane fade {{ $selectedTab === 'operational' ? 'show active' : '' }}" id="tab-operational">
          <div class="card mb-4">
            <div class="card-header">
              <h5 class="mb-0">Operasional Indoor & Outdoor</h5>
              <small class="text-muted">
                Indoor dan outdoor diatur terpisah, tapi tetap memakai resource fotografer yang sama.
              </small>
            </div>

            <div class="card-body">
              <form action="{{ route('admin.schedules.rules.update') }}" method="POST">
                @csrf
                @method('PUT')

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
                              <input class="form-check-input"
                                type="checkbox"
                                name="rules[{{ $index }}][is_active]"
                                value="1"
                                {{ $rule->is_active ? 'checked' : '' }}>
                            </div>
                          </td>

                          <td>
                            <input type="time"
                              name="rules[{{ $index }}][indoor_open_time]"
                              class="form-control rule-input"
                              value="{{ $rule->indoor_open_time }}">
                          </td>

                          <td>
                            <input type="time"
                              name="rules[{{ $index }}][indoor_close_time]"
                              class="form-control rule-input"
                              value="{{ $rule->indoor_close_time }}">
                          </td>

                          <td>
                            <input type="number"
                              name="rules[{{ $index }}][indoor_capacity]"
                              class="form-control rule-input"
                              value="{{ $rule->indoor_capacity }}">
                          </td>

                          <td class="group-divider-right">
                            <input type="number"
                              name="rules[{{ $index }}][indoor_buffer_minutes]"
                              class="form-control rule-input"
                              value="{{ $rule->indoor_buffer_minutes }}">
                          </td>

                          <td>
                            <input type="time"
                              name="rules[{{ $index }}][outdoor_open_time]"
                              class="form-control rule-input"
                              value="{{ $rule->outdoor_open_time }}">
                          </td>

                          <td>
                            <input type="time"
                              name="rules[{{ $index }}][outdoor_close_time]"
                              class="form-control rule-input"
                              value="{{ $rule->outdoor_close_time }}">
                          </td>

                          <td class="group-divider-right">
                            <input type="number"
                              name="rules[{{ $index }}][outdoor_buffer_minutes]"
                              class="form-control rule-input"
                              value="{{ $rule->outdoor_buffer_minutes }}">
                          </td>

                          <td>
                            <input type="number"
                              name="rules[{{ $index }}][extra_duration_minutes]"
                              class="form-control rule-input"
                              value="{{ $rule->extra_duration_minutes }}">
                          </td>

                          <td>
                            <input type="number"
                              name="rules[{{ $index }}][extra_duration_fee]"
                              class="form-control rule-input-fee"
                              value="{{ $rule->extra_duration_fee }}">
                          </td>
                        </tr>
                      @endforeach
                    </tbody>
                  </table>
                </div>

                <div class="d-flex justify-content-end mt-3">
                  <button type="submit" class="btn btn-primary">
                    <i class="bx bx-save me-1"></i> Simpan Pengaturan
                  </button>
                </div>
              </form>
            </div>
          </div>

          <div class="card addon-setting-card">
            <div class="card-header">
              <h5 class="mb-0">Pengaturan Add-on Video Cinematic</h5>
              <small class="text-muted">Harga add-on ini akan dipakai pada booking client dan booking manual.</small>
            </div>
            <div class="card-body">
              <form action="{{ route('admin.schedules.addon-settings.update') }}" method="POST">
                @csrf
                @method('PUT')

                @php
                  $iphoneAddon = collect($videoAddons ?? [])->firstWhere('addon_key', 'iphone');
                  $cameraAddon = collect($videoAddons ?? [])->firstWhere('addon_key', 'camera');
                @endphp

                <div class="row">
                  <div class="col-md-6 mb-3">
                    <label class="form-label">Video Cinematic - iPhone</label>
                    <input type="number"
                      name="addons[iphone][price]"
                      class="form-control"
                      value="{{ $iphoneAddon['price'] ?? $iphoneAddon->price ?? 0 }}"
                      min="0">
                  </div>

                  <div class="col-md-6 mb-3">
                    <label class="form-label">Video Cinematic - Camera</label>
                    <input type="number"
                      name="addons[camera][price]"
                      class="form-control"
                      value="{{ $cameraAddon['price'] ?? $cameraAddon->price ?? 0 }}"
                      min="0">
                  </div>
                </div>

                <div class="d-flex justify-content-end">
                  <button type="submit" class="btn btn-outline-primary">
                    Simpan Harga Add-on
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>

        {{-- TAB JADWAL HARIAN --}}
        <div class="tab-pane fade {{ $selectedTab === 'daily' ? 'show active' : '' }}" id="tab-daily">
          <div class="daily-toolbar-card mb-4">
            <form method="GET" action="{{ route('admin.schedules.index') }}" class="row g-3 align-items-end">
              <input type="hidden" name="tab" value="daily">

              <div class="col-md-4">
                <label class="form-label">Pilih Tanggal</label>
                <input type="date" name="date" class="form-control" value="{{ $selectedDate }}">
              </div>

              <div class="col-md-3">
                <button type="submit" class="btn btn-primary w-100">
                  Tampilkan Jadwal
                </button>
              </div>
            </form>
          </div>

          <div class="row">
            <div class="col-12 mb-4">
              <div class="row g-4">
                @forelse ($photographers as $photographer)
                  @php
                    $photographerBookings = $dayBookings
                        ->where('photographer_user_id', $photographer->id)
                        ->sortBy('start_time')
                        ->values();
                  @endphp

                  <div class="col-12">
                    <div class="gcal-photographer-card">
                      <div class="gcal-photographer-header">
                        <div>
                          <div class="gcal-photographer-name">{{ $photographer->name }}</div>
                          <div class="gcal-photographer-email">{{ $photographer->email }}</div>
                        </div>

                        <div class="gcal-booking-count">
                          {{ $photographerBookings->count() }} booking
                        </div>
                      </div>

                      @if ($photographerBookings->count())
                        <div class="gcal-schedule-list">
                          @foreach ($photographerBookings as $booking)
                            @php
                              $start = \Carbon\Carbon::parse($booking->start_time)->format('H:i');
                              $end = \Carbon\Carbon::parse($booking->end_time)->format('H:i');
                              $duration =
                                  (int) ($booking->duration_minutes ?? 0) +
                                  (int) ($booking->extra_duration_minutes ?? 0);
                            @endphp

                            <div class="gcal-event-row">
                              <div class="gcal-time-pill">
                                {{ $start }} - {{ $end }}
                              </div>

                              <button type="button"
                                class="gcal-event-card js-booking-detail"
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
                                <div class="gcal-event-title">
                                  {{ $booking->package->name ?? 'Paket Foto' }}
                                </div>
                                <div class="gcal-event-meta">
                                  {{ $booking->client_name }} • {{ ucfirst($booking->location_type ?? '-') }} •
                                  {{ $booking->location_name ?: '-' }}
                                </div>
                              </button>
                            </div>
                          @endforeach
                        </div>
                      @else
                        <div class="gcal-empty-state">
                          Belum ada booking untuk fotografer ini pada tanggal
                          {{ \Carbon\Carbon::parse($selectedDate)->translatedFormat('d F Y') }}.
                        </div>
                      @endif
                    </div>
                  </div>
                @empty
                  <div class="col-12">
                    <div class="card">
                      <div class="card-body text-center text-muted py-4">
                        Belum ada fotografer aktif.
                      </div>
                    </div>
                  </div>
                @endforelse
              </div>
            </div>
          </div>
        </div>

        {{-- TAB BOOKING MANUAL --}}
        <div class="tab-pane fade {{ $selectedTab === 'manual' ? 'show active' : '' }}" id="tab-manual">
          <div class="row">
            <div class="col-lg-8 mb-4">
              <div class="card">
                <div class="card-header">
                  <h5 class="mb-0">Tambah Booking Manual</h5>
                  <small class="text-muted">
                    Pilih paket dan tanggal dulu, lalu pilih jadwal, baru pilih fotografer yang tersedia.
                  </small>
                </div>

                <div class="card-body">
                  <form action="{{ route('admin.schedules.manual-request.store') }}"
                    method="POST"
                    id="manualBookingForm"
                    enctype="multipart/form-data">
                    @csrf

                    <div class="manual-section-title">Data Paket</div>

                    <div class="mb-3">
                      <label class="form-label">Paket Foto</label>
                      <select name="package_id" id="packageSelect" class="form-select" required>
                        <option value="">Pilih Paket</option>
                        @foreach ($packages as $package)
                          <option value="{{ $package->id }}"
                            data-duration="{{ $package->duration_minutes }}"
                            data-location="{{ strtolower(trim($package->location_type)) }}">
                            {{ $package->name }} ({{ $package->duration_minutes }} menit)
                          </option>
                        @endforeach
                      </select>
                    </div>

                    <div class="mb-3">
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

                    <div class="mb-3">
                      <label class="form-label">Extra Duration</label>
                      <select name="extra_duration_units" id="extraDurationUnits" class="form-select">
                        <option value="0">Tidak ada extra durasi</option>
                        <option value="1">+ 30 menit</option>
                        <option value="2">+ 60 menit</option>
                        <option value="3">+ 90 menit</option>
                        <option value="4">+ 120 menit</option>
                        <option value="5">+ 150 menit</option>
                      </select>
                      <small class="text-muted">
                        Biaya Rp {{ number_format($extraDurationFee, 0, ',', '.') }} per {{ $extraDurationMinutes }} menit
                      </small>
                    </div>

                    <div class="alert alert-light border mb-4">
                      <div><strong>Ringkasan Otomatis</strong></div>
                      <small class="d-block">Durasi total: <span id="summaryDuration">-</span></small>
                      <small class="d-block">Biaya extra durasi: <span id="summaryExtraFee">Rp 0</span></small>
                      <small class="d-block">Biaya add-on video: <span id="summaryVideoFee">Rp 0</span></small>
                    </div>

                    <div class="manual-section-title">Data Klien</div>

                    <div class="mb-3">
                      <label class="form-label">Email Klien</label>
                      <select name="client_user_id" id="clientSelect" class="form-select" required>
                        <option value="">Pilih Email Klien</option>
                        @foreach ($clients as $client)
                          <option value="{{ $client->id }}"
                            data-name="{{ $client->name }}"
                            data-phone="{{ $client->phone }}">
                            {{ $client->email }}
                          </option>
                        @endforeach
                      </select>
                    </div>

                    <div class="row">
                      <div class="col-md-6 mb-3">
                        <label class="form-label">Nama Klien</label>
                        <input type="text" id="clientName" class="form-control" readonly>
                      </div>

                      <div class="col-md-6 mb-3">
                        <label class="form-label">No. HP Klien</label>
                        <input type="text" id="clientPhone" class="form-control" readonly>
                      </div>
                    </div>

                    <div class="manual-section-title">Jadwal</div>

                    <div class="mb-3">
                      <label class="form-label">Tanggal Booking</label>
                      <input type="date" name="booking_date" id="bookingDate" class="form-control" value="{{ $selectedDate }}" required>
                    </div>

                    <div class="mb-3">
                      <label class="form-label">Pilih Jadwal Tersedia</label>
                      <input type="hidden" name="start_time" id="selectedStartTime" required>

                      <div id="slotButtons" class="slot-button-grid">
                        <div class="text-muted small">Pilih paket dan tanggal terlebih dahulu.</div>
                      </div>
                    </div>

                    <div class="mb-3">
                      <label class="form-label">Pilih Fotografer yang Ready</label>
                      <select name="photographer_user_id" id="photographerSelect" class="form-select" required disabled>
                        <option value="">Pilih jadwal dulu</option>
                      </select>
                    </div>

                    <div class="manual-section-title">Lokasi</div>

                    <div class="mb-3">
                      <label class="form-label">Tipe Lokasi</label>
                      <input type="text" id="locationTypeDisplay" class="form-control" readonly>
                    </div>

                    <div class="mb-3" id="locationManualWrapper" style="display: none;">
                      <label class="form-label">Lokasi Foto</label>
                      <input type="text" name="location_name" id="locationName" class="form-control"
                        placeholder="Masukkan lokasi outdoor">
                    </div>

                    <div class="mb-3" id="locationIndoorWrapper" style="display: none;">
                      <label class="form-label">Lokasi Foto</label>
                      <input type="text" class="form-control" value="Indoor Studio Monoframe" readonly>
                    </div>

                    <div class="manual-section-title">Moodboard & Catatan</div>

                    <div class="mb-3">
                      <label class="form-label">Moodboard (Opsional, maksimal 10 file)</label>
                      <input type="file"
                        name="moodboards[]"
                        id="moodboardsInput"
                        class="form-control"
                        accept=".jpg,.jpeg,.png,.webp"
                        multiple>
                      <div class="moodboard-helper" id="moodboardsInfo">
                        Upload referensi foto bila ada. Maksimal 10 file.
                      </div>
                    </div>

                    <div class="mb-3">
                      <label class="form-label">Catatan</label>
                      <textarea name="notes" class="form-control" rows="3"></textarea>
                    </div>

                    <button type="submit" class="btn btn-primary w-100">
                      Simpan Booking Manual
                    </button>
                  </form>
                </div>
              </div>
            </div>

            <div class="col-lg-4 mb-4">
              <div class="card">
                <div class="card-header">
                  <h5 class="mb-0">Cara Pakai Booking Manual</h5>
                </div>
                <div class="card-body">
                  <ol class="ps-3 mb-0">
                    <li class="mb-2">Pilih paket foto.</li>
                    <li class="mb-2">Pilih add-on video jika perlu.</li>
                    <li class="mb-2">Pilih jumlah extra duration.</li>
                    <li class="mb-2">Pilih klien.</li>
                    <li class="mb-2">Pilih tanggal booking.</li>
                    <li class="mb-2">Pilih jadwal yang tersedia.</li>
                    <li class="mb-2">Pilih fotografer yang ready di jadwal tersebut.</li>
                    <li class="mb-2">Kalau paket outdoor, isi lokasi manual.</li>
                    <li class="mb-2">Upload moodboard bila ada referensi.</li>
                    <li>Simpan booking.</li>
                  </ol>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>{{-- tab-content --}}
    </div>{{-- nav-align-top --}}
  </div>

  {{-- MODAL DETAIL BOOKING --}}
  <div class="modal" id="dailyBookingDetailModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content border-0 shadow-lg" style="border-radius: 24px;">
        <div class="modal-header border-0 pb-0">
          <h4 class="modal-title fw-bold" id="detailPackage">Detail Booking</h4>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body pt-3">
          <div class="gcal-detail-row">
            <div class="gcal-detail-icon">
              <i class="bx bx-time-five"></i>
            </div>
            <div>
              <div class="gcal-detail-label">Jadwal Foto</div>
              <div class="gcal-detail-value" id="detailTime">-</div>
              <div class="gcal-detail-subvalue" id="detailDate">-</div>
            </div>
          </div>

          <div class="gcal-detail-row">
            <div class="gcal-detail-icon">
              <i class="bx bx-map"></i>
            </div>
            <div>
              <div class="gcal-detail-label">Lokasi</div>
              <div class="gcal-detail-value" id="detailLocation">-</div>
              <div class="gcal-detail-subvalue" id="detailLocationType">-</div>
            </div>
          </div>

          <div class="gcal-detail-row">
            <div class="gcal-detail-icon">
              <i class="bx bx-user"></i>
            </div>
            <div>
              <div class="gcal-detail-label">Klien</div>
              <div class="gcal-detail-value" id="detailClient">-</div>
              <div class="gcal-detail-subvalue" id="detailPhone">-</div>
            </div>
          </div>

          <div class="gcal-detail-row">
            <div class="gcal-detail-icon">
              <i class="bx bx-camera"></i>
            </div>
            <div>
              <div class="gcal-detail-label">Fotografer</div>
              <div class="gcal-detail-value" id="detailPhotographer">-</div>
              <div class="gcal-detail-subvalue" id="detailDuration">-</div>
            </div>
          </div>

          <div class="gcal-detail-row mb-0">
            <div class="gcal-detail-icon">
              <i class="bx bx-note"></i>
            </div>
            <div>
              <div class="gcal-detail-label">Catatan</div>
              <div class="gcal-detail-value" id="detailNotes">-</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

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
        if (!clientSelect) return;
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
        if (!packageSelect) return;

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

        locationTypeDisplay.value = locationType ? locationType.toUpperCase() : '';

        if (locationType === 'indoor') {
          locationIndoorWrapper.style.display = 'block';
          locationManualWrapper.style.display = 'none';
          if (locationName) locationName.value = '';
        } else if (locationType === 'outdoor') {
          locationIndoorWrapper.style.display = 'none';
          locationManualWrapper.style.display = 'block';
        } else {
          locationIndoorWrapper.style.display = 'none';
          locationManualWrapper.style.display = 'none';
        }
      }

      function resetPhotographers() {
        if (!photographerSelect) return;
        photographerSelect.innerHTML = '<option value="">Pilih jadwal dulu</option>';
        photographerSelect.disabled = true;
      }

      function resetSlotSelection() {
        if (selectedStartTime) selectedStartTime.value = '';
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
        videoAddonType.addEventListener('change', function () {
          handlePackageLocation();
        });
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
