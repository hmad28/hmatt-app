# Hmatt - Cloudflare Worker Beginner Guide

Panduan ini khusus untuk kamu yang belum pernah pakai Cloudflare Worker sama sekali.

## 0) Penting dulu (security)

Di `INFO.md` saat ini ada secret sensitif (Resend API key + Google client secret).

Saran kuat:
- rotate/ganti semua secret itu setelah setup selesai,
- jangan simpan secret di file repo,
- pakai Cloudflare **Worker Secrets** untuk semua key.

## 1) Kamu harus buka website yang mana?

1. Buka: `https://dash.cloudflare.com`
2. Login / buat akun Cloudflare.
3. Di sidebar kiri, klik **Workers & Pages**.
4. Klik **Create**.
5. Pilih **Create Worker**.
6. Beri nama worker, contoh: `hmatt-auth-worker`.
7. Klik **Deploy**.

Sampai sini worker sudah jadi, walau masih template default.

## 2) Edit kode Worker di dashboard (tanpa CLI dulu)

Masih di halaman worker:
1. Klik **Edit code**.
2. Replace isi file utama worker dengan template minimal di bawah.
3. Klik **Deploy**.

Template minimal (langsung bisa jalan untuk test koneksi Flutter):

```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true, service: "hmatt-auth-worker" });
    }

    if (request.method === "POST" && url.pathname === "/auth/google/mobile") {
      const body = await request.json().catch(() => ({}));
      if (!body.idToken) {
        return json({ status: "unauthenticated" }, 401);
      }

      return json({
        status: "authenticated",
        identifier: "google_user",
        jwt: "mock.jwt.google_user",
        method: "google",
        isEmailVerified: true
      });
    }

    if (request.method === "POST" && url.pathname === "/auth/login") {
      return json({
        status: "authenticated",
        identifier: "demo_user",
        jwt: "mock.jwt.demo_user",
        method: "password",
        isEmailVerified: true
      });
    }

    if (request.method === "POST" && url.pathname === "/auth/register") {
      return json({
        status: "authenticated",
        identifier: "new_user",
        jwt: "mock.jwt.new_user",
        method: "password",
        isEmailVerified: false
      });
    }

    if (request.method === "POST" && url.pathname === "/auth/verify-email") {
      return json({
        status: "authenticated",
        identifier: "new_user",
        jwt: "mock.jwt.new_user",
        method: "password",
        isEmailVerified: true
      });
    }

    if (request.method === "POST" && url.pathname === "/auth/resend-verification") {
      return json({ ok: true });
    }

    if (request.method === "POST" && url.pathname === "/auth/logout") {
      return json({ ok: true });
    }

    return json({ message: "Not Found" }, 404);
  }
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json" }
  });
}
```

## 3) Cari URL worker kamu

Di halaman worker biasanya ada domain seperti:
- `https://hmatt-auth-worker.<subdomain>.workers.dev`

Ini yang nanti dipakai ke `AUTH_API_BASE_URL` di Flutter.

## 4) Set secrets di Worker (via Dashboard)

Masih di worker yang sama:
1. Klik tab **Settings**.
2. Cari section **Variables**.
3. Di bagian **Secrets**, klik **Add secret**.
4. Tambahkan:
   - `RESEND_API_KEY`
   - `RESEND_FROM_EMAIL` -> `noreply@hammad.biz.id`
   - `GOOGLE_WEB_CLIENT_ID` -> `684951596815-juj5aheqn1sca17i6n8blqvnprnlvcsi.apps.googleusercontent.com`
   - `APP_CLIENT_API_KEY` -> bebas, buat string panjang random
   - `JWT_SECRET` -> bebas, string random panjang

Catatan: yang aman adalah secret disimpan di sini, bukan di Flutter.

## 5) Isi env Flutter lokal

Di root project, buat file `dart_defines.local.json`:

```json
{
  "AUTH_MODE": "worker",
  "AUTH_API_BASE_URL": "https://hmatt-auth-worker.<subdomain>.workers.dev",
  "AUTH_API_KEY": "isi_APP_CLIENT_API_KEY",
  "GOOGLE_WEB_CLIENT_ID": "684951596815-juj5aheqn1sca17i6n8blqvnprnlvcsi.apps.googleusercontent.com"
}
```

Lalu run:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

## 6) Tentang Web Client (pertanyaan kamu tadi)

Saat bikin Google OAuth **Web Client**:
- `Authorized JavaScript origins` -> bisa kosong
- `Authorized redirect URIs` -> bisa kosong

Kalau console mewajibkan isi redirect URI, isi saja:
- `https://hmatt-auth-worker.<subdomain>.workers.dev/auth/google/callback`

## 7) Setelah ini, next real production

Setelah koneksi app -> worker aman, baru lanjut:
- verifikasi Google ID token beneran di worker (pakai endpoint Google token info/JWK verify),
- kirim email verifikasi beneran via Resend,
- simpan user/session ke database (D1/Supabase/Postgres).
