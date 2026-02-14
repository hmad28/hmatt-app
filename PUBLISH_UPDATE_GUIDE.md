# Panduan Publish & Update Hmatt (Tanpa Play Store)

Dokumen ini menjawab pertanyaan: **pakai GitHub saja atau perlu landing page/Vercel?**

Repo distribusi kamu: `https://github.com/hmad28/hmatt-distribution.git`

## Ringkasan Cepat

- **Tidak wajib** bikin landing page.
- Paling cepat: **GitHub saja** (repo publik + Release assets).
- Kalau mau pakai domain sendiri `hmatt.hammad.biz.id`, itu bisa tahap berikutnya (opsional).
- Mekanisme update di app tetap sama: app baca `version.json`, lalu buka link APK terbaru.

## Opsi yang Disarankan (Mulai dari paling mudah)

1. **Opsi A - GitHub only (paling cepat, disarankan untuk awal)**
   - `version.json` di GitHub repo publik
   - APK di GitHub Releases
2. **Opsi B - Domain sendiri (`hmatt.hammad.biz.id`)**
   - `version.json` + APK di server/domain sendiri
   - Bisa pakai Vercel/hosting statis lain, tapi landing page tetap tidak wajib

---

## Opsi A - GitHub Only (Step by Step)

### 1) Pakai repo distribusi yang sudah kamu buat

Repo: `https://github.com/hmad28/hmatt-distribution.git`

Kalau repo masih kosong, **iya, push dulu** file awal (`version.json`) ke branch `main`.

### 2) Tambahkan file `version.json` di root repo

Contoh isi awal:

```json
{
  "latest_version": "1.0.0",
  "update_message": "Versi stabil awal.",
  "update_url": "https://github.com/<username>/hmatt-distribution/releases/download/v1.0.0/hmatt-v1.0.0.apk"
}
```

URL config yang dipakai app:

`https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json`

### 3) Build APK release

Naikkan dulu versi di `pubspec.yaml` (mis. `1.0.1+2`), lalu build:

```bash
flutter build apk --release --dart-define=UPDATE_CONFIG_URL=https://raw.githubusercontent.com/<username>/hmatt-distribution/main/version.json

# untuk repo kamu:
flutter build apk --release --dart-define=UPDATE_CONFIG_URL=https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json
```

Output APK default:

`build/app/outputs/flutter-apk/app-release.apk`

Rename file agar jelas versi, contoh:

`hmatt-v1.0.1.apk`

### 4) Upload APK ke GitHub Release

- Buat release tag: `v1.0.1`
- Upload asset: `hmatt-v1.0.1.apk`

Link APK akan jadi seperti:

`https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.1/hmatt-v1.0.1.apk`

### 5) Update `version.json`

Ubah isi menjadi versi terbaru:

```json
{
  "latest_version": "1.0.1",
  "update_message": "Perbaikan scroll dan UI mobile.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.1/hmatt-v1.0.1.apk"
}
```

Commit perubahan `version.json`.

Selesai. Device user yang buka app akan melihat banner update.

### 5a) Cara push file awal ke repo distribusi (sekali setup)

Di folder lokal `hmatt-distribution`:

```bash
git init
git branch -M main
git remote add origin https://github.com/hmad28/hmatt-distribution.git
git add version.json
git commit -m "add initial version config"
git push -u origin main
```

Kalau repo sudah pernah di-init dan punya remote, cukup:

```bash
git add version.json
git commit -m "update version config"
git push
```

---

## Opsi B - Domain Sendiri `hmatt.hammad.biz.id` (Opsional)

Kalau ingin link lebih rapi:

- `https://hmatt.hammad.biz.id/updates/version.json`
- `https://hmatt.hammad.biz.id/downloads/hmatt-v1.0.1.apk`

Langkahnya sama seperti Opsi A, hanya beda lokasi hosting file.

Build command jadi:

```bash
flutter build apk --release --dart-define=UPDATE_CONFIG_URL=https://hmatt.hammad.biz.id/updates/version.json
```

> Catatan: Vercel boleh dipakai untuk hosting file statis, tetapi **landing page tidak wajib**.

---

## Checklist Rilis Versi Baru

1. Ubah fitur di kode.
2. Naikkan versi di `pubspec.yaml`.
3. Build APK release.
4. Upload APK baru ke hosting (GitHub Release atau domain sendiri).
5. Update `version.json` (`latest_version`, `update_message`, `update_url`).
6. Tes di 1 device lama:
   - buka app lama
   - pastikan banner update muncul
   - klik update
   - install APK baru

---

## Troubleshooting Penting

### Banner update tidak muncul

- Cek `UPDATE_CONFIG_URL` benar dan bisa dibuka dari browser HP.
- Cek isi `version.json` valid JSON.
- Cek `latest_version` memang lebih besar dari versi app terpasang.

### APK tidak bisa di-install sebagai update

- Penyebab paling umum: APK baru ditandatangani dengan keystore berbeda.
- Solusi: pastikan semua release pakai keystore yang sama.

### Klik tombol update tapi gagal download

- Cek `update_url` langsung bisa diakses di browser HP.
- Pastikan file APK benar-benar ada di URL tersebut.

---

## FAQ Singkat

### Perlu backend khusus?
Tidak. Cukup file `version.json` + file APK yang bisa diakses publik.

### Perlu Play Store?
Tidak wajib. Bisa distribusi APK langsung via link.

### Perlu landing page?
Tidak wajib. Direct link ke APK sudah cukup.

---

## Next Step Paling Praktis Buat Kamu Sekarang

1. Buat file `version.json` di repo `hmatt-distribution` lalu push ke `main`.
2. Cek URL ini bisa dibuka dari browser:
   - `https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json`
3. Build APK release dengan `UPDATE_CONFIG_URL` di atas.
4. Upload APK ke GitHub Release (`v1.0.0` / `v1.0.1`).
5. Update `update_url` di `version.json` ke link release APK, lalu push lagi.
