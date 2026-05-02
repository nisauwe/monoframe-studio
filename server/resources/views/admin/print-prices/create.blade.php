@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Paket Cetak')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="print-create-shell">

      {{-- HERO HEADER --}}
      <div class="print-create-hero mb-4">
        <div class="print-create-hero-left">
          <div class="print-create-hero-icon">
            <i class="bx bx-printer"></i>
          </div>

          <div>
            <div class="print-create-kicker">MANAJEMEN PAKET CETAK</div>
            <h4>Tambah Paket Cetak</h4>
            <p>
              Tambahkan ukuran cetak, harga cetak, harga bingkai, catatan, dan status
              agar klien dapat memilih layanan cetak foto dengan mudah.
            </p>
          </div>
        </div>

        <div class="print-create-hero-actions">
          <a href="{{ route('admin.packages.index', ['tab' => 'print-prices']) }}" class="btn print-create-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      {{-- ERROR ALERT --}}
      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4 print-create-alert" role="alert">
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

      <div class="row g-4">
        <div class="col-lg-8">
          <div class="card print-create-card">
            <div class="card-header">
              <div>
                <h5 class="mb-1">Form Paket Cetak</h5>
                <p class="mb-0">
                  Lengkapi ukuran cetak, harga cetak, harga bingkai, status, dan catatan tambahan.
                </p>
              </div>
            </div>

            <div class="card-body">
              <form action="{{ route('admin.print-prices.store') }}" method="POST">
                @csrf

                <div class="print-form-section">
                  <div class="print-section-heading">
                    <div class="print-section-icon">
                      <i class="bx bx-ruler"></i>
                    </div>

                    <div>
                      <h6>Detail Paket Cetak</h6>
                      <p>
                        Masukkan ukuran dan harga layanan cetak yang akan tampil ke klien.
                      </p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-6">
                      <label for="size_label" class="form-label">Ukuran Cetak</label>
                      <input
                        type="text"
                        name="size_label"
                        id="size_label"
                        class="form-control"
                        value="{{ old('size_label') }}"
                        placeholder="Contoh: 4R"
                        required
                        autofocus>
                      <div class="form-text">
                        Contoh ukuran: 2R, 3R, 4R, 5R, 10R, A4, atau Custom.
                      </div>
                    </div>

                    <div class="col-md-6">
                      <label for="base_price" class="form-label">Harga Cetak</label>
                      <div class="input-group print-input-group">
                        <span class="input-group-text">Rp</span>
                        <input
                          type="number"
                          name="base_price"
                          id="base_price"
                          class="form-control"
                          value="{{ old('base_price') }}"
                          min="0"
                          placeholder="Contoh: 15000"
                          required>
                      </div>
                      <div class="form-text">
                        Harga dasar untuk cetak foto tanpa bingkai.
                      </div>
                    </div>

                    <div class="col-md-6">
                      <label for="frame_price" class="form-label">Harga Bingkai</label>
                      <div class="input-group print-input-group">
                        <span class="input-group-text">Rp</span>
                        <input
                          type="number"
                          name="frame_price"
                          id="frame_price"
                          class="form-control"
                          value="{{ old('frame_price') }}"
                          min="0"
                          placeholder="Contoh: 25000"
                          required>
                      </div>
                      <div class="form-text">
                        Isi 0 jika ukuran cetak ini tidak menyediakan bingkai.
                      </div>
                    </div>

                    <div class="col-md-6">
                      <label for="is_active" class="form-label d-block">Status</label>

                      <div class="print-status-card">
                        <div class="print-status-info">
                          <div class="print-status-icon">
                            <i class="bx bx-check-shield"></i>
                          </div>

                          <div>
                            <div class="print-status-title">Status Paket</div>
                            <div class="print-status-subtitle">
                              Jika aktif, paket cetak akan tampil ke klien.
                            </div>
                          </div>
                        </div>

                        <input type="hidden" name="is_active" value="0">

                        <div class="form-check form-switch print-switch mb-0">
                          <input
                            class="form-check-input"
                            type="checkbox"
                            role="switch"
                            id="is_active"
                            name="is_active"
                            value="1"
                            {{ old('is_active', true) ? 'checked' : '' }}>
                          <label class="form-check-label" for="is_active">
                            Aktif
                          </label>
                        </div>
                      </div>
                    </div>

                    <div class="col-12">
                      <label for="notes" class="form-label">Catatan</label>
                      <textarea
                        name="notes"
                        id="notes"
                        rows="5"
                        class="form-control print-textarea"
                        placeholder="Catatan tambahan (opsional)">{{ old('notes') }}</textarea>
                      <div class="form-text">
                        Contoh: sudah termasuk laminasi, estimasi cetak 1 hari, atau catatan khusus lainnya.
                      </div>
                    </div>
                  </div>
                </div>

                <div class="print-form-actions">
                  <button type="submit" class="btn btn-primary">
                    <i class="bx bx-save me-1"></i>
                    Simpan Paket Cetak
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>

        <div class="col-lg-4">
          <div class="print-side-sticky">
            <div class="print-helper-card">
              <div class="print-helper-icon">
                <i class="bx bx-bulb"></i>
              </div>

              <h5>Tips Paket Cetak</h5>
              <p>
                Buat paket cetak berdasarkan ukuran foto yang paling sering dipilih klien.
                Pastikan harga cetak dan harga bingkai sudah sesuai.
              </p>

              <div class="print-helper-list">
                <div class="print-helper-item">
                  <i class="bx bx-check-circle"></i>
                  <span>Gunakan label ukuran yang jelas, misalnya 4R atau A4.</span>
                </div>

                <div class="print-helper-item">
                  <i class="bx bx-check-circle"></i>
                  <span>Harga cetak dan bingkai wajib berupa angka.</span>
                </div>

                <div class="print-helper-item">
                  <i class="bx bx-check-circle"></i>
                  <span>Nonaktifkan paket jika belum siap ditampilkan ke klien.</span>
                </div>
              </div>
            </div>

            <div class="print-preview-card mt-4">
              <div class="print-preview-head">
                <div>
                  <div class="print-preview-label">Preview</div>
                  <h6 id="previewPrintTitle">Paket Cetak Baru</h6>
                </div>

                <span class="badge bg-label-success" id="previewStatusBadge">Aktif</span>
              </div>

              <div class="print-preview-body">
                <div class="print-preview-icon">
                  <i class="bx bx-printer"></i>
                </div>

                <div>
                  <div class="print-preview-title" id="previewSizeLabel">Ukuran Cetak</div>
                  <div class="print-preview-subtitle" id="previewNotesText">
                    Harga cetak dan bingkai akan tampil di daftar paket cetak.
                  </div>
                </div>
              </div>

              <div class="print-preview-price-grid">
                <div>
                  <small>Harga Cetak</small>
                  <strong id="previewBasePrice">Rp 0</strong>
                </div>

                <div>
                  <small>Harga Bingkai</small>
                  <strong id="previewFramePrice">Rp 0</strong>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      .print-create-hero {
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

      .print-create-hero::after {
        content: "";
        position: absolute;
        width: 260px;
        height: 260px;
        right: -90px;
        bottom: -130px;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.14);
      }

      .print-create-hero-left {
        position: relative;
        z-index: 2;
        display: flex;
        align-items: flex-start;
        gap: 18px;
        min-width: 0;
        max-width: 900px;
      }

      .print-create-hero-icon {
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

      .print-create-kicker {
        color: rgba(255, 255, 255, 0.78);
        font-size: 12px;
        font-weight: 900;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        margin-bottom: 8px;
      }

      .print-create-hero h4 {
        color: #ffffff;
        font-size: 30px;
        font-weight: 900;
        line-height: 1.2;
        margin-bottom: 10px;
      }

      .print-create-hero p {
        color: rgba(255, 255, 255, 0.86);
        font-size: 15px;
        font-weight: 600;
        line-height: 1.75;
        margin-bottom: 0;
      }

      .print-create-hero-actions {
        position: relative;
        z-index: 2;
        flex-shrink: 0;
      }

      .print-create-back-btn {
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

      .print-create-back-btn:hover {
        background: #ffffff;
        color: var(--mf-primary);
        transform: translateY(-2px);
        box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
      }

      .print-create-alert {
        border: 0;
        border-radius: 20px;
        box-shadow: var(--mf-shadow-soft);
      }

      .print-create-alert i {
        font-size: 20px;
      }

      .print-create-card,
      .print-helper-card,
      .print-preview-card {
        border: 0;
        border-radius: 30px;
        background: rgba(255, 255, 255, 0.98);
        box-shadow: var(--mf-shadow-soft);
        overflow: hidden;
      }

      .print-create-card .card-header {
        padding: 30px 34px 22px !important;
        border-bottom: 1px solid var(--mf-border);
        background:
          radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
          linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      }

      .print-create-card .card-header h5 {
        color: var(--mf-ink);
        font-weight: 900;
      }

      .print-create-card .card-header p {
        color: var(--mf-muted);
        font-size: 14px;
        font-weight: 600;
        line-height: 1.6;
      }

      .print-create-card .card-body {
        padding: 30px 34px 34px !important;
        background:
          radial-gradient(circle at top right, rgba(159, 191, 210, 0.10), transparent 35%),
          linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      }

      .print-form-section {
        margin-bottom: 30px;
        padding-bottom: 30px;
        border-bottom: 1px solid var(--mf-border);
      }

      .print-section-heading {
        display: flex;
        align-items: flex-start;
        gap: 14px;
        margin-bottom: 20px;
      }

      .print-section-icon,
      .print-status-icon,
      .print-helper-icon,
      .print-preview-icon {
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

      .print-section-heading h6 {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 5px;
      }

      .print-section-heading p {
        color: var(--mf-muted);
        font-size: 13px;
        font-weight: 600;
        line-height: 1.6;
        margin-bottom: 0;
      }

      .print-create-card .form-label {
        color: var(--mf-ink);
        font-size: 12px;
        font-weight: 900;
        letter-spacing: 0.02em;
        margin-bottom: 8px;
      }

      .print-create-card .form-control {
        min-height: 54px;
        border-radius: 18px !important;
        border: 1px solid var(--mf-border) !important;
        background: #ffffff !important;
        color: var(--mf-ink) !important;
        font-size: 14px !important;
        font-weight: 700 !important;
        box-shadow: none !important;
      }

      .print-create-card .form-control:focus {
        border-color: rgba(88, 115, 220, 0.48) !important;
        box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
      }

      .print-create-card .form-text {
        color: var(--mf-muted);
        font-size: 12px;
        font-weight: 600;
        margin-top: 8px;
      }

      .print-textarea {
        min-height: 132px !important;
        padding-top: 14px !important;
        resize: vertical;
      }

      .print-input-group {
        min-height: 54px;
        border: 1px solid var(--mf-border);
        border-radius: 18px;
        overflow: hidden;
        background: #ffffff;
        transition: 0.18s ease;
      }

      .print-input-group:focus-within {
        border-color: rgba(88, 115, 220, 0.48);
        box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
      }

      .print-input-group .input-group-text {
        border: 0 !important;
        background: #ffffff !important;
        color: var(--mf-muted) !important;
        font-size: 13px !important;
        font-weight: 900 !important;
        padding-left: 16px;
        padding-right: 16px;
      }

      .print-input-group .form-control {
        border: 0 !important;
        border-radius: 0 !important;
        min-height: 52px !important;
      }

      .print-status-card {
        min-height: 84px;
        padding: 16px 18px;
        border: 1px solid var(--mf-border);
        border-radius: 22px;
        background:
          radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 36%),
          #ffffff;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 16px;
      }

      .print-status-info {
        display: flex;
        align-items: center;
        gap: 14px;
        min-width: 0;
      }

      .print-status-title {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 4px;
      }

      .print-status-subtitle {
        color: var(--mf-muted);
        font-size: 12px;
        font-weight: 600;
        line-height: 1.55;
      }

      .print-switch {
        flex-shrink: 0;
      }

      .print-switch .form-check-input {
        width: 46px;
        height: 24px;
        cursor: pointer;
      }

      .print-switch .form-check-label {
        color: var(--mf-ink);
        font-weight: 900;
        margin-left: 6px;
        cursor: pointer;
      }

      .print-form-actions {
        display: flex;
        justify-content: flex-end;
        align-items: center;
        flex-wrap: wrap;
        gap: 12px;
      }

      .print-form-actions .btn {
        min-height: 48px;
        border-radius: 16px;
        font-weight: 900;
        padding-left: 24px;
        padding-right: 24px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
      }

      .print-side-sticky {
        position: sticky;
        top: 105px;
      }

      .print-helper-card,
      .print-preview-card {
        padding: 26px;
      }

      .print-helper-icon {
        width: 58px;
        height: 58px;
        border-radius: 20px;
        font-size: 30px;
        margin-bottom: 18px;
      }

      .print-helper-card h5 {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 10px;
      }

      .print-helper-card p {
        color: var(--mf-muted);
        font-size: 14px;
        font-weight: 600;
        line-height: 1.7;
        margin-bottom: 18px;
      }

      .print-helper-list {
        display: flex;
        flex-direction: column;
        gap: 12px;
      }

      .print-helper-item {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        color: var(--mf-ink);
        font-size: 13px;
        font-weight: 700;
        line-height: 1.55;
      }

      .print-helper-item i {
        color: var(--mf-primary);
        font-size: 18px;
        margin-top: 1px;
      }

      .print-preview-head {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 14px;
        margin-bottom: 18px;
      }

      .print-preview-label {
        color: var(--mf-muted);
        font-size: 11px;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        margin-bottom: 4px;
      }

      .print-preview-head h6 {
        color: var(--mf-ink);
        font-weight: 900;
        margin: 0;
      }

      .print-preview-body {
        display: flex;
        align-items: center;
        gap: 14px;
        padding: 16px;
        border: 1px solid var(--mf-border);
        border-radius: 22px;
        background:
          radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 38%),
          #ffffff;
        margin-bottom: 14px;
      }

      .print-preview-icon {
        width: 44px;
        height: 44px;
        border-radius: 16px;
        font-size: 20px;
      }

      .print-preview-title {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 3px;
      }

      .print-preview-subtitle {
        color: var(--mf-muted);
        font-size: 12px;
        font-weight: 600;
        line-height: 1.5;
      }

      .print-preview-price-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 12px;
      }

      .print-preview-price-grid div {
        padding: 14px;
        border: 1px solid var(--mf-border);
        border-radius: 18px;
        background: #ffffff;
      }

      .print-preview-price-grid small {
        display: block;
        color: var(--mf-muted);
        font-size: 11px;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        margin-bottom: 5px;
      }

      .print-preview-price-grid strong {
        color: var(--mf-ink);
        font-size: 13px;
        font-weight: 900;
      }

      @media (max-width: 992px) {
        .print-create-hero {
          align-items: flex-start;
          flex-direction: column;
        }

        .print-create-hero-actions,
        .print-create-back-btn {
          width: 100%;
        }

        .print-side-sticky {
          position: static;
        }
      }

      @media (max-width: 768px) {
        .print-create-hero {
          padding: 26px 22px;
        }

        .print-create-hero-left {
          flex-direction: column;
        }

        .print-create-hero h4 {
          font-size: 26px;
        }

        .print-create-card .card-header,
        .print-create-card .card-body {
          padding-left: 22px !important;
          padding-right: 22px !important;
        }

        .print-section-heading,
        .print-status-card,
        .print-status-info {
          align-items: flex-start;
          flex-direction: column;
        }

        .print-form-actions {
          flex-direction: column-reverse;
        }

        .print-form-actions .btn {
          width: 100%;
        }

        .print-helper-card,
        .print-preview-card {
          padding: 22px;
        }

        .print-preview-price-grid {
          grid-template-columns: 1fr;
        }
      }
    </style>
    <script>
      document.addEventListener('DOMContentLoaded', function () {
        const sizeLabelInput = document.getElementById('size_label');
        const basePriceInput = document.getElementById('base_price');
        const framePriceInput = document.getElementById('frame_price');
        const notesInput = document.getElementById('notes');
        const isActiveInput = document.getElementById('is_active');

        const previewPrintTitle = document.getElementById('previewPrintTitle');
        const previewStatusBadge = document.getElementById('previewStatusBadge');
        const previewSizeLabel = document.getElementById('previewSizeLabel');
        const previewNotesText = document.getElementById('previewNotesText');
        const previewBasePrice = document.getElementById('previewBasePrice');
        const previewFramePrice = document.getElementById('previewFramePrice');

        function formatRupiah(value) {
          const number = parseInt(value || 0, 10);

          if (Number.isNaN(number)) {
            return 'Rp 0';
          }

          return 'Rp ' + new Intl.NumberFormat('id-ID').format(number);
        }

        function updatePreview() {
          const sizeLabel = sizeLabelInput.value.trim();
          const notes = notesInput.value.trim();
          const isActive = isActiveInput.checked;

          previewPrintTitle.textContent = sizeLabel
            ? 'Paket Cetak ' + sizeLabel
            : 'Paket Cetak Baru';

          previewSizeLabel.textContent = sizeLabel || 'Ukuran Cetak';

          previewNotesText.textContent = notes
            ? notes
            : 'Harga cetak dan bingkai akan tampil di daftar paket cetak.';

          previewBasePrice.textContent = formatRupiah(basePriceInput.value);
          previewFramePrice.textContent = formatRupiah(framePriceInput.value);

          previewStatusBadge.textContent = isActive ? 'Aktif' : 'Tidak Aktif';

          previewStatusBadge.classList.toggle('bg-label-success', isActive);
          previewStatusBadge.classList.toggle('bg-label-secondary', !isActive);
        }

        [
          sizeLabelInput,
          basePriceInput,
          framePriceInput,
          notesInput,
          isActiveInput
        ].forEach(function (input) {
          if (!input) {
            return;
          }

          input.addEventListener('input', updatePreview);
          input.addEventListener('change', updatePreview);
        });

        updatePreview();
      });
    </script>
  </div>
@endsection
