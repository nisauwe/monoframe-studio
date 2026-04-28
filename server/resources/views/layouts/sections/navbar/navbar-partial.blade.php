@php
  use Illuminate\Support\Facades\Auth;

  $authUser = Auth::user();

  $profilePhotoUrl = $authUser && $authUser->profile_photo
    ? asset('storage/' . $authUser->profile_photo)
    : asset('assets/img/avatars/1.png');

  $displayName = $authUser?->name ?? 'Admin Monoframe';
  $displayRole = $authUser?->role ?? 'Admin';

  $firstName = explode(' ', trim($displayName))[0] ?? 'Admin';
@endphp

@if (isset($navbarFull))
  <div class="navbar-brand app-brand demo d-none d-xl-flex py-0 me-4">
    <a href="{{ url('/admin/dashboard') }}" class="app-brand-link gap-2">
      <span class="app-brand-logo demo">
        <img
          src="{{ asset('assets/img/logo/monoframe-logo.png') }}"
          alt="Monoframe Logo"
          style="width: 32px; height: 32px; object-fit: contain;">
      </span>
      <span class="app-brand-text demo menu-text fw-bold text-heading">MONOFRAME</span>
    </a>
  </div>
@endif

@if (!isset($navbarHideToggle))
  <div
    class="layout-menu-toggle navbar-nav align-items-xl-center me-3 me-xl-0 {{ isset($contentNavbar) ? ' d-xl-none ' : '' }}">
    <a class="nav-item nav-link px-0 me-xl-6" href="javascript:void(0)">
      <i class="icon-base bx bx-menu icon-md"></i>
    </a>
  </div>
@endif

<div class="navbar-nav-right d-flex align-items-center justify-content-between w-100 monoframe-navbar-custom" id="navbar-collapse">

  {{-- LEFT GREETING --}}
  <div class="monoframe-navbar-greeting">
    Hello <span>{{ strtoupper($firstName) }}</span>, welcome back!
  </div>

  {{-- RIGHT NAVBAR --}}
  <ul class="navbar-nav flex-row align-items-center ms-auto monoframe-navbar-actions">

    {{-- USER DROPDOWN --}}
    <li class="nav-item navbar-dropdown dropdown-user dropdown">
      <a
        class="nav-link dropdown-toggle hide-arrow p-0"
        href="javascript:void(0);"
        data-bs-toggle="dropdown">

        <div class="monoframe-navbar-profile-card">
          <img
            src="{{ $profilePhotoUrl }}"
            alt="{{ $displayName }}"
            class="monoframe-navbar-profile-photo">

          <div class="monoframe-navbar-profile-info">
            <div class="monoframe-navbar-profile-name">
              {{ $displayName }}
            </div>
            <div class="monoframe-navbar-profile-role">
              {{ $displayRole }}
            </div>
          </div>

          <i class="bx bx-chevron-down monoframe-navbar-profile-arrow"></i>
        </div>
      </a>

      <ul class="dropdown-menu dropdown-menu-end">
        <li>
          <a class="dropdown-item" href="{{ route('admin.profile.index') }}">
            <div class="d-flex align-items-center">
              <div class="flex-shrink-0 me-3">
                <div class="avatar avatar-online">
                  <img
                    src="{{ $profilePhotoUrl }}"
                    alt="{{ $displayName }}"
                    class="w-px-40 h-px-40 rounded-circle object-fit-cover">
                </div>
              </div>

              <div class="flex-grow-1">
                <h6 class="mb-0">{{ $displayName }}</h6>
                <small class="text-muted">{{ $displayRole }}</small>
              </div>
            </div>
          </a>
        </li>

        <li>
          <div class="dropdown-divider my-1"></div>
        </li>

        <li>
          <a class="dropdown-item" href="{{ route('admin.profile.index') }}">
            <i class="icon-base bx bx-user icon-md me-3"></i>
            <span>Profil Saya</span>
          </a>
        </li>

        <li>
          <div class="dropdown-divider my-1"></div>
        </li>
      </ul>
    </li>
  </ul>
</div>