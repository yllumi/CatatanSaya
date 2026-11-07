## Ringkasan

Saat ini **instalasi ini belum bisa di-DR (disaster recovery)**: seluruh metadata app hanya ter-backup **lokal di server yang sama**, dan volume app yang hidup **tidak punya satu pun snapshot offsite**. Jadi bila server hilang total, data app hilang total — bukan hanya "harus menambah ulang satu per satu". Bahkan bila backup-nya ada, belum ada jalur *restore massal*: restore yang tersedia bersifat per-volume dan butuh record app yang sudah ada di DB.

---

## 1. Inventaris state yang harus dipulihkan

| State | Lokasi | Offsite? | Bisa diregenerasi? |
|---|---|---|---|
| Metadata app/user/billing/server/parked/backup-selection | `rames.sqlite` di named volume `rames` (`docker-compose.yml`) | ❌ snapshot `VACUUM INTO` lokal di `/var/lib/rames/backup` | ❌ (sumber kebenaran) |
| **Secret env app** (nilai literal, mis. `MARIADB_ROOT_PASSWORD`) | kolom `data` → field `env` di `apps_apps` **dan** `database/env/<name>.env` | ❌ | ❌ |
| Artefak app (`compose_content`, override port/nama/env, clone repo) | `apps/<name>/` (bind `${PWD}`) | ❌ | sebagian: template app dari `templates/<slug>` (git), app repo dari git |
| Deploy key SSH app + `known_hosts` | `database/keys/` (gitignored) | ❌ | hanya bila masih punya kuncinya |
| Passphrase restic | `database/restic/password` | ❌ (kunci ke semua backup!) | ❌ |
| Konfigurasi dashboard (`.env`: `SESSION_SECRET`, AWS, `APP_DOMAIN`, `PORT_RANGE_*`) | root repo (gitignored) | ❌ | ⚠️ manual |
| Vhost Nginx | `/etc/nginx/sites-available` (host) | ❌ | ✅ `NginxConfigGenerator` dari DB |
| Sertifikat SSL | `/etc/letsencrypt` | ❌ | ✅ re-issue (`SslIssuer`), kena rate limit LE |
| **Data volume app** | Docker volumes | ⚠️ restic S3 — **hanya yang dicentang "Berkala"** | ❌ |
| Konten parked HTML, logo branding | `database/parked/`, volume `rames` | ❌ | ❌ (dicatat sebagai batasan: `SPECS §8j.9`, `§7.16`) |

## 2. Kondisi nyata server ini (bukti perintah)

Diambil read-only (SELECT / `restic snapshots`), tanpa menyentuh data:

- App hidup: **2** (`image` = Chevereto, `picoclaw`); server registry: hanya `local` (single-server, belum ada agent).
- Volume hidup: `image_chevereto-images`, `image_mariadb-data`, `image_redis-data`, `picoclaw_picoclaw-data`, `picoclaw_picoclaw-ssh`.
- `backup_volumes` yang `scheduled:true` = **3**, semuanya milik app yang sudah dihapus (`testdocker_*`, `nocodb_nocodb-data`). **Tidak satu pun volume app hidup terjadwal** — `image_*` bahkan belum terdaftar.
- Run terjadwal terakhir (2026-11-07 08:37, `runtime/backup/status.json`): `volumes: 0`, status `ok` → **sukses palsu**, tidak ada peringatan.
- Repo restic: **45 snapshot**, terbaru **2026-10-29**, semuanya `project:wahoo` (app yang sudah tidak ada). Tag snapshots berisi `volume:`, `project:`, `app:<id>`, `strategy:` → bagus, pemetaan app↔volume bisa direkonstruksi dari S3 saja.
- Backup DB: 8 snapshot lokal (terakhir 2026-11-07), retensi 7 hari/4 pekan/3 bulan — semuanya di volume `rames` yang sama, yang **sengaja dikecualikan** dari backup volume (`SPECS §8i.7`).
- Puing: `apps/hermes/` kosong, `database/keys/` masih menyimpan kunci `hey`, `sollubiznew`, `wasender` (app sudah tidak ada).

**Kesimpulan angka:** RPO efektif untuk data app saat ini = ∞ (tidak ada backup), untuk metadata = 0 hanya bila disk selamat.

## 3. Gap menuju "pulihkan semua app ke server lain"

- **G1 — DB tidak pernah offsite.** Snapshot DB satu-satunya salinan ada di server yang sama. Ini gap paling fatal: DB memuat daftar app, port host, template, subdomain, **dan secret env**.
- **G2 — Artefak bind-mount tidak ikut backup apa pun.** `apps/`, `database/env/`, `database/keys/`, `database/restic/password`, `.env`. Tanpa ini, DB saja tidak cukup: app template butuh override port hasil pilihan user, app private butuh deploy key.
- **G3 — Backup volume opt-in & tidak ada kelengkapan.** Default OFF, dan tidak ada guard saat target terjadwal hilang → run "0 volume, ok".
- **G4 — Tidak ada konsep "bundle instalasi".** Tidak ada satu artefak/snapshot yang menyatakan "inilah seluruh instalasi pada waktu T".
- **G5 — Tidak ada restore massal.** `cli/backup.php restore` butuh `appId` + record app (validasi kepemilikan); `restore-archived` membuat volume baru per volume. Untuk N app: N × (buat volume → buat ulang app → arahkan ke volume → tunggu deploy) — persis pekerjaan manual yang ingin dihindari.
- **G6 — Dependensi lingkungan server baru:** DNS/wildcard, `APP_DOMAIN`/subdomain bisa berbeda, bentrok host port (`PORT_RANGE_*`), bentrok `container_name` (`ContainerNames` fail-fast), SSL re-issue kena rate limit Let's Encrypt.
- **G7 — Secret ada di DB dalam bentuk plaintext** (terverifikasi: `env` berisi nilai literal, panjang 48 char untuk password). Jadi setiap salinan offsite DB **wajib terenkripsi** dan aksesnya setara akses produksi.
- **G8 — Mode multi-server tidak menyelamatkan.** DB agent adalah data turunan (`SPECS §5.2`) dan juga lokal; agent tetap melayani app bila control plane mati, tapi tidak bisa menggantikan control plane (tanpa user/billing/registry). Repo restic tiap server dikonfigurasi dari `.env` masing-masing server.
- **G9 — Tidak ada uji restore berkala**, jadi "ada snapshot" belum terbukti "bisa dipulihkan".

## 4. Opsi

### Opsi A — Runbook cold DR sekarang (tanpa ubah kode, dampak terbesar)
1. **Offsite metadata**: ambil hasil `VACUUM INTO` (sudah konsisten, kelas `DbBackup`) lalu dorong ke restic repo yang sama dari host/helper — **jangan** backup volume `rames` dengan kebijakan `stop` (akan mematikan proses backup itu sendiri).
2. **Offsite artefak**: `restic backup apps/ database/env/ database/keys/ .env` (tag baru, mis. `role:install`) — jangan mencampur tag yang dipakai UI `volume:`/`project:`/`app:`.
3. **Nyalakan "Berkala"** untuk semua volume app hidup + `php cli/backup.php run <volume> manual`, lalu buktikan dengan `restic snapshots` bahwa tag app benar.
4. **Simpan offsite di luar S3**: `database/restic/password` + `.env` (tanpa itu backup = brankas tanpa kunci).
5. **Uji drill**: pulihkan ke VPS sementara (DB restore + 1 volume) → buktikan, jangan diasumsikan.
6. Tambah guard murah: run dengan `volumes: 0` saat ada app hidup ⇒ status `warning`, bukan `ok`.

### Opsi B — Fitur "DR bundle + restore instalasi" (yang benar-benar menjawab permintaan)
Satu bundle per snapshot S3, dihasilkan worker async:

```
manifest.json      # versi dashboard, APP_DOMAIN asal, daftar app {id,name,template,ports,domains,volumes,restic_snapshot_id}
rames.sqlite       # snapshot konsisten
artifacts.tar.gz   # apps/, database/env/, database/keys/, branding/, parked/
```

- `cli/dr.php export` → bangun bundle → `restic backup` (tag `role:install`) → catat di `runtime/dr/status.json`.
- `cli/dr.php restore --snapshot <id> [--domain baru]` di server baru, urutan **fail-fast sebelum efek samping**:
  1. validasi repo + manifest + `restic check`;
  2. restore DB (pakai `DbBackup::restore` — sudah aman/atomik) + artefak dengan permission benar (`env`/`keys` 0600);
  3. remap `server_id` → `local`, deteksi bentrok nama/port/domain (`ContainerNames`, `AppPorts`, `SubdomainManager`);
  4. per app: buat volume dari snapshot (jalur `VolumeRestoreService` arsip) → `docker compose up -d` lewat `DeployerInterface` (jangan jalur deploy kedua);
  5. render ulang vhost (`NginxConfigGenerator`) → reload → enqueue SSL (`SslIssuer`) → cetak checklist DNS.
- Karena `manifest` bisa juga direkonstruksi dari **tag snapshot restic**, bundle tetap bisa dipulihkan bila file manifest rusak.
- Tidak ada otorisasi baru (CLI tepercaya), tanpa state di controller, semua logika di `app/library/Dr/` — konsekuensinya **Tingkat Verifikasi V3** + dokumentasi SPECS §8l/ARCHITECTURE §5.x.

### Opsi C — Promote agent jadi control plane
Dinilai **tidak disarankan** sekarang: DB agent adalah proyeksi turunan, tanpa user/billing/registry, dan butuh jalur migrasi state baru yang lebih berisiko daripada Opsi B.

## 5. Rekomendasi urutan

| Prioritas | Aksi | Efek |
|---|---|---|
| **P0 (hari ini)** | Opsi A butir 1–4 | Mengubah RPO data app dari ∞ → 24 jam |
| **P0** | Drill restore 1 app ke host lain | Membuktikan backup benar-benar bisa dipakai |
| **P1** | Guard "run 0 volume" + default "Berkala" ON untuk volume app | Menutup kegagalan senyap |
| **P1** | Opsi B (`cli/dr.php` export/restore + manifest) | Menjawab "tanpa menambah satu per satu" |
| **P2** | Kartu "Kesiapan DR" di `/backups` + drill terjadwal | Mencegah regresi diam-diam |

## 6. Risiko yang wajib diketahui

- **Snapshot DB memuat secret plaintext** → simpan hanya di restic (terenkripsi) atau bundle terenkripsi; jangan taruh di bucket terbuka/laptop tanpa enkripsi.
- **Passphrase restic + `.env` adalah kunci tunggal**: hilang = semua snapshot S3 tidak berguna.
- **SSL**: re-issue massal bisa menyentuh limit LE (5 duplikat/minggu per domain); restore harus menjadwalkan SSL bertahap, bukan serentak.
- **Port & nama container** tidak dijamin kosong di server baru → restore massal wajib preflight `AppPorts`/`ContainerNames` sebelum menulis apa pun.
- **App hasil "Impor project compose"** menyimpan `local_path` absolut (`ComposeImporter`) — tidak portabel lintas host, harus ditangani terpisah.
- **S3 berbeda region/akun**: bila bucket ikut hilang bersama server (mis. akun cloud yang sama), DR tetap gagal — simpan salinan kedua.

---

Lanjutan yang bisa saya kerjakan (pilih salah satu): **(1)** susun runbook P0 lengkap dengan perintah per langkah (termasuk skrip host kecil untuk offsite DB+artefak), **(2)** rancang detail + implementasi `cli/dr.php export|restore` beserta manifest dan test (V3), atau **(3)** tambahkan guard kelengkapan backup + kartu kesiapan DR di `/backups`.

Sebelum memilih (2), saya perlu 3 keputusan Anda: apakah akan tetap **single-server** atau ada agent; apakah **bundle menyertakan secret** (terenkripsi) atau dipisah manual; dan apakah **SSL di-issue otomatis** saat restore atau hanya checklist.