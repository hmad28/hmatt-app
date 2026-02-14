# README FIRST - Rencana Aplikasi Flutter (Android + Windows)

Dokumen ini adalah blueprint awal supaya proses development kamu rapi, cepat jalan, dan minim bongkar ulang di tengah jalan.

## 1) Konsep Aplikasi

Nama kerja: **TaskFlow Lite**

Tujuan:
- Aplikasi manajemen tugas harian yang simpel, cepat, dan nyaman dipakai di mobile (Android) dan desktop (Windows).

Kenapa konsep ini cocok untuk start:
- Scope jelas (mudah jadi MVP)
- Banyak fitur yang bisa ditambah bertahap
- Cocok untuk latihan arsitektur Flutter yang benar
- Relevan dipakai sehari-hari (mudah diuji)

## 2) Target Platform

- **Android**: target utama (UX mobile-first)
- **Windows Desktop**: target kedua (layout lebih lebar, keyboard shortcut, resize)

Catatan penting lingkungan:
- Dari hasil pengecekan sebelumnya, Android sudah siap.
- Untuk build/run Windows, install **Visual Studio** + workload **Desktop development with C++**.

## 3) Fitur MVP (Wajib Versi Pertama)

1. **Daftar tugas**
   - Tampil list tugas
   - Status: belum selesai / selesai

2. **Tambah tugas**
   - Input judul (wajib)
   - Input deskripsi (opsional)
   - Pilih prioritas (low/medium/high)

3. **Edit & hapus tugas**
   - Ubah judul/deskripsi/prioritas
   - Hapus dengan konfirmasi

4. **Filter & sorting**
   - Filter: semua / aktif / selesai
   - Sort: terbaru, prioritas tertinggi, deadline terdekat

5. **Penyimpanan lokal**
   - Data tetap ada saat aplikasi ditutup
   - Gunakan local DB sederhana (disarankan: Isar atau Hive)

6. **UI responsif Android + Windows**
   - Android: bottom sheet/form sederhana
   - Windows: dialog/form lebih lebar + dukungan keyboard

## 4) Fitur V2 (Setelah MVP Stabil)

- Deadline + reminder lokal
- Tag/kategori tugas
- Pencarian cepat
- Ekspor/impor data JSON
- Statistik produktivitas mingguan

## 5) Arsitektur yang Disarankan

Gunakan pola yang mudah dirawat dari awal:

- **State Management**: Riverpod
- **Layering**:
  - `presentation` (UI, widget, page)
  - `application` (use case / business logic)
  - `domain` (entity, repository contract)
  - `data` (model, datasource, repository impl)

Keuntungan:
- Mudah testing
- Mudah scaling fitur
- Tidak cepat berantakan saat file bertambah

## 6) Struktur Folder Project

```text
lib/
  core/
    constants/
    theme/
    utils/
  features/
    tasks/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        widgets/
        providers/
  app.dart
  main.dart
```

## 7) Dependency Awal yang Direkomendasikan

`pubspec.yaml` (awal):
- `flutter_riverpod`
- `go_router`
- `intl`
- Salah satu local DB:
  - opsi A: `isar`, `isar_flutter_libs`
  - opsi B: `hive`, `hive_flutter`

Dev dependency:
- `build_runner`
- `flutter_lints`

## 8) Standar UI/UX Dasar

- Gunakan Material 3
- Warna netral + aksen biru/hijau (jelas dan profesional)
- Spacing konsisten (8, 12, 16, 24)
- Gunakan komponen reusable (button/input/card)
- Empty state yang jelas saat belum ada tugas
- Feedback aksi: snackbar untuk sukses/gagal

## 9) Roadmap Implementasi (Step-by-Step)

### Tahap 1 - Bootstrap Project
- Buat project Flutter
- Setup package dasar
- Buat struktur folder
- Setup theme + router + halaman awal

### Tahap 2 - Core Task CRUD
- Buat entity/model task
- Implement local storage
- Implement tambah/edit/hapus/toggle selesai
- Tampilkan list dinamis

### Tahap 3 - UX Penyempurnaan
- Filter + sorting
- Validasi form input
- Empty/loading/error states
- Polishing Android + Windows layout

### Tahap 4 - Quality & Release Preparation
- Unit test untuk use case utama
- Widget test basic halaman list
- Cek performa ringan
- Build release Android + Windows

## 10) Checklist Siap Build

### Android
- [ ] `flutter doctor` semua hijau untuk Android
- [ ] App icon + app name final
- [ ] Permission yang dibutuhkan saja
- [ ] `flutter build apk --release`

### Windows
- [ ] Visual Studio + C++ workload terpasang
- [ ] Uji resize window + minimum size
- [ ] Uji keyboard navigation (tab/enter)
- [ ] `flutter build windows --release`

## 11) Definisi Selesai MVP

MVP dianggap selesai jika:
- Bisa tambah, edit, hapus, centang selesai tugas
- Data persist setelah app restart
- UI rapi di Android dan Windows
- Tidak ada crash pada flow utama
- Build release Android dan Windows berhasil

## 12) Perintah Awal yang Akan Dipakai

Jika project belum diinisialisasi:

```bash
flutter create .
flutter pub get
flutter run -d android
flutter run -d windows
```

Untuk kualitas kode:

```bash
flutter analyze
flutter test
```

---

Kalau kamu mau, langkah berikutnya aku bisa langsung bantu generate struktur folder + skeleton kode MVP (halaman list tugas, form tambah tugas, dan local storage) agar kamu tinggal lanjut implementasi fitur.
 dalam delapan minggu pertama pengembangan.