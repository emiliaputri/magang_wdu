# SIS WDU Mobile - Field Data Collection

![ ](docs/img/SIS-WDU-logo.png)

**SIS WDU Mobile** adalah aplikasi pengumpulan data lapangan (mobile data collection) yang dirancang khusus untuk enumerator. Aplikasi ini merupakan ekstensi dari sistem utama **SIS WDU (Laravel)**, yang memungkinkan pengisian survei secara cepat, responsif, dan mendukung logika kondisional yang kompleks secara offline.

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|---|---|
| **Core Framework** | Flutter (Dart) |
| **State Management** | Provider |
| **Networking** | HTTP Client (REST API) |
| **Local Storage** | SharedPreferences & Flutter Secure Storage |
| **Typography** | Google Fonts (Inter/Outfit) |
| **Design System** | Custom Material Design (Premium Aesthetics) |

---

## 🏗️ Arsitektur Aplikasi

Aplikasi ini menggunakan pendekatan **Clean Architecture** yang disederhanakan untuk Flutter, memisahkan antara UI, Logika Bisnis, dan Infrastruktur:

- **UI Layer**: Widget Flutter yang responsif dan komponen yang dapat digunakan ulang (`lib/widgets`).
- **Domain Layer**: Logika evaluasi survei (skip logic) dan pemetaan model data.
- **Data Layer**: Integrasi REST API dengan backend Laravel dan penyimpanan lokal untuk draft serta token.

### Fitur Utama Mobile:
- **Dynamic Survey Rendering**: Merender pertanyaan secara dinamis berdasarkan konfigurasi dari server (Open Ended, Multiple Choice, Matrix, dll).
- **On-Device Logic Evaluation**: Memproses *skip logic* dan *page flow* secara instan di perangkat.
- **Secure Authentication**: Penyimpanan token akses menggunakan enkripsi tingkat sistem.
- **Offline Experience**: Mendukung penyimpanan draft jawaban sementara (Auto-save).

---

## 🚀 Instalasi & Pengembangan

### Prasyarat:
- Flutter SDK (Versi terbaru)
- Dart SDK
- Android Studio / VS Code dengan plugin Flutter
- Koneksi ke API SIS WDU (Laravel)

### Langkah-langkah:
1. **Clone Repositori**:
   ```bash
   git clone <repo-url>
   cd wdu-flutter
   ```
2. **Install Dependensi**:
   ```bash
   flutter pub get
   ```
3. **Konfigurasi Environment**:
   Pastikan file `lib/service/api.dart` mengarah ke URL backend yang benar.
4. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

---

## 📂 Struktur Direktori

```text
/lib
  /core           # Tema global, konstanta, dan utilitas inti
  /models         # Pemetaan model data dari respons API
  /providers      # State management (Auth, Survey session)
  /services       # Logic API, AuthService, dan SurveyLogicEvaluator
  /screens        # Halaman UI utama (Login, Dashboard, Submission)
  /widgets        # Komponen UI dinamis (Input fields, Custom buttons)
/assets           # Gambar, ikon, dan aset statis
```

---

## 🔗 Integrasi dengan SIS WDU Utama

Aplikasi ini mengonsumsi API dari sistem utama SIS WDU. Untuk dokumentasi sistem utama, silakan lihat:
- **Main README**: [SIS-WDU-README.md](docs/SIS-WDU-README.md)
- **System Flowcharts**: [SIS-WDU-system_flowcharts.md](docs/SIS-WDU-system_flowcharts.md)

---

## 🛡️ Lisensi

Proyek ini bersifat **privat** dan hanya untuk penggunaan internal **Wahana Data Utama (WDU)**.
