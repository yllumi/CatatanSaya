# Analisis Rancangan Aplikasi AnaOnline Mobile

**Status:** Draf analisis — belum final
**Acuan:** [[Digitalisasi Iuran Anggota dan Pemutakhiran Data berbasis Aplikasi Mobile]]
**Dokumen terkait:** [[Ketentuan Herregistrasi Anggota Pemuda Persis]] · [[Baseline Bidang Administrasi Pemuda Persis]] · [[Strategi Menghimpun Data Anggota Pemuda]]
**Tanggal:** 25 Oktober 2026

---

## 1. Ringkasan Eksekutif

AnaOnline Mobile adalah aplikasi pendamping (companion app) dari SIM organisasi AnaOnline yang sudah berjalan sepuluh tahun. Aplikasi ini **tidak dibangun sebagai pengganti** AnaOnline, melainkan sebagai kanal baru di sisi anggota yang memecahkan dua masalah yang saling mengunci:

1. **Anggota jarang menyentuh sistem**, sehingga data keanggotaan tidak pernah termutakhirkan.
2. **Iuran masih dikelola manual berjenjang**, sehingga kas lambat terdistribusi dan rekonsiliasi antarlevel mahal.

Strateginya adalah menempatkan kewajiban yang bersifat **bulanan** (iuran) sebagai *hook*, dan kewajiban yang bersifat **berkala** (pemutakhiran profil, herregistrasi lima tahunan) sebagai *payload* yang ikut terselesaikan setiap kali anggota membuka aplikasi. *Payload* ini **tidak diproses di dalam aplikasi mobile**: mobile menampilkan statusnya dan mengalihkan anggota ke formulir yang sudah tersedia di AnaOnline.

**MVP (Tahap 1)** dirancang dengan satu pilar fungsional inti ditambah fondasi:

| Pilar | Fungsi | Alasan masuk MVP |
|---|---|---|
| **Iuran Anggota Digital** | Pembayaran iuran + alokasi otomatis ke 4 jenjang + penarikan mandiri | Satu-satunya alasan anggota mau membuka aplikasi 12× setahun; sekaligus *hook* yang membuat tahap berikutnya punya pengguna aktif |

**Tahap 2** menambahkan dua kemampuan yang saling menopang:

| Fitur Tahap 2 | Fungsi | Alasan penempatan |
|---|---|---|
| **Kanal Informasi Pimpinan Jam'iyyah** | Diseminasi kebijakan, surat edaran, pengumuman resmi per jenjang | Butuh otorisasi wilayah yang baru stabil di tahap 1; sekaligus kanal distribusi *prompt* pemutakhiran data |
| **e-KTA digital** | Kartu tanda anggota digital dengan verifikasi keaslian | Menjadi insentif konkret bagi anggota yang menuntaskan pembayaran & pemutakhiran data; memerlukan alur payout & ledger stabil agar keanggotaan aktif dapat dipercaya |

Fitur pemutakhiran data profil **tidak** dijadikan pilar tersendiri di layar utama, melainkan ditempelkan sebagai konsekuensi dari fitur-fitur di atas (lihat §5.5). Ini disengaja: kalau pemutakhiran profil berdiri sebagai menu terpisah, aplikasi akan mengulang kegagalan sepuluh tahun AnaOnline versi web.

> [!important] Prinsip: mobile sebagai penampil status, web sebagai kanal formulir
> Herregistrasi **tidak** dibangun ulang di aplikasi mobile. Form herregistrasi yang lengkap dan komprehensif sudah tersedia di platform AnaOnline, dan menduplikasinya berarti dua sumber kebenaran untuk satu proses yang sama. Aplikasi mobile hanya **menampilkan status keanggotaan** — aktif, akan berakhir, atau nonaktif — dan **mengalihkan (redirect)** anggota ke kanal herregistrasi di AnaOnline ketika tindakan diperlukan. Lihat §5.6.
>
> Prinsip yang sama berlaku untuk form pemutakhiran data profil: aplikasi hanya mendorong, menautkan, dan menampilkan hasilnya.

---

## 2. Turunan Masalah Menjadi Kebutuhan

| Masalah (dari latar belakang) | Kebutuhan sistem | Fitur |
|---|---|---|
| Rendahnya partisipasi *self-service profile update* | Anggota harus punya alasan rutin membuka aplikasi | Iuran (T1) + Kanal Informasi (T2) + e-KTA (T2) |
| Basis data tidak *real-time* | Data harus termutakhirkan sebagai efek samping interaksi rutin | *Profile nudge* pasca-transaksi |
| Pencatatan iuran tidak akurat di cabang | Satu sumber kebenaran transaksi, tidak ada pencatatan ganda | Iuran digital + ledger (T1) |
| Distribusi kas lambat berjenjang | Alokasi porsi dihitung saat transaksi, bukan setelahnya | *Auto-split* (T1) |
| Rekonsiliasi antarleval lambat | Laporan diturunkan dari satu ledger, bukan dari rekap manual | Laporan per jenjang (T1) |
| Transparansi alur dana rendah | Pimpinan tiap jenjang melihat saldo & riwayatnya sendiri | Dasbor keuangan jenjang (T1) |

Keterangan: **T1** = MVP/Tahap 1, **T2** = Tahap 2.

> [!note] Batasan penting
> Dokumen latar belakang menyebut "multi-channel payment gateway" dan "direct payout". Keduanya membawa implikasi hukum, perizinan, dan risiko finansial yang jauh melampaui pekerjaan teknis. Lihat §9 untuk prasyarat non-teknis sebelum sprint pertama.

---

## 3. Ruang Lingkup

### 3.1 Termasuk dalam MVP (Tahap 1)

**A. Iuran Anggota Digital**
- Tagihan bulanan otomatis per anggota.
- Pembayaran via *payment gateway*: Virtual Account, QRIS, e-wallet.
- Iuran bulanan **Rp 20.000** (ditetapkan PP), dengan porsi otomatis: Cabang 50%, Daerah 20%, Wilayah 15%, Pusat 15%.
- Status tagihan: hanya `belum_bayar` dan `lunas`.
- Pembayaran dapat mencakup banyak bulan sekaligus (tunggakan dan/atau bulan mendatang), minimal 1 bulan.
- Riwayat pembayaran anggota dan kuitansi digital.
- **Auto-split** porsi per jenjang saat pembayaran terkonfirmasi.
- **Dasbor keuangan jenjang**: saldo porsi, riwayat masuk, status penarikan.
- **Penarikan mandiri (disbursement)** ke rekening resmi kepengurusan, dengan alur persetujuan.
- **Halaman admin jenjang** (`admin_pc`/`pd`/`pw`/`pp`): rekap pembayaran iuran anggota sampai batas levelnya, dengan drill-down dan ekspor (§5.2).
- Ekspor laporan (CSV/PDF) per periode per jenjang.

**B. Fondasi yang wajib ada (bukan fitur, tapi prasyarat)**
- Autentikasi terpadu dengan akun AnaOnline (**API login sudah tersedia**) dan penanganan reset kata sandi sesuai [[Ketentuan Herregistrasi Anggota Pemuda Persis]] butir 3.
- **Role dibawa dari data anggota AnaOnline** saat login: `anggota`, `admin_pc`, `admin_pd`, `admin_pw`, `admin_pp`, `superadmin`.
- Otorisasi berbasis peran **dan** wilayah jenjang (pohon wilayah Pusat → Wilayah → Daerah → Cabang) — dipakai ulang seluruh fitur tahap 2.
- PWA: installable, *offline shell* untuk halaman arsip yang sudah dibuka.
- *Profile nudge* pasca-transaksi (§5.5) — versi minimal, terbatas pada field kritis.
- **Penampil status keanggotaan** (aktif / akan berakhir / nonaktif) beserta tanggal batas herregistrasi, ditarik dari `member_snapshot`.
- **Pengarahan ke kanal AnaOnline** untuk herregistrasi dan pemutakhiran profil, dengan *deep link* ke formulir yang sesuai (§5.6).

### 3.2 Tahap 2

**A. Kanal Informasi Pimpinan Jam'iyyah**
- Publikasi pengumuman/surat edaran dengan **target audiens berjenjang** (Pusat → Wilayah → Daerah → Cabang → Anggota).
- Kategori: kebijakan, surat edaran, agenda, instruksi.
- Lampiran berkas (PDF) dan tautan.
- Status baca (dibaca/belum) untuk pengurus — mendukung pembuktian diseminasi.
- *Push notification* dan arsip yang bisa dicari.

**B. e-KTA Digital**
- Kartu tanda anggota digital dengan foto, nomor anggota, jenjang kepemimpinan, dan **status keaktifan** yang diambil langsung dari `member_snapshot` — bukan gambar statis.
- **Kode verifikasi** (QR) yang dapat dipindai pihak lain untuk memastikan keaslian kartu tanpa membuka data pribadi berlebih.
- **Masa berlaku** mengikuti siklus herregistrasi 5 tahunan sesuai [[Ketentuan Herregistrasi Anggota Pemuda Persis]]; kartu otomatis menandai status nonaktif bila siklus tidak dipenuhi.
- **Prasyarat penerbitan** yang dapat dikonfigurasi: data profil tuntas pada field kritis dan/atau tidak ada tunggakan iuran. Ini menjadikan e-KTA *imbalan* dari perilaku yang diinginkan, bukan fitur pasif.
- *Mode terang* untuk ditunjukkan di layar, dan ekspor gambar untuk keperluan cetak oleh PD/PC.

> [!note] Batas e-KTA
> e-KTA adalah **representasi digital dari status keanggotaan**, bukan dokumen identitas resmi yang berdiri sendiri. Verifikasi akhir keabsahan tetap merujuk pada data keanggotaan di AnaOnline.

### 3.3 Sengaja ditunda (pasca-Tahap 2)

| Fitur | Alasan penundaan |
|---|---|
| Pemutakhiran profil berbasis *form lengkap* di aplikasi | Formulir lengkap sudah ada di AnaOnline web; mobile cukup mengarahkan ke sana |
| Herregistrasi lima tahunan sebagai **proses** (formulir, pengajuan, aktivasi) | Formulir yang lengkap dan komprehensif sudah ada di AnaOnline; menduplikasinya di mobile menciptakan dua sumber kebenaran. Mobile hanya menampilkan status dan mengarahkan (§5.6) |
| Pembayaran iuran Mukhtamar / uang pangkal | Volume rendah, pola berbeda dari iuran bulanan |
| Fitur kaderisasi, halaqah, e-office | Domain berbeda; jangan membebani tahap awal |
| Chat / forum antaranggota | Biaya moderasi tinggi, bukan kebutuhan inti |

> [!warning] Penempatan e-KTA perlu dikonfirmasi
> e-KTA diusulkan di Tahap 2 dengan asumsi modul pembayaran dan pemutakhiran data sudah berjalan sehingga status keaktifan dapat dipercaya. Bila e-KTA harus terbit untuk **seluruh** anggota — bukan hanya yang aktif di aplikasi — ia berubah menjadi fitur tahap 1 yang terikat langsung pada alur herregistrasi.

### 3.4 Non-goals

- Menggantikan fungsi admin AnaOnline versi web untuk pengurus (data master, verifikasi, dsb.).
- Menjadi dompet digital anggota (tidak ada saldo yang bisa dibelanjakan).
- Menjadi akuntansi penuh; sistem ini adalah **sumber transaksi**, bukan pembukuan resmi — meski harus bisa diekspor ke pembukuan.
- Menjadi **repositori dokumen organisasi** (QA-QD, SK, pedoman) — fitur ini dikeluarkan dari ruang lingkup.

---

## 4. Arsitektur Teknis

### 4.1 Gambaran Umum

```
┌──────────────────────────┐
│  │  Anggota (PWA Svelte)    │
│  Pengurus / Admin (PWA)   │
└───────────┬──────────────┘
            │ HTTPS / JSON
┌───────────▼──────────────────────────────┐
│  API Gateway / Nginx                     │
└───────────┬──────────────────────────────┘
            │
┌───────────▼──────────────────────────────┐
│  Backend — PHP Webman Framework          │
│  ├─ Modul Iuran (tagihan, split, payout) │
│  ├─ Modul Informasi (T2)                 │
│  ├─ Modul e-KTA (T2)                     │
│  ├─ Modul Akun & Otorisasi (role+wilayah)│
│  └─ Webhook & Scheduler (Workerman)      │
└───────┬───────────────┬──────────────────┘
        │               │
   ┌────▼─────┐   ┌─────▼──────┐   ┌──────────────┐
   │PostgreSQL│   │  Redis     │   │ Object Store │
   │(ledger)  │   │(cache/q)   │   │(lampiran    │
   │          │   │            │   │ pengumuman) │
   └──────────┘   └────────────┘   └──────────────┘
        │
   ┌────▼──────────────┐   ┌─────────────────────┐
   │ DB AnaOnline lama │   │ Payment Gateway     │
   │ (read/reference)  │   │ (VA/QRIS/e-wallet)  │
   └───────────────────┘   └─────────────────────┘
```

### 4.2 Pilihan Backend: PHP Webman Framework

**Alasan pemilihan**
- **Model proses persisten (Workerman/event-loop)**: Webman berjalan sebagai daemon tanpa *bootstrap* per request. Ini penting untuk dua hal yang jadi jantung aplikasi ini: **webhook pembayaran** yang harus cepat dan idempoten, serta **scheduler** untuk generate tagihan bulanan dan rekonsiliasi otomatis.
- **Ekosistem PHP**: memudahkan integrasi dan pemeliharaan oleh tim yang sudah memegang AnaOnline versi PHP, serta ketersediaan talenta lokal.
- **Websocket siap pakai**: bisa dipakai untuk notifikasi saldo/penarikan ke dasbor pengurus tanpa infrastruktur tambahan.
- **Jejak memori lebih kecil** dibanding PHP-FPM untuk beban webhook yang lonjakan.
- **Dukungan proses konsumen**: modul Tahap 2 (penerbitan token kartu, pengiriman notifikasi, penjadwalan publikasi) dapat dijalankan sebagai worker terpisah di dalam proses yang sama, tanpa menambah runtime baru.

**Konsekuensi yang harus diantisipasi**
- Model *long-running* berarti kode tidak boleh menyimpan state antar-request di properti statis; setiap koneksi DB harus dikelola poolnya dan ditutup dengan benar.
- Debugging berbeda dari PHP konvensional (tidak ada auto-reload; perlu alur deploy berbasis *graceful reload*).
- Ekosistem library lebih kecil dibanding Laravel; beberapa hal (queue, admin panel) harus dirakit sendiri atau memakai paket komunitas.

**Struktur modul yang diusulkan**

```
app/
  controller/
  model/
  service/
    Billing/        # generate tagihan, siklus bulanan
    Payment/        # adapter gateway, webhook, idempotensi
    Ledger/         # double-entry, auto-split, saldo jenjang
    Payout/         # pengajuan, persetujuan, eksekusi disbursement
    Announcement/   # T2 — publikasi, targeting audiens, status baca
    EKta/           # T2 — penerbitan kartu, verifikasi QR, siklus berlaku
    Membership/     # sinkronisasi data anggota + role dari AnaOnline
    Region/         # pohon wilayah & resolusi cakupan admin
    Reporting/      # rekap pembayaran per jenjang (§5.2)
  middleware/       # auth, RBAC+wilayah, rate limit
  process/          # worker scheduler, event consumer
config/
```

Modul T2 sengaja **ditempatkan sebagai service terpisah**, bukan dicampur ke modul Iuran. Alasannya: keduanya punya siklus hidup sendiri (kartu bisa diterbitkan ulang, pengumuman bisa kedaluwarsa) dan tidak boleh membuat rilis ulang modul pembayaran setiap kali ada perubahan. Yang mereka butuhkan dari modul lain hanyalah **status keanggotaan** dan **otorisasi wilayah** — dua hal yang sudah tersedia lewat `Membership` dan `middleware`.

**Keputusan penyimpanan berkas**

Lampiran pengumuman disimpan di **Object Store**, bukan di disk server aplikasi. Alasan: (a) Webman berjalan multi-proses sehingga berkas lokal rawan tidak konsisten antar-worker; (b) pertumbuhan lampiran tidak bisa diprediksi; (c) memudahkan *signed URL* berumur pendek sehingga berkas tidak bisa diakses tanpa otorisasi. Metadata lampiran tetap di PostgreSQL.

**Titik keputusan penting: pemisahan kompleksitas dengan pola *adapter***

Payment gateway **wajib** diabstraksi di balik interface `PaymentGateway` (`createCharge`, `parseWebhook`, `verifySignature`, `getStatus`, `refund`). Alasannya bukan sekadar kerapian: kebijakan organisasi kemungkinan akan berganti penyedia, dan alur *disbursement* punya karakter berbeda per penyedia. Tanpa adapter, kode bisnis akan menempel ke satu vendor dan biaya migrasi sangat tinggi.

### 4.3 Pilihan Frontend: Svelte PWA

**Alasan pemilihan**
- **Ukuran bundel kecil** dan performa baik di perangkat kelas menengah-bawah — relevan karena basis anggota tersebar, tidak semua memakai perangkat baru.
- Reaktivitas bawaan cocok untuk UI yang penuh status dinamis (status tagihan, saldo, status baca).
- PWA menghindari biaya dan friksi distribusi App Store/Play Store, serta memungkinkan *update* instan. Ini penting untuk organisasi yang tidak punya tim mobile native tetap.

**Konsekuensi yang harus diantisipasi**
- **Push notification di iOS terbatas** (hanya untuk PWA yang sudah di-*install*, dan itu pun sejak iOS 16.4). Ini melemahkan *engagement driver* yang menjadi inti strategi. Mitigasi: kanal fallback WhatsApp/email untuk pengingat iuran; jangan bertumpu pada push sebagai satu-satunya kanal.
- Tidak ada akses ke fitur native tertentu (biometrik penuh, kamera lanjutan untuk KTA scan) tanpa pembungkus native.
- *Update* otomatis berarti setiap regresi langsung dirasakan semua pengguna; wajib ada *staging* dan strategi versi API yang kompatibel.

**Bentuk organisasi kode**

```
src/
  lib/
    api/          # client ter-generate dari OpenAPI
    session/      # auth + refresh, penanganan offline
    components/   # design system internal
    offline/      # cache arsip pengumuman untuk akses luring
  routes/
    (public)/     # onboarding, login, reset password
    (member)/     # beranda, iuran, riwayat, informasi, e-KTA, profil
    (leader)/     # dasbor jenjang, rekap admin, penarikan, publikasi
```

Pemisahan `(member)` dan `(leader)` bukan hanya soal UI: keduanya punya model otorisasi berbeda (individu vs. jabatan+wilayah), dan memisahkannya sejak awal mencegah logika wilayah bocor ke kode sisi anggota.

**Kontrak API**

Bersama Svelte, backend sebaiknya mengekspos **OpenAPI spec** dan menurunkan *type* klien secara otomatis. Ini memberi keuntungan yang lebih besar daripada di stack monolit: dua basis kode terpisah tanpa kontrak eksplisit akan cepat menyimpang, terutama pada enum status pembayaran yang kritikal.

### 4.4 Keputusan Arsitektur Kunci

| # | Keputusan | Alternatif | Alasan |
|---|---|---|---|
| A1 | AnaOnline Mobile memakai **database transaksi sendiri** untuk ledger iuran, disinkronkan dengan DB keanggotaan AnaOnline | Menulis langsung ke DB AnaOnline | DB keanggotaan lama dipakai banyak modul; menambah beban tulis transaksi berisiko mengganggu sistem eksisting |
| A2 | **Double-entry ledger** untuk setiap pemindahan dana | Kolom saldo yang di-*update* langsung | Saldo yang di-update in-place tidak auditabel dan rawan selisih saat ada kegagalan parsial |
| A3 | PWA, bukan aplikasi native | Flutter/React Native | Biaya distribusi & pemeliharaan lebih rendah; cukup untuk kebutuhan tahap 1–2 |
| A4 | Sinkronisasi anggota **satu arah** (AnaOnline → Mobile) di tahap 1 | Dua arah | Menghindari konflik data ganda; pemutakhiran profil tetap lewat kanal yang sudah ada di tahap ini |
| A5 | Autentikasi **federated** ke AnaOnline lewat API login yang sudah ada; **role dibawa dari data anggota** dan tidak dikelola di mobile | Tabel pengguna & peran terpisah di mobile | AnaOnline sudah menjadi sumber data anggota; peran ganda akan cepat menyimpang dan menjadi celah otorisasi |
| A6 | Status keaktifan — untuk e-KTA maupun penampil status — **diturunkan** dari `member_snapshot`, tidak disimpan sebagai kolom terpisah | Menyimpan status di tabel kartu | Dua sumber kebenaran akan berselisih; kartu harus selalu mencerminkan data keanggotaan saat ini |
| A7 | Mobile **tidak menyimpan maupun memproses** data herregistrasi; hanya menampilkan status dan mengalihkan ke AnaOnline | Formulir herregistrasi ringkas di mobile | Formulir lengkap sudah ada di AnaOnline; duplikasi menciptakan dua sumber kebenaran dan beban pemeliharaan ganda |
| A8 | Tagihan hanya punya status **`belum_bayar`/`lunas`**; siklus percobaan bayar hidup di `payment_intent` | Status tagihan mengikuti status gateway | Dua model status yang bercampur membuat tagihan tampak "hangus" padahal kewajiban tetap ada |
| A9 | Porsi & nominal disimpan sebagai **aturan berversi** (`contribution_rule`) yang terikat ke periode tagihan | Menghitung dengan aturan terkini saat pembayaran | Kenaikan nominal tidak boleh mengubah alokasi transaksi atau tagihan lama secara retroaktif |
| A10 | Cakupan data admin diturunkan dari **pohon wilayah** (`region`), bukan dari field bebas di token | Menyimpan daftar cabang per admin | Satu acuan untuk rekap, informasi, dan e-KTA; menghindari aturan visibilitas yang saling bertentangan |

> [!warning] Keputusan A1 perlu dipastikan lebih dulu
> Jika tim AnaOnline tidak memungkinkan replikasi/sinkronisasi data anggota, A1 harus direvisi menjadi integrasi API. Ini **blocker** dan harus dikonfirmasi sebelum estimasi sprint dibuat.

---

## 5. Rancangan Fungsional

### 5.1 Pilar 1 — Iuran Anggota Digital

**Ketentuan nominal dan porsi (berlaku saat ini)**

| Parameter | Nilai |
|---|---|
| Iuran bulanan | **Rp 20.000** — ditetapkan Pimpinan Pusat |
| Pimpinan Cabang | **50%** → Rp 10.000 |
| Pimpinan Daerah | **20%** → Rp 4.000 |
| Pimpinan Wilayah | **15%** → Rp 3.000 |
| Pimpinan Pusat | **15%** → Rp 3.000 |
| **Total** | **100%** → Rp 20.000 |

Nominal ditetapkan oleh PP dan dapat berubah; komposisi porsi juga dapat berubah. Keduanya **tidak boleh** di-*hardcode* maupun ditulis ulang di kode frontend — lihat "Model aturan" di bawah.

**Status tagihan: hanya dua**

```
belum_bayar  →  lunas
```

Tidak ada status `menunggu`, `kadaluarsa`, atau `gagal` pada tagihan. Alasannya: status tagihan menyatakan **kewajiban anggota**, bukan kondisi percobaan pembayaran. Percobaan bayar yang batal atau kedaluwarsa tetap meninggalkan tagihan `belum_bayar` — pagar waktunya hidup di sesi pembayaran gateway, dicatat terpisah di `payment_intent`.

**Aturan pembayaran**

1. **Tunggakan lama dapat dibayar kapan pun.** Tagihan bulan-bulan sebelumnya yang `belum_bayar` tidak pernah hangus dan selalu tampil di beranda.
2. **Bulan mendatang dapat dibayar lebih awal.** Tagihan tahun berjalan dibuat di muka, sehingga anggota dapat membayar bulan depan (dan seterusnya) sebelum waktunya.
3. **Satu sesi minimal 1 bulan, boleh akumulatif.** Anggota memilih sejumlah bulan dalam satu transaksi (mis. 1, 3, 6, 12 bulan). Nominal sesi = total tagihan terpilih, dan **dialokasikan per tagihan** saat lunas — bukan lump sum tanpa rincian.
4. **Kombinasi bebas.** Tunggakan dan bulan mendatang boleh digabung dalam satu pembayaran. UI menyarankan urutan kronologis agar anggota tidak bingung, tetapi tidak memaksanya.
5. **Tidak ada pembayaran sebagian per bulan.** Satu tagihan dibayar penuh Rp 20.000. Ini menyederhanakan rekonsiliasi dan mencegah saldo menggantung di akun anggota.

**Alur utama pembayaran**

1. Scheduler (Webman process) membuat/menjaga tagihan bulanan untuk seluruh anggota aktif, memakai nominal dan porsi yang berlaku pada periode tagihan. Tagihan tahun berjalan dibuat di muka agar pembayaran di depan mungkin.
2. Anggota membuka beranda → melihat daftar `belum_bayar`: tunggakan di atas, bulan berjalan, lalu bulan mendatang.
3. Anggota memilih satu atau beberapa bulan → sistem menghitung total dan menampilkan rincian per bulan.
4. Anggota memilih metode bayar → backend membuat *charge* untuk **total**, menyimpan `payment_intent` beserta daftar tagihan yang dicakup.
5. Gateway mengirim webhook → backend **memverifikasi tanda tangan**, memeriksa **idempotensi**, lalu dalam satu transaksi database menandai **semua** tagihan dalam sesi menjadi `lunas`.
6. Untuk **setiap** tagihan, backend membuat jurnal ledger: debet kas gateway, kredit porsi tiap jenjang menurut aturan yang berlaku pada periode tagihan tersebut.
7. Anggota menerima kuitansi (satu dokumen dengan rincian per bulan); dasbor jenjang langsung memperlihatkan saldo bertambah.

> [!important] Prinsip yang tidak boleh dilanggar
> Langkah 5 dan 6 harus atomik **per sesi pembayaran**. Jika webhook tercatat lunas tetapi split gagal, organisasi punya uang yang tidak teralokasi. Jika split jalan dua kali, terjadi penggelembungan saldo jenjang. Pada pembayaran akumulatif, atomisitas mencakup seluruh tagihan dalam sesi: tidak boleh ada kondisi "3 bulan lunas, 1 bulan tertunggak padahal uangnya sudah masuk penuh".

**Model aturan (nominal + porsi, berversi)**

```
contribution_rule          -- aturan iuran yang berlaku
  id
  effective_from           -- tanggal mulai berlaku
  effective_to             -- NULL = masih berlaku
  nominal_bulanan          -- saat ini 20000
  keterangan               -- dasar penetapan (mis. keputusan PP)

contribution_share         -- porsi per jenjang dalam satu aturan
  id
  contribution_rule_id
  level                    # PUSAT | WILAYAH | DAERAH | CABANG
  percentage_bp            # basis poin; 5000 = 50%, 2000 = 20%, 1500 = 15%
```

**Aturan awal yang di-seed:** `nominal_bulanan = 20000`, porsi `CABANG 50%`, `DAERAH 20%`, `WILAYAH 15%`, `PUSAT 15%`, dengan `effective_from` = tanggal rilis.

Mengapa berversi: nominal akan berubah lewat keputusan PP. Tanpa versi, laporan periode lama berubah retroaktif ketika aturan baru diterapkan.

**Validasi yang wajib di-enforce sistem**
- Σ persentase = 100% — divalidasi saat menyimpan aturan.
- Nominal > 0 dan bilangan bulat rupiah.
- Pembulatan: dengan Rp 20.000 dan porsi 50/20/15/15 semua hasil bulat. Untuk nominal lain yang menghasilkan pecahan, *rounding remainder* dibebankan ke satu jenjang yang ditentukan (default: Cabang) agar total selalu = nominal penuh.
- **Aturan yang dipakai adalah aturan yang berlaku pada periode tagihan**, bukan aturan terkini. Ini krusial saat ada kenaikan nominal: tagihan Januari tetap memakai aturan Januari meski dibayar di Juni.
- Perubahan aturan hanya berlaku ke depan; tidak boleh mengubah tagihan atau jurnal yang sudah ada.

**Kapasitas penyimpanan tagihan**

Karena tagihan tahun berjalan dibuat di muka, baris `bill` bertambah sekitar 12 × jumlah anggota per tahun. Untuk basis puluhan ribu anggota ini masih nyaman di PostgreSQL (orde ratusan ribu baris per tahun) asalkan ada indeks `(member_id, periode)` dan `(status, periode)`. Yang perlu dijaga bukan volumenya, melainkan batas pembuatan: **maksimal satu tahun anggaran di muka**, lalu diperpanjang lewat scheduler.

**Dasbor keuangan jenjang**

- Anggota melihat: total tunggakan, bulan berjalan, riwayat `lunas`, kuitansi per bulan.
- Pengurus melihat: rekap pembayaran anggota di wilayahnya (lihat §5.2) serta saldo porsi jenjangnya, daftar transaksi penyumbang, grafik tren, ekspor.
- **Batas visibilitas**: Cabang hanya melihat cabangnya; Daerah melihat cabang-cabang di daerahnya; Wilayah melihat daerah-daerah di wilayahnya; Pusat melihat semua. Transparansi ini bergerak **lintas jenjang ke bawah**, bukan lintas jenjang sejajar.

**Penarikan mandiri (disbursement)**

Alur yang diusulkan:

```
diajukan → disetujui_admin_jenjang → diproses_gateway → selesai
                  │
                  └→ ditolak (dengan alasan)
```

- Rekening tujuan harus **terdaftar dan terverifikasi** lebih dulu (nama rekening sesuai kepengurusan), tidak boleh gratis-input per transaksi.
- Wajib ada **maker-checker**: pengaju dan penyetuju minimal dua orang berbeda, keduanya berperan admin di jenjang yang sama.
- Batas nominal per transaksi dan per periode agar tidak ada penarikan tunggal yang menguras kas jenjang.

> [!question] Hal yang perlu diputuskan organisasi, bukan teknis
> Role `admin_pc`/`admin_pd`/`admin_pw`/`admin_pp` menetapkan siapa yang boleh melihat rekap dan mengajukan penarikan. Yang belum ditetapkan: apakah peran admin yang sama juga berwenang **menyetujui** penarikan, atau perlu pejabat terpisah (mis. ketua/bendahara khusus) agar maker-checker benar-benar melibatkan dua orang. Jawaban ini harus tertuang dalam ketentuan resmi sebelum rilis.

### 5.2 Peran Pengguna & Halaman Admin Jenjang

**Model peran**

| Role | Cakupan data | Akses halaman admin |
|---|---|---|
| `anggota` | Data dirinya sendiri | Tidak |
| `admin_pc` | Anggota di **satu cabang** | Ya — rekap cabang |
| `admin_pd` | Anggota di **seluruh cabang** dalam daerahnya | Ya — rekap daerah, drill-down per cabang |
| `admin_pw` | Anggota di **seluruh daerah** dalam wilayahnya | Ya — rekap wilayah, drill-down per daerah/cabang |
| `admin_pp` | **Seluruh anggota nasional** | Ya — rekap nasional |
| `superadmin` | Seluruh data + konfigurasi sistem | Ya — termasuk aturan iuran & pengguna |

**Asal role: dibawa dari AnaOnline, bukan dikelola di mobile**

- Role **tidak** menjadi data milik aplikasi mobile, dan **tidak ada** halaman pengelolaan peran di mobile.
- Role diambil dari respons **API login AnaOnline** yang sudah tersedia, dibawa dalam token/klaim sesi, dan divalidasi ulang ke AnaOnline saat login.
- Aplikasi hanya menyimpan **salinan** role di sesi (`member_snapshot.role`) untuk keperluan tampilan dan *routing*; **otorisasi sebenarnya selalu diverifikasi di server** pada setiap permintaan.

> [!important] Prinsip otorisasi
> Menyembunyikan menu admin di frontend adalah kenyamanan, bukan keamanan. Setiap endpoint rekap dan penarikan **wajib** memeriksa role **dan** posisi wilayah pada level server — termasuk memastikan `region_id` yang diminta benar-benar berada di bawah wilayah admin tersebut, bukan sekadar ada di token.

**Pohon wilayah sebagai satu-satunya acuan cakupan**

Cakupan data admin ditentukan oleh pohon wilayah (Pusat → Wilayah → Daerah → Cabang). Tabel `region` harus menjadi acuan tunggal yang dipakai bersama oleh rekap iuran, kanal informasi Tahap 2, dan e-KTA. Ini menghapus kebutuhan akan mesin targeting wilayah terpisah.

**Halaman admin: rekap pembayaran iuran**

1. **Ringkasan** — jumlah anggota aktif, jumlah lunas bulan ini vs. belum, total nilai terkumpul periode ini, dan total tunggakan.
2. **Daftar anggota** — nama, cabang (bagi jenjang di atasnya), status bulan berjalan, jumlah bulan tertunggak, total tunggakan, tanggal pembayaran terakhir. Dapat difilter dan diurutkan.
3. **Rekap per periode** — matriks anggota × 12 bulan untuk melihat pola tunggakan.
4. **Drill-down** — PD: daftar cabang → masuk ke cabang; PW: daerah → cabang; PP: wilayah → daerah → cabang. **Total anak harus selalu sama dengan total induk**; bila tidak, itu indikator bug.
5. **Ekspor** — CSV/PDF untuk rapat dan audit.
6. **Detail anggota** — riwayat tagihan dan pembayaran satu anggota, untuk menangani sengketa "saya sudah bayar".

> [!warning] Yang tidak boleh dilakukan halaman admin
> - Mengubah status tagihan menjadi `lunas` secara manual tanpa jejak transaksi. Bila koreksi diperlukan, buat **transaksi koreksi** yang tercatat.
> - Menghapus data pembayaran.
> - Melihat data anggota di luar cakupan wilayahnya, termasuk lewat menebak ID pada URL.

**Minimalisasi data di halaman admin**

Rekap iuran tidak memerlukan NIK, alamat, atau dokumen kependudukan. Halaman admin hanya menampilkan **nama, nomor anggota, cabang, status iuran** — cukup untuk keperluan rekap, tanpa memperluas permukaan kebocoran data.

### 5.3 Tahap 2 — Kanal Informasi Pimpinan Jam'iyyah

> [!info] Penempatan
> Fitur ini dipindahkan dari MVP ke Tahap 2 karena bergantung pada otorisasi wilayah yang harus stabil lebih dulu, dan karena nilainya baru terasa ketika sudah ada basis pengguna aktif hasil modul iuran.

**Model publikasi**

```
announcement
  id
  judul
  isi (markdown terbatas)
  kategori       # KEB_BIJAKAN | SURAT_EDARAN | AGENDA | INSTRUKSI
  target_audience # array: {level, region_id|null}
  publikasi_pada
  kedaluwarsa_pada
  prioritas      # memengaruhi urutan di beranda
```

- **Targeting berjenjang** adalah fitur kuncinya, bukan sekadar daftar berita. Surat edaran untuk PW Jawa Barat tidak boleh muncul di beranda PC di Sumatera.
- **Penyaringan turunan**: publikasi ke satu jenjang otomatis terlihat oleh jenjang di bawahnya yang berada dalam wilayahnya (Pusat → semua; PW → PD & PC di wilayahnya).
- **Status baca** dicatat per pengurus, dengan dua level: *terkirim* dan *dibaca*. Ini yang mengubah kanal informasi dari "menyiarkan" menjadi "memastikan tersampaikan".
- **Arsip yang bisa dicari** — kebutuhan yang sering muncul belakangan: pengurus butuh menemukan surat edaran tahun lalu saat audit.

**Bentuk tampilan**
- Beranda anggota: kartu informasi prioritas tinggi + daftar ringkas.
- Beranda pengurus: informasi yang menargetkan jabatannya, dengan penanda belum dibaca dan status pembacaan jenjang di bawahnya (untuk pengurus yang meneruskan).

> [!tip] Satu detail yang menentukan adopsi
> Pengurus harus bisa **meneruskan** informasi ke kanal WhatsApp dengan satu ketukan (tautan + ringkasan otomatis). Tanpa ini, kanal informasi akan berhenti di aplikasi dan tidak sampai ke anggota yang belum menginstal PWA.

### 5.4 Tahap 2 — e-KTA Digital

**Tujuan.** Memberi anggota sesuatu yang konkret dan langsung berguna dari aplikasi, sekaligus menjadikan status keaktifan keanggotaan **terlihat** — bukan hanya tercatat di basis data.

**Isi kartu**
- Foto, nama, nomor anggota.
- Jenjang kepemimpinan dan wilayah (PC/PD/PW).
- Tanggal berlaku & tanggal batas herregistrasi berikutnya.
- QR verifikasi.

**Status kartu diturunkan, bukan disimpan**

Kartu **tidak** memiliki kolom status sendiri. Tampilannya dihitung saat diminta:

| Kondisi `member_snapshot` | Tampilan kartu |
|---|---|
| Aktif & data kritis lengkap | Kartu penuh, berlaku |
| Aktif tapi data kritis belum lengkap | Kartu dengan pita "perlu pemutakhiran data" + tombol langsung ke pengisian |
| Ada tunggakan iuran (jika dijadikan syarat) | Kartu dengan penanda tunggakan |
| Nonaktif (melewati batas herregistrasi) | Kartu redup/abu dengan keterangan "nonaktif" dan tautan **kelola herregistrasi di AnaOnline** |

**Verifikasi keaslian**

QR berisi token bertanda tangan (JWT berumur pendek atau token acak yang divalidasi ke server), **bukan** data pribadi mentah. Pemindai menerima respons minimal: nama, nomor anggota, status aktif, dan jenjang — cukup untuk memverifikasi, tanpa membocorkan NIK atau alamat. Tampilan pemindai tidak memerlukan login (agar bisa dicek di lapangan), tetapi dibatasi laju agar tidak dipakai untuk penelusuran massal.

**Cetak**

PD/PC masih memerlukan KTA fisik sesuai [[Ketentuan Herregistrasi Anggota Pemuda Persis]] butir 9. Aplikasi menyediakan ekspor gambar beresolusi cetak dan ekspor massal per cabang bagi admin — sehingga digitalisasi tidak memutus kebutuhan lama.

> [!question] Perlu keputusan
> Apakah e-KTA mensyaratkan tunggakan iuran nol? Jika ya, anggota yang menunggak kehilangan akses ke kartu — berisiko memicu penolakan dan kontak dukungan. Alternatif yang lebih lunak: kartu tetap tampil, tetapi dengan penanda jelas, dan pembatasan hanya pada keperluan tertentu (mis. mengikuti kegiatan resmi).

### 5.5 Mekanisme Pemutakhiran Data sebagai Konsekuensi

Ini bagian yang menyatukan seluruh fitur Tahap 1 dan Tahap 2 dan mewujudkan tujuan dari [[Strategi Menghimpun Data Anggota Pemuda]].

| Titik sentuh | Tahap | Trigger | Permintaan data |
|---|---|---|---|
| Pasca pembayaran berhasil | T1 | Selesai transaksi iuran | Konfirmasi 3–4 field **kritis** (nomor HP, alamat, status pekerjaan/pendidikan, PC) — bukan seluruh form |
| Pasca membaca informasi | T2 | Info kategori kebijakan/instruksi | Konfirmasi "data saya masih berlaku?" dengan satu tombol |
| Membuka e-KTA yang bertanda belum lengkap | T2 | Kartu menunjukkan pita "perlu pemutakhiran" | Tautan ke formulir pemutakhiran di AnaOnline untuk field yang ditandai |
| Menjelang batas keanggotaan | T1 | 30 hari sebelum batas 5 tahun | Status + tautan ke kanal herregistrasi di AnaOnline (§5.6) |

e-KTA sendiri berfungsi sebagai **umpan balik visual** dari mekanisme pemutakhiran data: anggota dapat melihat langsung bahwa kelengkapan datanya berpengaruh pada status kartu. Ini alasan tambahan menempatkannya di Tahap 2 — bukan sekadar fitur kartu, melainkan penutup lingkaran antara transaksi, data, dan identitas keanggotaan.

Prinsip desainnya: **jangan pernah meminta anggota mengisi form panjang tanpa imbalan langsung**. Setiap permintaan data harus menempel pada sesuatu yang baru saja anggota selesaikan, dan harus bisa dijawab dalam kurang dari satu menit. Bila jawabannya memerlukan formulir lengkap, aplikasi **tidak** membukanya sendiri — ia mengarahkan ke AnaOnline.

> [!note] Perubahan data tetap harus punya jejak
> Jejak perubahan (`mobile_app`, waktu, nilai lama → nilai baru) dicatat oleh **AnaOnline sebagai pemilik formulir**, bukan oleh aplikasi mobile. Mobile hanya membaca hasilnya lewat `member_snapshot`. Ini konsekuensi langsung dari prinsip "mobile sebagai penampil status" dan perlu dipastikan saat integrasi.

### 5.6 Status Keanggotaan & Pengalihan ke Kanal Herregistrasi

**Tujuan.** Membuat status keanggotaan **terlihat** setiap kali anggota membuka aplikasi, tanpa membangun ulang alur herregistrasi yang sudah lengkap di AnaOnline.

**Yang ditampilkan aplikasi**

| Elemen | Sumber | Catatan |
|---|---|---|
| Status keanggotaan (`aktif` / `akan berakhir` / `nonaktif`) | `member_snapshot.status_keaktifan` | Diturunkan, tidak diedit di mobile |
| Tanggal batas herregistrasi berikutnya | `member_snapshot` | Dihitung dari tanggal registrasi/ma'ruf + kelipatan 5 tahun |
| Sisa waktu | Turunan | Dihitung di klien; tidak perlu disimpan |
| Tanggal herregistrasi terakhir | `member_snapshot` | Sebagai riwayat keanggotaan |
| Tombol tindakan | — | Hanya muncul bila status menuntut tindakan |

**Aturan tampilan**

- `aktif` dengan sisa > 90 hari → badge netral, tanpa tombol tindakan.
- `aktif` dengan sisa ≤ 90 hari → badge peringatan + tombol **"Lanjutkan Herregistrasi di AnaOnline"**.
- `nonaktif` → badge merah + penjelasan singkat ("masa keanggotaan berakhir pada …") + tombol yang sama.

**Mekanisme pengalihan**

1. Aplikasi membuka kanal herregistrasi AnaOnline melalui **tautan langsung** (browser sistem atau *in-app browser*), membawa penanda asal `?from=mobile` untuk keperluan analitik.
2. Bila sesi AnaOnline masih berlaku, anggota langsung masuk ke formulir. Bila tidak, ia diarahkan ke login/reset kata sandi AnaOnline — **persis sebagaimana ketentuan** pada [[Ketentuan Herregistrasi Anggota Pemuda Persis]] butir 3.
3. Setelah selesai, anggota kembali ke aplikasi. Aplikasi **tidak** menganggap status berubah sampai `member_snapshot` tersinkron ulang; ada tombol "perbarui status" yang memicu tarik-ulang data.
4. Bila status belum berubah padahal anggota merasa sudah menyelesaikan, aplikasi menampilkan penjelasan bahwa pemrosesan ada di AnaOnline beserta tautan ke dasbor AnaOnline — **bukan** klaim bahwa pembayaran/pengajuan gagal.

> [!warning] Yang tidak boleh dilakukan aplikasi
> - Menyimpan salinan formulir herregistrasi atau mengumpulkan berkasnya.
> - Menampilkan status "terdaftar" secara optimistis setelah anggota menekan tombol.
> - Menjadi jalur pembayaran biaya herregistrasi yang terpisah dari AnaOnline — kecuali kelak diputuskan bahwa biaya herregistrasi memakai ledger iuran yang sama (§5.1). Untuk saat ini, **pembayaran herregistrasi tetap di AnaOnline**.

> [!note] Konsekuensi pada integrasi
> Fitur ini menambah satu kebutuhan integrasi: `member_snapshot` harus memuat `status_keaktifan`, `tanggal_registrasi_atau_maruf`, `tanggal_herregistrasi_terakhir`, dan `tanggal_batas_herregistrasi`. Bila AnaOnline belum menyediakan kolom turunan tanggal batas, perhitungan dilakukan di sisi mobile secara konsisten (satu fungsi, diuji dengan kasus tanggal akhir bulan dan tahun kabisat).

---

## 6. Model Data Inti

```sql
-- Ringkas, bukan DDL final

member_snapshot     -- salinan data anggota dari AnaOnline (hasil API login)
  id, anaonline_member_id (unik), nama,
  cabang_id, daerah_id, wilayah_id, status_keaktifan,
  role,                             -- anggota|admin_pc|admin_pd|admin_pw|admin_pp|superadmin
  tanggal_registrasi_atau_maruf, tanggal_herregistrasi_terakhir,
  tanggal_batas_herregistrasi,      -- turunan; NULL-nya dihitung klien (§5.6)
  terakhir_sinkron, versi_data
  -- TIDAK ada data formulir herregistrasi di sini (A7)

region              -- pohon wilayah: PUSAT > WILAYAH > DAERAH > CABANG (A10)
  id, level, nama, parent_id (NULL untuk Pusat)

contribution_rule   -- aturan iuran berversi (§5.1, A9)
  id, effective_from, effective_to (NULL = berlaku),
  nominal_bulanan,                  -- saat ini 20000
  keterangan

contribution_share  -- porsi per jenjang dalam satu aturan
  id, contribution_rule_id, level,
  percentage_bp                     -- 5000=50%, 2000=20%, 1500=15%, 1500=15%
  -- CHECK jumlah percentage_bp per rule = 10000

bill                -- tagihan periodik
  id, member_id, periode (YYYY-MM), jenis (BULANAN|PANGKAL|MUKHTAMAR),
  nominal, status (belum_bayar|lunas), contribution_rule_id,
  paid_at
  -- UNIQUE(member_id, periode, jenis) mencegah tagihan ganda
  -- TIDAK ada status menunggu/kadaluarsa/gagal (A8)

payment_intent      -- sesi percobaan bayar; boleh mencakup banyak tagihan
  id, gateway, gateway_reference (unik), metode,
  nominal, status (pending|paid|failed|expired),
  expires_at, paid_at
  -- UNIQUE(gateway, gateway_reference) untuk idempotensi

payment_intent_bill -- tagihan yang dicakup satu sesi pembayaran
  payment_intent_id, bill_id
  -- total nominal sesi = SUM(bill.nominal) dari baris di sini

ledger_entry        -- jurnal double-entry
  id, transaksi_id, akun_id, debit, kredit, dibuat_pada
  -- CHECK (debit = 0 OR kredit = 0)

ledger_account      -- akun per jenjang
  id, level, region_id, jenis (KAS_GATEWAY|HAK_CABANG|HAK_DAERAH|HAK_WILAYAH|HAK_PUSAT)

payout_request
  id, account_id, nominal, rekening_id, status,
  diajukan_oleh, disetujui_oleh, dieksekusi_pada

-- ── Tahap 2 ──────────────────────────────────────────────

-- ── Tahap 2 ──────────────────────────────────────────────

announcement
  id, judul, isi, kategori, prioritas, publikasi_pada,
  kedaluwarsa_pada, lampiran_ref (NULL = tanpa lampiran)

announcement_target
  announcement_id, level, region_id (NULL = semua)

announcement_read
  announcement_id, user_id, dibaca_pada

kta_verification_token  -- token QR berumur pendek
  id, member_id, token_hash, diterbitkan_pada, kedaluwarsa_pada,
  dicabut_pada
```

**Catatan desain**
- `payment_intent.status` mengikuti siklus percobaan bayar (`pending`/`paid`/`failed`/`expired`), sedangkan `bill.status` hanya `belum_bayar`/`lunas`. Keduanya **tidak boleh** saling diturunkan secara implisit (A8); tagihan hanya berubah ke `lunas` lewat service yang juga menulis jurnal.
- Tagihan menyimpan `contribution_rule_id`, bukan salinan persentase. Nominal dan porsi saat tagihan dibuat dapat direkonstruksi kapan pun, dan kenaikan aturan tidak mengubah tagihan lama (A9).
- `payment_intent_bill` memungkinkan satu sesi pembayaran mencakup banyak bulan. Tanpa tabel ini, pembayaran akumulatif hanya bisa disimpan sebagai lump sum dan tidak dapat direkonsiliasi per periode.
- `region` adalah acuan tunggal cakupan admin dan targeting informasi. `daerah_id`/`wilayah_id` pada anggota boleh di-denormalisasi untuk kueri cepat, tetapi harus selalu dapat ditelusuri kembali ke pohon `region`.
- Nominal `20000` hanya ada di `contribution_rule` (seed), tidak di kode frontend maupun di perhitungan rekap.
- `role` di `member_snapshot` adalah **salinan** dari AnaOnline untuk tampilan dan *routing*; otorisasi sebenarnya diverifikasi di server terhadap `region` (A5, A10).
- Tabel `member_snapshot` sengaja **tidak** menyimpan data pribadi sensitif berlebih; cukup yang dibutuhkan aplikasi. Ini mengurangi beban kepatuhan perlindungan data.
- Nama field konsisten Bahasa Indonesia untuk domain organisasi, Bahasa Inggris untuk domain teknis — supaya tidak ada campuran setengah-setengah di satu tabel.
- `lampiran_ref` pada `announcement` menunjuk berkas di Object Store, dibuka melalui *signed URL* berumur pendek; tidak ada metadata versi dokumen karena repositori sudah dikeluarkan dari ruang lingkup.
- e-KTA **tidak** punya tabel kartu tersendiri. Yang disimpan hanya `kta_verification_token`; seluruh tampilan kartu diturunkan dari `member_snapshot` (A6). Ini mencegah kartu tampil "aktif" padahal keanggotaan sudah nonaktif.
- Tidak ada tabel apa pun untuk proses herregistrasi — bukan kelalaian, melainkan keputusan A7. Yang disimpan hanya **hasil**-nya (`tanggal_herregistrasi_terakhir`, `status_keaktifan`) yang berasal dari AnaOnline.

---

## 7. Keamanan, Privasi, dan Kepatuhan

| Area | Risiko | Mitigasi |
|---|---|---|
| Webhook pembayaran | Pemalsuan notifikasi lunas | Verifikasi tanda tangan + *allowlist* IP gateway + rekonsiliasi berkala ke API gateway |
| Idempotensi | Saldo jenjang terpenggelembungan | Kunci unik pada referensi gateway; transisi status lewat state machine |
| Otorisasi wilayah | Admin melihat/menarik dana atau rekap jenjang lain | *Middleware* yang memeriksa `role` + posisi `region` pada **setiap** query, bukan hanya di UI (A10) |
| Eskalasi peran | Anggota mengubah klaim role pada token | Role divalidasi ulang ke AnaOnline saat login; klaim token tidak dipercaya sendirian |
| Pembayaran akumulatif | Uang diterima penuh tetapi hanya sebagian tagihan lunas | Atomisitas per sesi + `payment_intent_bill` sebagai daftar tagihan yang dicakup |
| Data pribadi anggota | Kebocoran NIK, alamat, nomor HP | Minimalisasi data; enkripsi kolom sensitif; log akses |
| Akun | Pengambilalihan akun | Sesuai ketentuan: reset via email terdaftar; eskalasi ke admin PC/PD; wajib 2FA untuk akun pengurus |
| Penarikan dana | Penyalahgunaan oleh pengurus | Maker-checker, rekening pra-terverifikasi, batas nominal, log audit |
| Lampiran pengumuman (T2) | Berkas berbahaya / disalahgunakan | Pembatasan tipe & ukuran, pemindaian berkas, *signed URL* berumur pendek |
| Verifikasi e-KTA (T2) | Pemindaian massal untuk mengumpulkan data anggota | Token berumur pendek tanpa data pribadi berlebih; pembatasan laju; respons minimal |
| Katastrofik | Kehilangan data ledger | Backup harian terenkripsi + uji restore berkala (ledger tanpa uji restore = tidak ada backup) |

**Kepatuhan.** Aplikasi akan menyimpan data pribadi anggota dalam skala nasional. Perlu ada dasar hukum internal (ketentuan organisasi) yang menyatakan tujuan pengumpulan, retensi, dan hak anggota atas datanya. Ini pekerjaan dokumen, tapi **harus selesai sebelum go-live**, karena menambal kebijakan setelah data terkumpul jauh lebih mahal.

---

## 8. Roadmap Pengembangan

Estimasi dalam bentuk durasi relatif per fase, bukan tanggal, karena bergantung pada ketersediaan tim dan kesiapan integrasi.

### Tahap 1 — MVP

| Fase | Isi | Keluaran yang bisa dinilai |
|---|---|---|
| **0. Prasyarat** | Konfirmasi bentuk respons API login (role & wilayah); konfirmasi ketentuan penarikan dana | Keputusan tertulis, bukan dokumen teknis |
| **1. Fondasi** | Kerangka Webman, login AnaOnline + role, pohon wilayah & cakupan admin, skeleton PWA, pipeline deploy, *profile nudge* minimal, **penampil status keanggotaan + pengalihan ke AnaOnline** | Login dengan 6 role berjalan; admin PC tidak dapat membuka data PD di *staging* |
| **2. Iuran inti** | `contribution_rule` seed Rp 20.000 (50/20/15/15), tagihan tahun berjalan, adapter gateway (1 penyedia dulu), webhook, ledger, **pembayaran akumulatif multi-bulan**, kuitansi | Pembayaran 1, 3, dan 6 bulan end-to-end dari VA/QRIS di *staging*; total porsi = nominal |
| **3. Rekap & dasbor jenjang** | Halaman admin per jenjang dengan drill-down, saldo porsi, laporan, ekspor | Total anak = total induk; rekap cocok dengan perhitungan manual |
| **4. Payout** | Pengajuan, maker-checker, eksekusi | Penarikan satu jenjang berhasil dengan jejak audit |
| **5. Uji coba** | Pilot terbatas 1 PD / beberapa PC, pengukuran | Metrik adopsi & partisipasi data awal |

### Tahap 2

| Fase | Isi | Keluaran yang bisa dinilai |
|---|---|---|
| **6. Kanal informasi** | Publikasi, targeting berjenjang, kategori, status baca, push, penerusan ke WhatsApp, lampiran | Surat edaran uji tersampaikan sesuai jenjang |
| **7. e-KTA** | Kartu turunan status, QR verifikasi, ekspor cetak, penanda data belum lengkap | Kartu uji berubah status sesuai perubahan keanggotaan |
| **8. Uji coba Tahap 2 & iterasi** | Pilot lebih luas, pengukuran metrik informasi & kelengkapan data | Metrik §11 bergerak, bukan sekadar fitur selesai |

> [!warning] Mengapa payout tetap sebelum Tahap 2
> Payout adalah fitur dengan risiko finansial tertinggi, tetapi ia **menutup janji inti MVP**: kas sampai ke jenjang tanpa proses berjenjang. Menempatkannya sebelum kanal informasi berarti Tahap 1 selesai sebagai produk yang utuh secara finansial, sementara Tahap 2 dibangun di atas basis pengguna yang sudah terbentuk. Pada fase uji coba, penarikan dana masih dapat dilakukan manual oleh Pusat.

> [!note] Ketergantungan antarfase Tahap 2
> Fase 6 dan 7 tidak saling bergantung dan dapat dikerjakan paralel atau dibalik urutannya, asalkan fase 1 (status keanggotaan) sudah stabil.

---

## 9. Prasyarat Non-Teknis (Blocker)

Dokumen latar belakang mengasumsikan otomatisasi finansial penuh. Sebelum pekerjaan teknis serius dimulai, empat hal berikut harus diputuskan:

1. **Badan hukum & kepemilikan rekening.** Rekening penampung dana gateway harus atas nama entitas yang sah. Uang anggota yang mengalir lewat rekening pribadi adalah risiko hukum dan kepercayaan.
2. **Skema perizinan pembayaran.** Model *auto-split* + *disbursement* ke banyak jenjang dapat dikategorikan sebagai layanan pemindahan dana. Perlu konsultasi dengan penyedia gateway tentang model yang sesuai (mis. *sub-merchant* / *split payment* resmi vs. penampung tunggal).
3. **Tata tertib penarikan.** Nominal (Rp 20.000) dan porsi (50/20/15/15) sudah ditetapkan PP dan menjadi seed sistem, tetapi otoritas penyetuju penarikan belum — lihat pertanyaan terbuka di §5.1.
4. **Dasar pemrosesan data pribadi.** Lihat §7.

> [!faq]- Kalau ketentuan belum ada, apakah pengembangan tetap bisa jalan?
> Bisa, dengan **menunda fase 4 (payout)** dan menjalankan fase 1–3. Nominal dan porsi sudah pasti sehingga fase 2–3 tidak menunggu keputusan apa pun. Yang tidak bisa dihindari adalah keputusan nomor 1 dan 2, karena menentukan desain adapter gateway sejak awal.

Satu prasyarat tambahan muncul karena Tahap 2:

5. **Prasyarat penerbitan e-KTA.** Apakah e-KTA diterbitkan untuk semua anggota atau hanya yang memenuhi syarat tertentu (data lengkap, iuran lancar), dan bagaimana perlakuan bagi anggota yang tidak memakai aplikasi sama sekali.

---

## 10. Risiko

| # | Risiko | Dampak | Mitigasi |
|---|---|---|---|
| R1 | Push notification iOS tidak andal untuk PWA | *Engagement driver* melemah | Kanal fallback WhatsApp/email; promosi "tambahkan ke layar utama" saat onboarding |
| R2 | Respons API login tidak memuat role dan/atau wilayah | Fase 1 terhambat; cakupan admin tidak dapat ditentukan | Konfirmasi kontrak API di fase 0; bila belum ada, perlu penyesuaian di sisi AnaOnline, bukan solusi di sisi mobile |
| R3 | Adopsi pengurus rendah di jenjang bawah | Fitur informasi & penarikan tidak terpakai | Pilot terbatas, pendampingan admin PC; targetkan pengurus sebagai pengguna *early adopter* |
| R4 | Kenaikan nominal iuran oleh PP tanpa versi aturan | Tagihan & alokasi lama berubah retroaktif | `contribution_rule` berversi, terikat per periode tagihan (A9) |
| R5 | Tim maintainer tunggal di Webman | Bus factor tinggi | Konvensi kode, dokumentasi modul, CI wajib |
| R6 | Ukuran bundel/kompleksitas PWA tumbuh | Pengalaman memburuk di perangkat lemah | Budget ukuran bundel di CI; uji di perangkat kelas bawah sejak fase 2 |
| R7 | Sengketa "sudah bayar tapi status belum lunas" | Beban dukungan & kepercayaan | Halaman status pembayaran transparan; tombol "periksa ulang" yang memicu rekonsiliasi bukan menunggu; SLA manual |
| R8 | Kartu e-KTA menampilkan status yang sudah kedaluwarsa | Kesan organisasi tidak tertib data | Status diturunkan dari `member_snapshot` (A6), bukan disimpan; token verifikasi berumur pendek |
| R9 | Anggota menyelesaikan herregistrasi di AnaOnline tetapi status belum berubah saat kembali | Anggapan aplikasi rusak / data hilang | Tarik-ulang data setelah kembali; pesan yang menyatakan pemrosesan ada di AnaOnline; tautan ke dasbor AnaOnline |
| R10 | Pengalihan keluar aplikasi (tab browser) membuat anggota tidak kembali | Kebingungan alur | Buka di *in-app browser* dengan tombol "kembali ke aplikasi"; jangan gunakan pengalihan tanpa jalan pulang |
| R11 | Anggota membayar 6 bulan sekaligus, lalu ingin mengubah pilihan | Kebingungan & potensi refund | Ringkasan konfirmasi sebelum bayar; setelah `paid`, perubahan hanya lewat koreksi berjejak, bukan edit |
| R12 | Rekap admin lambat pada data nasional (`admin_pp`) | Halaman tidak terpakai | Indeks `(status, periode)` + agregasi ter-*cache*; uji beban dengan volume nasional sejak fase 3 |

---

## 11. Metrik Keberhasilan

Berhasil bukan ketika fiturnya selesai, tapi ketika angka berikut bergerak.

**Sasaran Tahap 1** (6 bulan pasca-rilis MVP):

| Metrik | Baseline | Target |
|---|---|---|
| Proporsi anggota yang memakai aplikasi minimal 1×/bulan | ~0 | ≥ 25% dari anggota aktif |
| Rasio pembayaran iuran via aplikasi | mayoritas manual | ≥ 40% nilai iuran bulanan |
| Kelengkapan field kritis anggota | (ukur saat fase 0 — prasyarat) | +20 poin persentase |
| Waktu rekonsiliasi antarjenjang | hari/minggu | < 1 hari |
| Anggota yang sadar status keanggotaannya (membuka penampil status ≥ 1×/tahun) | tidak terukur | ≥ 50% anggota aktif aplikasi |
| Proporsi anggota dengan sisa masa keanggotaan ≤ 90 hari yang mengklik tautan herregistrasi | tidak terukur | ≥ 40% |
| Proporsi pembayaran yang mencakup > 1 bulan (bukti fitur akumulatif dipakai) | ~0 | ≥ 15% transaksi |
| Tunggakan rata-rata bulan per anggota aktif | (ukur saat fase 0) | menurun ≥ 30% dalam 6 bulan |
| Admin jenjang aktif memakai halaman rekap minimal 1×/bulan | 0 | ≥ 70% akun admin |

> [!caution] Metrik pengalihan bukan ukuran keberhasilan akhir
> Klik tautan hanya mengukur **kesampaian pesan**, bukan terselesaikannya herregistrasi — penyelesaian terjadi di AnaOnline dan tidak terlihat dari sisi aplikasi. Bila ingin mengukur hasil, perlu satu angka dari AnaOnline yang dicocokkan dengan penanda `?from=mobile` pada tautan.

**Sasaran Tahap 2** (6 bulan pasca-rilis Tahap 2):

| Metrik | Baseline | Target |
|---|---|---|
| Rasio surat edaran terbaca oleh pengurus sasaran | tidak terukur | ≥ 80% dalam 7 hari |
| Rata-rata usia pembaruan data profil | tidak diketahui | ≤ 12 bulan |
| Anggota aktif yang memiliki e-KTA aktif | 0 | ≥ 60% anggota aktif aplikasi |

> [!tip] Kenapa keberhasilan kanal informasi diukur dari keterbacaan
> Jumlah pengumuman bukan ukuran keberhasilan — bisa tinggi tanpa dibaca. Yang mengubah perilaku adalah ketika surat edaran benar-benar sampai dan dibaca pengurus sasaran.

---

## 12. Catatan Terbuka

- [ ] Konfirmasi kontrak API login AnaOnline: apakah respons memuat `role` (`anggota`/`admin_pc`/`admin_pd`/`admin_pw`/`admin_pp`/`superadmin`) beserta ID cabang/daerah/wilayah.
- [ ] Konfirmasi struktur pohon wilayah resmi (PW/PD/PC) sebagai acuan cakupan admin, termasuk apakah satu pengurus bisa memegang lebih dari satu jabatan/wilayah.
- [ ] Penyedia gateway yang dipakai, dan apakah mendukung *split payment* resmi.
- [ ] Kewenangan penyetujuan penarikan per jenjang (apakah admin yang sama atau pejabat terpisah) & batas nominal.
- [ ] Apakah role `superadmin` dikelola di AnaOnline atau dianggap peran teknis terpisah.
- [ ] Apakah `admin_pp` boleh mengekspor data rekap nasional (pertimbangan minimalisasi data).
- [ ] Kebutuhan Bahasa daerah / aksesibilitas di PWA.
- [ ] Rencana migrasi data iuran historis (jika ingin riwayat sebelum rilis).
- [ ] Periode awal pembuatan tagihan saat go-live (mulai bulan rilis atau mundur ke awal tahun).
- [ ] Syarat penerbitan e-KTA dan perlakuan bagi anggota tanpa akses aplikasi.
- [ ] Kebutuhan penerbitan KTA massal per cabang (ekspor cetak) pada fase 7.
- [ ] URL/tautan langsung ke formulir herregistrasi dan profil di AnaOnline (perlu dukungan *deep link* dari sisi AnaOnline).
- [ ] Apakah AnaOnline menyediakan `tanggal_batas_herregistrasi` secara langsung, atau harus dihitung di sisi mobile.
- [ ] Format penanda asal (`?from=mobile`) untuk mengukur hasil pengalihan, bila AnaOnline dapat mencatatnya.

---

## 13. Penutup

Rancangan ini menerjemahkan dua tujuan dari [[Digitalisasi Iuran Anggota dan Pemutakhiran Data berbasis Aplikasi Mobile]] menjadi rencana bertahap yang bisa dieksekusi. **Tahap 1** menempatkan iuran sebagai penggerak interaksi bulanan — Rp 20.000 per bulan, terbagi 50/20/15/15 ke Cabang/Daerah/Wilayah/Pusat — dengan pembayaran fleksibel satu hingga banyak bulan sekaligus, menutup janji finansialnya sampai kas benar-benar sampai ke jenjang, dan menjadikan status keanggotaan terlihat tanpa menduplikasi alur herregistrasi. Rekap per jenjang memberi pengurus alat kerja nyata, bukan sekadar status. **Tahap 2** — kanal informasi dan e-KTA — dibangun di atas basis pengguna yang sudah terbentuk, sehingga setiap fitur baru punya orang yang benar-benar membukanya, bukan sekadar terpasang. Pemutakhiran data tetap menjadi hasil samping seluruh interaksi tersebut, bukan menu yang menunggu dikunjungi.

Pembagian peran antara mobile dan AnaOnline sengaja tegas: **mobile adalah kanal interaksi dan penampil status; AnaOnline tetap menjadi pemilik formulir dan proses**. Herregistrasi, pemutakhiran profil, dan verifikasi administratif tidak dibangun ulang — aplikasi hanya memastikan anggota menyadari statusnya dan dapat sampai ke formulir yang tepat dalam satu ketukan. Ini menjaga satu sumber kebenaran untuk setiap proses kritis.

Pilihan PHP Webman untuk backend memberi keunggulan pada webhook, scheduler, dan efisiensi proses yang menjadi denyut aplikasi ini; Svelte PWA memberi biaya distribusi rendah dengan konsekuensi pada keandalan notifikasi yang harus dimitigasi sejak awal. Keduanya tetap memadai untuk kebutuhan Tahap 2 tanpa perubahan arsitektur mendasar.

Yang paling menentukan keberhasilan bukan pilihan framework, melainkan **kesiapan keputusan organisasi** pada §9: kepemilikan rekening penampung, skema perizinan pembayaran, otoritas penarikan, dasar hukum pemrosesan dana serta data, dan syarat penerbitan e-KTA. Sistem hanya dapat menegakkan aturan yang sudah ditetapkan; tanpa itu, aplikasi secanggih apa pun akan berhenti di tahap uji coba.
