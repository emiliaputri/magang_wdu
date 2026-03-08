# Changelog

All notable changes to this Flutter project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

---
## [1.1.0] - 08 Maret 2026
### Ditambahkan
- menambahkan model data dummy dikarenakan endpoint nya blm ada, namanya survey_question
- menambahkan service dummy juga yang bernama kan dummy_service
- menambahkan page cek/edit yang terhubung kesemua project

## [1.1.0] - 06 Maret 2026
### Ditambahkan
- menambahkan page list survey sesuai dengan isi briefing sebelumnya

### Dihapus
- Menghapus beberapa tombol yang tidak digunakan lagi, yaitu Add Question, Create Client, dan Add Kuisioner.



## [1.1.0] - 04 Maret 2026
### Ditambahkan
- Menambahkan beberapa file baru di dalam folder widget untuk memisahkan komponen UI agar lebih terstruktur.

### Diubah
- Mengubah warna background halaman login menjadi putih agar tampilannya lebih sederhana dan bersih.

### Dihapus
- Menghapus beberapa file yang sudah tidak digunakan, seperti List Survey Page BPK dan List Survey Page Transjakarta, karena keduanya sudah digabungkan menjadi satu file agar lebih terstruktur.


## [1.1.0] - 02 Maret 2026
### Ditambahkan
- Menambahkan beberapa folder baru, yaitu folder core yang berisi subfolder api, constant, theme, dan utils, serta menambahkan folder provider untuk pengelolaan state.


### Diubah
- Melakukan penyesuaian pada folder model, sehingga model sekarang mengikuti struktur data dari Laravel. Data sudah tidak di-hardcode lagi dan sudah terhubung langsung dengan endpoint API Laravel.
- Membuat ulang struktur folder project agar sesuai dengan konsep Clean Architecture sehingga kode lebih rapi dan mudah dikelola.


### Dihapus
-

## [1.2.0] - 2026-03-02
### Added
- Implemented dynamic client fetching from Laravel API in the Dashboard.
- Added comprehensive debug logging for authentication and API connectivity.
- Integrated `ClientService` for robust data management.

### Changed
- Refactored `DashboardPage` to use a reactive loading state.
- Improved search and filtering logic to support dynamically loaded data.
- Optimized Dashboard UI by hiding the "Active Projects" section.

### Fixed
- Resolved missing `Storage` and `Api` imports in `dashboard_page.dart`.
- Fixed data scope issues in the client list section.

## [1.1.0] - 2026-02-27
### Added
- Added client-specific pages: `project_tj`, `list_survey_BPK`, and `list_survey_transjakarta`.
- Developed individual response details (`detail_responden_bpk` and `transjakarta`).
- Implemented `survey_success` result pages for both clients.
- Polished the survey creation and dashboard flows with role-based visibility.

## [1.1.0] - 2026-02-26
### Added
- Added `project_tj` page to view client projects.
- Added `detail_responden` page for respondent monitoring and analysis.
- Polished the `add_question` page design.

## [1.1.0] - 2026-02-25
### Added
- Added paragraph type, image type, and "add page" functionality in the `add_question` page.

### Changed
- Slightly updated the dashboard design by adding a client page.
- Updated the create survey page design.

## [1.1.0] - 2026-02-24
### Added
- `add_question` page for adding questions to the survey.
- `cek_edit_survey` page to view and modify survey data.
- `monitor_survey` page to monitor responses and survey filling activities.

---

## [1.1.0] - 2026-02-23
### Added
- Survey model mapping from API (`lib/models`).
- API services for surveys and authentication (`lib/service`).
- Reusable UI components (`lib/widgets`).
- Added image assets for branding (`assets/images`).
- `province_target` page to display available locations for survey target provinces.
- `create survey` page to input new questionnaires.

### Changed
- Refactored API service structure.
- Fixed navigation between pages.
- Adjusted dashboard layout for Web.

### Fixed
- API endpoint mapping issues.
- State not updating after receiving API responses.

---

## [1.0.0] - 2026-02-20
### Added
- Initial Flutter project setup.
- Login page.
- Dashboard page.
- Local storage helper (`lib/utils`).
- API integration using HTTP.
- Token storage using SharedPreferences.

### Fixed
- JSON parsing errors.
