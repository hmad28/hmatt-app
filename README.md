# Hmatt (Flutter)

Aplikasi pencatatan keuangan offline.

## Menjalankan aplikasi

1. Siapkan file `dart_defines.json` (copy dari `dart_defines.example.json`).
2. Jalankan:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Fitur update lintas device (praktis)

Agar semua device bisa cek update tanpa ubah kode per device:

1. Host file `version.json` di URL publik (contoh paling mudah: GitHub raw).
2. Isi `UPDATE_CONFIG_URL` di `dart_defines.json` dengan URL file tersebut.
3. Build APK/AAB dengan define yang sama, lalu install ke device mana pun.
4. Saat ada rilis baru, cukup update isi `version.json` di server/hosting.

Contoh format `version.json`:

```json
{
  "latest_version": "1.0.1",
  "update_message": "Perbaikan performa dan bug minor.",
  "update_url": "https://play.google.com/store/apps/details?id=id.biz.hammad.hmatt"
}
```

Catatan:
- Jika URL update config tidak bisa diakses internet, app tetap normal (silent fail).
- Anda juga bisa mengatur URL update dari Owner Dashboard (Windows route `/owner`) tanpa rebuild.
