## Ringkasan penilaian

Arahnya benar di 3 hal: metadata offsite, enkripsi client-side, dan satu pemicu restore. Tapi rencana "cukup pegang akun Turso + key enkripsi" **belum cukup**, karena (a) ada state yang **tidak ada di DB sama sekali**, (b) kode sekarang **belum bisa jalan di atas Turso** (semuanya berbasis berkas SQLite), (c) "enkripsi semuanya" bukan sekadar menyimpan ciphertext di kolom, dan (d) **orkestrator restore massal tidak ada** — Turso tidak menciptakannya.

---

## A. State yang tetap terlewat walau DB pindah ke Turso

| # | Yang terlewat | Bukti di repo/instalasi | Akibat |
|---|---|---|---|
| A1 | **`.env` control plane** — bukan hanya "kredensial Turso" | Key yang ada: `SESSION_SECRET`, `APP_DOMAIN`, `PORT_RANGE_*`, `AWS_*`, **`BILLING_DUITKU_API_KEY`**, `ADMIN_EMAIL` | Pembayaran mati, rentang port beda, admin email kosong ⇒ SSL gagal |
| A2 | **Passphrase restic** (`database/restic/password`) | file 0600, gitignored | Tanpa ini snapshot volume S3 **tidak bisa dibuka** — jadi butuh **3 rahasia**, bukan 2 |
| A3 | **Paket `host_ports` lokal** | `PortOverrides::persist()` hanya menulis `docker-compose.override.ports.yml` + `compose_files`/`primary_port`; `host_ports` metadata hanya untuk app agent | Restore DB-only ⇒ port host pilihan user hilang, `up` memakai port bawaan repo → bentrok/berubah |
| A4 | **Private key SSH app** | DB hanya menyimpan nama (`ssh_key`); isi kunci di `database/keys/<name>` (`SshKeyManager`) | App repo privat gagal `git clone` saat restore |
| A5 | **`known_hosts`** | `database/keys/known_hosts` (`config/deploy.php`) | Jangan direstore buta — host key GitHub bisa berubah; lebih baik TOFU ulang |
| A6 | **Logo branding** (biner di volume `rames`, **bukan** di tabel) + **konten parked HTML** | `SPECS §7.16`, `§8j.9` | Logo hilang; domain parkir mode `html` ⇒ 404 senyap |
| A7 | **Bind mount & app impor compose** | `VolumeTargetMap` hanya named volume; `ComposeImporter` mencatat `local_path` absolut | Data bind tidak ter-backup; app impor tidak portabel lintas host |
| A8 | **`/etc/letsencrypt` + `CLOUDFLARE_CREDS`** | mount di `docker-compose.yml` | Re-issue = rate limit LE; DNS-01 butuh file kredensial yang tak ada di DB |
| A9 | **Image hasil `build:` lokal** | repo-mode app | Harus rebuild: butuh source + kredensial registry/build-secret; tag upstream bisa hilang |
| A10 | **Material TLS + token agent** | ada di `servers_servers` (`token`, `tls_cert_pem`, lihat `AgentClient`) | Bagus (ikut DB), **tapi** agent yang diinstal ulang punya cert baru ≠ pin lama; DB agent tetap lokal |

---

## B. Kode sekarang tidak bisa jalan di Turso tanpa refactor inti

Bukti konkret:

- **Berbasis berkas**: `config('deploy.sqlite_file')` → `PDO('sqlite:…')` (`SqliteDatabase`). Identity handle = `realpath#dev:ino` → konsep "berkas diganti" tidak ada di remote.
- **`VACUUM INTO`** untuk snapshot (`SqliteDatabase::snapshot`) — Turso/libSQL tidak menyediakan snapshot berbasis file; seluruh desain `DbBackup` (snapshot → unduh → restore berkas → `PRAGMA integrity_check`) harus diganti ke `turso db dump`/PITR.
- **`flock` sebagai mutex lintas-proses** (`DbBackup`, `BackupRunLock`). Lock file lokal tidak berlaku lintas host/pod; dua writer remote bisa balapan.
- **`PRAGMA`**: `journal_mode=WAL`, `busy_timeout`, `synchronous`, `table_info` di `SchemaMigrations` — harus diuji satu per satu terhadap sqld (sebagian diterima, sebagian no-op).
- **`BEGIN IMMEDIATE`**: aman untuk single-writer, tapi di Turso transaksi interaktif punya batas durasi; closure panjang (`transferAllFrom`, impor JSON) berisiko timeout.
- **Endpoint unduh/restore berbasis berkas** (`GET /backups/db/download`, `cli/db.php restore <berkas>`) — harus berubah.
- **Dependensi runtime**: dashboard hari ini tetap jalan tanpa internet; dengan Turso, Turso down = **dashboard mati total** (auth & daftar app butuh DB). Worker Webman persistent + query remote ⇒ p95 dan throughput turun; tanpa replica/cache, tiap request auth jadi round-trip.

---

## C. "Enkripsi dulu" — yang tidak gratis

- Enkripsi level-halaman **tidak mungkin** di Turso ⇒ harus **field-level AEAD**. Berarti mengubah **seluruh jalur baca**: `UserStore` (login), `AppAccess`, `EnvManager` (`$app['env']`), `ServerStore` (token), `TwoFactorService`, `ErrorStore`, billing.
- Field mana yang wajib: `apps.env`, `apps.compose_content` (bisa memuat secret), `apps.ssh_key`, `servers.token`, secret 2FA, `error_events` (stack trace sering memuat kredensial), billing.
- **Trade-off yang harus dipilih sadar**: mengenkripsi `name`/`username`/`domain` ⇒ index & keunikan (`AppStore::nameExistsOnServer`, login lookup) **rusak**. Jadi metadata tetap terbuka ⇒ Turso tetap melihat "siapa punya app apa, domain apa, berapa user".
- **Integritas & rollback**: AEAD wajib + **AAD** terikat ke id/kolom, plus penanda versi monoton. Tanpa itu, siapa pun yang memegang token Turso bisa **mengembalikan nilai lama** (mis. saldo kredit) atau menghapus baris → dashboard "sehat" tapi data salah.
- **Manajemen kunci**: KEK milik Anda + DEK per instalasi (rotasi tanpa re-enkripsi seluruh data). Wajib ada **break-glass**: bila key hilang, admin & 2FA tak bisa didekripsi ⇒ terkunci permanen walau DB utuh.

---

## D. Yang paling terlewat: tidak ada orkestrator restore

Ini inti permintaan Anda, dan **tidak lahir dari Turso**. Yang belum ada sama sekali:

1. Restore DB dari remote + **migrasi skema** ke versi kode baru (pin versi di manifest).
2. Regenerasi artefak per app: template (`TemplateCatalog`), compose (`compose_content`/repo clone), **port override** (butuh A3 dulu).
3. Preflight bentrok: nama container (`ContainerNames`), port host (`AppPorts`), subdomain (`SubdomainManager`).
4. Restore volume dengan **urutan benar**: strategi `snapshot` harus sebelum container pertama `up`; strategi `dump` harus **setelah** container DB hidup (kode sekarang: `VolumeRestoreService` menuntut record app + container).
5. `compose up` per app via `DeployerInterface` + tangkap kegagalan per app.
6. Render ulang Nginx (`NginxConfigGenerator`) + reload, lalu **antrekan SSL** (rate limit ⇒ bertahap, bukan serentak).
7. Idempoten & **resumable** (restore 20 app bisa putus di app ke-7), log/progress, serta laporan app mana gagal.
8. Checklist eksternal: DNS, firewall 80/443, `APP_DOMAIN`, Cloudflare.

---

## E. Konsistensi antar-simpanan (point-in-time skew)

Turso/DB di T1, volume restic di T2, artefak di T3. `backup_registry` di DB bisa **basi** (terbukti saat ini: registry mencatat app yang sudah dihapus, dan run terakhir memproses **0 volume** dengan status `ok`). Restore harus memakai aturan "snapshot volume **terbaru yang tidak lebih baru** dari snapshot DB", dan lebih aman **merekonstruksi manifest dari tag restic** (`volume:`/`project:`/`app:`) daripada percaya kolom `last_snapshot`.

---

## F. Konsekuensi memilih Turso (jujur)

| Aspek | Kenyataan |
|---|---|
| Nilai tambah riil | Hanya bila Anda butuh **state live bersama** antar-host (control plane + agent membaca DB yang sama) |
| Biaya | Refactor driver + locking + backup (V3), latensi per query, kuota rows-read (polling monitor/job), ketergantungan internet, 2 vendor (Turso + S3) |
| Keamanan | Enkripsi server-side Turso **tidak** melindungi dari Turso sendiri → tetap perlu client-side; token Turso = kewenangan penuh atas ciphertext |
| DR | Turso tetap perlu backup sendiri (PITR/dump); tabel ciphertext ≠ backup instalasi |
| Alternatif setara | **restic sudah client-side encrypted dengan passphrase milik Anda** dan sudah offsite di S3 |

---

## G. Rekomendasi

**Jika tujuannya murni DR (bukan multi-host live): jangan pindahkan DB ke Turso.** Tambahkan saja 3 hal kecil di atas mekanisme yang sudah ada:

1. **P0-a (murah, wajib):** simpan `host_ports` untuk app **lokal** juga (paritas dengan agent) — menutup A3 tanpa menyentuh disk-artifact.
2. **P0-b:** bundle DR terenkripsi di repo restic yang sudah ada: `rames.sqlite` (hasil `VACUUM INTO`, konsisten) + tar `apps/`, `database/env/`, `database/keys/`, `branding/`, `parked/` + `manifest.json` (versi, app list, port, domain, snapshot id per volume). Enkripsi = restic (sudah ada), tidak perlu kripto baru.
3. **P1:** `cli/dr.php restore` = orkestrator §D, idempoten, urutan volume benar, plus guard "run 0 volume saat ada app hidup ⇒ warning".

**Jika tetap mau Turso:** hibrida yang paling murah —
- Turso untuk metadata **non-rahasia** saja (hindari refactor besar & masalah index);
- secret tetap di **vault terenkripsi** (S3/restic) dan diambil saat boot;
- hapus ketergantungan `VACUUM INTO`/`flock` (ganti lock tabel + dump resmi Turso) dan sediakan **embedded replica** agar dashboard tidak mati saat Turso/internet down.

**Satu hal yang tidak bisa dikompromikan:** target DR sebaiknya **memakai domain yang sama** (cukup re-point DNS). Ganti domain baru ⇒ URL absolut yang tersimpan **di dalam data app** (mis. `CHEVERETO_HOSTNAME`, `siteurl` WordPress, callback payment/webhook) ikut rusak dan tidak bisa diperbaiki generik oleh control plane.

---

Kalau Anda setuju arahnya, saya bisa lanjut ke salah satu: **(1)** implementasi P0-a + bundle `cli/dr.php export` (V2–V3), **(2)** rancangan detail `cli/dr.php restore` beserta urutan volume/port/SSL + test, atau **(3)** dokumen keputusan (SPECS §8l) yang membandingkan tegas "restic vault" vs "Turso" agar tidak diimplementasikan dua kali.