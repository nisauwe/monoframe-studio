<div class="row g-3">
  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_title">Judul Kontak</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_title"
      name="title"
      placeholder="Contoh: Front Office"
      required
    >
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_division">Divisi</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_division"
      name="division"
      placeholder="Contoh: Front Office / Payment Support"
    >
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_contact_person">Nama Kontak</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_contact_person"
      name="contact_person"
      placeholder="Contoh: Rina Sari"
    >
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_platform">Platform</label>
    <select class="form-select" id="{{ $prefix }}_platform" name="platform" required>
      <option value="whatsapp">WhatsApp</option>
      <option value="instagram">Instagram</option>
      <option value="tiktok">TikTok</option>
      <option value="email">Email</option>
      <option value="phone">Telepon</option>
      <option value="website">Website</option>
    </select>
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_contact_value">Email</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_contact_value"
      name="contact_value"
      placeholder="Contoh: contact@monoframe.com"
      required
    >
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_whatsapp_number">Nomor WhatsApp</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_whatsapp_number"
      name="whatsapp_number"
      placeholder="Opsional, contoh: 0813xxxx"
    >
    <small class="text-muted">Dipakai jika platform WhatsApp.</small>
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_url">URL</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_url"
      name="url"
      placeholder="Opsional, contoh: https://instagram.com/monoframe"
    >
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_service_hours">Jam Layanan</label>
    <input
      type="text"
      class="form-control"
      id="{{ $prefix }}_service_hours"
      name="service_hours"
      placeholder="Contoh: 08:00 - 17:00 / 24 Jam"
    >
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_priority">Prioritas</label>
    <select class="form-select" id="{{ $prefix }}_priority" name="priority" required>
      <option value="low">Rendah</option>
      <option value="normal" selected>Normal</option>
      <option value="high">Tinggi</option>
      <option value="urgent">Darurat</option>
    </select>
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_status">Status</label>
    <select class="form-select" id="{{ $prefix }}_status" name="status" required>
      <option value="active" selected>Aktif</option>
      <option value="standby">Standby</option>
      <option value="inactive">Nonaktif</option>
    </select>
  </div>

  <div class="col-md-6">
    <label class="form-label" for="{{ $prefix }}_sort_order">Urutan Tampil</label>
    <input
      type="number"
      min="0"
      class="form-control"
      id="{{ $prefix }}_sort_order"
      name="sort_order"
      value="0"
    >
  </div>

  <div class="col-12">
    <label class="form-label" for="{{ $prefix }}_description">Deskripsi</label>
    <textarea
      class="form-control"
      id="{{ $prefix }}_description"
      name="description"
      rows="3"
      placeholder="Contoh: Kendala booking, jadwal, pertanyaan paket foto"
    ></textarea>
  </div>

  <div class="col-md-6">
    <div class="form-check">
      <input
        class="form-check-input"
        type="checkbox"
        id="{{ $prefix }}_is_emergency"
        name="is_emergency"
        value="1"
      >
      <label class="form-check-label" for="{{ $prefix }}_is_emergency">
        Tandai sebagai kontak darurat
      </label>
    </div>
  </div>

  <div class="col-md-6">
    <div class="form-check">
      <input
        class="form-check-input"
        type="checkbox"
        id="{{ $prefix }}_is_visible_to_client"
        name="is_visible_to_client"
        value="1"
        checked
      >
      <label class="form-check-label" for="{{ $prefix }}_is_visible_to_client">
        Tampilkan di aplikasi klien
      </label>
    </div>
  </div>
</div>
