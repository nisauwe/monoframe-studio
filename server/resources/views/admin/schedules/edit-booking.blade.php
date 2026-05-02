@extends('layouts/contentNavbarLayout')

@section('title', 'Edit Booking')

@section('content')
  @php
    $selectedExtraUnits = (int) old('extra_duration_units', $scheduleBooking->extra_duration_units ?? 0);
    $selectedVideoAddon = old('video_addon_type', $scheduleBooking->video_addon_type);
    $currentStartTime = old('start_time', \Carbon\Carbon::parse($scheduleBooking->start_time)->format('H:i:s'));
    $currentPhotographerId = old('photographer_user_id', $scheduleBooking->photographer_user_id);

    $paidBookingAmount = (int) ($scheduleBooking->paid_booking_amount ?? 0);
    $totalBookingAmount = (int) ($scheduleBooking->total_booking_amount ?? 0);
    $remainingBookingAmount = (int) ($scheduleBooking->remaining_booking_amount ?? 0);
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="booking-edit-shell">
      <div class="booking-edit-hero mb-4">
        <div class="booking-edit-hero-left">
          <div class="booking-edit-hero-icon">
            <i class="bx bx-edit-alt"></i>
          </div>

          <div>
            <div class="booking-edit-kicker">MONITORING BOOKING</div>
            <h4>Edit Booking Klien</h4>
            <p>
              Perbarui booking klien dengan alur yang sama seperti booking manual: pilih paket,
              tanggal, jadwal tersedia, fotografer yang ready, lokasi, status, dan catatan.
            </p>
          </div>
        </div>

        <div class="booking-edit-hero-actions">
          <a
            href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => 'all']) }}"
            class="btn booking-edit-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4 booking-edit-alert" role="alert">
          <div class="d-flex gap-2">
            <i class="bx bx-error-circle mt-1"></i>
            <div>
              <strong>Terjadi kesalahan.</strong>
              <ul class="mb-0 mt-2 ps-3">
                @foreach ($errors->all() as $error)
                  <li>{{ $error }}</li>
                @endforeach
              </ul>
            </div>
          </div>
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4 booking-edit-alert" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      <form
        action="{{ route('admin.schedules.bookings.update', $scheduleBooking->id) }}"
        method="POST"
        id="editBookingForm">
        @csrf
        @method('PUT')

        <div class="row g-4">
          <div class="col-xl-8 col-lg-7">
            <div class="card booking-edit-card">
              <div class="card-header">
                <div>
                  <h5 class="mb-1">Form Edit Booking</h5>
                  <p class="mb-0">
                    Pilihan jadwal otomatis dihitung dari jam operasional, kapasitas indoor,
                    buffer, dan fotografer yang tersedia.
                  </p>
                </div>
              </div>

              <div class="card-body">
                <div class="booking-form-section">
                  <div class="booking-section-heading">
                    <div class="booking-section-icon">
                      <i class="bx bx-package"></i>
                    </div>

                    <div>
                      <h6>Data Paket</h6>
                      <p>
                        Pilih paket, add-on video, dan extra duration. Total harga dan sisa bayar
                        akan berubah otomatis mengikuti pilihan ini.
                      </p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-12">
                      <label for="packageSelect" class="form-label">Paket Foto</label>
                      <select name="package_id" id="packageSelect" class="form-select" required>
                        <option value="">Pilih Paket</option>
                        @foreach ($packages as $package)
                          <option
                            value="{{ $package->id }}"
                            data-duration="{{ $package->duration_minutes }}"
                            data-location="{{ strtolower(trim($package->location_type)) }}"
                            data-price="{{ $package->discounted_price ?? $package->price }}"
                            {{ (string) old('package_id', $scheduleBooking->package_id) === (string) $package->id ? 'selected' : '' }}>
                            {{ $package->name }} - Rp {{ number_format($package->discounted_price ?? $package->price, 0, ',', '.') }}
                            ({{ ucfirst($package->location_type) }}, {{ $package->duration_minutes }} menit)
                          </option>
                        @endforeach
                      </select>
                    </div>

                    <div class="col-md-6">
                      <label for="videoAddonType" class="form-label">Add-on Video Cinematic</label>
                      <select name="video_addon_type" id="videoAddonType" class="form-select">
                        <option value="">Tanpa add-on video</option>
                        @foreach (($videoAddons ?? []) as $addon)
                          @php
                            $addonKey = is_array($addon) ? ($addon['addon_key'] ?? $addon['key'] ?? null) : $addon->addon_key;
                            $addonName = is_array($addon) ? ($addon['addon_name'] ?? $addon['name'] ?? null) : $addon->addon_name;
                            $addonPrice = is_array($addon) ? ($addon['price'] ?? 0) : $addon->price;
                          @endphp

                          @if ($addonKey)
                            <option
                              value="{{ $addonKey }}"
                              data-price="{{ $addonPrice }}"
                              {{ $selectedVideoAddon === $addonKey ? 'selected' : '' }}>
                              {{ $addonName }} - Rp {{ number_format($addonPrice, 0, ',', '.') }}
                            </option>
                          @endif
                        @endforeach
                      </select>
                    </div>

                    <div class="col-md-6">
                      <label for="extraDurationUnits" class="form-label">Extra Duration</label>
                      <select name="extra_duration_units" id="extraDurationUnits" class="form-select">
                        <option value="0" {{ $selectedExtraUnits === 0 ? 'selected' : '' }}>Tidak ada extra durasi</option>
                        @for ($unit = 1; $unit <= 5; $unit++)
                          <option value="{{ $unit }}" {{ $selectedExtraUnits === $unit ? 'selected' : '' }}>
                            + {{ $extraDurationMinutes * $unit }} menit
                          </option>
                        @endfor
                      </select>
                      <div class="form-text">
                        Biaya Rp {{ number_format($extraDurationFee, 0, ',', '.') }} per {{ $extraDurationMinutes }} menit.
                      </div>
                    </div>
                  </div>

                  <div class="summary-card mt-3">
                    <div>
                      <small>Durasi Total</small>
                      <strong id="summaryDuration">-</strong>
                    </div>

                    <div>
                      <small>Harga Paket</small>
                      <strong id="summaryPackagePrice">Rp 0</strong>
                    </div>

                    <div>
                      <small>Biaya Extra</small>
                      <strong id="summaryExtraFee">Rp 0</strong>
                    </div>

                    <div>
                      <small>Biaya Video</small>
                      <strong id="summaryVideoFee">Rp 0</strong>
                    </div>

                    <div>
                      <small>Total Harga</small>
                      <strong id="summaryTotalPrice">Rp 0</strong>
                    </div>

                    <div>
                      <small>Sisa Bayar</small>
                      <strong id="summaryRemainingAmount">Rp 0</strong>
                    </div>
                  </div>
                </div>

                <div class="booking-form-section">
                  <div class="booking-section-heading">
                    <div class="booking-section-icon">
                      <i class="bx bx-user"></i>
                    </div>

                    <div>
                      <h6>Data Klien</h6>
                      <p>Pilih akun klien, lalu sesuaikan nama dan nomor HP jika diperlukan.</p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-12">
                      <label for="clientSelect" class="form-label">Email Klien</label>
                      <select name="client_user_id" id="clientSelect" class="form-select" required>
                        <option value="">Pilih Email Klien</option>
                        @foreach ($clients as $client)
                          <option
                            value="{{ $client->id }}"
                            data-name="{{ $client->name }}"
                            data-phone="{{ $client->phone }}"
                            {{ (string) old('client_user_id', $scheduleBooking->client_user_id) === (string) $client->id ? 'selected' : '' }}>
                            {{ $client->email }}
                          </option>
                        @endforeach
                      </select>
                    </div>

                    <div class="col-md-6">
                      <label for="clientName" class="form-label">Nama Klien</label>
                      <input
                        type="text"
                        name="client_name"
                        id="clientName"
                        class="form-control"
                        value="{{ old('client_name', $scheduleBooking->client_name) }}"
                        required>
                    </div>

                    <div class="col-md-6">
                      <label for="clientPhone" class="form-label">No. HP Klien</label>
                      <input
                        type="text"
                        name="client_phone"
                        id="clientPhone"
                        class="form-control"
                        value="{{ old('client_phone', $scheduleBooking->client_phone) }}">
                    </div>
                  </div>
                </div>

                <div class="booking-form-section">
                  <div class="booking-section-heading">
                    <div class="booking-section-icon">
                      <i class="bx bx-calendar"></i>
                    </div>

                    <div>
                      <h6>Jadwal & Fotografer</h6>
                      <p>
                        Pilih tanggal, lalu pilih jadwal tersedia. Setelah jadwal dipilih,
                        sistem akan menampilkan fotografer yang ready.
                      </p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-6">
                      <label for="bookingDate" class="form-label">Tanggal Booking</label>
                      <input
                        type="date"
                        name="booking_date"
                        id="bookingDate"
                        class="form-control"
                        value="{{ old('booking_date', \Carbon\Carbon::parse($scheduleBooking->booking_date)->toDateString()) }}"
                        required>
                    </div>

                    <div class="col-md-6">
                      <label for="photographerSelect" class="form-label">Pilih Fotografer yang Ready</label>
                      <select name="photographer_user_id" id="photographerSelect" class="form-select" required disabled>
                        <option value="">Pilih jadwal dulu</option>
                      </select>
                      <div class="form-text">Fotografer akan muncul setelah jadwal tersedia dipilih.</div>
                    </div>

                    <div class="col-12">
                      <label class="form-label">Pilih Jadwal Tersedia</label>
                      <input
                        type="hidden"
                        name="start_time"
                        id="selectedStartTime"
                        value="{{ $currentStartTime }}"
                        required>

                      <div
                        id="slotButtons"
                        class="slot-button-grid"
                        data-current-start="{{ $currentStartTime }}">
                        <div class="text-muted small">Memuat jadwal tersedia...</div>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="booking-form-section">
                  <div class="booking-section-heading">
                    <div class="booking-section-icon">
                      <i class="bx bx-map"></i>
                    </div>

                    <div>
                      <h6>Lokasi</h6>
                      <p>Lokasi otomatis mengikuti tipe lokasi paket. Outdoor wajib mengisi nama lokasi.</p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-6">
                      <label for="locationTypeDisplay" class="form-label">Tipe Lokasi</label>
                      <input
                        type="text"
                        id="locationTypeDisplay"
                        class="form-control"
                        value="{{ strtoupper($scheduleBooking->location_type ?? '-') }}"
                        readonly>
                    </div>

                    <div class="col-md-6" id="locationNameWrapper">
                      <label for="locationName" class="form-label">Lokasi Foto</label>
                      <input
                        type="text"
                        name="location_name"
                        id="locationName"
                        class="form-control"
                        value="{{ old('location_name', $scheduleBooking->location_name) }}"
                        placeholder="Contoh: Hotel Padang / Pantai Air Manis">
                    </div>
                  </div>
                </div>

                <div class="booking-form-section mb-0">
                  <div class="booking-section-heading">
                    <div class="booking-section-icon">
                      <i class="bx bx-slider-alt"></i>
                    </div>

                    <div>
                      <h6>Status & Catatan</h6>
                      <p>Perbarui status booking, status pembayaran, dan catatan internal booking.</p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-6">
                      <label for="bookingStatus" class="form-label">Status Booking</label>
                      <select name="status" id="bookingStatus" class="form-select" required>
                        <option value="pending" {{ old('status', $scheduleBooking->status) === 'pending' ? 'selected' : '' }}>Pending</option>
                        <option value="confirmed" {{ old('status', $scheduleBooking->status) === 'confirmed' ? 'selected' : '' }}>Confirmed</option>
                        <option value="completed" {{ old('status', $scheduleBooking->status) === 'completed' ? 'selected' : '' }}>Completed</option>
                        <option value="cancelled" {{ old('status', $scheduleBooking->status) === 'cancelled' ? 'selected' : '' }}>Cancelled</option>
                      </select>
                    </div>

                    <div class="col-md-6">
                      <label for="paymentStatus" class="form-label">Status Pembayaran</label>
                      <select name="payment_status" id="paymentStatus" class="form-select">
                        <option value="unpaid" {{ old('payment_status', $scheduleBooking->payment_status) === 'unpaid' ? 'selected' : '' }}>Belum Bayar</option>
                        <option value="pending" {{ old('payment_status', $scheduleBooking->payment_status) === 'pending' ? 'selected' : '' }}>Menunggu Pembayaran</option>
                        <option value="failed" {{ old('payment_status', $scheduleBooking->payment_status) === 'failed' ? 'selected' : '' }}>Pembayaran Gagal</option>
                        <option value="dp_paid" {{ old('payment_status', $scheduleBooking->payment_status) === 'dp_paid' ? 'selected' : '' }}>DP Dibayar</option>
                        <option value="partially_paid" {{ old('payment_status', $scheduleBooking->payment_status) === 'partially_paid' ? 'selected' : '' }}>Sebagian Dibayar</option>
                        <option value="paid" {{ old('payment_status', $scheduleBooking->payment_status) === 'paid' ? 'selected' : '' }}>Lunas</option>
                        <option value="fully_paid" {{ old('payment_status', $scheduleBooking->payment_status) === 'fully_paid' ? 'selected' : '' }}>Fully Paid</option>
                      </select>
                      <div class="form-text">
                        Nominal pembayaran tetap mengikuti data transaksi/payment yang sudah masuk.
                      </div>
                    </div>

                    <div class="col-12">
                      <label for="notes" class="form-label">Catatan</label>
                      <textarea
                        name="notes"
                        id="notes"
                        class="form-control booking-textarea"
                        rows="5"
                        placeholder="Catatan booking...">{{ old('notes', $scheduleBooking->notes) }}</textarea>
                    </div>
                  </div>
                </div>
              </div>

              <div class="card-footer booking-edit-footer">
                <a
                  href="{{ route('admin.schedules.index', ['tab' => 'booking-monitoring', 'booking_filter' => 'all']) }}"
                  class="btn btn-outline-secondary">
                  Batal
                </a>

                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-save me-1"></i>
                  Simpan Perubahan
                </button>
              </div>
            </div>
          </div>

          <div class="col-xl-4 col-lg-5">
            <div class="booking-preview-sticky">
              <div class="booking-preview-card">
                <div class="booking-preview-head">
                  <div>
                    <div class="booking-preview-label">Preview</div>
                    <h6 id="previewPackageName">{{ $scheduleBooking->package->name ?? 'Paket Foto' }}</h6>
                  </div>

                  <span class="badge bg-label-primary" id="previewStatus">
                    {{ ucfirst($scheduleBooking->status ?? 'pending') }}
                  </span>
                </div>

                <div class="booking-preview-user">
                  <div class="booking-preview-avatar">
                    {{ strtoupper(mb_substr($scheduleBooking->client_name ?: 'K', 0, 1)) }}
                  </div>

                  <div>
                    <div class="booking-preview-name" id="previewClientName">
                      {{ $scheduleBooking->client_name ?: 'Klien' }}
                    </div>
                    <div class="booking-preview-subtitle" id="previewClientPhone">
                      {{ $scheduleBooking->client_phone ?: '-' }}
                    </div>
                  </div>
                </div>

                <div class="booking-preview-grid">
                  <div>
                    <small>Tanggal</small>
                    <strong id="previewDate">
                      {{ \Carbon\Carbon::parse($scheduleBooking->booking_date)->translatedFormat('d M Y') }}
                    </strong>
                  </div>

                  <div>
                    <small>Jam</small>
                    <strong id="previewTime">
                      {{ \Carbon\Carbon::parse($scheduleBooking->start_time)->format('H:i') }}
                    </strong>
                  </div>

                  <div>
                    <small>Fotografer</small>
                    <strong id="previewPhotographer">
                      {{ $scheduleBooking->photographerUser->name ?? $scheduleBooking->photographer_name ?? '-' }}
                    </strong>
                  </div>

                  <div>
                    <small>Lokasi</small>
                    <strong id="previewLocation">
                      {{ ucfirst($scheduleBooking->location_type ?? '-') }}
                    </strong>
                  </div>
                </div>

                <div class="booking-preview-total">
                  <small>Total Harga</small>
                  <strong id="previewEstimatedTotal">
                    Rp {{ number_format($totalBookingAmount, 0, ',', '.') }}
                  </strong>
                </div>

                <div class="booking-payment-preview-grid">
                  <div>
                    <small>Sudah Bayar</small>
                    <strong id="previewPaidAmount">
                      Rp {{ number_format($paidBookingAmount, 0, ',', '.') }}
                    </strong>
                  </div>

                  <div>
                    <small>Sisa Bayar</small>
                    <strong id="previewRemainingAmount">
                      Rp {{ number_format($remainingBookingAmount, 0, ',', '.') }}
                    </strong>
                  </div>
                </div>

                <div class="booking-preview-note">
                  <i class="bx bx-info-circle"></i>
                  <span>
                    Total dihitung dari harga paket + extra duration + add-on video. Sudah bayar
                    mengikuti transaksi payment yang berhasil.
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>

  <style>
    .booking-edit-hero {
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

    .booking-edit-hero::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .booking-edit-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .booking-edit-hero-icon {
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

    .booking-edit-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .booking-edit-hero h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .booking-edit-hero p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .booking-edit-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .booking-edit-back-btn {
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
      white-space: nowrap;
      box-shadow: 0 16px 30px rgba(22, 43, 77, 0.16);
      transition: 0.2s ease;
    }

    .booking-edit-back-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .booking-edit-alert {
      border: 0;
      border-radius: 20px;
      box-shadow: var(--mf-shadow-soft);
    }

    .booking-edit-card,
    .booking-preview-card {
      border: 0;
      border-radius: 30px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .booking-edit-card .card-header {
      padding: 30px 34px 22px !important;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .booking-edit-card .card-header h5 {
      color: var(--mf-ink);
      font-weight: 900;
    }

    .booking-edit-card .card-header p {
      color: var(--mf-muted);
      font-size: 14px;
      font-weight: 600;
      line-height: 1.6;
    }

    .booking-edit-card .card-body {
      padding: 30px 34px 34px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.10), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .booking-form-section {
      margin-bottom: 34px;
      padding-bottom: 34px;
      border-bottom: 1px solid var(--mf-border);
    }

    .booking-form-section.mb-0 {
      margin-bottom: 0 !important;
      padding-bottom: 0 !important;
      border-bottom: 0;
    }

    .booking-section-heading {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 18px;
    }

    .booking-section-icon {
      width: 48px;
      height: 48px;
      border-radius: 17px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 23px;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
    }

    .booking-section-heading h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 5px;
    }

    .booking-section-heading p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .booking-edit-card .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.02em;
      margin-bottom: 8px;
    }

    .booking-edit-card .form-control,
    .booking-edit-card .form-select {
      min-height: 54px;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      box-shadow: none !important;
    }

    .booking-edit-card .form-control:focus,
    .booking-edit-card .form-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .booking-edit-card .form-text {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      margin-top: 8px;
    }

    .booking-textarea {
      min-height: 132px !important;
      padding-top: 14px !important;
      resize: vertical;
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

    .summary-card small,
    .booking-preview-grid small,
    .booking-preview-total small,
    .booking-payment-preview-grid small {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      margin-bottom: 5px;
    }

    .summary-card strong,
    .booking-preview-grid strong,
    .booking-preview-total strong,
    .booking-payment-preview-grid strong {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.45;
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
      background: #ffffff;
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
      color: #ffffff;
      border-color: transparent;
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.24);
    }

    .booking-edit-footer {
      padding: 24px 34px 30px !important;
      border-top: 1px solid var(--mf-border);
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
      background: #ffffff;
    }

    .booking-edit-footer .btn {
      min-height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding-left: 24px;
      padding-right: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .booking-preview-sticky {
      position: sticky;
      top: 105px;
    }

    .booking-preview-card {
      padding: 26px;
    }

    .booking-preview-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 18px;
    }

    .booking-preview-label {
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      margin-bottom: 4px;
    }

    .booking-preview-head h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin: 0;
      line-height: 1.35;
    }

    .booking-preview-user {
      display: flex;
      align-items: center;
      gap: 14px;
      padding: 18px;
      border-radius: 24px;
      margin-bottom: 16px;
      background:
        radial-gradient(circle at top right, rgba(255, 255, 255, 0.28), transparent 34%),
        linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
    }

    .booking-preview-avatar {
      width: 54px;
      height: 54px;
      border-radius: 19px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: rgba(255, 255, 255, 0.18);
      color: #ffffff;
      font-size: 20px;
      font-weight: 900;
      flex-shrink: 0;
    }

    .booking-preview-name {
      color: #ffffff;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .booking-preview-subtitle {
      color: rgba(255, 255, 255, 0.82);
      font-size: 13px;
      font-weight: 700;
    }

    .booking-preview-grid,
    .booking-payment-preview-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
      margin-bottom: 16px;
    }

    .booking-preview-grid div,
    .booking-preview-total,
    .booking-payment-preview-grid div {
      padding: 14px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .booking-payment-preview-grid {
      margin-top: 12px;
    }

    .booking-preview-note {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      margin-top: 14px;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      line-height: 1.6;
    }

    .booking-preview-note i {
      color: var(--mf-primary);
      font-size: 17px;
      margin-top: 1px;
    }

    @media (max-width: 991px) {
      .booking-preview-sticky {
        position: static;
      }

      .booking-edit-hero {
        align-items: flex-start;
        flex-direction: column;
      }

      .booking-edit-hero-actions,
      .booking-edit-back-btn {
        width: 100%;
      }

      .summary-card {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 768px) {
      .booking-edit-hero {
        padding: 26px 22px;
      }

      .booking-edit-hero-left {
        flex-direction: column;
      }

      .booking-edit-hero h4 {
        font-size: 26px;
      }

      .booking-edit-card .card-header,
      .booking-edit-card .card-body,
      .booking-edit-footer {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .booking-section-heading {
        flex-direction: column;
      }

      .booking-edit-footer {
        flex-direction: column-reverse;
        align-items: stretch;
      }

      .booking-edit-footer .btn {
        width: 100%;
      }

      .booking-preview-grid,
      .booking-payment-preview-grid {
        grid-template-columns: 1fr;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const packageSelect = document.getElementById('packageSelect');
      const extraDurationUnits = document.getElementById('extraDurationUnits');
      const videoAddonType = document.getElementById('videoAddonType');

      const clientSelect = document.getElementById('clientSelect');
      const clientName = document.getElementById('clientName');
      const clientPhone = document.getElementById('clientPhone');

      const photographerSelect = document.getElementById('photographerSelect');
      const bookingDate = document.getElementById('bookingDate');
      const selectedStartTime = document.getElementById('selectedStartTime');
      const slotButtons = document.getElementById('slotButtons');

      const locationTypeDisplay = document.getElementById('locationTypeDisplay');
      const locationNameWrapper = document.getElementById('locationNameWrapper');
      const locationName = document.getElementById('locationName');

      const bookingStatus = document.getElementById('bookingStatus');

      const summaryDuration = document.getElementById('summaryDuration');
      const summaryPackagePrice = document.getElementById('summaryPackagePrice');
      const summaryExtraFee = document.getElementById('summaryExtraFee');
      const summaryVideoFee = document.getElementById('summaryVideoFee');
      const summaryTotalPrice = document.getElementById('summaryTotalPrice');
      const summaryRemainingAmount = document.getElementById('summaryRemainingAmount');

      const previewPackageName = document.getElementById('previewPackageName');
      const previewStatus = document.getElementById('previewStatus');
      const previewClientName = document.getElementById('previewClientName');
      const previewClientPhone = document.getElementById('previewClientPhone');
      const previewDate = document.getElementById('previewDate');
      const previewTime = document.getElementById('previewTime');
      const previewPhotographer = document.getElementById('previewPhotographer');
      const previewLocation = document.getElementById('previewLocation');
      const previewEstimatedTotal = document.getElementById('previewEstimatedTotal');
      const previewPaidAmount = document.getElementById('previewPaidAmount');
      const previewRemainingAmount = document.getElementById('previewRemainingAmount');

      const bookingId = '{{ $scheduleBooking->id }}';
      const currentStartTime = '{{ $currentStartTime }}';
      const currentPhotographerId = '{{ $currentPhotographerId }}';

      const extraDurationStepMinutes = {{ (int) $extraDurationMinutes }};
      const extraDurationStepFee = {{ (int) $extraDurationFee }};
      const paidBookingAmount = {{ (int) $paidBookingAmount }};

      function formatRupiah(value) {
        return 'Rp ' + Number(value || 0).toLocaleString('id-ID');
      }

      function selectedOption(select) {
        return select?.options?.[select.selectedIndex] || null;
      }

      function normalizeTime(value) {
        if (!value) {
          return '';
        }

        return value.length === 5 ? value + ':00' : value;
      }

      function updateClientFromSelect() {
        const selected = selectedOption(clientSelect);

        if (!selected || !selected.value) {
          return;
        }

        clientName.value = selected.dataset.name || clientName.value;
        clientPhone.value = selected.dataset.phone || clientPhone.value;

        updatePreview();
      }

      function updateLocationByPackage() {
        const selected = selectedOption(packageSelect);
        const rawLocation = (selected?.dataset?.location || '').toLowerCase().trim();

        let locationType = '';

        if (rawLocation.includes('outdoor')) {
          locationType = 'outdoor';
        } else if (rawLocation.includes('indoor')) {
          locationType = 'indoor';
        }

        locationTypeDisplay.value = locationType ? locationType.toUpperCase() : '';

        if (locationType === 'indoor') {
          locationNameWrapper.style.display = 'block';
          locationName.value = 'Indoor Studio Monoframe';
          locationName.readOnly = true;
        } else if (locationType === 'outdoor') {
          locationNameWrapper.style.display = 'block';
          locationName.readOnly = false;

          if (locationName.value === 'Indoor Studio Monoframe') {
            locationName.value = '';
          }
        } else {
          locationNameWrapper.style.display = 'block';
          locationName.readOnly = false;
        }
      }

      function updateSummary() {
        const selectedPackage = selectedOption(packageSelect);
        const duration = parseInt(selectedPackage?.dataset?.duration || '0', 10);
        const packagePrice = parseInt(selectedPackage?.dataset?.price || '0', 10);

        const extraUnits = parseInt(extraDurationUnits?.value || '0', 10);
        const extraMinutes = extraUnits * extraDurationStepMinutes;
        const extraFee = extraUnits * extraDurationStepFee;

        const selectedVideo = selectedOption(videoAddonType);
        const videoFee = parseInt(selectedVideo?.dataset?.price || '0', 10);

        const totalDuration = duration + extraMinutes;
        const totalPrice = packagePrice + extraFee + videoFee;
        const remainingAmount = Math.max(0, totalPrice - paidBookingAmount);

        summaryDuration.textContent = totalDuration > 0 ? totalDuration + ' menit' : '-';
        summaryPackagePrice.textContent = formatRupiah(packagePrice);
        summaryExtraFee.textContent = formatRupiah(extraFee);
        summaryVideoFee.textContent = formatRupiah(videoFee);
        summaryTotalPrice.textContent = formatRupiah(totalPrice);
        summaryRemainingAmount.textContent = formatRupiah(remainingAmount);

        previewEstimatedTotal.textContent = formatRupiah(totalPrice);
        previewPaidAmount.textContent = formatRupiah(paidBookingAmount);
        previewRemainingAmount.textContent = formatRupiah(remainingAmount);
      }

      function resetPhotographers() {
        photographerSelect.innerHTML = '<option value="">Pilih jadwal dulu</option>';
        photographerSelect.disabled = true;
      }

      function updatePreview() {
        const selectedPackage = selectedOption(packageSelect);
        const selectedPhotographer = selectedOption(photographerSelect);

        previewPackageName.textContent = selectedPackage?.text?.trim() || 'Paket Foto';

        previewStatus.textContent = bookingStatus.value
          ? bookingStatus.value.charAt(0).toUpperCase() + bookingStatus.value.slice(1)
          : 'Pending';

        previewClientName.textContent = clientName.value.trim() || 'Klien';
        previewClientPhone.textContent = clientPhone.value.trim() || '-';
        previewDate.textContent = bookingDate.value || '-';
        previewTime.textContent = selectedStartTime.value
          ? selectedStartTime.value.substring(0, 5)
          : '-';

        previewPhotographer.textContent = selectedPhotographer?.dataset?.name || selectedPhotographer?.text || '-';
        previewLocation.textContent = locationTypeDisplay.value || '-';

        updateSummary();
      }

      function renderSlotButtons(slots) {
        slotButtons.innerHTML = '';
        resetPhotographers();

        const selectedValue = normalizeTime(selectedStartTime.value || currentStartTime);

        if (!Array.isArray(slots) || !slots.length) {
          selectedStartTime.value = '';
          slotButtons.innerHTML = '<div class="text-danger small">Tidak ada jadwal kosong untuk pilihan ini.</div>';
          updatePreview();
          return;
        }

        let hasActiveSlot = false;

        slots.forEach(function (slot) {
          const btn = document.createElement('button');
          const slotStart = normalizeTime(slot.start_time);

          btn.type = 'button';
          btn.className = 'slot-btn';

          const suffix = slot.remaining_capacity === null
            ? `ready ${slot.ready_photographers_count} fotografer`
            : `sisa indoor ${slot.remaining_capacity} | ready ${slot.ready_photographers_count} fotografer`;

          btn.textContent = `${slot.label} | ${suffix}`;

          if (slotStart === selectedValue) {
            btn.classList.add('active');
            selectedStartTime.value = slot.start_time;
            hasActiveSlot = true;
          }

          btn.addEventListener('click', function () {
            document.querySelectorAll('.slot-btn').forEach(function (el) {
              el.classList.remove('active');
            });

            btn.classList.add('active');
            selectedStartTime.value = slot.start_time;

            loadAvailablePhotographers();
            updatePreview();
          });

          slotButtons.appendChild(btn);
        });

        if (hasActiveSlot) {
          loadAvailablePhotographers();
        } else {
          selectedStartTime.value = '';
          resetPhotographers();
        }

        updatePreview();
      }

      async function loadAvailableSlots() {
        const packageId = packageSelect.value;
        const date = bookingDate.value;
        const extraUnits = extraDurationUnits?.value || 0;

        slotButtons.innerHTML = '<div class="text-muted small">Memuat jadwal tersedia...</div>';
        selectedStartTime.value = selectedStartTime.value || currentStartTime;
        resetPhotographers();

        if (!packageId || !date) {
          slotButtons.innerHTML = '<div class="text-muted small">Pilih paket dan tanggal terlebih dahulu.</div>';
          selectedStartTime.value = '';
          updatePreview();
          return;
        }

        try {
          const params = new URLSearchParams({
            package_id: packageId,
            booking_date: date,
            extra_duration_units: extraUnits,
            exclude_booking_id: bookingId
          });

          const response = await fetch(`{{ route('admin.schedules.available-slots') }}?${params.toString()}`);
          const data = await response.json();

          renderSlotButtons(Array.isArray(data) ? data : []);
        } catch (error) {
          selectedStartTime.value = '';
          slotButtons.innerHTML = '<div class="text-danger small">Gagal memuat jadwal tersedia.</div>';
          updatePreview();
        }
      }

      async function loadAvailablePhotographers() {
        const packageId = packageSelect.value;
        const date = bookingDate.value;
        const start = selectedStartTime.value;
        const extraUnits = extraDurationUnits?.value || 0;

        photographerSelect.disabled = true;
        photographerSelect.innerHTML = '<option value="">Memuat fotografer...</option>';

        if (!packageId || !date || !start) {
          resetPhotographers();
          updatePreview();
          return;
        }

        try {
          const params = new URLSearchParams({
            package_id: packageId,
            booking_date: date,
            start_time: start,
            extra_duration_units: extraUnits,
            exclude_booking_id: bookingId
          });

          const response = await fetch(`{{ route('admin.schedules.available-photographers') }}?${params.toString()}`);
          const data = await response.json();

          photographerSelect.innerHTML = '';

          if (!Array.isArray(data) || !data.length) {
            photographerSelect.innerHTML = '<option value="">Tidak ada fotografer yang ready</option>';
            photographerSelect.disabled = true;
            updatePreview();
            return;
          }

          photographerSelect.innerHTML = '<option value="">Pilih Fotografer</option>';

          data.forEach(function (item) {
            const option = document.createElement('option');

            option.value = item.id;
            option.textContent = `${item.name} - ${item.email}`;
            option.dataset.name = item.name;

            if (String(item.id) === String(currentPhotographerId)) {
              option.selected = true;
            }

            photographerSelect.appendChild(option);
          });

          photographerSelect.disabled = false;
          updatePreview();
        } catch (error) {
          photographerSelect.innerHTML = '<option value="">Gagal memuat fotografer</option>';
          photographerSelect.disabled = true;
          updatePreview();
        }
      }

      [packageSelect, bookingDate, extraDurationUnits].forEach(function (input) {
        if (!input) {
          return;
        }

        input.addEventListener('change', function () {
          updateLocationByPackage();
          updateSummary();
          selectedStartTime.value = '';
          loadAvailableSlots();
        });
      });

      [videoAddonType, clientName, clientPhone, photographerSelect, locationName, bookingStatus].forEach(function (input) {
        if (!input) {
          return;
        }

        input.addEventListener('input', updatePreview);
        input.addEventListener('change', updatePreview);
      });

      if (clientSelect) {
        clientSelect.addEventListener('change', updateClientFromSelect);
      }

      updateLocationByPackage();
      updateSummary();
      loadAvailableSlots();
      updatePreview();
    });
  </script>
@endsection
