
## Ringkasan

Fitur ini **belum ada** dan bukan perluasan §8g: `SPECS.md` §8g hanya mem-backup **berkas data dashboard** (`database/*.json`, config Nginx) ke disk lokal, **tidak pernah** menyentuh volume app. Jadi ini modul baru lintas lapisan (library + worker + scheduler + UI + image + kredensial + dokumentasi) yang menyentuh hampir semua peran.

Kabar baiknya, fondasinya sudah tersedia: dashboard berjalan sebagai **root + `docker.sock`** (SPECS §5), sudah punya pola **helper container** (`NginxReloader`), pola **worker detached** (`deploy.php`, `ssl.php`), pola **scheduler in-container** (`app/process/UpdateCheckProcess`), pola **secret level dashboard** (`CLOUDFLARE_CREDS` via `.env` → `deploy.php`), dan enumerasi volume (`DockerClient::listVolumes()`, label `com.docker.compose.project`).

## Analisis

### 1. Apa yang dianggap "volume" (cakupan)
| Kandidat | Catatan |
|---|---|
| **Named volume app** (label `com.docker.compose.project` = nama app) | Inti permintaan. Bisa di-map ke app → bisa lewat `AppAccess`. |
| **Volume yatim** (app sudah dihapus, mode preserve §7.4) | Masih berisi data; harus tetap di-backup sampai retensi habis, atau sengaja dilewati. |
| **Bind mount host** (`./data:/data`, `driver_opts o:bind` ke `${PWD}/.hermes`) | Banyak app nyata (`hermes`, dsb.) menyimpan data di sini, bukan named volume. Lebih mudah (langsung dari FS dashboard, tanpa helper container) — tapi keputusan cakupan. |
| **Anonymous volume** | Tidak punya nama stabil, sulit di-map ke app → umumnya diabaikan. |
| **Volume container eksternal** (bukan milik app) | Di luar domain (`/volumes` pun hanya admin melihatnya). |

### 2. Konsistensi data — edge case paling berbahaya
`tar` volume **selagi container hidup** menghasilkan gambar setengah-tulis. Untuk MySQL/MariaDB/Postgres, hasil restore bisa **korup tanpa error**. Tiga kebijakan:
- **Dump logis** (`mysqldump`/`pg_dump`) untuk container DB — paling benar; `DbContainerDetector` + `DbDump` sudah ada pondasinya.
- **Tar mentah** — cepat, tapi berisiko untuk DB hidup (harus dicatat sebagai risiko yang diterima).
- **Stop container sesaat** → downtime (bertabrakan dengan ekspektasi "backup harian otomatis").

### 3. Mesin backup & format output
Tidak ada SDK S3 di `composer.json` (hanya guzzle/symfony-yaml/monolog/webman), dan tidak ada `rclone`/`restic`/`aws-cli` di `Dockerfile` (Alpine `php:8.3-cli` + git/docker-cli/certbot/util-linux). Pilihan:

| Opsi | Kelebihan | Konsekuensi |
|---|---|---|
| **restic** | Inkremental + **dedup** + **enkripsi** + retensi native (`forget --keep-daily`), restore mudah | Butuh binary di image + **passphrase repo** (secret baru) + format non-standar |
| **rclone** (atau `aws-cli` alpine) | Binary static, `copy`/`sync` ke remote `s3:`; file tetap tar mentah | Tanpa dedup/enkripsi bawaan; multipart & resume ditangani rclone |
| **aws-sdk-php** (composer) | Tanpa binary eksternal | Dependency baru berat; multipart upload harus dirakit sendiri |
| **Guzzle + SigV4 manual** | Nol dependency | Hindari — implementasi kripto/kanonikalisasi rawan salah |

Alur eksekusi seragam (meniru `NginxReloader`): jalankan helper container via `docker run --rm -v <vol>:/data <image> …` lewat `ProcessRunner` (array + `bypass_shell`), **stream** langsung ke tujuan (hindari spool besar ke disk).

### 4. Penjadwalan harian
| Opsi | Meniru | Pro | Kontra |
|---|---|---|---|
| **Worker Webman** (`app/process/BackupProcess` + `Timer::add(86400)`) | `UpdateCheckProcess` | Satu tempat, kontrol admin dari UI, bisa debounce "backup sekarang" | Ikut mati saat dashboard recreate → jadwal bisa terlewat |
| **systemd timer host** (`host/backup.sh` + `backup.timer`, dipasang `install.sh`) → `docker exec rames-webman php cli/backup.php` | `certbot-renew.timer` | **Andal**, independen lifecycle container | Menambah artefak host + langkah installer |

Tidak ada `cron` di image; menambah supervisord = kompleks → kurang cocok.

### 5. Retensi, biaya, dan `docker compose down`
- Kata "harian" tanpa kebijakan retensi akan menumbuhkan biaya S3 tanpa batas. Perlu kebijakan (mis. N harian + M mingguan) — idealnya sebagian di **S3 lifecycle policy** (lebih andal dari penghapusan di app).
- **Penting**: §7.4 menyatakan `docker compose down` (tanpa `-v`) **mempertahankan** named volume agar app bisa dibuat ulang dengan nama sama. Backup tidak boleh mengubah perilaku itu, dan restore harus sadar bahwa volume yang "dipertahankan" dimiliki ulang oleh project dengan nama sama.

### 6. Keamanan (larangan keras)
- Kredensial S3 **tidak boleh** hard-code, tidak pernah masuk `apps.json`/log/UI. Preseden hari ini: dashboard memakai `.env` → `environment:` compose (`CLOUDFLARE_CREDS` → `deploy.php`). Perlu **keputusan lokasi** dan `chmod 0600`.
- Jangan taruh secret di **argv** proses (bocor di `ps`) — pakai env/`--env-file` atau file passphrase terproteksi.
- Data keluar host → bila pelanggan sensitif, wajib enkripsi at-rest (bawaan restic, atau SSE-S3/SSE-KMS).
- **Restore = operasi paling destruktif** → wajib satu pintu otorisasi + konfirmasi ganda; jangan menaruh cek hanya di tombol.
- `ProcessRunner` + `SigchldGuard` untuk semua spawn (exit code wajib terbaca).

### 7. Dampak arsitektur & dokumentasi
- Modul baru `app/library/Backup/` (`VolumeBackup`, `BackupTarget`/`BackupRepository`, `BackupPlanner`, `BackupState/RunStore`, `RestoreService`), worker `cli/backup.php`, `app/process/BackupProcess` (bila opsi scheduler in-container), halaman `/backups` + controller, ability baru, `runtime/backup/`, `runtime/logs/backup/`.
- Entri baru `SPECS.md` (mis. §8h) + `ARCHITECTURE.md` §4.3/§5.x + tabel `.env` + `Dockerfile` (binary) + `host` (bila timer).
- ⚠️ **Tabrakan penamaan**: §8g sudah memakai `BACKUP_ENABLED`, `BACKUP_RETENTION`, `BACKUP_PATH`, `database/backups/`. Fitur volume **wajib** namespace berbeda (mis. `VOLUME_BACKUP_*` / `S3_*`) agar tidak bentrok.
- Visibilitas: app bisa di-share (§7.7). Halaman/laporan backup harus lewat `AppAccess::visible()`; non-admin tidak boleh melihat backup app user lain (halaman `/volumes` sudah memakai aturan ini).

### 8. Edge case lain
Volume besar → hindari spool penuh di disk; upload terputus → resume/checksum, idempotensi (nama snapshot = tanggal+app); jam "harian" (jam sepi?) perlu config atau tetap; app multi-volume → serial vs paralel; backup gagal sebagian harus tampak di UI, bukan senyap; disk penuh saat backup lokal; volume milik app yang sedang `error` deploy.

---

## Pertanyaan Kritis (grill) — butuh jawaban Anda sebelum saya pecah jadi misi

1. **Cakupan & konsistensi data**: apakah hanya **named volume app**, atau **termasuk bind mount** (`apps/{name}/*`) and **volume yatim**? Untuk container DB hidup, mana yang dipilih: **dump logis** (aman, `mysqldump`/`pg_dump`), **tar mentah** (risiko korup, diterima), atau **stop container sesaat** (ada downtime)?
2. **Mesin & format**: **restic** (dedup + enkripsi + retensi native, butuh binary + passphrase repo), **rclone/aws-cli** (file tar mentah, mudah dibaca tanpa tool khusus), atau **aws-sdk-php** (dependency Composer berat)? Ini menentukan format restore & isi image.
3. **Penjadwalan & kredensial**: **worker Webman `Timer`** (in-container, bisa terlewat saat recreate) atau **systemd timer host** (meniru `certbot-renew.timer`, lebih andal)? Kredensial S3 disimpan di **`.env`/`environment:` compose** (preseden `CLOUDFLARE_CREDS`) atau **file baru `database/…` chmod 0600**?
4. **Scope Phase 1 & retensi**: apakah **restore via UI** masuk sekarang, atau Phase 1 cukup **backup + status + retensi** dan restore jadi prosedur terdokumentasi (seperti §8g poin 5)? Kebijakan retensi: berapa hari/minggu, dan dihapus oleh app atau S3 lifecycle policy?
5. **Otorisasi**: backup berisi data app — halaman backup **disaring `AppAccess`** (non-admin bisa memicu/melihat backup app yang boleh diaksesnya) atau **admin-only** seperti purge volume?

## Rencana Usulan (setelah jawaban — urutan per peran)

Belum dieksekusi. Setelah Anda menjawab, saya pecah jadi misi berurutan:
1. **Auth & Security** — definisi ability baru (`backup`/`restore`), aturan visibilitas, lokasi & proteksi kredensial, larangan secret di log/argv.
2. **Deploy & Docker** — helper container backup, penambahan binary ke `Dockerfile`, env compose, instalasi timer host bila dipilih.
3. **Backend PHP** — `app/library/Backup/*`, worker `cli/backup.php`, `app/process/BackupProcess`, controller + route, state/retensi.
4. **Frontend UI** — halaman `/backups`, status & riwayat, tombol "Backup sekarang"/restore (sesuai ability).
5. **Verifier** (Rames Assure) — `php -l`, `composer test`, smoke render view, uji compose tiruan di direktori temp, **tanpa menyentuh data runtime nyata** (larangan #15/#16).
6. **Docs Architect** (Rames Assure) — `SPECS.md` (§8h baru), `ARCHITECTURE.md` §4.3/§5.x, tabel `.env`, dan catatan restore.

## Verifikasi (yang akan diwajibkan nanti)
- `php -l` tiap file PHP yang disentuh; `composer test` (PHPUnit 10, warning = gagal).
- Smoke render view `/backups` di luar HTTP.
- Uji backup ke direktori temp + project palsu (S3 target tiruan/minio), **selalu** `docker compose down -v` di akhir; **dilarang** menyentuh `database/*.json`, `apps`, `nginx-status` nyata.

## Risiko & Sisa Pekerjaan
- **Korupsi restore DB** bila tar mentah dipilih (§2) — risiko terbesar; butuh keputusan eksplisit.
- **Biaya & ukuran tanpa retensi** → wajib kebijakan retensi.
- **Kebocoran kredensial** ke log/argv/`ps` bila tidak disiplin.
- **Tabrakan nama env** dengan §8g (`BACKUP_*`) bila tidak dipakem namespace baru.
- **Scheduler terlewat** bila memilih worker in-container.
- Cakupan bind mount vs named volume menentukan kompleksitas implementasi secara signifikan.

Silakan jawab (boleh ringkas, mis. "1: named volume app saja + dump logis, 2: restic, 3: systemd timer + file 0600, 4: Phase 1 tanpa restore UI, 5: admin-only") — setelah itu saya kunci rencana dan mulai mendelegasikan ke tim.**