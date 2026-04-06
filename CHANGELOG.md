# Changelog

All notable changes to this Flutter project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

---
## [1.2.8] - 2026-04-06
### Features
- Add Biodata page for respondent data input before survey
- Dynamic button labels (Isi Kuisioner / Cek Edit) based on answer status
- Local storage draft for answers (saves before database submission)
### Bug Fixes
- Fix submit payload format (wrap in "data" field)
- Fix edit answer payload (separate question & answer arrays)
- Fix province dropdown (use fallback data when API returns empty)
- Improve answer display design in Monitor (Google Forms style)
### Changes
- Auto-refresh status after survey submission
- Add auto-save draft when navigating between pages


## [1.2.7] - 2026-04-02
### Added
- Combined survey detail endpoint with response report to display complete question data in Lihat Monitor page
- Added new method getFullSurveyDetail() to merge /report/{responseId} and /all-report endpoints
- Added elaborate answer display in Lihat Monitor page (similar to Google Form):
  - Matrix questions: displayed as table with SS/S/TS/STS columns and radio button circles
  - Checkbox questions: displayed with checkbox UI showing all options (checked for selected)
  - Radio questions: displayed with radio button UI showing all options (highlighted for selected)
  - Text/Paragraph: displayed as plain text answer
  
### Fixed
- Fixed API endpoint from /detail to /all-report for fetching survey questions
- Fixed answer filtering by responseId to show only selected respondent's answers

## [1.2.6] - 2026-04-01
### Improvements:
- Change password visibility icon from lock to eye icons (visibility_off/visibility_rounded)
- Update monitoring status field to use supervision_status with values: pending, revision_needed, approve, decline
- Display province_name from biodata in monitoring list
- Fix timeline format in Lihat Monitor page:
- Show date + time format (example: "01 Apr 2026\n21:15")
- Auto-calculate duration from start and end time difference
- Reduce size for mobile responsive display

## fixes
- Fix: update production api url and fix logout handling android


## [1.2.5] - 2026-03-31
### Added
- Monitoring Page - View: Display respondent location information including IP Address, region (city/province), latitude, and longitude
- Monitoring Page - View: Added embedded map display using OpenStreetMap
- Monitoring Page - View: Added button to open location in Google Maps

### Bug Fixes:
- Logout: Fixed logout process to properly redirect to login page
- Logout: Added last route clearing to prevent redirect to previous page

### Technical Changes:
- Added flutter_map and latlong2 packages for map display
- Added url_launcher package to open Google Maps
- Optimized client image display with cached_network_image
- Added fallback images for TransJakarta and BPD clients

## [1.2.4] - 2026-03-30
### Added
- Survey fill/edit functionality: users can now fill new surveys or edit existing responses
- Auto-redirect to survey fill page when user has not filled the questionnaire yet
- Submit answer endpoint for new survey submissions
- Status badge column in monitoring table to display response moderation status (PENDING, APPROVE, REVISION, DECLINE)
- `submitAnswer` endpoint in endpoints.dart

### Changed
- Updated survey response detail model parsing to handle various API response formats
- Improved model parsing to support data wrapped in arrays or different key structures
- Button label changed from "Cek / Edit" to "Cek / Isi Kuisioner"
- AppBar title dynamically changes between "Isi Kuisioner" (for new) and "Cek / Edit Survey" (for existing)

### Fixed
- Fixed issue where users were stuck on "Data tidak ditemukan" page instead of being redirected to fill the survey

---

## [1.2.3] - 2026-03-27
### Added
- Logout button in the dashboard page

## [1.2.2] - 2026-03-26
### Changed
- survey card size to prevent bottom overflow
- Resized the table in monitoring data; it is now horizontally scrollable to the left to view all data

## [1.2.2] - 2026-03-13
### Added
- project_list folder inside the widget directory, containing header_cell, project_client_card, project_row, and project_section files for better project file structure
- Logging to ApiClient to indicate the presence of the Authorization header

### remove
- Unused folders and files: app_constant, question_model, logic_evaluator, and submission_service


## [1.2.2] - 2026-03-11, 12
### Added
- cek_edit page with endpoint integration

### Changed
- Client card layout from horizontal scroll to vertical scroll
- Detail response design with "View" button now connected to endpoint

### remove
- Unused folders and files: dummy_service

## [1.2.1] - 2026-03-11
### Fixed
- Fixed client image display issues.

### Changed
- Updated the UI for the check and edit pages.

## [1.2.0] - 2026-03-08
### Added
- Added `survey_question` dummy data model while waiting for the endpoint.
- Added `dummy_service` as a temporary mock service.
- Added a cross-project check/edit page.

## [1.1.9] - 2026-03-06
### Added
- Added survey list page as per previous briefing.

### Removed
- Removed unused buttons: Add Question, Create Client, and Add Questionnaire.

## [1.1.8] - 2026-03-04
### Added
- Added new files in the widget folder to better structure UI components.

### Changed
- Updated the login page background color to white for a cleaner look.

### Removed
- Removed deprecated files (List Survey Page BPK and Transjakarta) after merging them into a single structured file.

## [1.1.7] - 2026-03-02
### Added
- Added `core` folder containing `api`, `constant`, `theme`, and `utils` subfolders.
- Added `provider` folder for state management.

### Changed
- Updated the `model` folder to match Laravel data structure (removed hardcoded data, connected to API).
- Refactored the project folder structure to follow Clean Architecture principles.

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
- Created `add_question` page for adding questions to the survey.
- Created `cek_edit_survey` page to view and modify survey data.
- Created `monitor_survey` page to monitor responses and survey filling activities.

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
