# Hmatt (Flutter)

Aplikasi manajemen keuangan pribadi **offline-first** berbasis Flutter.

Repo ini berisi implementasi Hmatt dengan fokus utama Android (mobile-first), plus dukungan Windows untuk operasional desktop seperti Owner Dashboard.

## Status proyek (ringkas)

- Nama aplikasi: `Hmatt`
- Versi saat ini (repo): `1.0.6`
- Package Android: `id.biz.hammad.hmatt`
- Penyimpanan lokal: `Hive`
- State management: `Riverpod`
- Router: `GoRouter`

## Fitur yang sudah ada

- Autentikasi lokal multi-user (username/password hash bcrypt)
- Transaksi `income` / `expense` / `transfer`
- Master data akun/dompet dan kategori
- Plan keuangan (saving/spending) + realisasi manual/otomatis
- Kalender keuangan + event finansial
- Statistik ringkas dan insight cashflow
- Backup/restore JSON per user
- Cek update aplikasi via `version.json` (silent fail saat offline)
- Owner Dashboard (khusus Windows) untuk broadcast dan pengaturan URL update

## Menjalankan aplikasi (development)

1. Copy file env lokal dari contoh:
   - `dart_defines.example.json` -> `dart_defines.local.json`
2. Sesuaikan nilainya.
3. Jalankan:

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.local.json
```

Contoh jalankan Windows:

```bash
flutter run -d windows --dart-define-from-file=dart_defines.local.json
```

Untuk build/release update checker, repo ini sudah menyediakan contoh `dart_defines.release.json`.

## Daftar `dart-define` yang dipakai aplikasi

- `AUTH_MODE` -> `mock` (default) atau `worker`
- `AUTH_API_BASE_URL` -> base URL Cloudflare Worker auth
- `AUTH_API_KEY` -> API key client app (validasi ke worker)
- `GOOGLE_WEB_CLIENT_ID` -> Web Client ID untuk verifikasi token Google di worker
- `UPDATE_CONFIG_URL` -> URL publik `version.json` untuk cek update
- `OWNER_DASHBOARD_PIN` -> PIN akses dashboard owner (opsional)
- `UPDATE_TRUSTED_HOSTS` -> allowlist host update (pisahkan koma, opsional)

## Tutorial download APK (untuk pengguna)

Jika ingin install/update aplikasi dari file APK manual:

1. Buka halaman release terbaru:
   - `https://github.com/hmad28/hmatt-distribution/releases`
2. Pilih release paling baru (tag versi paling tinggi, misal `v1.0.3`).
3. Di bagian **Assets**, klik file APK (contoh: `hmatt-v1.0.3.apk`).
4. Tunggu download selesai.
5. Buka file APK dari notifikasi atau folder `Download`.
6. Jika muncul peringatan keamanan Android, izinkan **Install unknown apps** untuk browser/file manager yang digunakan.
7. Tekan **Install**.
8. Jika sudah pernah install versi lama, Android akan update aplikasi tanpa menghapus data user lokal.

Catatan penting:
- Jangan uninstall aplikasi lama sebelum update, agar data lokal tidak hilang.
- Setelah install sukses, file APK lama di folder `Download` bisa dihapus untuk hemat storage.
- Pastikan APK diambil dari repo resmi: `hmad28/hmatt-distribution`.

## Fitur update lintas device (praktis)

Agar semua device bisa cek update tanpa ubah kode per device:

1. Host file `version.json` di URL publik (contoh paling mudah: GitHub raw).
2. Isi `UPDATE_CONFIG_URL` di file define yang dipakai build (contoh `dart_defines.local.json` / `dart_defines.release.json`) dengan URL file tersebut.
3. Build APK/AAB dengan define yang sama, lalu install ke device mana pun.
4. Saat ada rilis baru, cukup update isi `version.json` di server/hosting.

Contoh format `version.json`:

```json
{
  "latest_version": "1.0.6",
  "update_message": "Perbaikan performa dan bug minor.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.3/hmatt-v1.0.3.apk"
}
```

Catatan:
- Jika URL update config tidak bisa diakses internet, app tetap normal (silent fail).
- URL update bisa diubah dari Owner Dashboard (Windows route `/owner`) tanpa rebuild aplikasi.

## Dokumen konteks pengembangan

- `FULL_CONCEPT.md` -> konsep produk dan arsitektur tingkat tinggi (revisi 2026).
- `UI_UX_CONCEPT.md` -> konsep UI/UX aktual berdasarkan implementasi saat ini.
- `PUBLISH_UPDATE_GUIDE.md` -> alur rilis APK + update `version.json`.
- `AUTH_WORKER_SETUP.md` -> setup auth real via Cloudflare Worker + Google + Resend.
- `CLOUDFLARE_WORKER_BEGINNER.md` -> panduan beginner buat Worker dari nol.
- `FEATURE_PLAN_KEUANGAN.md` -> detail fitur plan tabungan/pengeluaran barang yang akan dikembangkan.
