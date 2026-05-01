@extends('layouts/contentNavbarLayout')

@section('title', 'Hasil Review Klien')

@section('content')
  @php
    $ratingOptions = [
        '5' => '5 Bintang',
        '4' => '4 Bintang',
        '3' => '3 Bintang',
        '2' => '2 Bintang',
        '1' => '1 Bintang',
    ];

    $ratingBadgeClass = function ($rating) {
        $rating = (int) $rating;

        return match (true) {
            $rating >= 4 => 'success',
            $rating === 3 => 'warning',
            $rating <= 2 && $rating >= 1 => 'danger',
            default => 'secondary',
        };
    };

    $ratingLabel = function ($rating) {
        $rating = (int) $rating;

        return match ($rating) {
            5 => 'Sangat Puas',
            4 => 'Puas',
            3 => 'Cukup',
            2 => 'Kurang Puas',
            1 => 'Buruk',
            default => 'Belum Dinilai',
        };
    };
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell review-page">

      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      <div class="review-hero-card mb-4">
        <div class="review-hero-left">
          <div class="review-hero-icon">
            <i class="bx bx-message-rounded-dots"></i>
          </div>

          <div>
            <div class="review-hero-kicker">MONITORING KLIEN</div>
            <h4>Hasil Review Klien</h4>
            <p>
              Pantau ulasan dari klien berdasarkan tanggal review, isi komentar, rating,
              dan paket foto yang diambil. Admin hanya dapat menghapus review yang tidak sesuai,
              tanpa mengubah isi review dari klien.
            </p>
          </div>
        </div>

        <div class="review-hero-actions">
          <div class="review-hero-badge">
            <i class="bx bx-star"></i>
            {{ number_format((float) $averageRating, 1, ',', '.') }}/5 Rating
          </div>
        </div>
      </div>

      <div class="row g-4 mb-4">
        <div class="col-xl-3 col-md-6">
          <div class="card stat-card h-100 review-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Total Review</div>
                  <h3 class="stat-number">{{ $totalReviews }}</h3>
                  <div class="stat-helper">Semua ulasan klien</div>
                </div>

                <div class="stat-icon review-stat-icon bg-label-primary">
                  <i class="bx bx-message-rounded-dots"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="card stat-card h-100 review-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Rata-rata Rating</div>
                  <h3 class="stat-number">{{ number_format((float) $averageRating, 1, ',', '.') }}/5</h3>
                  <div class="stat-helper">Penilaian layanan</div>
                </div>

                <div class="stat-icon review-stat-icon bg-label-warning">
                  <i class="bx bx-star"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="card stat-card h-100 review-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Review Hari Ini</div>
                  <h3 class="stat-number">{{ $todayReviews }}</h3>
                  <div class="stat-helper">Masuk pada hari ini</div>
                </div>

                <div class="stat-icon review-stat-icon bg-label-success">
                  <i class="bx bx-calendar-check"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="card stat-card h-100 review-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Rating Rendah</div>
                  <h3 class="stat-number">{{ $lowRatingReviews }}</h3>
                  <div class="stat-helper">Rating 1 sampai 2</div>
                </div>

                <div class="stat-icon review-stat-icon bg-label-danger">
                  <i class="bx bx-error-circle"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="review-info-card mb-4">
        <div class="review-info-icon">
          <i class="bx bx-info-circle"></i>
        </div>

        <div>
          <h6>Monitoring Review Klien</h6>
          <p>
            Admin dapat memantau review yang diberikan klien setelah booking selesai.
            Review hanya bisa dilihat dan dihapus jika dianggap tidak sesuai.
            Admin tidak dapat mengubah isi review dari klien.
          </p>
        </div>
      </div>

      <div class="card section-card review-list-card">
        <div class="card-header">
          <div class="review-card-head">
            <div>
              <h5 class="section-title">Daftar Review Klien</h5>
              <p class="section-subtitle mb-0">
                Review ditampilkan dalam bentuk kartu agar data klien, paket, rating,
                dan komentar lebih nyaman dibaca.
              </p>
            </div>

            <div class="review-total-badge">
              <i class="bx bx-message-square-detail"></i>
              {{ $reviews->total() }} review
            </div>
          </div>
        </div>

        <div class="card-body review-filter-body">
          <form method="GET" action="{{ route('admin.reviews.index') }}" class="review-filter-form">
            <div class="review-filter-grid">
              <div class="review-filter-group review-filter-search-group">
                <label class="form-label">Cari Review</label>

                <div class="review-search-input-group">
                  <span class="review-search-addon">
                    <i class="bx bx-search"></i>
                  </span>

                  <input
                    type="text"
                    name="search"
                    class="form-control review-search-control"
                    placeholder="Cari nama klien, email, paket, atau isi review..."
                    value="{{ request('search') }}"
                  >
                </div>
              </div>

              <div class="review-filter-group">
                <label class="form-label">Rating</label>
                <select name="rating" class="form-select review-filter-control">
                  <option value="" {{ !request('rating') ? 'selected' : '' }}>
                    Semua Rating
                  </option>

                  @foreach ($ratingOptions as $value => $label)
                    <option value="{{ $value }}" {{ request('rating') === $value ? 'selected' : '' }}>
                      {{ $label }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="review-filter-group">
                <label class="form-label">Dari Tanggal</label>
                <input
                  type="date"
                  name="date_from"
                  class="form-control review-filter-control"
                  value="{{ request('date_from') }}"
                >
              </div>

              <div class="review-filter-group">
                <label class="form-label">Sampai Tanggal</label>
                <input
                  type="date"
                  name="date_to"
                  class="form-control review-filter-control"
                  value="{{ request('date_to') }}"
                >
              </div>

              <div class="review-filter-actions">
                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-filter-alt me-1"></i>
                  Filter
                </button>

                <a href="{{ route('admin.reviews.index') }}" class="btn btn-outline-secondary">
                  Refresh
                </a>
              </div>
            </div>
          </form>
        </div>

        <div class="review-card-body">
          <div class="review-card-grid">
            @forelse ($reviews as $review)
              @php
                $booking = $review->booking;
                $client = $review->client;
                $package = $booking?->package;

                $printOrder = $booking?->printOrder;

                $packageBasePrice = (int) (
                    $booking?->package_base_price
                    ?? $package?->discounted_price
                    ?? $package?->price
                    ?? 0
                );

                $extraDurationFee = (int) ($booking?->extra_duration_fee ?? 0);
                $videoAddonPrice = (int) ($booking?->video_addon_price ?? 0);

                $bookingTotal = (int) (
                    $booking?->total_booking_amount
                    ?? ($packageBasePrice + $extraDurationFee + $videoAddonPrice)
                );

                $printTotal = (int) ($printOrder?->total_amount ?? 0);

                $grandTotal = $bookingTotal + $printTotal;

                $clientName = $client?->name ?? $booking?->client_name ?? 'Klien';
                $clientEmail = $client?->email ?? '-';
                $clientPhone = $client?->phone ?? $booking?->client_phone ?? '-';
                $clientInitial = mb_strtoupper(mb_substr($clientName ?: 'K', 0, 1));

                $bookingDate = $booking?->booking_date
                    ? \Carbon\Carbon::parse($booking->booking_date)->format('d M Y')
                    : '-';

                $bookingStart = $booking?->start_time
                    ? \Carbon\Carbon::parse($booking->start_time)->format('H:i')
                    : null;

                $bookingEnd = $booking?->end_time
                    ? \Carbon\Carbon::parse($booking->end_time)->format('H:i')
                    : null;

                $rating = (int) ($review->rating ?? 0);
                $badge = $ratingBadgeClass($rating);

                $reviewDate = $review->created_at ? $review->created_at->format('d M Y') : '-';
                $reviewTime = $review->created_at ? $review->created_at->format('H:i') : '-';
              @endphp

              <div class="review-card-item">
                <div class="review-card-top">
                  <div class="review-client-block">
                    <div class="review-client-avatar">
                      {{ $clientInitial }}
                    </div>

                    <div class="review-client-info">
                      <div class="review-client-name">
                        {{ $clientName }}
                      </div>

                      <div class="review-client-meta">
                        <i class="bx bx-envelope"></i>
                        <span>{{ $clientEmail }}</span>
                      </div>

                      <div class="review-client-meta">
                        <i class="bx bx-phone"></i>
                        <span>{{ $clientPhone }}</span>
                      </div>
                    </div>
                  </div>

                  <form
                    action="{{ route('admin.reviews.destroy', $review) }}"
                    method="POST"
                    onsubmit="return confirm('Yakin ingin menghapus review ini? Review yang dihapus tidak dapat dikembalikan.');"
                  >
                    @csrf
                    @method('DELETE')

                    <button type="submit" class="btn btn-outline-danger review-delete-icon-btn" title="Hapus Review">
                      <i class="bx bx-trash"></i>
                    </button>
                  </form>
                </div>

                <div class="review-rating-section">
                  <div>
                    <span class="badge bg-label-{{ $badge }} review-rating-label">
                      {{ $ratingLabel($rating) }}
                    </span>

                    <div class="review-stars">
                      @for ($i = 1; $i <= 5; $i++)
                        @if ($i <= $rating)
                          <i class="bx bxs-star"></i>
                        @else
                          <i class="bx bx-star review-star-empty"></i>
                        @endif
                      @endfor
                    </div>
                  </div>

                  <div class="review-rating-number">
                    {{ $rating }}/5
                  </div>
                </div>

                <div class="review-comment-box">
                  <div class="review-quote-icon">
                    <i class="bx bxs-quote-left"></i>
                  </div>

                  <p>
                    @if ($review->comment)
                      {{ $review->comment }}
                    @else
                      <span class="text-muted">Tidak ada komentar dari klien.</span>
                    @endif
                  </p>
                </div>

                <div class="review-mini-detail-list">
                  <div class="review-mini-detail">
                    <div class="review-mini-icon bg-label-primary">
                      <i class="bx bx-package"></i>
                    </div>

                    <div>
                      <span>Paket Foto</span>
                      <strong>{{ $package?->name ?? '-' }}</strong>

                      <p>
                        {{ $package?->location_type ? ucfirst($package->location_type) : '-' }}

                        @if ($package?->duration_minutes)
                          • {{ $package->duration_minutes }} menit
                        @endif
                      </p>
                    </div>
                  </div>

                  <div class="review-mini-detail">
                    <div class="review-mini-icon bg-label-info">
                      <i class="bx bx-calendar"></i>
                    </div>

                    <div>
                      <span>Jadwal Booking</span>
                      <strong>{{ $bookingDate }}</strong>

                      <p>
                        @if ($bookingStart && $bookingEnd)
                          {{ $bookingStart }} - {{ $bookingEnd }}
                        @elseif ($bookingStart)
                          {{ $bookingStart }}
                        @else
                          -
                        @endif
                      </p>
                    </div>
                  </div>

                  <div class="review-mini-detail">
                    <div class="review-mini-icon bg-label-success">
                      <i class="bx bx-time-five"></i>
                    </div>

                    <div>
                      <span>Tanggal Review</span>
                      <strong>{{ $reviewDate }}</strong>
                      <p>{{ $reviewTime }} WIB</p>
                    </div>
                  </div>
                </div>

                <div class="review-card-footer-info">
                  <div>
                    <i class="bx bx-map"></i>
                    <span>{{ $booking?->location_name ?? '-' }}</span>
                  </div>

                  <strong>
                    Rp {{ number_format($grandTotal, 0, ',', '.') }}
                  </strong>
                </div>

                <div class="review-price-breakdown">
                  <div>
                    <span>Booking</span>
                    <strong>Rp {{ number_format($bookingTotal, 0, ',', '.') }}</strong>
                  </div>

                  <div>
                    <span>Cetak</span>
                    <strong>Rp {{ number_format($printTotal, 0, ',', '.') }}</strong>
                  </div>
                </div>
              </div>
            @empty
              <div class="review-empty-state">
                <i class="bx bx-message-square-x"></i>
                <h6>Belum ada review dari klien</h6>
                <p>Review yang diberikan klien setelah booking selesai akan tampil di sini.</p>
              </div>
            @endforelse
          </div>
        </div>

        @if ($reviews->hasPages())
          <div class="card-footer review-footer">
            {{ $reviews->links() }}
          </div>
        @endif
      </div>
    </div>
  </div>

  <style>
    :root {
      --mf-primary: #2f48a6;
      --mf-blue: #5d7ce4;
      --mf-ink: #23314f;
      --mf-muted: #6b7c93;
      --mf-border: #dce8f1;
      --mf-shadow-soft: 0 18px 42px rgba(52, 79, 165, 0.10);
    }

    .review-page {
      max-width: 1480px;
      margin: 0 auto;
    }

    .review-hero-card {
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

    .review-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .review-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .review-hero-icon {
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

    .review-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .review-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .review-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .review-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .review-hero-badge {
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

    .review-hero-badge i {
      font-size: 20px;
      color: #ffab00;
    }

    .review-stat-card {
      min-height: 142px;
      border: 0;
      border-radius: 28px;
      overflow: hidden;
      box-shadow: var(--mf-shadow-soft);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      transition: 0.22s ease;
    }

    .review-stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 48px rgba(52, 79, 165, 0.14);
    }

    .stat-label {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .stat-number {
      color: var(--mf-ink);
      font-size: 30px;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .stat-helper {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
    }

    .review-stat-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 28px;
    }

    .review-info-card {
      display: grid;
      grid-template-columns: 58px 1fr;
      gap: 16px;
      align-items: flex-start;
      padding: 22px 24px;
      border-radius: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-shadow: var(--mf-shadow-soft);
    }

    .review-info-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 28px;
      box-shadow: 0 16px 32px rgba(88, 115, 220, 0.22);
    }

    .review-info-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .review-info-card p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .review-list-card {
      border: 0;
      border-radius: 30px;
      overflow: hidden;
      box-shadow: var(--mf-shadow-soft);
      background: #ffffff;
    }

    .review-list-card .card-header {
      padding: 30px 34px 22px !important;
      background: #ffffff;
      border-bottom: 1px solid var(--mf-border);
    }

    .review-card-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 16px;
    }

    .section-title {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .section-subtitle {
      color: var(--mf-muted);
      font-weight: 600;
    }

    .review-total-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 13px;
      font-weight: 900;
      white-space: nowrap;
    }

    .review-total-badge i {
      font-size: 18px;
    }

    .review-filter-body {
      padding: 26px 34px 30px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .review-filter-form {
      border: 1px solid var(--mf-border);
      border-radius: 26px;
      padding: 20px;
      background: #ffffff;
      box-shadow: 0 10px 24px rgba(22, 43, 77, 0.04);
    }

    .review-filter-grid {
      display: grid;
      grid-template-columns: minmax(360px, 1.7fr) minmax(170px, 0.7fr) minmax(180px, 0.75fr) minmax(180px, 0.75fr) auto;
      gap: 14px;
      align-items: end;
    }

    .review-filter-group {
      min-width: 0;
    }

    .review-filter-group .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .review-filter-control {
      width: 100%;
      height: 52px !important;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      box-shadow: none !important;
    }

    .review-filter-control:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .review-search-input-group {
      display: flex;
      align-items: stretch;
      width: 100%;
      height: 52px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
      overflow: hidden;
      transition: 0.18s ease;
    }

    .review-search-input-group:focus-within {
      border-color: rgba(88, 115, 220, 0.48);
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
    }

    .review-search-addon {
      width: 58px;
      min-width: 58px;
      height: 100%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: #ffffff;
      color: var(--mf-ink);
      border-right: 1px solid var(--mf-border);
      font-size: 20px;
    }

    .review-search-control {
      height: 100% !important;
      flex: 1;
      min-width: 0;
      border: 0 !important;
      border-radius: 0 !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      padding: 0 18px !important;
      box-shadow: none !important;
      outline: none !important;
    }

    .review-search-control:focus {
      border: 0 !important;
      box-shadow: none !important;
      outline: none !important;
    }

    .review-search-control::placeholder {
      color: rgba(107, 124, 147, 0.62) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
    }

    .review-filter-actions {
      display: flex;
      align-items: end;
      gap: 10px;
      min-width: 190px;
    }

    .review-filter-actions .btn {
      height: 52px;
      border-radius: 18px;
      font-weight: 900;
      padding-left: 16px;
      padding-right: 16px;
      white-space: nowrap;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .review-filter-actions .btn-primary {
      min-width: 104px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      border: 0;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.20);
    }

    .review-filter-actions .btn-outline-secondary {
      min-width: 86px;
      background: #ffffff;
      border-color: var(--mf-border);
      color: var(--mf-ink);
    }

    .review-card-body {
      padding: 0 34px 34px;
      background:
        radial-gradient(circle at bottom left, rgba(88, 115, 220, 0.08), transparent 34%),
        linear-gradient(180deg, #f8fbfd 0%, #ffffff 100%);
    }

    .review-card-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
    }

    .review-card-item {
      display: flex;
      flex-direction: column;
      min-height: 100%;
      border: 1px solid var(--mf-border);
      border-radius: 28px;
      padding: 20px;
      background: #ffffff;
      box-shadow: 0 14px 34px rgba(22, 43, 77, 0.06);
      transition: 0.22s ease;
    }

    .review-card-item:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 50px rgba(52, 79, 165, 0.14);
    }

    .review-card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 16px;
    }

    .review-client-block {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      min-width: 0;
      flex: 1;
    }

    .review-client-avatar {
      width: 52px;
      height: 52px;
      border-radius: 19px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      color: #ffffff;
      font-size: 18px;
      font-weight: 900;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 12px 26px rgba(88, 115, 220, 0.22);
    }

    .review-client-info {
      min-width: 0;
    }

    .review-client-name {
      color: var(--mf-ink);
      font-weight: 900;
      font-size: 17px;
      line-height: 1.3;
      margin-bottom: 6px;
    }

    .review-client-meta {
      display: flex;
      align-items: center;
      gap: 6px;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.6;
      min-width: 0;
    }

    .review-client-meta span {
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .review-client-meta i {
      color: var(--mf-primary);
      font-size: 15px;
      flex-shrink: 0;
    }

    .review-delete-icon-btn {
      width: 38px;
      height: 38px;
      padding: 0;
      border-radius: 14px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 17px;
      background: #ffffff;
    }

    .review-rating-section {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      padding: 14px;
      border-radius: 22px;
      border: 1px solid rgba(224, 231, 241, 0.9);
      background:
        radial-gradient(circle at top right, rgba(255, 171, 0, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      margin-bottom: 14px;
    }

    .review-rating-label {
      font-size: 12px;
      font-weight: 900;
      padding: 8px 10px;
      border-radius: 999px;
      white-space: nowrap;
      margin-bottom: 9px;
    }

    .review-stars {
      display: flex;
      align-items: center;
      gap: 2px;
      color: #ffab00;
      font-size: 18px;
      line-height: 1;
    }

    .review-star-empty {
      color: #d9dee3;
    }

    .review-rating-number {
      color: var(--mf-ink);
      font-size: 20px;
      font-weight: 900;
      line-height: 1;
      white-space: nowrap;
    }

    .review-comment-box {
      position: relative;
      min-height: 132px;
      border-radius: 24px;
      padding: 46px 18px 18px;
      background:
        radial-gradient(circle at top right, rgba(88, 115, 220, 0.08), transparent 34%),
        linear-gradient(180deg, #fbfdff 0%, #f4f7fb 100%);
      border: 1px solid rgba(224, 231, 241, 0.9);
      margin-bottom: 14px;
    }

    .review-quote-icon {
      position: absolute;
      top: 15px;
      left: 18px;
      width: 28px;
      height: 28px;
      border-radius: 12px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: rgba(255, 171, 0, 0.14);
      color: #c57b00;
      font-size: 18px;
    }

    .review-comment-box p {
      color: var(--mf-ink);
      font-size: 14px;
      font-weight: 700;
      line-height: 1.75;
      margin-bottom: 0;
      white-space: pre-line;
      display: -webkit-box;
      -webkit-line-clamp: 5;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .review-mini-detail-list {
      display: grid;
      gap: 10px;
      margin-top: auto;
    }

    .review-mini-detail {
      display: grid;
      grid-template-columns: 42px 1fr;
      gap: 11px;
      align-items: flex-start;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      padding: 13px;
      background: #ffffff;
    }

    .review-mini-icon {
      width: 42px;
      height: 42px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 20px;
    }

    .review-mini-detail span {
      display: block;
      color: var(--mf-muted);
      font-size: 10px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 4px;
    }

    .review-mini-detail strong {
      display: block;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
      line-height: 1.4;
    }

    .review-mini-detail p {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.55;
      margin: 4px 0 0;
    }

    .review-card-footer-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-top: 12px;
      padding: 13px 14px;
      border-radius: 20px;
      background: rgba(47, 177, 140, 0.08);
    }

    .review-card-footer-info div {
      display: flex;
      align-items: center;
      gap: 6px;
      min-width: 0;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 800;
    }

    .review-card-footer-info div i {
      color: var(--mf-primary);
      font-size: 16px;
      flex-shrink: 0;
    }

    .review-card-footer-info div span {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .review-card-footer-info strong {
      color: #167a64;
      font-size: 12px;
      font-weight: 900;
      white-space: nowrap;
    }

    .review-empty-state {
      grid-column: 1 / -1;
      text-align: center;
      padding: 60px 20px;
      border: 1px dashed var(--mf-border);
      border-radius: 28px;
      background: #ffffff;
      color: var(--mf-muted);
      font-weight: 700;
    }

    .review-empty-state i {
      display: block;
      color: var(--mf-primary);
      font-size: 58px;
      margin-bottom: 12px;
    }

    .review-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .review-empty-state p {
      margin-bottom: 0;
    }

    .review-footer {
      padding: 18px 34px !important;
      background: #ffffff;
      border-top: 1px solid var(--mf-border);
    }

    @media (max-width: 1400px) {
      .review-filter-grid {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }

      .review-filter-search-group {
        grid-column: span 2;
      }

      .review-filter-actions {
        grid-column: span 2;
        justify-content: flex-end;
        width: 100%;
      }
    }

    @media (max-width: 1200px) {
      .review-card-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }

    @media (max-width: 992px) {
      .review-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .review-hero-actions,
      .review-hero-badge {
        width: 100%;
      }

      .review-filter-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .review-filter-search-group,
      .review-filter-actions {
        grid-column: span 2;
      }

      .review-filter-actions {
        justify-content: flex-start;
      }
    }

    @media (max-width: 768px) {
      .review-hero-card {
        padding: 26px 22px;
      }

      .review-hero-left {
        flex-direction: column;
      }

      .review-hero-badge {
        min-height: 50px;
      }

      .review-list-card .card-header,
      .review-filter-body,
      .review-card-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .review-info-card {
        grid-template-columns: 1fr;
      }

      .review-filter-form {
        padding: 16px;
      }

      .review-filter-grid,
      .review-card-grid {
        grid-template-columns: 1fr;
      }

      .review-filter-search-group,
      .review-filter-actions {
        grid-column: span 1;
      }

      .review-filter-actions {
        flex-direction: column;
        min-width: 0;
      }

      .review-filter-actions .btn,
      .review-filter-actions .btn-outline-secondary {
        width: 100%;
      }

      .review-card-top {
        align-items: flex-start;
      }

      .review-client-block {
        min-width: 0;
      }

      .review-rating-section {
        flex-direction: column;
      }

      .review-card-footer-info {
        align-items: flex-start;
        flex-direction: column;
      }
    }

    .review-price-breakdown {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 10px;
        margin-top: 10px;
      }

      .review-price-breakdown div {
        padding: 11px 12px;
        border-radius: 18px;
        border: 1px solid var(--mf-border);
        background:
          radial-gradient(circle at top right, rgba(88, 115, 220, 0.08), transparent 34%),
          linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      }

      .review-price-breakdown span {
        display: block;
        color: var(--mf-muted);
        font-size: 10px;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        margin-bottom: 4px;
      }

      .review-price-breakdown strong {
        display: block;
        color: var(--mf-ink);
        font-size: 12px;
        font-weight: 900;
      }
  </style>
@endsection