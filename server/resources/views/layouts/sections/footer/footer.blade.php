@php
  $containerFooter = !empty($containerNav) ? $containerNav : 'container-fluid';
@endphp

<footer class="content-footer footer bg-footer-theme">
  <div class="{{ $containerFooter }}">
    <div class="footer-container d-flex align-items-center justify-content-center py-4">
      <div class="text-body text-center fw-semibold">
        © {{ date('Y') }} Monoframe Studio
      </div>
    </div>
  </div>
</footer>