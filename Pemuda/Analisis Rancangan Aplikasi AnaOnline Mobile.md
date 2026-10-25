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

**Tahap 2** menambahkan tiga kemampuan yang saling menopang:

| Fitur Tahap 2 | Fungsi | Alasan penempatan |
|---|---|---|
| **Kanal Informasi Pimpinan Jam'iyyah** | Diseminasi kebijakan, surat edaran, pengumuman resmi per jenjang | Butuh otorisasi wilayah yang baru stabil di tahap 1; sekaligus kanal distribusi *prompt* pemutakhiran data |
| **Repositori Dokumen Organisasi** | QA-QD, SK, surat edaran, pedoman — tersimpan, ber-versi, dan dapat dicari per jenjang | Nilainya bergantung pada kanal informasi (dokumen menempel pada surat/pengumuman); tidak ada gunanya dibangun sebelum ada pengguna aktif |
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
| Keputusan & pedoman organisasi tersebar di banyak berkas | Dokumen resmi terpusat, ber-versi, dan dapat dirujuk | Repositori Dokumen Organisasi (T2) |

Keterangan: **T1** = MVP/Tahap 1, **T2** = Tahap 2.

> [!note] Batasan penting
> Dokumen latar belakang menyebut "multi-channel payment gateway" dan "direct payout". Keduanya membawa implikasi hukum, perizinan, dan risiko finansial yang jauh melampaui pekerjaan teknis. Lihat §9 untuk prasyarat non-teknis sebelum sprint pertama.

---

## 3. Ruang Lingkup

### 3.1 Termasuk dalam MVP (Tahap 1)

**A. Iuran Anggota Digital**
- Tagihan bulanan otomatis per anggota.
- Pembayaran via *payment gateway*: Virtual Account, QRIS, e-wallet.
- Status tagihan: `belum_bayar`, `menunggu`, `lunas`, `kadaluarsa`, `gagal`.
- Riwayat pembayaran anggota dan kuitansi digital.
- **Auto-split** porsi per jenjang saat pembayaran terkonfirmasi.
- **Dasbor keuangan jenjang**: saldo porsi, riwayat masuk, status penarikan.
- **Penarikan mandiri (disbursement)** ke rekening resmi kepengurusan, dengan alur persetujuan.
- Ekspor laporan (CSV/PDF) per periode per jenjang.

**B. Fondasi yang wajib ada (bukan fitur, tapi prasyarat)**
- Autentikasi terpadu dengan akun AnaOnline (SSO) dan penanganan reset kata sandi sesuai [[Ketentuan Herregistrasi Anggota Pemuda Persis]] butir 3.
- Otorisasi berbasis peran **dan** wilayah jenjang — dipakai ulang seluruh fitur tahap 2.
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
- Terhubung ke Repositori Dokumen: setiap pengumuman/surat dapat merujuk versi dokumen resmi yang berlaku.

**B. Repositori Dokumen Organisasi**
- **Jenis dokumen**: QA-QD (Qaidah/Quality Assurance & Quality Development), SK (Surat Keputusan), surat edaran, pedoman kerja bidang, dan dokumen resmi lain yang ditetapkan.
- **Ber-versi**: setiap revisi menyimpan versi lama; dokumen berstatus `berlaku` / `dicabut` / `arsip` — pengurus tidak lagi bertanya "ini SK yang mana?".
- **Metadata wajib**: nomor dokumen, tanggal penetapan, pejabat/lembaga penetap, jenjang keberlakuan (Pusat/Wilayah/Daerah/Cabang), dan tanggal mulai/berakhir berlaku.
- **Targeting jenjang**: dokumen hanya terlihat oleh jenjang yang berhak (dan jenjang di bawahnya bila ditetapkan berlaku turun).
- **Pencarian** berdasarkan nomor, judul, jenis, tahun, dan isi teks.
- **Unduh & baca luring**: dokumen yang sudah dibuka tetap dapat diakses saat sinyal buruk (penting untuk pengurus di lapangan).
- **Kontrol unggah**: pembatasan jenis berkas, batas ukuran, dan pemindaian berkas sebelum dipublikasikan.

**C. e-KTA Digital**
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
- Menjadi sistem manajemen dokumen penuh (alur persetujuan dokumen berjenjang, tanda tangan digital) — repositori hanya menyimpan, mem-versi, dan menyebarkan dokumen yang sudah ditetapkan.

---

## 4. Arsitektur Teknis

### 4.1 Gambaran Umum

```
┌──────────────────────────┐
│  Anggota (PWA Svelte)    │
│  Pengurus (PWA Svelte)   │
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
│  ├─ Modul Dokumen (T2)                   │
│  ├─ Modul e-KTA (T2)                     │
│  ├─ Modul Akun & Otorisasi Wilayah       │
│  └─ Webhook & Scheduler (Workerman)      │
└───────┬───────────────┬──────────────────┘
        │               │
   ┌────▼─────┐   ┌─────▼──────┐   ┌──────────────┐
   │PostgreSQL│   │  Redis     │   │ Object Store │
   │(ledger)  │   │(cache/q)   │   │(lampiran,    │
   │          │   │            │   │ dokumen)     │
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
- **Dukungan proses konsumen**: modul Tahap 2 (indeks pencarian dokumen, OCR, penerbitan token kartu) dapat dijalankan sebagai worker terpisah di dalam proses yang sama, tanpa menambah runtime baru.

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
    Document/       # T2 — repositori, versi dokumen, pencarian
    EKta/           # T2 — penerbitan kartu, verifikasi QR, siklus berlaku
    Membership/     # sinkronisasi data anggota dari AnaOnline
  middleware/       # auth, RBAC+wilayah, rate limit
  process/          # worker scheduler, event consumer
config/
```

Modul T2 sengaja **ditempatkan sebagai service terpisah**, bukan dicampur ke modul Iuran. Alasannya: ketiganya punya siklus hidup sendiri (dokumen bisa ber-versi, kartu bisa diterbitkan ulang, pengumuman bisa kedaluwarsa) dan tidak boleh membuat rilis ulang modul pembayaran setiap kali ada perubahan. Yang mereka butuhkan dari modul lain hanyalah **status keanggotaan** dan **otorisasi wilayah** — dua hal yang sudah tersedia lewat `Membership` dan `middleware`.

**Keputusan penyimpanan berkas**

Lampiran pengumuman dan dokumen organisasi disimpan di **Object Store**, bukan di disk server aplikasi. Alasan: (a) Webman berjalan multi-proses sehingga berkas lokal rawan tidak konsisten antar-worker; (b) pertumbuhan dokumen tidak bisa diprediksi; (c) memudahkan *signed URL* berumur pendek sehingga dokumen tidak bisa diakses tanpa otorisasi. Metadata dan relasi versi tetap di PostgreSQL.

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
    offline/      # cache dokumen & arsip untuk akses luring
  routes/
    (public)/     # onboarding, login, reset password
    (member)/     # beranda, iuran, riwayat, informasi, dokumen, e-KTA, profil
    (leader)/     # dasbor jenjang, penarikan, publikasi, unggah dokumen
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
| A5 | Autentikasi **federated** ke AnaOnline, bukan tabel user baru | Akun terpisah | Anggota sudah punya akun; akun ganda adalah sumber kebingungan dan beban dukungan |
| A6 | Status keaktifan — untuk e-KTA maupun penampil status — **diturunkan** dari `member_snapshot`, tidak disimpan sebagai kolom terpisah | Menyimpan status di tabel kartu | Dua sumber kebenaran akan berselisih; kartu harus selalu mencerminkan data keanggotaan saat ini |
| A9 | Mobile **tidak menyimpan maupun memproses** data herregistrasi; hanya menampilkan status dan mengalihkan ke AnaOnline | Formulir herregistrasi ringkas di mobile | Formulir lengkap sudah ada di AnaOnline; duplikasi menciptakan dua sumber kebenaran dan beban pemeliharaan ganda |
| A7 | Dokumen organisasi disimpan di Object Store dengan metadata + relasi versi di PostgreSQL | Disk server aplikasi | Multi-proses Webman + pertumbuhan dokumen + kebutuhan *signed URL* |
| A8 | Publikasi informasi & dokumen memakai **satu mesin targeting jenjang** yang sama | Targeting terpisah per modul | Dokumen menempel pada surat/pengumuman; satu mesin mencegah aturan visibilitas yang saling bertentangan |

> [!warning] Keputusan A1 perlu dipastikan lebih dulu
> Jika tim AnaOnline tidak memungkinkan replikasi/sinkronisasi data anggota, A1 harus direvisi menjadi integrasi API. Ini **blocker** dan harus dikonfirmasi sebelum estimasi sprint dibuat.

---

## 5. Rancangan Fungsional

### 5.1 Pilar 1 — Iuran Anggota Digital

**Alur utama pembayaran**

1. Scheduler (Webman process) membuat tagihan bulanan untuk seluruh anggota aktif, berdasarkan aturan nominal yang berlaku dan data keanggotaan yang tersinkron.
2. Anggota membuka beranda → melihat tagihan berjalan.
3. Anggota memilih metode bayar → backend membuat *charge* di gateway, menyimpan `payment_intent` berstatus `pending`.
4. Gateway mengirim webhook → backend **memverifikasi tanda tangan**, memeriksa **idempotensi** (satu `intent` hanya boleh jadi `paid` sekali), lalu menandai lunas.
5. Dalam satu **transaksi database**, backend membuat jurnal ledger: debet kas gateway, kredit kewajiban tiap jenjang sesuai porsi.
6. Anggota menerima kuitansi digital; dasbor jenjang langsung memperlihatkan saldo bertambah.

> [!important] Prinsip yang tidak boleh dilanggar
> Langkah 4 dan 5 harus atomik. Jika webhook tercatat lunas tetapi split gagal, organisasi punya uang yang tidak teralokasi. Jika split jalan dua kali, terjadi penggelembungan saldo jenjang.

**Model porsi (auto-split)**

Porsi disimpan sebagai **konfigurasi berversi**, bukan angka hardcode:

```
split_rule
  id
  effective_from      # tanggal mulai berlaku
  effective_to        # NULL = berlaku
  level               # PUSAT | WILAYAH | DAERAH | CABANG
  percentage          # basis poin (integer), mis. 1000 = 10%
  nominal_override    # opsional, untuk iuran flat
```

Alasan berversi: nominal dan komposisi porsi akan berubah lewat keputusan Mukhtamar/Munas. Tanpa versi, laporan periode lama akan berubah retroaktif saat aturan baru diterapkan.

**Validasi yang wajib di-enforce sistem**
- Σ persentase = 100% (atau dengan porsi "operasional/pusat" eksplisit) — divalidasi saat simpan aturan.
- Pembulatan: sisakan *rounding remainder* ke satu jenjang yang ditentukan, supaya total pecahan selalu = nominal penuh.
- Perubahan aturan hanya berlaku ke depan; tidak boleh mengubah transaksi yang sudah ada.

**Dasbor keuangan jenjang**

- Anggota melihat: tagihan bulan ini, status, riwayat 12 bulan, kuitansi.
- Pengurus melihat: saldo porsi jenjangnya, daftar transaksi penyumbang, grafik tren, ekspor.
- **Batas visibilitas**: Pengurus Cabang hanya melihat cabangnya; Daerah melihat agregat daerah; Pusat melihat semua. Ini penerapan langsung dari tujuan "transparansi", tapi transparansi **lintas jenjang ke bawah**, bukan lintas jenjang sejajar.

**Penarikan mandiri (disbursement)**

Alur yang diusulkan:

```
diajukan → disetujui_bendahara → diproses_gateway → selesai
                    │
                    └→ ditolak (dengan alasan)
```

- Rekening tujuan harus **terdaftar dan terverifikasi** lebih dulu (nama rekening sesuai kepengurusan), tidak boleh gratis-input per transaksi.
- Wajib ada **maker-checker**: pengaju dan penyetuju minimal dua orang berbeda.
- Batas nominal per transaksi dan per periode agar tidak ada penarikan tunggal yang menguras kas jenjang.

> [!question] Hal yang perlu diputuskan organisasi, bukan teknis
> Siapa yang berwenang menyetujui penarikan di tiap jenjang? Apakah penyetuju cukup di jenjang yang sama, atau perlu *counter-approval* dari jenjang di atas untuk nominal besar? Ini harus tertuang dalam ketentuan resmi sebelum rilis, karena sistem hanya akan menegakkan aturan yang tertulis.

### 5.2 Tahap 2 — Kanal Informasi Pimpinan Jam'iyyah

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

### 5.3 Tahap 2 — Repositori Dokumen Organisasi

**Tujuan.** Menjadikan dokumen resmi organisasi — QA-QD, SK, surat edaran, pedoman kerja bidang — dapat **ditemukan, dipastikan versinya, dan disebarkan** dari satu tempat, alih-alih beredar sebagai lampiran di grup WhatsApp yang tidak diketahui mana yang berlaku.

**Model dokumen**

```
document
  id
  jenis          # QA_QD | SK | SURAT_EDARAN | PEDOMAN | LAINNYA
  nomor_dokumen  # unik per jenis + tahun
  judul
  ringkasan
  pejabat_penetap
  tanggal_penetapan
  berlaku_mulai, berlaku_sampai
  status         # BERLAKU | DICABUT | ARSIP
  level_keberlakuan   # PUSAT | WILAYAH | DAERAH | CABANG
  region_id      # NULL untuk Pusat
  versi_terkini

document_version
  id, document_id, nomor_versi, berkas_ref (object store),
  hash_berkas, diunggah_oleh, diunggah_pada, catatan_revisi

document_access_log
  document_id, user_id, aksi (LIHAT|UNDUH), waktu
```

**Prinsip yang harus ditegakkan sistem**

1. **Dokumen tidak boleh dihapus.** Pencabutan mengubah `status`, bukan menghapus baris. Alasan: sengketa keanggotaan dan audit sering justru membutuhkan dokumen yang sudah dicabut.
2. **Versi lama tetap dapat diakses** dengan penanda jelas "versi lama — sudah digantikan oleh versi X per tanggal Y". Tanpa penanda ini, orang akan memakai versi lama tanpa sadar.
3. **Nomor dokumen unik.** Sistem menolak nomor ganda; ini mencegah dua SK berbeda dengan nomor sama beredar bersamaan.
4. **`hash_berkas` dicatat** saat unggah, untuk mendeteksi berkas yang berubah di luar sistem.
5. **Visibilitas mengikuti jenjang keberlakuan** dan aturan turunan wilayah yang sama dengan kanal informasi (A8).

**Pencarian**

Pencarian harus mencakup **isi teks** dokumen, bukan hanya judul — pengurus biasanya mengingat isi ("aturan tentang iuran") bukan nomornya. Pendekatan yang realistis untuk MVP tahap 2: ekstraksi teks PDF saat unggah, disimpan di kolom `tsvector` PostgreSQL. Jika dokumen berupa hasil pindai, perlu OCR; sebaiknya dijadwalkan sebagai pekerjaan terpisah karena biayanya berbeda kelas.

**Kaitan dengan kanal informasi**

Setiap pengumuman/surat edaran dapat merujuk `document_id`. Saat pengurus membuka pengumuman, sistem menampilkan versi dokumen yang **berlaku pada tanggal publikasi pengumuman tersebut** — bukan versi terbaru. Ini detail kecil yang mencegah kesalahpahaman "dokumen yang dirujuk sudah berubah".

> [!warning] Kontrol unggah bukan formalitas
> Repositori dokumen adalah kanal resmi. Wajib ada pembatasan siapa yang boleh mengunggah per jenis dokumen (SK kemungkinan hanya Sekretaris Jenderal/sekretariat Pusat), batas ukuran berkas, dan pemindaian malware sebelum berkas dapat diunduh orang lain.

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
| Menjelang herregistrasi | T1 | 30 hari sebelum batas 5 tahun | Status + tautan ke kanal herregistrasi di AnaOnline (§5.6) |

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

member_snapshot     -- salinan data anggota dari AnaOnline
  id, anaonline_member_id (unik), nama, jenjang_wilayah,
  cabang_id, daerah_id, wilayah_id, status_keaktifan,
  tanggal_registrasi_atau_maruf, tanggal_herregistrasi_terakhir,
  tanggal_batas_herregistrasi,      -- turunan; NULL-nya dihitung klien (§5.6)
  terakhir_sinkron, versi_data
  -- TIDAK ada data formulir herregistrasi di sini (A9)

bill                -- tagihan periodik
  id, member_id, periode (YYYY-MM), jenis (BULANAN|PANGKAL|MUKHTAMAR),
  nominal, jatuh_tempo, status, split_rule_id

payment_intent      -- percobaan bayar
  id, bill_id, gateway, gateway_reference (unik), metode,
  nominal, status, expires_at, paid_at
  -- UNIQUE(gateway, gateway_reference) untuk idempotensi

ledger_entry        -- jurnal double-entry
  id, transaksi_id, akun_id, debit, kredit, dibuat_pada
  -- CHECK (debit = 0 OR kredit = 0)

ledger_account      -- akun per jenjang
  id, level, region_id, jenis (KAS_GATEWAY|HAK_PUSAT|HAK_WILAYAH|...)

payout_request
  id, account_id, nominal, rekening_id, status,
  diajukan_oleh, disetujui_oleh, dieksekusi_pada

split_rule
  id, effective_from, effective_to, level, percentage_bp, nominal_override

-- ── Tahap 2 ──────────────────────────────────────────────

audience_rule        -- satu mesin targeting untuk pengumuman & dokumen
  id, tipe_objek (ANNOUNCEMENT|DOCUMENT), objek_id,
  level, region_id (NULL = semua)

announcement
  id, judul, isi, kategori, prioritas, publikasi_pada,
  kedaluwarsa_pada, document_id (NULL = tanpa rujukan dokumen)

announcement_read
  announcement_id, user_id, dibaca_pada

document
  id, jenis, nomor_dokumen (unik per jenis+tahun), judul, ringkasan,
  pejabat_penetap, tanggal_penetapan, berlaku_mulai, berlaku_sampai,
  status (BERLAKU|DICABUT|ARSIP), level_keberlakuan, region_id,
  versi_terkini, isi_tsv (tsvector untuk pencarian isi)

document_version
  id, document_id, nomor_versi, berkas_ref, hash_berkas,
  diunggah_oleh, diunggah_pada, catatan_revisi

document_access_log
  document_id, user_id, aksi, waktu

kta_verification_token  -- token QR berumur pendek
  id, member_id, token_hash, diterbitkan_pada, kedaluwarsa_pada,
  dicabut_pada
```

**Catatan desain**
- `payment_intent.status` dan `bill.status` **tidak boleh** saling diturunkan secara implisit; keduanya punya siklus hidup sendiri dan hanya disinkronkan lewat service.
- Tabel `member_snapshot` sengaja **tidak** menyimpan data pribadi sensitif berlebih; cukup yang dibutuhkan aplikasi. Ini mengurangi beban kepatuhan perlindungan data.
- Nama field konsisten Bahasa Indonesia untuk domain organisasi, Bahasa Inggris untuk domain teknis — supaya tidak ada campuran setengah-setengah di satu tabel.
- `audience_rule` menggantikan `announcement_target`: satu tabel untuk pengumuman dan dokumen (A8), dengan `tipe_objek` sebagai pembeda. `document_id` pada `announcement` menjaga rujukan dokumen tetap eksplisit.
- e-KTA **tidak** punya tabel kartu tersendiri. Yang disimpan hanya `kta_verification_token`; seluruh tampilan kartu diturunkan dari `member_snapshot` (A6). Ini mencegah kartu tampil "aktif" padahal keanggotaan sudah nonaktif.
- Tidak ada tabel apa pun untuk proses herregistrasi — bukan kelalaian, melainkan keputusan A9. Yang disimpan hanya **hasil**-nya (`tanggal_herregistrasi_terakhir`, `status_keaktifan`) yang berasal dari AnaOnline.

---

## 7. Keamanan, Privasi, dan Kepatuhan

| Area | Risiko | Mitigasi |
|---|---|---|
| Webhook pembayaran | Pemalsuan notifikasi lunas | Verifikasi tanda tangan + *allowlist* IP gateway + rekonsiliasi berkala ke API gateway |
| Idempotensi | Saldo jenjang terpenggelembungan | Kunci unik pada referensi gateway; transisi status lewat state machine |
| Otorisasi wilayah | Pengurus melihat/menarik dana jenjang lain | *Middleware* yang memeriksa `level + region_id` pada **setiap** query, bukan hanya di UI |
| Data pribadi anggota | Kebocoran NIK, alamat, nomor HP | Minimalisasi data; enkripsi kolom sensitif; log akses |
| Akun | Pengambilalihan akun | Sesuai ketentuan: reset via email terdaftar; eskalasi ke admin PC/PD; wajib 2FA untuk akun pengurus |
| Penarikan dana | Penyalahgunaan oleh pengurus | Maker-checker, rekening pra-terverifikasi, batas nominal, log audit |
| Berkas dokumen (T2) | Unggahan berkas berbahaya / dokumen palsu | Pemindaian malware, pembatasan tipe & ukuran, `hash_berkas`, otorisasi unggah per jenis dokumen |
| Akses dokumen (T2) | Dokumen jenjang tertentu terbaca jenjang lain | *Signed URL* berumur pendek; visibilitas dari `audience_rule`, dicek di server |
| Verifikasi e-KTA (T2) | Pemindaian massal untuk mengumpulkan data anggota | Token berumur pendek tanpa data pribadi berlebih; pembatasan laju; respons minimal |
| Katastrofik | Kehilangan data ledger | Backup harian terenkripsi + uji restore berkala (ledger tanpa uji restore = tidak ada backup) |

**Kepatuhan.** Aplikasi akan menyimpan data pribadi anggota dalam skala nasional. Perlu ada dasar hukum internal (ketentuan organisasi) yang menyatakan tujuan pengumpulan, retensi, dan hak anggota atas datanya. Ini pekerjaan dokumen, tapi **harus selesai sebelum go-live**, karena menambal kebijakan setelah data terkumpul jauh lebih mahal.

---

## 8. Roadmap Pengembangan

Estimasi dalam bentuk durasi relatif per fase, bukan tanggal, karena bergantung pada ketersediaan tim dan kesiapan integrasi.

### Tahap 1 — MVP

| Fase | Isi | Keluaran yang bisa dinilai |
|---|---|---|
| **0. Prasyarat** | Konfirmasi integrasi data anggota; penetapan aturan porsi; keputusan kebijakan penarikan dana | Keputusan tertulis, bukan dokumen teknis |
| **1. Fondasi** | Kerangka Webman, SSO, RBAC+wilayah, skeleton PWA, pipeline deploy, *profile nudge* minimal, **penampil status keanggotaan + pengalihan ke AnaOnline** | Login, otorisasi, dan status keanggotaan berjalan di *staging* |
| **2. Iuran inti** | Model tagihan, adapter gateway (1 penyedia dulu), webhook, ledger, kuitansi | Pembayaran end-to-end dari VA/QRIS di *staging* |
| **3. Split & dasbor** | Auto-split, saldo jenjang, laporan, ekspor | Laporan per jenjang cocok dengan perhitungan manual |
| **4. Payout** | Pengajuan, maker-checker, eksekusi | Penarikan satu jenjang berhasil dengan jejak audit |
| **5. Uji coba** | Pilot terbatas 1 PD / beberapa PC, pengukuran | Metrik adopsi & partisipasi data awal |

### Tahap 2

| Fase | Isi | Keluaran yang bisa dinilai |
|---|---|---|
| **6. Mesin targeting bersama** | `audience_rule` (A8), kerangka publikasi & dokumen, otorisasi jenjang lanjutan | Satu aturan visibilitas dipakai dua modul |
| **7. Kanal informasi** | Publikasi, kategori, status baca, push, penerusan ke WhatsApp | Surat edaran uji tersampaikan sesuai jenjang |
| **8. Repositori dokumen** | Dokumen ber-versi, unggah terkontrol, pencarian isi teks, baca luring, rujukan dari pengumuman | SK/QA-QD uji dapat ditemukan dari nomor maupun isi |
| **9. e-KTA** | Kartu turunan status, QR verifikasi, ekspor cetak, penanda data belum lengkap | Kartu uji berubah status sesuai perubahan keanggotaan |
| **10. Uji coba Tahap 2 & iterasi** | Pilot lebih luas, pengukuran metrik informasi & kelengkapan data | Metrik §11 bergerak, bukan sekadar fitur selesai |

> [!warning] Mengapa payout tetap sebelum Tahap 2
> Payout adalah fitur dengan risiko finansial tertinggi, tetapi ia **menutup janji inti MVP**: kas sampai ke jenjang tanpa proses berjenjang. Menempatkannya sebelum kanal informasi berarti Tahap 1 selesai sebagai produk yang utuh secara finansial, sementara Tahap 2 dibangun di atas basis pengguna yang sudah terbentuk. Pada fase uji coba, penarikan dana masih dapat dilakukan manual oleh Pusat.

> [!note] Ketergantungan antarfase Tahap 2
> Fase 6 harus mendahului 7 dan 8 karena keduanya memakai mesin targeting yang sama. Fase 9 **tidak** bergantung pada 7–8 dan dapat dikerjakan paralel, asalkan data status keanggotaan dari fase 1 sudah stabil.

---

## 9. Prasyarat Non-Teknis (Blocker)

Dokumen latar belakang mengasumsikan otomatisasi finansial penuh. Sebelum pekerjaan teknis serius dimulai, empat hal berikut harus diputuskan:

1. **Badan hukum & kepemilikan rekening.** Rekening penampung dana gateway harus atas nama entitas yang sah. Uang anggota yang mengalir lewat rekening pribadi adalah risiko hukum dan kepercayaan.
2. **Skema perizinan pembayaran.** Model *auto-split* + *disbursement* ke banyak jenjang dapat dikategorikan sebagai layanan pemindahan dana. Perlu konsultasi dengan penyedia gateway tentang model yang sesuai (mis. *sub-merchant* / *split payment* resmi vs. penampung tunggal).
3. **Ketentuan porsi dan tata tertib penarikan.** Angka persentase dan otoritas penyetuju adalah keputusan organisasi. Sistem tidak boleh menebak.
4. **Dasar pemrosesan data pribadi.** Lihat §7.

> [!faq]- Kalau ketentuan belum ada, apakah pengembangan tetap bisa jalan?
> Bisa, dengan **menunda fase 4 (payout)** dan menjalankan fase 1–3. Aturan porsi di fase 3 memerlukan angka pasti, tetapi dapat dikonfigurasi di akhir dan tidak memblokir arsitektur. Yang tidak bisa dihindari adalah keputusan nomor 1 dan 2, karena menentukan desain adapter gateway sejak awal.

Dua prasyarat tambahan muncul karena Tahap 2:

5. **Kebijakan dokumen resmi.** Repositori hanya dapat berfungsi bila organisasi menetapkan jenis dokumen mana yang wajib diunggah, siapa yang berwenang menetapkan versi berlaku, dan kapan dokumen dinyatakan dicabut. Tanpa ini, sistem akan menjadi tempat penumpukan berkas tanpa otoritas.
6. **Prasyarat penerbitan e-KTA.** Apakah e-KTA diterbitkan untuk semua anggota atau hanya yang memenuhi syarat tertentu (data lengkap, iuran lancar), dan bagaimana perlakuan bagi anggota yang tidak memakai aplikasi sama sekali.

---

## 10. Risiko

| # | Risiko | Dampak | Mitigasi |
|---|---|---|---|
| R1 | Push notification iOS tidak andal untuk PWA | *Engagement driver* melemah | Kanal fallback WhatsApp/email; promosi "tambahkan ke layar utama" saat onboarding |
| R2 | Integrasi data anggota ke AnaOnline tidak tersedia | MVP terhambat di fase 1 | Konfirmasi dini (§9); opsi sementara: impor berkala |
| R3 | Adopsi pengurus rendah di jenjang bawah | Fitur informasi & penarikan tidak terpakai | Pilot terbatas, pendampingan admin PC; targetkan pengurus sebagai pengguna *early adopter* |
| R4 | Perubahan aturan porsi saat berjalan | Laporan lama berubah | `split_rule` berversi (§5.1) |
| R5 | Tim maintainer tunggal di Webman | Bus factor tinggi | Konvensi kode, dokumentasi modul, CI wajib |
| R6 | Ukuran bundel/kompleksitas PWA tumbuh | Pengalaman memburuk di perangkat lemah | Budget ukuran bundel di CI; uji di perangkat kelas bawah sejak fase 2 |
| R7 | Sengketa "sudah bayar tapi status belum lunas" | Beban dukungan & kepercayaan | Halaman status pembayaran transparan; tombol "periksa ulang" yang memicu rekonsiliasi bukan menunggu; SLA manual |
| R8 | Repositori dokumen menjadi tumpukan berkas tanpa otoritas | Pengurus tetap memakai versi lama dari WhatsApp | Validasi nomor & versi wajib (§5.3); penunjukan pengelola dokumen per jenjang |
| R9 | Kartu e-KTA menampilkan status yang sudah kedaluwarsa | Kesan organisasi tidak tertib data | Status diturunkan dari `member_snapshot` (A6), bukan disimpan; token verifikasi berumur pendek |
| R10 | Waktu Tahap 2 molor karena cakupan dokumen melebar | Fitur bernilai tinggi (informasi) tertahan | Batasi jenis dokumen pada rilis pertama; OCR hasil pindai dijadwalkan terpisah |
| R11 | Anggota menyelesaikan herregistrasi di AnaOnline tetapi status belum berubah saat kembali | Anggapan aplikasi rusak / data hilang | Tarik-ulang data setelah kembali; pesan yang menyatakan pemrosesan ada di AnaOnline; tautan ke dasbor AnaOnline |
| R12 | Pengalihan keluar aplikasi (tab browser) membuat anggota tidak kembali | Kebingungan alur | Buka di *in-app browser* dengan tombol "kembali ke aplikasi"; jangan gunakan pengalihan tanpa jalan pulang |

---

## 11. Metrik Keberhasilan

Berhasil bukan ketika fiturnya selesai, tapi ketika angka berikut bergerak.

**Sasaran Tahap 1** (6 bulan pasca-rilis MVP):

| Metrik | Baseline | Target |
|---|---|---|
| Proporsi anggota yang memakai aplikasi minimal 1×/bulan | ~0 | ≥ 25% dari anggota aktif |
| Rasio pembayaran iuran via aplikasi | mayoritas manual | ≥ 40% nilai iuran bulanan |
| Kelengkapan field kritis anggota | (ukur saat fase 0) | +20 poin persentase |
| Waktu rekonsiliasi antarjenjang | hari/minggu | < 1 hari |
| Anggota yang sadar status keanggotaannya (membuka penampil status ≥ 1×/tahun) | tidak terukur | ≥ 50% anggota aktif aplikasi |
| Proporsi anggota dengan sisa masa keanggotaan ≤ 90 hari yang mengklik tautan herregistrasi | tidak terukur | ≥ 40% |

> [!caution] Metrik pengalihan bukan ukuran keberhasilan akhir
> Klik tautan hanya mengukur **kesampaian pesan**, bukan terselesaikannya herregistrasi — penyelesaian terjadi di AnaOnline dan tidak terlihat dari sisi aplikasi. Bila ingin mengukur hasil, perlu satu angka dari AnaOnline yang dicocokkan dengan penanda `?from=mobile` pada tautan.

**Sasaran Tahap 2** (6 bulan pasca-rilis Tahap 2):

| Metrik | Baseline | Target |
|---|---|---|
| Rasio surat edaran terbaca oleh pengurus sasaran | tidak terukur | ≥ 80% dalam 7 hari |
| Waktu pencarian dokumen resmi yang berlaku | menit–jam (tanya ke grup) | < 1 menit, berhasil ≥ 90% percobaan |
| Proporsi dokumen SK/QA-QD aktif yang tersedia di repositori | 0 | ≥ 90% dokumen periode berjalan |
| Rata-rata usia pembaruan data profil | tidak diketahui | ≤ 12 bulan |
| Anggota aktif yang memiliki e-KTA aktif | 0 | ≥ 60% anggota aktif aplikasi |

> [!tip] Kenapa metrik dokumen memakai "waktu pencarian"
> Jumlah unggahan bukan ukuran keberhasilan — bisa tinggi tanpa dipakai. Yang mengubah perilaku pengurus adalah ketika mencari SK lebih cepat lewat aplikasi daripada bertanya di grup WhatsApp.

---

## 12. Catatan Terbuka

- [ ] Konfirmasi mekanisme sinkronisasi data anggota dengan AnaOnline (blocker §9, A1).
- [ ] Angka porsi per jenjang dan mekanisme perubahannya.
- [ ] Penyedia gateway yang dipakai, dan apakah mendukung *split payment* resmi.
- [ ] Kewenangan penyetujuan penarikan per jenjang & batas nominal.
- [ ] Apakah pengurus menggunakan akun AnaOnline yang sama, atau perlu akun jabatan terpisah.
- [ ] Kebutuhan Bahasa daerah / aksesibilitas di PWA.
- [ ] Rencana migrasi data iuran historis (jika ingin riwayat sebelum rilis).
- [ ] Struktur wilayah resmi (PW/PD/PC) dan apakah satu pengurus bisa memegang lebih dari satu jabatan/wilayah.
- [ ] Daftar jenis dokumen yang masuk repositori pada rilis pertama, dan otoritas unggah per jenis.
- [ ] Format nomor dokumen resmi (SK, QA-QD) untuk validasi keunikan.
- [ ] Apakah repositori perlu menampung dokumen hasil pindai (butuh OCR) sejak rilis pertama.
- [ ] Syarat penerbitan e-KTA dan perlakuan bagi anggota tanpa akses aplikasi.
- [ ] Kebutuhan penerbitan KTA massal per cabang (ekspor cetak) pada fase 9.
- [ ] URL/tautan langsung ke formulir herregistrasi dan profil di AnaOnline (perlu dukungan *deep link* dari sisi AnaOnline).
- [ ] Apakah AnaOnline menyediakan `tanggal_batas_herregistrasi` secara langsung, atau harus dihitung di sisi mobile.
- [ ] Format penanda asal (`?from=mobile`) untuk mengukur hasil pengalihan, bila AnaOnline dapat mencatatnya.

---

## 13. Penutup

Rancangan ini menerjemahkan dua tujuan dari [[Digitalisasi Iuran Anggota dan Pemutakhiran Data berbasis Aplikasi Mobile]] menjadi rencana bertahap yang bisa dieksekusi. **Tahap 1** menempatkan iuran sebagai penggerak interaksi bulanan, menutup janji finansialnya sampai kas benar-benar sampai ke jenjang, dan menjadikan status keanggotaan terlihat tanpa menduplikasi alur herregistrasi. **Tahap 2** — kanal informasi, repositori dokumen, dan e-KTA — dibangun di atas basis pengguna yang sudah terbentuk, sehingga setiap fitur baru punya orang yang benar-benar membukanya, bukan sekadar terpasang. Pemutakhiran data tetap menjadi hasil samping seluruh interaksi tersebut, bukan menu yang menunggu dikunjungi.

Pembagian peran antara mobile dan AnaOnline sengaja tegas: **mobile adalah kanal interaksi dan penampil status; AnaOnline tetap menjadi pemilik formulir dan proses**. Herregistrasi, pemutakhiran profil, dan verifikasi administratif tidak dibangun ulang — aplikasi hanya memastikan anggota menyadari statusnya dan dapat sampai ke formulir yang tepat dalam satu ketukan. Ini menjaga satu sumber kebenaran untuk setiap proses kritis.

Pilihan PHP Webman untuk backend memberi keunggulan pada webhook, scheduler, dan efisiensi proses yang menjadi denyut aplikasi ini; Svelte PWA memberi biaya distribusi rendah dengan konsekuensi pada keandalan notifikasi yang harus dimitigasi sejak awal. Keduanya tetap memadai untuk kebutuhan Tahap 2 tanpa perubahan arsitektur mendasar.

Yang paling menentukan keberhasilan bukan pilihan framework, melainkan **kesiapan keputusan organisasi** pada §9: ketentuan porsi, otoritas penarikan, dasar hukum pemrosesan dana serta data, kebijakan dokumen resmi, dan syarat penerbitan e-KTA. Sistem hanya dapat menegakkan aturan yang sudah ditetapkan; tanpa itu, aplikasi secanggih apa pun akan berhenti di tahap uji coba.
