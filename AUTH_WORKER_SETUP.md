# Hmatt Auth Setup (Google + Resend + Cloudflare Worker)

Dokumen ini untuk menyalakan auth **real** (bukan mock) di Hmatt.

## 1) Android Package dan SHA-1

Sudah disesuaikan di project ini:
- `applicationId`: `id.biz.hammad.hmatt`
- `namespace`: `id.biz.hammad.hmatt`
- `MainActivity package`: `id.biz.hammad.hmatt`

Pastikan data OAuth Android di Google Console pakai nilai yang sama.

## 2) Google OAuth - apa isi Web Client URL?

Untuk flow mobile ini, app mengirim **Google ID Token** ke Worker. Tidak ada browser redirect di app.

- Saat membuat **OAuth Client ID -> Web application**:
  - `Authorized JavaScript origins`: boleh kosong
  - `Authorized redirect URIs`: boleh kosong

Jika Google Console memaksa isi redirect URI, pakai:
- `https://<worker-domain>/auth/google/callback`

Catatan: yang dipakai Flutter untuk server verification adalah **Web Client ID** (bukan Android Client ID).

## 3) Resend

1. Verifikasi domain pengirim di Resend.
2. Buat API key Resend.
3. Tentukan sender, contoh: `noreply@hammad.biz.id`.

## 4) Cloudflare Worker Secrets

Set secret di Worker (jangan di Flutter):

```bash
wrangler secret put RESEND_API_KEY
wrangler secret put RESEND_FROM_EMAIL
wrangler secret put GOOGLE_WEB_CLIENT_ID
wrangler secret put APP_CLIENT_API_KEY
wrangler secret put JWT_SECRET
```

Nilai yang diisi:
- `RESEND_API_KEY`: API key dari Resend
- `RESEND_FROM_EMAIL`: email sender, contoh `noreply@hammad.biz.id`
- `GOOGLE_WEB_CLIENT_ID`: client id web dari Google OAuth
- `APP_CLIENT_API_KEY`: key untuk validasi request dari app
- `JWT_SECRET`: secret untuk sign JWT

## 5) Endpoint Worker yang harus ada

- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/google/mobile`
- `POST /auth/verify-email`
- `POST /auth/resend-verification`
- `POST /auth/logout`

Response minimal yang Flutter pakai:

```json
{
  "status": "authenticated",
  "identifier": "hammad",
  "jwt": "...",
  "method": "google",
  "isEmailVerified": true
}
```

## 6) Env Flutter (dart-define)

1. Copy file contoh:
   - dari `dart_defines.example.json`
   - menjadi `dart_defines.local.json`
2. Isi nilainya.
3. Jalankan:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

Atau manual:

```bash
flutter run --dart-define=AUTH_MODE=worker --dart-define=AUTH_API_BASE_URL=https://your-worker.your-subdomain.workers.dev --dart-define=AUTH_API_KEY=your_app_client_api_key --dart-define=GOOGLE_WEB_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
```

## 7) Checklist cepat debug

- Login Google gagal -> cek package id + SHA-1 + OAuth Android Client.
- Login Google sukses tapi Worker tolak -> cek `GOOGLE_WEB_CLIENT_ID` di Worker secret.
- Email tidak terkirim -> cek domain Resend sudah verified + `RESEND_FROM_EMAIL` sesuai domain.
- App selalu balik ke halaman login -> cek `AUTH_MODE`, `AUTH_API_BASE_URL`, dan response endpoint auth.

## 8) Keamanan penting

- Jangan commit API key ke repo.
- Simpan key hanya di secret manager (Cloudflare secrets / local private file).
- Karena key sempat ditulis di `INFO.md`, sebaiknya rotate key Resend setelah setup stabil.
