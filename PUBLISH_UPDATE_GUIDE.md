# Panduan Publish & Update Hmatt (Tanpa Play Store)

Dokumen ini menjawab pertanyaan: **pakai GitHub saja atau perlu landing page/Vercel?**

Repo distribusi kamu: `https://github.com/hmad28/hmatt-distribution.git`

## Ringkasan Cepat

- **Tidak wajib** bikin landing page.
- Paling cepat: **GitHub saja** (repo publik + Release assets).
- Kalau mau pakai domain sendiri `hmatt.hammad.biz.id`, itu bisa tahap berikutnya (opsional).
- Mekanisme update di app tetap sama: app baca `version.json`, lalu buka link APK terbaru.

## Jawaban Singkat Pertanyaan Kamu

- **Push apa?** Untuk repo distribusi, cukup push file `version.json` (dan file pendukung kecil bila perlu).
- **Project Flutter perlu dipush ke repo distribusi?** Tidak perlu.
- **Perlu landing page/Vercel?** Tidak wajib.
- **Langkah pertama sekarang?** Push `version.json` dulu ke `main`, lalu build APK release.

## `version.json` Itu Dari Mana?

`version.json` **dibuat manual oleh kamu**. File ini bukan auto-generated dari Flutter.

Fungsinya: jadi "pengumuman versi terbaru" yang dibaca aplikasi saat dibuka.

Cara paling mudah buat file ini: langsung dari website GitHub repo `hmatt-distribution`.

### Cara buat `version.json` langsung di GitHub (paling gampang)

1. Buka `https://github.com/hmad28/hmatt-distribution`
2. Klik **Add file** -> **Create new file**
3. Isi nama file: `version.json`
4. Paste isi berikut:

```json
{
  "latest_version": "1.0.0",
  "update_message": "Versi stabil awal.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.0/hmatt-v1.0.0.apk"
}
```

5. Klik **Commit new file** ke branch `main`

### Cara cek file sudah benar

Buka URL ini di browser:

`https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json`

Kalau JSON tampil, berarti app bisa membaca file update config.

### Kapan file ini diubah?

Setiap rilis baru.

Contoh rilis `1.0.1`, maka `version.json` harus diubah manual ke:

```json
{
  "latest_version": "1.0.1",
  "update_message": "Perbaikan scroll dan UI mobile.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.1/hmatt-v1.0.1.apk"
}
```

Lalu commit lagi. Selesai.

## Opsi yang Disarankan (Mulai dari paling mudah)

1. **Opsi A - GitHub only (paling cepat, disarankan untuk awal)**
   - `version.json` di GitHub repo publik
   - APK di GitHub Releases
2. **Opsi B - Domain sendiri (`hmatt.hammad.biz.id`)**
   - `version.json` + APK di server/domain sendiri
   - Bisa pakai Vercel/hosting statis lain, tapi landing page tetap tidak wajib

---

## Opsi A - GitHub Only (Step by Step)

> Bagian ini versi paling detail, mengikuti repo kamu: `hmad28/hmatt-distribution`.

### Prasyarat

Sebelum mulai, pastikan:

- Repo distribusi `hmatt-distribution` sudah `Public`.
- Repo punya branch `main`.
- Kamu punya project Flutter Hmatt yang bisa dibuild.

### 1) Pakai repo distribusi yang sudah kamu buat

Repo: `https://github.com/hmad28/hmatt-distribution.git`

Kalau repo masih kosong, **iya, push dulu** file awal (`version.json`) ke branch `main`.

> Catatan penting: `version.json` dibuat manual (lihat bagian "`version.json` Itu Dari Mana?").

### 1a) Isi file `version.json` awal

Simpan file ini di root repo `hmatt-distribution`:

```json
{
  "latest_version": "1.0.0",
  "update_message": "Versi stabil awal.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.0/hmatt-v1.0.0.apk"
}
```

> `update_url` boleh diarahkan ke release `v1.0.0` yang akan kamu buat setelah build.

### 2) Push `version.json` ke `main`

Jika repo distribusi baru dan kosong:

```bash
git clone https://github.com/hmad28/hmatt-distribution.git
cd hmatt-distribution
# buat/edit version.json di folder ini
git add version.json
git commit -m "add initial version config"
git push origin main
```

Jika repo sudah ada file sebelumnya:

```bash
git add version.json
git commit -m "update version config"
git push
```

URL config yang dipakai app:

`https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json`

### 3) Verifikasi URL raw bisa diakses

Buka URL ini di browser (PC/HP):

`https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json`

Kalau belum tampil JSON, jangan lanjut dulu ke build.

### 4) Build APK release dari project Flutter

Naikkan dulu versi di `pubspec.yaml` (mis. `1.0.1+2`), lalu build:

```bash
flutter build apk --release --dart-define=UPDATE_CONFIG_URL=https://raw.githubusercontent.com/<username>/hmatt-distribution/main/version.json

# untuk repo kamu:
flutter build apk --release --dart-define=UPDATE_CONFIG_URL=https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json
```

Tips versi:

- `pubspec.yaml` contoh: `version: 1.0.1+2`
- Yang dipakai checker adalah `1.0.1` (bagian sebelum `+`).

Output APK default:

`build/app/outputs/flutter-apk/app-release.apk`

Rename file agar jelas versi, contoh:

`hmatt-v1.0.1.apk`

### 5) Upload APK ke GitHub Release

- Buat release tag: `v1.0.1`
- Upload asset: `hmatt-v1.0.1.apk`

Link APK akan jadi seperti:

`https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.1/hmatt-v1.0.1.apk`

### 6) Update `version.json` ke versi terbaru

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

### 7) Test end-to-end di HP

1. Install APK lama dulu (mis. `1.0.0`).
2. Pastikan HP ada internet.
3. Buka app.
4. Banner update muncul untuk versi baru.
5. Klik `Update`.
6. Download dan install APK baru.

### 8) Siklus rilis berikutnya (repeat)

Setiap ada update fitur:

1. Ubah kode fitur.
2. Naikkan versi di `pubspec.yaml`.
3. Build APK release.
4. Upload APK ke release tag baru (`v1.0.2`, dst).
5. Ubah `version.json` ke versi baru.
6. Push `version.json`.

### Catatan: Cara push file awal (alternatif manual)

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

## Contoh Nyata Rilis Pertama (1.0.0)

1. `pubspec.yaml`:
   - `version: 1.0.0+1`
2. Build APK:

```bash
flutter build apk --release --dart-define=UPDATE_CONFIG_URL=https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json
```

3. Rename hasil build jadi `hmatt-v1.0.0.apk`.
4. Buat release `v1.0.0` di repo distribusi, upload APK.
5. Set `version.json`:

```json
{
  "latest_version": "1.0.0",
  "update_message": "Versi stabil awal.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.0/hmatt-v1.0.0.apk"
}
```

6. Push `version.json`.

---

## Contoh Nyata Update Kedua (1.0.1)

1. `pubspec.yaml` ubah jadi `version: 1.0.1+2`.
2. Build APK release lagi.
3. Rename jadi `hmatt-v1.0.1.apk`.
4. Buat release `v1.0.1`, upload APK.
5. Ubah `version.json`:

```json
{
  "latest_version": "1.0.1",
  "update_message": "Perbaikan scroll dan UI mobile.",
  "update_url": "https://github.com/hmad28/hmatt-distribution/releases/download/v1.0.1/hmatt-v1.0.1.apk"
}
```

6. Push `version.json`.
7. Device dengan app `1.0.0` akan melihat banner update.

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
- Cek app release memang dibuild memakai `--dart-define=UPDATE_CONFIG_URL=...` yang benar.

### APK tidak bisa di-install sebagai update

- Penyebab paling umum: APK baru ditandatangani dengan keystore berbeda.
- Solusi: pastikan semua release pakai keystore yang sama.
- Jika muncul konflik paket, uninstall dulu app lama (ini menghapus data lokal).

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

1. Buat/cek file `version.json` di repo `hmatt-distribution`, lalu push ke `main`.
2. Verifikasi URL ini bisa dibuka dari browser:
   - `https://raw.githubusercontent.com/hmad28/hmatt-distribution/main/version.json`
3. Build APK release dengan `UPDATE_CONFIG_URL` di atas.
4. Upload APK ke GitHub Release (tag sesuai versi: `v1.0.0`, `v1.0.1`, dst).
5. Update `version.json` sesuai link release APK terbaru, lalu push lagi.
