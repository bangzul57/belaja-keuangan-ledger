# Product Decisions & Non-Goals

Dokumen ini menjelaskan **keputusan produk penting**  
agar arah proyek **tidak berubah seiring waktu**.

---

## 🎯 Fokus Produk

Aplikasi ini dibuat untuk:
- Owner Tunggal
- Usaha kecil
- Pencatatan uang harian
- Tanpa akuntansi formal

---

## 🔒 Keputusan yang Dikunci

### 1. Single Owner Only
- Tidak ada multi-user
- Tidak ada role
- Tidak ada approval

Alasan:
- Target user mengelola usaha sendiri

---

### 2. Akuntansi Formal Ditolak
- Tidak ada debit/kredit
- Tidak ada COA
- Tidak ada neraca

Alasan:
- UMKM tidak butuh istilah teknis

---

### 3. Edit Saldo Manual Diperbolehkan
- User boleh menyesuaikan saldo kapan saja

Alasan:
- Realita UMKM sering tidak rapi
- Sistem harus menyesuaikan user, bukan sebaliknya

---

### 4. Transaksi = Peristiwa Nyata
- Semua dicatat sebagai transaksi
- Detail bersifat opsional

Alasan:
- Fleksibel untuk berbagai jenis usaha

---

### 5. Tanggal Fleksibel
- Default: tanggal hari ini
- User boleh ubah tanggal

Alasan:
- Banyak UMKM input belakangan

---

## ❌ Fitur yang Ditolak Secara Permanen

- Akuntansi formal
- Payroll
- Pajak
- Billing otomatis kompleks
- Produksi/manufaktur
- Manajemen proyek
- Marketplace / platform

Jika ada permintaan fitur di atas:
➡️ **Tolak dengan merujuk dokumen ini**

---

## 🧠 Prinsip Pengambilan Keputusan

Saat ragu, gunakan aturan ini:

1. Apakah ini membantu owner tunggal hari ini?
2. Apakah ini menambah kebebasan user?
3. Apakah ini bisa dijelaskan tanpa istilah teknis?

Jika tidak → fitur ditolak.

---

## 🧾 Catatan Akhir

> Lebih baik aplikasi sederhana yang dipakai setiap hari  
> daripada aplikasi canggih yang ditinggalkan.

Dokumen ini **bersifat final** kecuali ada alasan sangat kuat.
