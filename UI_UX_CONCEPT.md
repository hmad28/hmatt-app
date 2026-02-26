# Konsep UI/UX Hmatt (Detail Implementasi Saat Ini)

Dokumen ini menjelaskan UI/UX Hmatt secara lebih detail berdasarkan kondisi kode dan tampilan saat ini. Fokus utama: pewarnaan, posisi elemen, hirarki visual, pola interaksi, responsivitas, dan arah perbaikan tanpa mengubah DNA produk.

## 1. Design Direction

Hmatt memakai pendekatan **calm operational finance UI**: tampilan lembut, aksi cepat, dan informasi penting selalu dekat dengan titik interaksi.

Karakter visual:
- Ringan dan tidak agresif (background terang + elevasi minim).
- Komponen rounded untuk kesan ramah.
- Warna status dipakai fungsional, bukan dekoratif.
- Fokus layar diarahkan ke saldo, transaksi, dan tindakan tambah/edit.

## 2. Sistem Visual (Warna, Tipografi, Bentuk)

## 2.1 Palet warna utama

Sumber dan penerapan warna saat ini:

- **Brand seed**: `#0F766E` (teal) sebagai basis `ColorScheme` Material 3.
  - Referensi: `lib/core/theme/app_theme.dart:8`.
- **Scaffold background**: `#F3F6FA` (abu-biru terang).
  - Referensi: `lib/core/theme/app_theme.dart:15`.
- **AppBar text/ikon**: `#111827` (charcoal gelap) untuk keterbacaan tinggi.
  - Referensi: `lib/core/theme/app_theme.dart:19`.
- **Gradient aksen utama** (hero auth + saldo): `#0F766E -> #1E3A8A`.
  - Referensi: `lib/features/auth/presentation/pages/auth_entry_page.dart:90`, `lib/features/finance/presentation/widgets/balance_header.dart:28`.

Warna semantik transaksi:
- **Income**: `#197B4B`.
- **Expense**: `#B23A48`.
- **Transfer**: `#334155`.
- Referensi: `lib/features/finance/presentation/widgets/transaction_card.dart:27`.

Badge metode pembayaran:
- Cash: latar hijau muda (`#E8F5E9`) + teks hijau tua (`#1B5E20`).
- Non-cash: latar merah muda (`#FDE8E8`) + teks merah tua (`#B91C1C`).
- Referensi: `lib/features/finance/presentation/widgets/transaction_card.dart:204`.

## 2.2 Tipografi

- Font utama: `DM Sans` via Google Fonts.
- Peran tipografi:
  - `headlineSmall`: saldo utama/branding,
  - `titleMedium`: judul kartu/transaksi,
  - `bodySmall`: metadata sekunder (tanggal, akun, kategori).
- Referensi: `lib/core/theme/app_theme.dart:9`.

Implikasi UX:
- Angka finansial penting cukup kontras terhadap metadata.
- Aplikasi terasa modern tapi tetap formal untuk konteks uang.

## 2.3 Bentuk komponen

- Input: radius 14.
- Card: radius 16, tanpa bayangan default.
- Filled button: radius 14, padding vertikal 13.
- Referensi: `lib/core/theme/app_theme.dart:27`, `lib/core/theme/app_theme.dart:35`, `lib/core/theme/app_theme.dart:40`.

Implikasi UX:
- Konsistensi bentuk menjaga persepsi stabil dan terpercaya.
- Rounded corner tinggi membantu tampilan mobile terasa friendly.

## 2.4 Spacing dan ritme layout

Token spacing global:
- `8`, `12`, `16`, `24`.
- Padding dominan: `p12`, `p16`.
- Referensi: `lib/core/constants/app_spacing.dart:6`.

Ritme vertikal dominan:
- antar section: 12-16,
- antar elemen mikro: 4-8,
- antar blok utama card/list: 12.

## 3. Information Architecture dan Navigasi

## 3.1 Struktur area utama

Empat domain utama produk:
1. Home (ringkasan + transaksi).
2. Akun/Kategori (master data).
3. Plan (target + realisasi).
4. Calendar (kontrol waktu finansial).

## 3.2 Mobile navigation

- Komponen: `NavigationBar` bawah dengan 4 destination.
- Label saat ini: `Home`, `Akun`, `Plan`, `Calendar`.
- Mapping route:
  - index 0 -> `/home`,
  - index 1 -> `/masters`,
  - index 2 -> `/plans`,
  - index 3 -> `/calendar`.
- Bottom nav disembunyikan saat keyboard terbuka.
- Referensi: `lib/features/finance/presentation/widgets/mobile_bottom_nav.dart:25`.

## 3.3 Desktop/non-Android navigation

- Navigasi berbasis AppBar action + direct route.
- Owner dashboard tersedia khusus Windows.
- Dampak: desktop lebih cepat untuk operasi administratif, mobile lebih stabil untuk habit harian.

## 4. Detail Layout per Halaman

## 4.1 Auth Entry (Masuk/Daftar)

Struktur vertikal:
1. Hero branding gradient (atas).
2. Card form dengan TabBar (tengah).
3. Primary CTA button (bawah card).
4. Tombol Owner Dashboard (khusus Windows).

Detail posisi dan perilaku:
- Halaman dibungkus `Center` + `ConstrainedBox(maxWidth: 430)` untuk menjaga line length ideal.
- Hero card punya radius 18 + padding 16.
- Form berada dalam card terpisah agar input terlihat sebagai area kerja.
- TabBarView fixed height (`320`) menjaga stabilitas layout saat ganti tab.
- Referensi: `lib/features/auth/presentation/pages/auth_entry_page.dart:78`.

Catatan UX:
- Pola ini bagus untuk onboarding cepat.
- Risiko kecil: fixed height bisa terasa sempit di perangkat kecil dengan keyboard tinggi.

## 4.2 Home / Transaction List

Struktur urutan visual (top-to-bottom):
1. Update banner (conditional).
2. Balance header (focal point).
3. Plan summary card (conditional).
4. Insight cards: expense category + weekly trend (responsive row/column).
5. Filter & sort bar.
6. Daftar transaksi atau empty state.
7. Floating action button `Tambah` (global action).

Detail layout:
- Latar body gradient vertikal lembut (`#F7FBFC -> #EFF3FF`).
- Padding konten utama: `16`.
- Pada lebar `>= 900`, insight ditampilkan berdampingan; di bawahnya stack vertikal.
- Referensi: `lib/features/finance/presentation/pages/transaction_list_page.dart:145`.

Catatan UX:
- Fungsional lengkap, tetapi home cukup padat pada layar kecil.
- Focal point sudah benar (saldo + aksi tambah), namun insight sekunder bisa menurunkan fokus daftar transaksi saat data banyak.

## 4.3 Balance Header (Komponen kunci Home)

Anatomi komponen:
- Layer visual: gradient, radius 20, dan shadow hijau transparan tipis.
- Layer konten:
  - Label: "Total Saldo",
  - Angka saldo besar,
  - Tombol show/hide saldo,
  - Ringkasan pemasukan dan pengeluaran dua kolom.

Posisi:
- Full width container.
- Alignment teks dominan kiri, lalu ringkasan dual-column di baris bawah.
- Referensi: `lib/features/finance/presentation/widgets/balance_header.dart:23`.

Nilai UX:
- Memberi orientasi finansial dalam < 2 detik.
- Fitur hide saldo mendukung penggunaan di ruang publik.

## 4.4 Transaction Card

Grid horizontal 3 area:
1. **Leading**: icon circle berwarna sesuai tipe transaksi.
2. **Content**: judul, akun/kategori, badge payment, bukti, plan hint, tanggal.
3. **Trailing**: nominal besar + tombol edit/hapus.

Detil visual:
- Nominal diberi warna semantik + bold (`w700`).
- Metadata berada di ukuran lebih kecil agar hierarki tetap jelas.
- Aksi edit/hapus memakai `filledTonal` compact agar tidak terlalu berat.
- Referensi: `lib/features/finance/presentation/widgets/transaction_card.dart:34`.

Nilai UX:
- Mudah dipindai cepat karena warna nominal + ikon.
- Informasi pendukung cukup kaya tanpa memecah layout.

## 4.5 Master Data

Struktur:
- `DefaultTabController` 2 tab: Dompet/Rekening dan Kategori.
- Tombol tambah ditempatkan di kanan atas area konten.
- Daftar item dengan `ListTile` card-like + aksi hapus.

Posisi & perilaku:
- Form tambah via dialog modal.
- Hapus selalu lewat konfirmasi dialog.
- Feedback aksi melalui snackbar.

Nilai UX:
- CRUD pattern konsisten dan mudah dipelajari.

## 4.6 Financial Plan

Struktur:
1. Filter status plan.
2. List plan card.
3. FAB `Tambah Plan`.

Dialog plan (lebih kompleks):
- Urutan field: tipe -> status (saat edit) -> auto-track -> link kategori/akun -> judul -> nominal -> periode -> catatan.
- Mendukung progressive disclosure untuk field auto-track.

Nilai UX:
- Sudah kuat untuk use case menengah.
- Form cukup panjang, perlu grouping visual lebih tegas untuk mengurangi beban kognitif.

## 4.7 Calendar Overview

Struktur:
1. Header bulan (prev/next).
2. Ringkasan bulanan (income, expense, net).
3. Grid kalender.
4. Ringkasan hari terpilih.
5. Daftar event hari terpilih.
6. FAB `Tambah Event`.

Nilai UX:
- Memberikan bridge antara tanggal dan uang.
- Cocok untuk rutinitas review mingguan/bulanan.

## 4.8 Blueprint detail per page (posisi elemen)

Bagian ini memberi detail posisi elemen secara operasional agar mudah dipakai sebagai acuan redesign ringan.

### A. Auth Page
- **Zona atas**: hero gradient penuh lebar card (brand + value proposition singkat).
- **Zona tengah**: card auth dengan tab `Masuk` dan `Daftar`.
- **Zona bawah**: CTA utama (`Masuk`/`Daftar`) full width.
- **Desktop tambahan**: tombol Owner Dashboard diletakkan di bawah CTA utama.

Urutan prioritas visual:
1) Brand + konteks,
2) field kredensial,
3) tombol submit.

### B. Home / Transaction List
- **Zona app bar**: title + shortcut utilitas (master, plan, calendar, backup, logout).
- **Zona konten atas**: banner update (jika ada) + kartu saldo besar.
- **Zona konten tengah**: ringkasan plan + insight grafik.
- **Zona konten bawah**: filter/sort + daftar transaksi.
- **Zona fixed bawah (mobile)**: navbar dengan tombol tambah di tengah.

Urutan prioritas visual:
1) saldo total,
2) aksi tambah,
3) transaksi terbaru,
4) insight pelengkap.

### C. Master Data
- **Zona app bar**: title + tab `Dompet/Rekening` dan `Kategori`.
- **Zona konten**: tombol tambah per tab diletakkan di kanan atas list.
- **Zona list**: item card-like + aksi hapus di sisi kanan.
- **Zona fixed bawah (mobile)**: navbar dengan tombol tambah tengah (memberi helper snackbar).

Urutan prioritas visual:
1) pemilihan tab,
2) tombol tambah konteks tab,
3) daftar data,
4) aksi hapus.

### D. Plan Page
- **Zona app bar**: title halaman plan.
- **Zona atas**: filter status (all/active/completed/cancelled).
- **Zona tengah**: list card plan + progress.
- **Zona fixed bawah (mobile)**: navbar dengan tombol tambah tengah yang membuka form plan.

Urutan prioritas visual:
1) status/filter plan,
2) kartu plan aktif,
3) CTA tambah/edit/realisasi.

### E. Calendar Page
- **Zona atas**: header bulan (prev/next) + ringkasan bulan.
- **Zona inti**: grid kalender sebagai fokus interaksi.
- **Zona bawah konten**: ringkasan hari terpilih + daftar event hari tersebut.
- **Zona fixed bawah (mobile)**: navbar dengan tombol tambah tengah untuk tambah event.

Urutan prioritas visual:
1) konteks bulan aktif,
2) pemilihan tanggal,
3) event/action hari terpilih.

### F. Bottom Navigation (Mobile)
- Komposisi 5 slot horizontal:
  - slot 1: Home,
  - slot 2: Akun,
  - slot 3: **Tambah (FAB tengah)**,
  - slot 4: Plan,
  - slot 5: Calendar.
- Tombol tambah dibuat paling menonjol (FAB 52x52) untuk menegaskan aksi utama aplikasi.
- Bottom nav otomatis hilang saat keyboard terbuka agar tidak mengganggu input form.

## 5. Interaction Pattern

Pola interaksi yang konsisten:
- **Primary action persistent**: FAB pada halaman operasional.
- **Destructive action safety**: konfirmasi sebelum hapus/impor.
- **Immediate feedback**: snackbar untuk hasil aksi.
- **Contextual surface**: dialog untuk input cepat, bukan pindah halaman penuh.
- **Conditional rendering**: banner/update/plan summary hanya muncul saat relevan.

## 6. Responsivitas dan Platform Behavior

- Mobile-first pada alur finansial harian.
- Desktop tetap usable lewat AppBar action dan layout lebih lapang.
- Titik responsif eksplisit terlihat pada insight Home (`>= 900`).
- Keyboard-aware navigation meningkatkan kenyamanan input Android.

## 7. Accessibility Snapshot

Yang sudah membantu:
- Kontras teks utama cukup baik pada latar terang.
- Komponen Material 3 memberi baseline accessibility.

Yang perlu ditingkatkan:
- Belum ada checklist a11y formal.
- Perlu audit minimum tap target untuk ikon aksi compact.
- Perlu semantics label lebih lengkap pada elemen visual custom.

## 8. Konsistensi Bahasa dan Copy

Status saat ini:
- Mayoritas Indonesia, tetapi navigasi masih campuran (`Home`, `Plan`, `Calendar`).

Arah yang disarankan:
- Pilih satu bahasa utama UI (Indonesia penuh):
  - Beranda, Master, Rencana, Kalender.
- Selaraskan label, toast, dan empty state untuk tone yang sama.

## 9. Peta Hirarki Visual (Prioritas Informasi)

## Home
1. Saldo total + CTA tambah.
2. Daftar transaksi terbaru.
3. Filter aktif.
4. Insight sekunder (kategori/tren).

## Plan
1. Progress terhadap target.
2. Status (active/completed/cancelled).
3. Riwayat realisasi.
4. Pengaturan auto-track.

## Calendar
1. Bulan aktif + net bulanan.
2. Hari terpilih.
3. Event penting hari itu.

## 10. Kekuatan UX yang Sudah Mature

- Core loop penggunaan jelas: login -> catat -> monitor -> evaluasi.
- Visual system konsisten antar fitur besar.
- Fitur data-protection (backup/warning) sudah masuk alur nyata pengguna.
- Integrasi plan dengan transaksi memberi nilai lebih dari sekadar cashbook.

## 11. Gap UX Prioritas Tinggi

1. Kepadatan konten Home pada layar kecil.
2. Mixed language pada label navigasi.
3. Form Plan panjang tanpa sectioning yang lebih eksplisit.
4. Belum ada pedoman a11y tertulis per komponen.

## 12. Rekomendasi Perbaikan Tahap Berikutnya

### Tahap 1 - Hierarki Home
- Tampilkan transaksi terbaru lebih tinggi (di atas insight sekunder).
- Jadikan insight dapat dilipat (collapsible) untuk mode fokus catat cepat.

### Tahap 2 - Konsistensi bahasa
- Migrasi label navigasi ke Indonesia penuh.
- Sinkronkan copy notifikasi, empty state, dan CTA.

### Tahap 3 - Ergonomi form Plan
- Bagi dialog ke section visual:
  1) Tujuan,
  2) Nominal & periode,
  3) Tracking,
  4) Catatan.
- Tambah helper text ringkas pada field yang sering salah input.

### Tahap 4 - Accessibility baseline
- Tetapkan standar minimum:
  - target sentuh >= 44dp,
  - kontras teks minimal WCAG AA untuk elemen utama,
  - semantic labels pada ikon aksi kritikal,
  - fokus keyboard jelas di desktop.

## 13. Definisi UI/UX Hmatt Saat Ini

UI/UX Hmatt saat ini adalah:

**"Practical, calm, and action-oriented personal finance experience"**.

Pengguna diarahkan mencatat dengan cepat, memahami kondisi keuangan secara instan, lalu menjaga disiplin lewat plan dan kalender, dalam antarmuka yang ringan, konsisten, dan tidak berisik.
