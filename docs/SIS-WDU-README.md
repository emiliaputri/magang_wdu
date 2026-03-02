![ ](public/img/SIS-WDU-logo.png)

# SIS WDU — Survey's Integrated System

**SIS WDU** adalah sistem informasi survei berbasis web yang dibangun untuk mendukung kegiatan pengumpulan data, pengelolaan responden, dan pelaporan survei secara efisien. Dikembangkan oleh tim **Wahana Data Utama (WDU)**.

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|---|---|
| Backend | Laravel 11 (PHP 8.2+) |
| Frontend | Vue 3 + Inertia.js |
| Styling | Tailwind CSS |
| Build Tool | Vite |
| Database | MySQL |
| Real-time | Laravel Reverb (WebSocket) |
| AI | Groq API (llama-3.3-70b) |
| Export | DomPDF, Maatwebsite Excel |
| Email | SMTP + DKIM |
| Geolocation | IPInfo + Browser GPS |
| Automation | N8n Integration |

---

## Fitur Utama

### Manajemen Survei
- Buat, edit, duplikat, dan hapus survei
- Builder pertanyaan drag-and-drop dengan 10+ tipe pertanyaan:
  - Teks bebas, Pilihan ganda, Checkbox, Dropdown, Skala angka
  - Matrix, Gambar, Paragraf, dan Dokumen
- Pengaturan halaman survei (multi-page)
- Kondisional logic antar pertanyaan dan halaman (Flow & Page Logic)
- Toggle: IP Restriction, Progress Bar, N8n Integration, Survey Target Provinsi

### Manajemen Pengguna & Tim
- Role-based access: **Admin**, **PIC WDU**, **Client**, **Korlap**, **Enumerator**
- Kelola user, tim, klien, dan proyek
- Assign user ke proyek dan wilayah

### Kampanye Email
- Mail Builder drag-and-drop (teks, gambar, tombol, divider, 2-kolom)
- Kirim survei via email dengan token unik per penerima
- Tracking: open rate, click rate, response rate
- Manajemen daftar kontak & penerima
- Opt-out & resend individual
- Integrasi DKIM untuk deliverability

### Laporan & Analitik
- Rekap semua respons dengan filter dan pencarian
- Laporan individual per responden
- Grafik agregat per pertanyaan (Chart.js)
- AI Summary per pertanyaan & executive summary (Groq)
- Supervisi & moderasi respons (Pending / Revision / Approved / Declined)
- Export ke **Excel (.xlsx)** dan **PDF**

### Geotagging & Lokasi
- Penangkapan lokasi GPS dari browser
- Fallback ke geolokasi berbasis IP (IPInfo)
- Target survei per provinsi dengan progress tracking
- Peta visual lokasi responden

### Integrasi N8n & AI
- Auto-generate Google Spreadsheet dari data respons
- Jadwal otomatis AI Summary via scheduler
- Groq AI summarize teks terbuka, pilihan ganda, matrix, dan single choice

---

## Instalasi (Lokal / XAMPP)

### Prasyarat
- PHP 8.2+
- Composer
- Node.js 18+ & npm
- MySQL
- XAMPP (atau server lokal setara)

### Langkah-langkah

```bash
# 1. Clone repositori
git clone <repo-url> wdu-jetstream
cd wdu-jetstream

# 2. Install dependensi PHP
composer install

# 3. Install dependensi JavaScript
npm install

# 4. Salin dan konfigurasi environment
cp .env.example .env
php artisan key:generate

# 5. Konfigurasi database di .env
# DB_DATABASE, DB_USERNAME, DB_PASSWORD

# 6. Jalankan migrasi dan seeder
php artisan migrate --seed

# 7. Buat symbolic link storage
php artisan storage:link

# 8. Jalankan dev server (buka dua terminal)
php artisan serve
npm run dev
```

### Konfigurasi `.env` Penting

```env
APP_NAME='SIS WDU'
APP_URL=http://localhost:8000
APP_TIMEZONE=Asia/Jakarta

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nama_database
DB_USERNAME=root
DB_PASSWORD=

# Real-time (Reverb)
REVERB_HOST=localhost
REVERB_PORT=8080

# Email
MAIL_MAILER=smtp
MAIL_HOST=mail.example.com
MAIL_PORT=465
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=yourpassword

# Groq AI (opsional)
GROQ_API_KEY=your_groq_api_key

# IPInfo (opsional)
IPINFO_TOKEN=your_ipinfo_token
```

### Menjalankan Real-time Server

```bash
php artisan reverb:start
```

### Menjalankan Queue Worker

```bash
php artisan queue:work
```

---

## Peran Pengguna (Role)

| Role | Akses |
|---|---|
| **Admin** | Akses penuh ke semua fitur |
| **PIC WDU** | Kelola survei, klien, laporan, AI summary |
| **Client** | Lihat survei dan laporan proyek miliknya |
| **Korlap** | Monitor dan edit jawaban enumerator |
| **Enumerator** | Isi survei dan lihat jawaban sendiri |
| **Default User** | Akses terbatas |

---

## Struktur Direktori Utama

```
app/
├── Http/Controllers/   # Controller (Survey, Response, Campaign, dll.)
├── Models/             # Eloquent Models
├── Services/           # Business logic (AI Summary, dll.)
├── Exports/            # Maatwebsite Excel exports
resources/
├── js/
│   ├── Pages/          # Vue pages (Inertia)
│   └── Components/     # Vue components
├── views/              # Blade templates (email, PDF)
database/
├── migrations/         # 60+ migration files
└── seeders/
docs/
├── SIS-WDU-database_erd.md         # ERD & relasi tabel
└── SIS-WDU-system_flowcharts.md    # Flowchart sistem
```

---

## Dokumentasi

### Setup & Infrastruktur
- **Changelog**: [`changelog.md`](changelog.md)
- **Database ERD**: [`docs/SIS-WDU-database_erd.md`](docs/SIS-WDU-database_erd.md)
- **System Flowcharts**: [`docs/SIS-WDU-system_flowcharts.md`](docs/SIS-WDU-system_flowcharts.md)
- **Docker & CI/CD Setup**: [`docs/docker-cicd-setup.md`](docs/docker-cicd-setup.md)
- **N8n Setup**: [`docs/n8n-setup.md`](docs/n8n-setup.md)

### Panduan Fitur (User Guide)
- **Survey Builder**: [`docs/guide-survey-builder.md`](docs/guide-survey-builder.md)
- **Campaign Email**: [`docs/guide-campaign-email.md`](docs/guide-campaign-email.md)
- **AI Summarization**: [`docs/guide-ai-summarization.md`](docs/guide-ai-summarization.md)
- **Response Supervision**: [`docs/guide-response-supervision.md`](docs/guide-response-supervision.md)

### Integrasi
- **API Reference**: [`docs/api-reference.md`](docs/api-reference.md)
- **DKIM & Email Setup**: [`docs/integration-dkim-email.md`](docs/integration-dkim-email.md)

---

## Build Production

```bash
npm run build
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## Lisensi

Proyek ini bersifat **privat** dan hanya untuk penggunaan internal **Wahana Data Utama (WDU)**.
