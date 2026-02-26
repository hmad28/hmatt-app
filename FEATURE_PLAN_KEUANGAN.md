# Rencana Fitur: Plan Keuangan (Tabungan & Rencana Beli Barang)

Dokumen ini dibuat agar konteks pengembangan fitur berikutnya jelas, konsisten, dan mudah dipecah jadi task implementasi.

## Tujuan

- Membantu user membuat rencana keuangan sebelum uang dipakai.
- Mendukung dua jenis plan:
  - Plan tabungan (target menabung sejumlah nominal dalam periode tertentu).
  - Plan pengeluaran barang (target batas biaya untuk membeli barang tertentu).
- Memberi evaluasi perilaku finansial setelah realisasi:
  - Jika realisasi melebihi plan -> peringatan untuk lebih hemat.
  - Jika realisasi di bawah plan -> apresiasi dan prompt alasan kenapa bisa hemat.

## Ruang lingkup versi awal (MVP Plan)

- Buat plan baru dengan field inti.
- Lihat daftar plan aktif/selesai.
- Input realisasi nominal aktual.
- Lihat status plan: under, on track, over.
- Tampilkan feedback otomatis (peringatan/apresiasi).
- Simpan catatan refleksi saat realisasi < plan.

## Entitas data yang disarankan

### 1) Tabel `financial_plans`

- `id` (INTEGER PK AUTOINCREMENT)
- `user_id` (INTEGER, FK users)
- `type` (TEXT: `saving` | `spending_item`)
- `title` (TEXT, contoh: "Tabungan Motor", "Beli Laptop")
- `target_amount` (INTEGER, wajib, dalam satuan mata uang terkecil)
- `start_date` (TEXT/INTEGER timestamp)
- `end_date` (TEXT/INTEGER timestamp)
- `status` (TEXT: `active` | `completed` | `cancelled`)
- `notes` (TEXT, opsional)
- `created_at` (TEXT/INTEGER timestamp)
- `updated_at` (TEXT/INTEGER timestamp)

### 2) Tabel `financial_plan_realizations`

- `id` (INTEGER PK AUTOINCREMENT)
- `plan_id` (INTEGER, FK financial_plans)
- `actual_amount` (INTEGER, nominal realisasi)
- `realized_at` (TEXT/INTEGER timestamp)
- `reflection_note` (TEXT, opsional; direkomendasikan wajib saat under plan)
- `created_at` (TEXT/INTEGER timestamp)

Catatan: gunakan integer untuk nominal agar aman dari masalah floating point.

## Aturan evaluasi plan

Setelah user input `actual_amount`:

- `delta = actual_amount - target_amount`
- Jika `delta > 0` -> status evaluasi `over_plan`
  - tampilkan peringatan hemat
  - contoh: "Pengeluaran melebihi rencana Rp150.000. Yuk atur ulang prioritas agar lebih hemat."
- Jika `delta == 0` -> status evaluasi `on_plan`
  - tampilkan pesan netral positif
  - contoh: "Realisasi sesuai rencana. Bagus, pertahankan konsistensi."
- Jika `delta < 0` -> status evaluasi `under_plan`
  - tampilkan apresiasi
  - minta user isi alasan/refleksi
  - contoh: "Keren! Kamu lebih hemat Rp120.000. Ceritakan strategi yang berhasil supaya bisa diulang."

## Alur UI yang disarankan

### Halaman daftar plan

- Filter cepat: Semua, Aktif, Selesai.
- Card plan menampilkan:
  - judul plan
  - tipe plan
  - target nominal
  - periode
  - progress ringkas (jika ada realisasi)

### Form tambah/edit plan

- Tipe plan (`saving` / `spending_item`)
- Nama plan
- Target nominal
- Tanggal mulai dan selesai
- Catatan opsional

### Detail plan

- Ringkasan target
- Riwayat realisasi
- Tombol "Input Realisasi"
- Section "Evaluasi" (over/on/under)

### Form input realisasi

- Nominal aktual
- Tanggal realisasi
- Jika under plan -> tampilkan input alasan/refleksi (minimal 1-2 kalimat)

## Copywriting feedback (draft)

- Over plan:
  - "Realisasi melewati rencana. Coba kurangi pengeluaran non-prioritas minggu ini."
- On plan:
  - "Realisasi tepat sesuai plan. Disiplinmu sudah bagus."
- Under plan:
  - "Hebat, kamu lebih hemat dari rencana. Tulis alasan agar strategi ini bisa diulang."

## Integrasi dengan modul transaksi (tahap lanjut)

Versi awal bisa input realisasi manual. Versi lanjutan:

- Kaitkan plan dengan kategori transaksi tertentu.
- Auto-hit realisasi dari transaksi aktual pada periode plan.
- Tambah notifikasi saat mendekati deadline plan.

## Kriteria selesai fitur (acceptance criteria)

- User bisa membuat plan tabungan.
- User bisa membuat plan pengeluaran barang.
- User bisa mengisi realisasi dan langsung melihat evaluasi over/on/under.
- Sistem menampilkan peringatan saat over plan.
- Sistem menampilkan apresiasi + meminta refleksi saat under plan.
- Data plan dan realisasi tersimpan lokal dan tetap ada setelah app restart.

## Usulan urutan implementasi

1. Buat migration SQLite untuk tabel plan + realization.
2. Buat model dan repository plan.
3. Buat halaman daftar plan + form create/edit.
4. Buat detail plan + input realisasi.
5. Implement logic evaluasi + feedback message.
6. Tambah validasi refleksi saat under plan.
7. Tambah test logic evaluasi (over/on/under).
