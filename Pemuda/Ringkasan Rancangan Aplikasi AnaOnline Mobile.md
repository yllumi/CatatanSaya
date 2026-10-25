# Ringkasan Rancangan Aplikasi AnaOnline Mobile

**Untuk:** Pimpinan & pengurus Pimpinan Pusat, Wilayah, Daerah, Cabang
**Basis dokumen:** [[Analisis Rancangan Aplikasi AnaOnline Mobile]] (versi lengkap untuk tim teknis)
**Latar belakang:** [[Digitalisasi Iuran Anggota dan Pemutakhiran Data berbasis Aplikasi Mobile]]
**Tanggal:** 25 Oktober 2026 · **Status:** Draf untuk pembahasan

> [!abstract] Inti dalam lima kalimat
> AnaOnline Mobile adalah **aplikasi pendamping**, bukan pengganti AnaOnline. Fitur utamanya **pembayaran iuran Rp 20.000/bulan** yang langsung terbagi otomatis ke empat jenjang (Cabang 50%, Daerah 20%, Wilayah 15%, Pusat 15%). Setiap anggota dan pengurus memperoleh akses sesuai peran dan wilayahnya. Setelah pembayaran berjalan, aplikasi menambahkan **kanal informasi resmi** dan **e-KTA**. Data keanggotaan ikut termutakhirkan karena anggota rutin membuka aplikasi.

---

## 1. Masalah yang Diselesaikan

| Masalah hari ini | Akibatnya | Yang dilakukan aplikasi |
|---|---|---|
| Anggota jarang membuka AnaOnline | Data keanggotaan tidak mutakhir | Anggota diberi alasan rutin membuka aplikasi (iuran bulanan) |
| Iuran dicatat manual berjenjang | Risiko salah catat, laporan antarjenjang sulit dicocokkan | Satu pencatatan terpusat; semua jenjang membaca data yang sama |
| Dana harus disetor berjenjang ke atas | Kas di Cabang/Daerah lambat | Porsi otomatis masuk ke kas masing-masing jenjang sejak pembayaran |
| Pengurus tidak tahu siapa yang menunggak | Penagihan tidak terarah | Rekap tunggakan per cabang/daerah/wilayah |
| Surat edaran tersebar di grup WhatsApp | Tidak ada bukti tersampaikan | Kanal informasi resmi dengan status baca *(tahap 2)* |

---

## 2. Apa yang Akan Dibangun

### Tahap 1 — iuran digital *(prioritas utama)*

**Untuk anggota**
- Melihat tagihan **belum lunas** (termasuk tunggakan) dan riwayat pembayaran.
- Membayar melalui **Virtual Account, QRIS, atau e-wallet**.
- **Membayar banyak bulan sekaligus** — minimal 1 bulan, bisa 3, 6, atau 12 bulan; boleh mencampur tunggakan lama dan bulan mendatang.
- Menerima kuitansi digital per bulan.

**Untuk pengurus (sesuai jenjang)**
- Rekap pembayaran anggota sampai batas wilayahnya, dengan rincian per cabang (drill-down).
- Melihat saldo porsi jenjang dan riwayat dana masuk.
- **Menarik dana** porsi jenjang ke rekening resmi kepengurusan, dengan persetujuan dua orang.
- Mengekspor laporan untuk rapat dan audit.

### Tahap 2 — setelah iuran berjalan stabil

- **Kanal Informasi Pimpinan Jam'iyyah** — pengumuman dan surat edaran hanya sampai ke jenjang yang berhak, dengan status terbaca.
- **e-KTA digital** — kartu anggota dengan QR verifikasi; status pada kartu otomatis mengikuti status keanggotaan.

### Yang sengaja tidak dikerjakan di aplikasi

Formulir **herregistrasi** dan **pemutakhiran profil** tetap di AnaOnline, karena formnya sudah lengkap di sana. Aplikasi hanya menampilkan status keanggotaan dan **mengarahkan** anggota ke formulir tersebut. Dengan begitu tidak ada dua tempat pengisian untuk satu urusan, dan data tidak bisa berbeda antar sistem.

---

## 3. Skema Iuran

| Uraian | Nilai |
|---|---|
| Iuran per anggota per bulan | **Rp 20.000** *(ditetapkan PP)* |
| Pimpinan Cabang | 50% → **Rp 10.000** |
| Pimpinan Daerah | 20% → **Rp 4.000** |
| Pimpinan Wilayah | 15% → **Rp 3.000** |
| Pimpinan Pusat | 15% → **Rp 3.000** |

- Pembagian dilakukan **otomatis saat pembayaran terkonfirmasi** — tidak ada lagi penyetoran manual berjenjang.
- Status tagihan hanya **dua**: `belum bayar` dan `lunas`. Tunggakan **tidak pernah hangus** dan dapat dibayar kapan saja.
- Nominal dan persentase dapat diubah PP di kemudian hari **tanpa mengubah catatan transaksi lama**.

---

## 4. Siapa Bisa Melihat Apa

| Peran | Bisa melihat | Bisa menarik dana |
|---|---|---|
| Anggota | Data & tagihan sendiri | — |
| Admin Cabang | Anggota di cabangnya | Porsi cabang |
| Admin Daerah | Seluruh cabang di daerahnya | Porsi daerah |
| Admin Wilayah | Seluruh daerah di wilayahnya | Porsi wilayah |
| Admin Pusat | Seluruh nasional | Porsi pusat |
| Superadmin | Seluruh data + pengaturan sistem | — |

Peran **diambil dari akun AnaOnline saat login** — tidak dibuat baru, dan tidak dikelola terpisah di aplikasi. Pengurus otomatis mendapat akses admin sesuai jabatannya.

---

## 5. Alur Kerja

**Anggota membayar**
```
Buka aplikasi → lihat tagihan (tunggakan di atas) → pilih bulan (1 atau lebih)
→ bayar via VA/QRIS/e-wallet → lunas → porsi otomatis masuk ke 4 jenjang
```

**Pengurus menarik dana**
```
Lihat saldo jenjang → ajukan penarikan ke rekening resmi → disetujui pejabat kedua
→ dana ditransfer → tercatat di riwayat
```

**Anggota mendekati batas keanggotaan (5 tahun)**
```
Status di beranda menunjukkan "akan berakhir" → anggota menekan tombol
→ diarahkan ke formulir herregistrasi di AnaOnline → status diperbarui setelahnya
```

---

## 6. Teknologi Singkat

| Bagian | Pilihan | Alasan utama |
|---|---|---|
| Tampilan aplikasi | **Svelte PWA** | Ukuran ringan, cocok untuk perangkat kelas menengah; bisa dipasang seperti aplikasi tanpa lewat Play Store/App Store |
| Server & data | **PHP Webman** + PostgreSQL | Cepat menangani notifikasi pembayaran dan penjadwalan tagihan; selaras dengan tim yang sudah memelihara AnaOnline |

> [!warning] Satu keterbatasan yang perlu diketahui
> Notifikasi otomatis di iPhone (PWA) belum seandal di Android. Pengingat pembayaran karena itu juga dikirim melalui **WhatsApp/email** sebagai jalur cadangan.

---

## 7. Urutan Pengerjaan

| Fase | Fokus | Penanda selesai |
|---|---|---|
| 0 | Konfirmasi data login & ketentuan penarikan | Keputusan tertulis |
| 1 | Fondasi: login, peran, wilayah, status keanggotaan | Admin Cabang teruji tidak bisa melihat data Daerah |
| 2 | Pembayaran iuran (1, 3, 6 bulan) | Uji bayar berhasil, total porsi = nominal |
| 3 | Rekap & dasbor jenjang | Total cabang = total daerah = total wilayah |
| 4 | Penarikan dana | Satu penarikan berhasil dengan jejak audit |
| 5 | **Uji coba terbatas** (1 PD / beberapa PC) | Angka adopsi awal terukur |
| 6–8 | Kanal informasi → e-KTA → uji coba tahap 2 | — |

Jadwal belum ditetapkan; urutan ini disusun berdasarkan risiko. Penarikan dana diletakkan paling akhir karena risikonya paling besar, dan selama uji coba masih dapat dilakukan manual oleh Pusat.

---

## 8. Keputusan yang Diperlukan dari Pimpinan

Empat hal berikut **menentukan kelayakan proyek** dan tidak bisa dijawab tim teknis:

1. **Rekening penampung dana.** Harus atas nama entitas yang sah, bukan rekening pribadi.
2. **Skema perizinan pembayaran.** Perlu dipastikan model *auto-split* dan penarikan dana sesuai ketentuan penyedia gateway (mis. *split payment* resmi).
3. **Kewenangan penarikan.** Siapa yang mengajukan dan siapa yang menyetujui di tiap jenjang — saat ini peran admin menentukan akses, tetapi tidak otomatis berarti berwenang menyetujui.
4. **Dasar pemrosesan data pribadi.** Kebijakan internal tentang tujuan pengumpulan, penyimpanan, dan hak anggota atas datanya.

> [!note] Yang tidak perlu ditunggu
> Nominal (Rp 20.000) dan porsi (50/20/15/15) sudah pasti, sehingga pengembangan pembayaran dan rekap bisa berjalan tanpa menunggu keputusan lain.

---

## 9. Risiko Utama

| Risiko | Dampak | Penanganan |
|---|---|---|
| Respons API login AnaOnline belum memuat peran & wilayah | Pengerjaan tertahan di fase 1 | Dikonfirmasi sejak fase 0 |
| Pengurus jenjang bawah kurang memakai aplikasi | Fitur rekap tidak terpakai | Uji coba terbatas + pendampingan admin cabang |
| Sengketa "sudah bayar tapi belum lunas" | Beban layanan & turunnya kepercayaan | Halaman status transparan dan pemeriksaan ulang otomatis |
| Anggota keliru memilih jumlah bulan | Kebingungan & potensi pengembalian dana | Ringkasan konfirmasi sebelum bayar |

---

## 10. Ukuran Keberhasilan

Dinilai bukan dari fitur selesainya, tetapi dari perubahan angka berikut (**6 bulan setelah rilis**):

| Ukuran                                          | Target                          |
| ----------------------------------------------- | ------------------------------- |
| Anggota aktif memakai aplikasi minimal 1×/bulan | ≥ 25%                           |
| Nilai iuran dibayar melalui aplikasi            | ≥ 40%                           |
| Waktu rekonsiliasi antarjenjang                 | dari hari/minggu → **< 1 hari** |
| Tunggakan rata-rata per anggota                 | turun ≥ 30%                     |
| Admin jenjang memakai halaman rekap tiap bulan  | ≥ 70% akun admin                |

---

## 11. Yang Perlu Diketahui Sebelum Menyetujui

- Aplikasi ini **tidak menggantikan** AnaOnline. Data anggota tetap milik AnaOnline; aplikasi mobile membaca dan menampilkannya.
- Aplikasi **bukan dompet digital** dan **bukan pembukuan resmi** — ia sumber transaksi yang bisa diekspor ke pembukuan.
- Identitas dan formulir tetap di AnaOnline. Aplikasi hanya memastikan anggota **sadar status** dan **sampai ke formulir yang tepat**.
- Rancangan ini belum final; rincian teknis, arsitektur data, dan analisis risiko lengkap ada di [[Analisis Rancangan Aplikasi AnaOnline Mobile]].

---

*Pertanyaan dan masukan atas dokumen ini dapat disampaikan ke tim pengembang sebelum fase 1 dimulai.*
