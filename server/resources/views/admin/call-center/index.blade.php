@extends('layouts/contentNavbarLayout')

@section('title', 'Call Center Kontak')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Call Center Kontak</h4>
        <p class="text-muted mb-0">
          Kelola daftar kontak yang bisa dihubungi klien untuk pertanyaan paket, request custom, pembayaran, dan bantuan lain.
        </p>
      </div>

      <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#createContactModal">
        <i class="bx bx-plus me-1"></i> Tambah Kontak
      </button>
    </div>

    @if (session('success'))
      <div class="alert alert-success alert-dismissible" role="alert">
        {{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    @endif

    @if ($errors->any())
      <div class="alert alert-danger alert-dismissible" role="alert">
        <strong>Data belum valid.</strong>
        <ul class="mb-0 mt-2">
          @foreach ($errors->all() as $error)
            <li>{{ $error }}</li>
          @endforeach
        </ul>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    @endif

    <div class="row">
      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Total Kontak</span>
                <h3 class="card-title mb-2">{{ $summary['total'] ?? 0 }}</h3>
                <small class="text-primary fw-semibold">Kontak bantuan terdaftar</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-primary">
                  <i class="bx bx-phone-call"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Kontak Aktif</span>
                <h3 class="card-title mb-2">{{ $summary['active'] ?? 0 }}</h3>
                <small class="text-success fw-semibold">Siap dihubungi klien</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-success">
                  <i class="bx bx-check-circle"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Kontak Darurat</span>
                <h3 class="card-title mb-2">{{ $summary['emergency'] ?? 0 }}</h3>
                <small class="text-danger fw-semibold">Prioritas jika butuh bantuan cepat</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-danger">
                  <i class="bx bx-error-circle"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-lg-8 mb-4">
        <div class="card h-100">
          <div class="card-header">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
              <div>
                <h5 class="mb-0">Daftar Kontak</h5>
                <small class="text-muted">Kontak ini dapat ditampilkan juga di aplikasi Flutter klien.</small>
              </div>

              <form method="GET" action="{{ route('admin.call-center.index') }}" class="d-flex flex-wrap gap-2">
                <input
                  type="text"
                  name="q"
                  class="form-control"
                  value="{{ request('q') }}"
                  placeholder="Cari nama, divisi, kontak..."
                  style="width: 230px;"
                >

                <select name="division" class="form-select" style="width: 170px;">
                  <option value="">Semua Divisi</option>
                  @foreach ($divisions as $division)
                    <option value="{{ $division }}" @selected(request('division') === $division)>
                      {{ $division }}
                    </option>
                  @endforeach
                </select>

                <select name="platform" class="form-select" style="width: 150px;">
                  <option value="">Semua Platform</option>
                  <option value="whatsapp" @selected(request('platform') === 'whatsapp')>WhatsApp</option>
                  <option value="instagram" @selected(request('platform') === 'instagram')>Instagram</option>
                  <option value="tiktok" @selected(request('platform') === 'tiktok')>TikTok</option>
                  <option value="email" @selected(request('platform') === 'email')>Email</option>
                  <option value="phone" @selected(request('platform') === 'phone')>Telepon</option>
                  <option value="website" @selected(request('platform') === 'website')>Website</option>
                </select>

                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-search"></i>
                </button>

                <a href="{{ route('admin.call-center.index') }}" class="btn btn-outline-secondary">
                  Reset
                </a>
              </form>
            </div>
          </div>

          <div class="card-body">
            @if ($contacts->isEmpty())
              <div class="text-center py-5">
                <i class="bx bx-phone-off display-5 text-muted"></i>
                <h5 class="mt-3 mb-1">Belum ada kontak</h5>
                <p class="text-muted mb-3">Tambahkan kontak WhatsApp, Instagram, TikTok, Email, atau Website.</p>
                <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#createContactModal">
                  <i class="bx bx-plus me-1"></i> Tambah Kontak
                </button>
              </div>
            @else
              <div class="row g-3">
                @foreach ($contacts as $contact)
                  @php
                    $statusClass = match ($contact->status) {
                        'active' => 'success',
                        'standby' => 'secondary',
                        'inactive' => 'dark',
                        default => 'secondary',
                    };

                    $priorityClass = match ($contact->priority) {
                        'urgent' => 'danger',
                        'high' => 'warning',
                        'normal' => 'primary',
                        'low' => 'secondary',
                        default => 'secondary',
                    };

                    $platformIcon = match ($contact->platform) {
                        'whatsapp' => 'bxl-whatsapp',
                        'instagram' => 'bxl-instagram',
                        'tiktok' => 'bxl-tiktok',
                        'email' => 'bx-envelope',
                        'phone' => 'bx-phone',
                        'website' => 'bx-globe',
                        default => 'bx-link',
                    };
                  @endphp

                  <div class="col-md-6">
                    <div class="border rounded p-3 h-100">
                      <div class="d-flex justify-content-between align-items-start mb-2">
                        <div>
                          <h6 class="mb-1">{{ $contact->title }}</h6>
                          <small class="text-muted">{{ $contact->description ?: '-' }}</small>
                        </div>
                        <div class="d-flex flex-column align-items-end gap-1">
                          <span class="badge bg-label-{{ $statusClass }}">{{ $contact->status_label }}</span>
                          @if ($contact->is_emergency)
                            <span class="badge bg-label-danger">Darurat</span>
                          @endif
                        </div>
                      </div>

                      <ul class="list-unstyled mb-3">
                        <li class="mb-2">
                          <strong>Divisi:</strong> {{ $contact->division ?: '-' }}
                        </li>
                        <li class="mb-2">
                          <strong>Nama:</strong> {{ $contact->contact_person ?: '-' }}
                        </li>
                        <li class="mb-2">
                          <strong>Platform:</strong>
                          <i class="bx {{ $platformIcon }}"></i> {{ $contact->platform_label }}
                        </li>
                        <li class="mb-2">
                          <strong>Kontak:</strong> {{ $contact->contact_value }}
                        </li>
                        <li class="mb-2">
                          <strong>Jam Layanan:</strong> {{ $contact->service_hours ?: '-' }}
                        </li>
                        <li class="mb-2">
                          <strong>Prioritas:</strong>
                          <span class="badge bg-label-{{ $priorityClass }}">{{ $contact->priority_label }}</span>
                        </li>
                        <li class="mb-0">
                          <strong>Tampil di Klien:</strong>
                          @if ($contact->is_visible_to_client)
                            <span class="badge bg-label-success">Ya</span>
                          @else
                            <span class="badge bg-label-secondary">Tidak</span>
                          @endif
                        </li>
                      </ul>

                      <div class="d-flex flex-wrap gap-2">
                        @if ($contact->contact_url)
                          <a href="{{ $contact->contact_url }}" target="_blank" class="btn btn-success btn-sm">
                            <i class="bx {{ $platformIcon }} me-1"></i> Buka
                          </a>
                        @endif

                        <button
                          type="button"
                          class="btn btn-outline-warning btn-sm btn-edit-contact"
                          data-bs-toggle="modal"
                          data-bs-target="#editContactModal"
                          data-id="{{ $contact->id }}"
                          data-title="{{ $contact->title }}"
                          data-division="{{ $contact->division }}"
                          data-description="{{ $contact->description }}"
                          data-contact-person="{{ $contact->contact_person }}"
                          data-platform="{{ $contact->platform }}"
                          data-contact-value="{{ $contact->contact_value }}"
                          data-whatsapp-number="{{ $contact->whatsapp_number }}"
                          data-url="{{ $contact->url }}"
                          data-service-hours="{{ $contact->service_hours }}"
                          data-priority="{{ $contact->priority }}"
                          data-status="{{ $contact->status }}"
                          data-is-emergency="{{ $contact->is_emergency ? 1 : 0 }}"
                          data-is-visible-to-client="{{ $contact->is_visible_to_client ? 1 : 0 }}"
                          data-sort-order="{{ $contact->sort_order }}"
                        >
                          Edit
                        </button>

                        <form action="{{ route('admin.call-center.toggle-status', $contact) }}" method="POST">
                          @csrf
                          @method('PATCH')
                          <button type="submit" class="btn btn-outline-secondary btn-sm">
                            {{ $contact->status === 'active' ? 'Nonaktifkan' : 'Aktifkan' }}
                          </button>
                        </form>

                        <form action="{{ route('admin.call-center.destroy', $contact) }}" method="POST" class="form-delete-contact">
                          @csrf
                          @method('DELETE')
                          <button type="submit" class="btn btn-outline-danger btn-sm">
                            Hapus
                          </button>
                        </form>
                      </div>
                    </div>
                  </div>
                @endforeach
              </div>
            @endif
          </div>
        </div>
      </div>

      <div class="col-lg-4 mb-4">
        <div class="card mb-4">
          <div class="card-header">
            <h5 class="mb-0">Alur Bantuan Klien</h5>
            <small class="text-muted">Panduan kontak yang ditampilkan ke aplikasi klien</small>
          </div>
          <div class="card-body">
            <ol class="mb-0 ps-3">
              <li class="mb-3">
                <strong>Pertanyaan paket</strong><br>
                <small class="text-muted">Klien dapat menghubungi Front Office atau Admin untuk detail paket foto.</small>
              </li>
              <li class="mb-3">
                <strong>Request foto custom</strong><br>
                <small class="text-muted">Klien bisa bertanya jika konsep foto tidak tersedia di paket.</small>
              </li>
              <li class="mb-3">
                <strong>Kendala pembayaran</strong><br>
                <small class="text-muted">Klien diarahkan ke kontak Payment Support.</small>
              </li>
              <li class="mb-0">
                <strong>Kendala aplikasi</strong><br>
                <small class="text-muted">Klien diarahkan ke kontak Admin Sistem atau IT Support.</small>
              </li>
            </ol>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h5 class="mb-0">Template Pesan WhatsApp</h5>
            <small class="text-muted">Pesan cepat untuk klien</small>
          </div>
          <div class="card-body">
            <div class="border rounded p-3 bg-light">
              <small class="text-muted d-block mb-2">Contoh pesan:</small>
              <p class="mb-0 small" id="waTemplateText">
                Halo Monoframe Studio, saya ingin bertanya tentang layanan Monoframe.<br><br>
                Nama: [isi nama]<br>
                Pertanyaan: [isi pertanyaan]<br>
                Paket/Request: [isi paket atau request custom]<br><br>
                Terima kasih.
              </p>
            </div>

            <div class="d-grid mt-3">
              <button type="button" class="btn btn-outline-primary" id="copyTemplateButton">
                <i class="bx bx-copy me-1"></i> Copy Template
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- CREATE MODAL --}}
  <div class="modal fade" id="createContactModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <form method="POST" action="{{ route('admin.call-center.store') }}" class="modal-content">
        @csrf

        <div class="modal-header">
          <h5 class="modal-title">Tambah Kontak</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body">
          @include('admin.call-center.partials.form', [
              'prefix' => 'create',
              'contact' => null,
          ])
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-success">Simpan Kontak</button>
        </div>
      </form>
    </div>
  </div>

  {{-- EDIT MODAL --}}
  <div class="modal fade" id="editContactModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <form method="POST" action="#" class="modal-content" id="editContactForm">
        @csrf
        @method('PUT')

        <div class="modal-header">
          <h5 class="modal-title">Edit Kontak</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body">
          @include('admin.call-center.partials.form', [
              'prefix' => 'edit',
              'contact' => null,
          ])
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-warning">Update Kontak</button>
        </div>
      </form>
    </div>
  </div>
@endsection

@push('scripts')
  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const editButtons = document.querySelectorAll('.btn-edit-contact');
      const editForm = document.getElementById('editContactForm');

      const updateRouteTemplate = "{{ route('admin.call-center.update', '__ID__') }}";

      editButtons.forEach(function (button) {
        button.addEventListener('click', function () {
          const id = button.dataset.id;

          editForm.action = updateRouteTemplate.replace('__ID__', id);

          setField('edit_title', button.dataset.title);
          setField('edit_division', button.dataset.division);
          setField('edit_description', button.dataset.description);
          setField('edit_contact_person', button.dataset.contactPerson);
          setField('edit_platform', button.dataset.platform);
          setField('edit_contact_value', button.dataset.contactValue);
          setField('edit_whatsapp_number', button.dataset.whatsappNumber);
          setField('edit_url', button.dataset.url);
          setField('edit_service_hours', button.dataset.serviceHours);
          setField('edit_priority', button.dataset.priority);
          setField('edit_status', button.dataset.status);
          setField('edit_sort_order', button.dataset.sortOrder);

          setCheckbox('edit_is_emergency', button.dataset.isEmergency === '1');
          setCheckbox('edit_is_visible_to_client', button.dataset.isVisibleToClient === '1');
        });
      });

      const deleteForms = document.querySelectorAll('.form-delete-contact');

      deleteForms.forEach(function (form) {
        form.addEventListener('submit', function (event) {
          const confirmed = confirm('Yakin ingin menghapus kontak ini?');

          if (!confirmed) {
            event.preventDefault();
          }
        });
      });

      const copyButton = document.getElementById('copyTemplateButton');
      const templateText = document.getElementById('waTemplateText');

      if (copyButton && templateText) {
        copyButton.addEventListener('click', async function () {
          const text = templateText.innerText;

          try {
            await navigator.clipboard.writeText(text);
            alert('Template pesan berhasil disalin.');
          } catch (error) {
            alert('Gagal menyalin template.');
          }
        });
      }

      function setField(id, value) {
        const field = document.getElementById(id);
        if (field) {
          field.value = value || '';
        }
      }

      function setCheckbox(id, checked) {
        const field = document.getElementById(id);
        if (field) {
          field.checked = checked;
        }
      }
    });
  </script>
@endpush
