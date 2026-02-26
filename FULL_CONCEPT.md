## Konsep Produk Hmatt 2026 (Revisi Menyeluruh)

Hmatt adalah aplikasi manajemen keuangan **offline-first** berbasis Flutter untuk Android dan Windows dengan misi utama: membantu pengguna mengambil keputusan finansial harian dengan cepat, tenang, dan konsisten. Produk ini bukan lagi sekadar catatan pemasukan/pengeluaran, tetapi menjadi "sistem kerja keuangan pribadi" yang menggabungkan transaksi, perencanaan, kalender, dan disiplin evaluasi dalam satu alur yang sederhana.

Konsep baru ini memperbarui posisi produk dari "aplikasi catatan" menjadi **asisten operasional keuangan pribadi**, sambil tetap mempertahankan kekuatan inti: data lokal, cepat, dan minim ketergantungan internet.

---

## 1) Positioning dan Prinsip Produk

### Positioning
- **Kategori**: personal finance tracker + planning assistant (offline-first).
- **Target pengguna utama**:
  - pekerja harian/bulanan yang ingin kontrol arus kas,
  - keluarga kecil yang butuh pembagian akun/dompet,
  - pengguna yang mengutamakan privasi dan performa lokal.

### Prinsip Produk
- **Cepat dicatat**: transaksi harus bisa masuk dalam hitungan detik.
- **Jelas dipahami**: pengguna langsung tahu kondisi uangnya hari ini.
- **Terencana**: keputusan besar harus ditopang plan, bukan impuls.
- **Terkendali**: ada evaluasi rutin untuk menjaga disiplin.
- **Privat**: data tetap di device pengguna, tidak wajib cloud.

---

## 2) North Star dan Outcome yang Diukur

### North Star Metric
- Persentase hari dalam 30 hari terakhir ketika pengguna melakukan minimal 1 aktivitas finansial bermakna di aplikasi (catat transaksi, update plan, atau review kalender).

### Outcome Bisnis Produk
- Meningkatkan konsistensi pencatatan harian.
- Menurunkan gap antara rencana dan realisasi pengeluaran.
- Menjaga retensi dengan pengalaman yang ringan dan dapat dipercaya.

### Outcome Pengguna
- Pengguna lebih cepat tahu posisi kas real-time.
- Pengguna punya "alarm perilaku" saat pengeluaran mulai keluar jalur.
- Pengguna punya jejak refleksi untuk membangun kebiasaan finansial yang lebih baik.

---

## 3) Scope Fitur Versi Saat Ini (Reality Check)

Implementasi saat ini sudah mencakup fondasi konsep baru:

- **Autentikasi lokal multi-user** (username/password hash, session lokal).
- **Pencatatan transaksi**:
  - tipe income/expense/transfer,
  - account, category, catatan, bukti gambar,
  - filter jenis transaksi, metode pembayaran, dan sorting.
- **Master data**:
  - dompet/rekening,
  - kategori income/expense/both.
- **Plan keuangan**:
  - saving dan spending item,
  - target nominal + periode,
  - status aktif/selesai/batal,
  - realisasi manual,
  - auto-track dari transaksi.
- **Kalender keuangan**:
  - ringkasan bulanan,
  - detail harian,
  - event finansial (payday/reminder/custom).
- **Backup/restore JSON** untuk seluruh data user.
- **Cek update aplikasi** via konfigurasi `version.json` (silent fail saat offline).
- **Owner dashboard (Windows)** untuk operasional sederhana (broadcast dan update config URL).

---

## 4) Konsep UX End-to-End (Alur Harian)

### Fase A - Masuk dan orientasi
- User login cepat.
- User langsung melihat halaman utama transaksi + ringkasan saldo.
- Jika ada update, banner tampil non-intrusif.

### Fase B - Catat aktivitas keuangan
- Tombol tambah selalu terlihat.
- Form fokus ke field penting: nominal, tipe, akun, kategori.
- Bukti foto/nota opsional untuk transaksi yang butuh audit pribadi.

### Fase C - Kontrol dan koreksi
- User menyaring transaksi berdasarkan tipe/metode.
- User melihat pola mingguan dan komposisi pengeluaran kategori.
- User mengedit/menghapus transaksi yang salah input.

### Fase D - Rencana dan evaluasi
- User membuat plan target (tabungan/pembelian).
- Realisasi bisa manual atau otomatis dari transaksi terhubung.
- Evaluasi plan memberi sinyal: under/on/over plan.

### Fase E - Komitmen dan pengingat
- Kalender jadi pusat pantau tanggal finansial penting.
- User menambah event gajian/jatuh tempo/ingat bayar.
- Rutinitas review bulanan dibentuk lewat satu layar yang konsisten.

---

## 5) Arsitektur Konseptual yang Diterapkan

### Pendekatan
- **Feature-first + clean layering**:
  - `presentation` (UI/Provider),
  - `domain` (entity/usecase/repository contract),
  - `data` (datasource/repository implementation).

### Teknologi inti
- Flutter + Riverpod.
- Hive sebagai local persistence utama.
- GoRouter untuk navigasi.

### Konsep data
- Semua data utama (auth, transaksi, akun, kategori, plan, event) disimpan lokal.
- Isolasi data berbasis `userId` agar multi-user dalam satu device tetap aman.

### Konsep keandalan
- Operasi inti tidak memerlukan internet.
- Kegagalan jaringan pada update check tidak boleh mengganggu flow utama.

---

## 6) Model Domain Inti (Bahasa Bisnis)

### Auth Domain
- Entitas sesi lokal: status auth, identifier, userId.
- Fokus: akses cepat dan privasi lokal.

### Transaction Domain
- Entitas transaksi memuat:
  - nilai nominal,
  - tipe (income/expense/transfer),
  - metadata (akun, kategori, notes, bukti),
  - timestamp audit.

### Planning Domain
- Entitas plan memuat target, periode, status, dan opsi auto-track.
- Entitas realization memuat aktual, sumber (manual/auto), dan refleksi.
- Fungsi evaluasi plan menjadi aturan bisnis utama.

### Calendar Domain
- Entitas event untuk titik kontrol keuangan berbasis tanggal.
- Menyatukan "apa yang terjadi" (transaksi) dan "apa yang harus terjadi" (event).

---

## 7) Konsep Keamanan dan Privasi

### Sudah diterapkan
- Password disimpan dalam bentuk hash bcrypt.
- Data finansial tidak dikirim ke server eksternal secara default.

### Kebijakan produk
- Hmatt menempatkan pengguna sebagai pemilik penuh data.
- Backup/restore manual adalah mekanisme anti-kehilangan data utama pada mode offline.

### Catatan risiko yang perlu terus dikomunikasikan
- Jika aplikasi dihapus tanpa backup, data lokal hilang permanen.
- Edukasi backup harus tetap ditampilkan jelas di flow pengguna.

---

## 8) Konsep UI/UX Implementasi Saat Ini

Bagian ini diselaraskan dengan dokumen rinci `UI_UX_CONCEPT.md`, agar konsep produk dan konsep antarmuka berada pada narasi yang sama.

### Arah UX
- Hmatt memakai pola **fast-operational personal finance UX**: masuk cepat, lihat posisi kas, lalu lakukan aksi finansial inti.
- Prinsip operasional:
  - action-first (aksi utama selalu terlihat),
  - low friction (input seperlunya),
  - contextual guidance (feedback muncul saat relevan),
  - offline confidence (flow utama tetap jalan tanpa internet).

### Sistem visual yang sudah dipakai
- Tipografi utama: `DM Sans`.
- Seed warna brand: teal `#0F766E`.
- Latar global: `#F3F6FA` (terang, netral, minim kelelahan visual).
- Gradient aksen penting: teal -> navy (`#0F766E -> #1E3A8A`) pada area hero auth dan header saldo.
- Warna semantik transaksi:
  - income (hijau),
  - expense (merah),
  - transfer (slate).

### Struktur layout dan posisi elemen
- **Auth**: hero branding di atas, card form tab masuk/daftar di tengah, CTA utama di bawah.
- **Home**: update banner -> balance header -> plan summary -> insight -> filter/sort -> list transaksi -> tombol tambah utama di navbar bawah (mobile).
- **Master**: tab akun/kategori dengan pola CRUD konsisten.
- **Plan**: filter status, list plan, tambah plan dari tombol tengah navbar (mobile) + dialog auto-track transaksi.
- **Calendar**: header bulan, ringkasan bulanan, grid kalender, ringkasan hari, event harian, tambah event dari tombol tengah navbar (mobile).

### Struktur navigasi
- Mobile Android: bottom navigation 5 slot (Home, Akun, Tambah, Plan, Calendar) dengan tombol tambah di tengah sebagai aksi primer lintas halaman, disembunyikan saat keyboard terbuka.
- Desktop/non-Android: AppBar action + direct routing untuk operasi cepat.

### Identitas copy dan tone
- Bahasa operasional, singkat, tidak menghakimi.
- Umpan balik evaluasi plan bersifat membimbing (under/on/over plan).
- Fokus copy: bantu pengguna mengambil keputusan berikutnya, bukan sekadar menampilkan angka.

---

## 9) Batasan Versi Saat Ini

Konsep ini tetap realistis terhadap implementasi sekarang:

- Belum ada sinkronisasi cloud multi-device.
- Belum ada notifikasi scheduler lokal lintas platform yang matang.
- Belum ada budgeting detail per kategori dengan alarm real-time.
- Belum ada analitik prediktif (cashflow projection otomatis).
- Home pada layar kecil masih memiliki kepadatan informasi cukup tinggi.
- Konsistensi bahasa UI belum sepenuhnya satu bahasa.
- Baseline aksesibilitas formal (tap target, semantic labels, keyboard focus) belum terdokumentasi penuh.

Semua batasan ini adalah kontrol scope agar stabilitas core loop tetap terjaga.

---

## 10) Roadmap Konsep Lanjutan (Produk + UI/UX)

### Prioritas 1 - Reliability dan trust
- Enkripsi backup opsional dengan passphrase.
- Validasi impor backup lebih ketat + preview sebelum impor.
- Pengingat berkala "last backup".

### Prioritas 2 - UX hierarchy dan language consistency
- Susun ulang hirarki Home untuk menonjolkan saldo + transaksi terbaru lebih dulu.
- Insight sekunder dibuat lebih adaptif (misalnya dapat dilipat pada layar kecil).
- Seragamkan bahasa UI menjadi Indonesia penuh.
- Pertahankan pola tombol tambah di tengah navbar sebagai signature interaction untuk jalur mobile.

### Prioritas 3 - Form ergonomics dan accessibility baseline
- Sectioning yang lebih jelas pada form Plan (tujuan, nominal/periode, tracking, catatan).
- Validasi inline untuk error umum sebelum submit.
- Standar minimum a11y:
  - tap target >= 44dp,
  - kontras teks utama minimal setara WCAG AA,
  - semantic label pada aksi penting,
  - fokus keyboard jelas untuk desktop.

### Prioritas 4 - Smart planning dan decision support
- Budget bulanan per kategori.
- Reminder saat realisasi mendekati batas.
- Insight dari histori refleksi under-plan.
- Proyeksi saldo akhir bulan dan simulasi dampak pembelian terhadap plan.

### Prioritas 5 - Optional cloud
- Sinkronisasi opsional tanpa mengorbankan mode offline sebagai jalur utama.

---

## 11) Definisi Konsep Final

Hmatt adalah **offline financial operating system** untuk individu/keluarga kecil yang ingin mencatat, merencanakan, dan mengevaluasi keuangan secara konsisten, dengan antarmuka yang tenang, cepat, dan berorientasi aksi.

Konsep final menegaskan empat pilar:
- **Catat** (transactions),
- **Atur** (master data),
- **Rencanakan** (financial plans),
- **Jaga ritme** (calendar + evaluasi + backup).

Dengan penyelarasan ini, arsitektur teknis, pengalaman UI/UX, dan roadmap produk bergerak dalam satu arah: sederhana dipakai, kuat untuk kebiasaan, aman untuk data pengguna.
