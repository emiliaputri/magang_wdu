# Changelog

All notable changes to this Flutter project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

---
## [1.4.4] - 2026-04-24 *By Fadel
### Changed
- **Direct Survey Flow**: Completely removed the biodata form requirement. Respondents now go directly to the questionnaire.
- **Conditional Camera Flow**: Implemented logic to skip or show the camera capture page based on the `is_camera_enabled` setting from the Laravel dashboard.

### Improved
- **Monitoring UI**: Redesigned "Capaian Status" breakdown to be centered and full-width for better visibility.
- **List Survey UI**: Removed text truncation from survey titles and descriptions to show complete information.
- **Metadata Handling**: Updated camera capture to only collect necessary metadata (GPS/Time) without personal biodata dependencies.
- **Service Resilience**: Enhanced model parsing to handle both `setting` and `survey_settings` keys from the API.

### Removed
- **Biodata UI & Logic**: Deleted `BiodataPage` and stripped all biodata-related draft saving and submission logic.

---

## [1.4.3] - 2026-04-24 *By Fadel
### Added
- **Real-time Notifications (WebSockets)**: Integrated `laravel_echo` and `pusher_client` to support instant "bell" notifications via Laravel Reverb.
- **WebSocket Service**: New dedicated service for managing persistent socket connections with auto-host detection and authentication handling.
- **In-App Alerts**: Added "Kring-Kring" audio alerts and reactive unread badges that update instantly when a survey is audited (status change/flagging).
- **Fallback Listeners**: Implemented raw event listeners for `BroadcastNotificationCreated` to ensure maximum reliability across platform versions.

### Fixed
- **Exporting & Overlap UI**: Resolved UI overlap issues in the monitoring summary and fixed data exporting inconsistencies in the submission flow.
- **Dependency Conflicts**: Resolved version mismatches between `pusher_channels_flutter`, `flutter_secure_storage`, and the `js` package.
- **Model Robustness**: Updated `AppNotification` to gracefully handle varying Laravel database notification payloads.

---

## [1.4.2] - 2026-04-23 *By Fadel
### Added
- **Activity Logging**: Implemented background logging to Laravel for login, logout, 2FA changes, and active session detection with [SIS-APP] prefix and user email.

### Fixed
- **Survey Status Validation**: Fixed an issue where "DIBUKA" (open) surveys were incorrectly displayed as "DITUTUP" (closed) due to rigid status parsing. Added support for boolean and multiple string formats from the API.
- **UI Improvements**: Fixed `SurveyBentoCard` to prevent title/description truncation and removed excessive white space in survey grids.
- **Monitoring UI Refactor**: Redesigned monitoring header with status breakdown (Pending, Revision, etc.), implemented a compact list view for responses, and synchronized response timing with Laravel's `updated_at`.
- **Monitor Detail Improvements**: Redesigned detail page with a minimalist respondent info section, consistent frosted glass header, and intelligent question filtering.
- **Advanced Answer Fetching**: Implemented strict response ID validation and recursive data merging to prevent stale data between different responses.
- **Image Support in Monitoring**: Added visual preview for "Document" type questions with automatic image detection, correct path mapping to `/documents/`, and aspect-ratio preservation.
- **Client Image Fixes**: Resolved image loading issues by implementing `UniversalImage` for CORS bypass, automatic URL encoding for special characters, and improved logo scaling/padding (zoom-out effect) across project and survey pages.

---
## [1.4.1] - 2026-04-23 *By Fadel
### Added
- **Integrated 2FA Settings**: Implemented a comprehensive 2FA management page (`TwoFactorSettingsPage`) that handles password confirmation and OTP verification in a single, seamless flow.
- **Profile Photo Upload**: Integrated `image_picker` and implemented profile photo upload functionality with backend synchronization.
- **2FA System (Email OTP)**: Integrated email OTP verification during login.
- **OTP Resend Timer**: Added a 60-second countdown for resending codes.
- **OTP Input Limit**: Restricted OTP input to exactly 6 digits.
- **UniversalImage Widget**: Implemented a cross-platform image component that uses native HTML `<img>` tags on Web to bypass CORS restrictions for profile photos.
- **X-App-Platform Header**: Added OS identification (Android/iOS) for Laravel server.
- **Foundation Package**: Utilized the foundation package for safe platform detection.

### Improved
- **Settings UI Simplification**: Streamlined the settings page by removing icons and descriptive subtitles for a cleaner, text-focused look.
- **Profile Settings UI**: Fully revamped the settings page to mirror Laravel Jetstream's profile structure. Includes read-only identity fields with a notice to contact administrators.
- **Web Compatibility**: Enhanced `ApiClient` to support multipart file uploads on Web using binary data (bytes) instead of file paths.
- **UI Restructuring**: Removed the bottom navigation bar and moved the settings button to the Dashboard AppBar actions for a more streamlined experience.
- **Profile Photo Logic**: Integrated sanitization and the new `UniversalImage` widget to ensure profile photos load correctly across all environments.
- **Error Messages**: Enhanced clarity for incorrect password and expired OTP messages by removing technical jargon.
- **Navigation Logic**: Fixed automatic redirection to Dashboard or OTP Page post-login.
- **Login Footer**: Updated copyright year to 2026 and refined the UI.

### Fixed
- **Platform Error**: Resolved `Unsupported operation: Platform` crash on Flutter Web.
- **Merge Conflicts**: Cleaned up remaining conflicts and missing imports on the submission page.

---
## [1.4.0] - 2026-04-22
### Added
- **Biodata Toggle Setting**: Added support for `is_biodata_enabled` in survey_settings table to control whether respondent biodata form is required before starting the survey.
- **Voice Auto-Fill Survey**: Added smart voice note feature that records user speech, converts it to text, and automatically fills survey answers based on spoken responses.
- **Central Voice Recorder**: Implemented a single voice recorder section at the top of the questionnaire page for hands-free survey input.
- **Merge Conflict Resolution**: Successfully merged remote changes with local standardizations, specifically integrating `CachedNetworkImage` and improved logo fallback logic.
- **Smart Logo Fallbacks**: Implemented specialized, theme-consistent fallbacks for "TransJakarta" and "BPK" clients.
- **Improved Image Loading**: Switched to `CachedNetworkImage` for smoother profile and client logo rendering.  

### Improved
- **Dynamic Survey Flow**: The app now automatically checks biodata settings when loading survey data.
- **Voice Input Experience**: Improved accessibility and usability by allowing users to answer surveys without typing manually.

### Changed
- **Skip Biodata Process**: If biodata is disabled, users are redirected directly to the questionnaire/camera capture page without filling the biodata form.
- **Auto Default Biodata Values**: When biodata is skipped, the system automatically saves placeholder biodata values (- / anonymous) for submission consistency.
- **Survey Interaction Flow**: Users can now complete surveys using either manual input or voice-assisted auto-fill.
- **Emerald Green UI Standardization**: Replaced all hardcoded and legacy colors with the unified `AppTheme` design system across the Dashboard, Project Details, Survey List, and Monitoring modules.
- **Map Visual Refinement**: Updated map coordinate markers in `LihatMonitorPage` to **Red** for superior contrast and readability.
- **Global Navigation**: Modernized the dashboard's bottom navigation active state with `AppTheme.ijoGelap` for better visual hierarchy.
- **Modernized Survey Page**: Updated `SurveyBentoCard` and `ProjectCard` with premium Emerald accents, consistent status badges, and refined button styling.

### Fixed
- Properly merged `main` into `fix/submission-page` and resolved structural conflicts.
- Re-aligned `AppTheme` with the main branch color scheme.
- Updated `LihatMonitorPage` map markers to use actual GPS coordinates (Latitude/Longitude).
- Changed map marker color to **Red** for better contrast.
- Fixed Dropdown button responsiveness in `SubmissionPage`.
- Implemented horizontal scrolling for survey questions to improve UX.
- Enhanced page navigation logic and draft persistence.
- Submission Compatibility: Ensured surveys without biodata still proceed normally and remain compatible with existing submission flow.
- Voice Mapping Stability: Improved spoken answer detection and assignment to the correct survey questions.     

---

## [1.3.9] - 2026-04-21
### Fixed
- **Client Logos**: Resolved 404 errors for client logos by correcting the root path to `/img/client/` in `client_model.dart`.
- **Matrix Question**: Fixed data persistence issue where matrix answers were failing to save due to double JSON encoding. Answers are now sent as a raw JSON Map, allowing the backend to encode them correctly for database storage.

### Added
- **Initials Fallback**: Implemented a premium-look initials-based fallback (with gradients) for clients without logos in `ProjectClientCard` and `ProjectBpkPage`.
- **Dropdown Enhancements**: Added clear dropdown icons (`Icons.keyboard_arrow_down_rounded`) and professional styling to all dropdown fields in `SubmissionPage` for better visibility and UX.
- **Province Fallback**: Integrated a comprehensive list of all 38 Indonesian provinces as a fallback in `SubmissionPage` to prevent empty dropdowns when API data is missing.

---

## [1.3.8] - 2026-04-20
### Added
- **UniversalImage**: Implemented a cross-platform image loading solution that uses native HTML `<img>` tags on Web to bypass CORS decoding issues (`EncodingError`) while maintaining `CachedNetworkImage` for Mobile/Desktop. 
- Added proper type checking to prevent TypeError when parsing JSON answers
- Voice message / voice note recording support.
- Audio playback support for recorded voice notes.
- Microphone permission handling for voice recording feature.

### Fixed
- **Submission Logic**: Fixed matrix question persistence in `SubmissionPage`. Answers are now correctly formatted as JSON Strings for backend compatibility.
- **Compilation**: Resolved `The method 'File' isn't defined` error in `SubmissionPage.dart` by adding missing `dart:io` import.
- **Dependencies**: Fixed `pubspec.yaml` syntax error caused by duplicate `audioplayers` entries.
- **Image Display**: Resolved `EncodingError` on Flutter Web (Chrome) which prevented client logos from appearing when using the CanvasKit renderer.
- Fixed matrix question display in monitor view
- Matrix table structure is now ALWAYS displayed, even when no answer exists (previously showed "-")
- Refactored _buildMatrixAnswer with separate helper method _buildMatrixTable

### Changed
- **Submission UI**: Reverted `SubmissionPage` matrix interface to the previous table-based design per user preference while keeping the data persistence fixes.
- **Endpoints**: Modernized `baseUrl` and `storageUrl` logic in `endpoints.dart` to better support switching between local development (`php artisan serve`) and production.

### Improved
- **Robust Model Parsing**: Enhanced `_buildImageUrl` in `Client` and `UserProject` models to handle various path formats more gracefully.
- Enhanced mobile reporting workflow with voice note evidence support.


## [1.3.6] - 2026-04-17
### Fixed
- **Merge Conflict Resolution**: Successfully resolved significant merge conflicts in `CekEditMonitorPage` during the integration of monitoring feature updates into the main branch.
- **Document Type Support**: Restored handling and UI support for the `document` (file upload) question type in the monitoring edit view.
- **Parsing Stability**: Fixed "type 'int' is not a subtype of type 'String'" crash across `SubmissionService` and `ProvinceTarget` models by ensuring dynamic values from the API are cast to String before property assignment.
- Fix: Synchronize matrix question display between CekEditMonitor and LihatMonitor pages
- Fix: Resolve 500 error when saving checkbox answers with duplicate values
- Fix: Load latest answers from API instead of first (fixes data not updating after refresh)
- Feat: Add document upload support in CekEditMonitor page

### Added
- **Anonymous Entry Mode**: Added a toggle in `BiodataPage` to switch between "Lengkap" and "Anonim" modes. Anonymous mode requires only a Province selection to proceed.
- **Data Loss Prevention**: Integrated `WillPopScope` with a professional confirmation dialog in both `BiodataPage` and `SubmissionPage`. Users are now prompted to save a draft or confirm exit when navigating back.

### Changed
- **Monitor UI Synchronization**: Redesigned the Matrix question interface in `CekEditMonitorPage` to be visually consistent with `LihatMonitorPage`, ensuring a unified look and feel across the monitoring suite.
- **Matrix UI Enhancements**: Implemented a refined table-style layout for Matrix questions, featuring alternating row colors, improved fallback labels (e.g., "Row X", "Option X"), and specific color accents for standard Likert scales (SS, S, TS, STS).
- **Biodata UI Refactoring**: Redesigned the biodata form layout to accommodate the new mode selector and conditional input visibility.

### Improved
- **Lifecycle Connectivity**: Maintained `WidgetsBindingObserver` integration to ensure the monitor page re-fetches the latest state from the API whenever the application resumes from the background.


## [1.3.4] - 2026-04-16
### Fixed
- **Monitoring Data Restoration**: Fixed a critical bug where `CekEditMonitorPage` showed empty content by correctly merging survey structures from `/all-report` with answers from `/report`.
- **Backend Logo Pathing**: Resolved a 404 issue for client logos by correcting the base URL and implementing an aggressive `/img/client/` path enforcer in `Client` and `UserProject` models.
- **Image Priority**: Updated model parsers to prioritize the full `image_url` field from the API, ensuring more reliable image loading across the dashboard.
- **Client Branding Typo**: Corrected Indonesian spelling of "Kementrian" to **"Kementerian"** across all dynamic descriptions.
- **Syntax Fix**: Resolved a compilation error in `ClientCard` caused by accidental duplicated closing braces during manual edits.

### Added
- **Dynamic Client Descriptions**: Implemented specialized, professional headers for **Kementerian Komunikasi dan Digital**, **IMDI**, and **Test** clients in the survey listing page.
- **Logo Debug Tooltip**: Added a hover tooltip to `ClientCard` to display the source URL, assisting in real-time verification of backend image paths.

### Changed
- **Navigation UX**: Standardized button labels from "Cek / Edit" to **"Isi Kuesioner"** for better clarity in the survey dashboard.
- **Client Card Sizing**: Optimized logo frames by increasing the AspectRatio to 1.85 and reducing internal padding for a more spacious, premium feel.
- **Token Handling**: Fixed an issue where the auth token could become null after a session timeout.

## [1.3.3] - 2026-04-14
### Added
- Added dynamic sorting feature for survey responses in the Monitoring Interface (dropdown to toggle between "Terbaru / Terlama" ordering)
- Implemented a new search bar functionality in the Clients section of `DashboardPage` for quick lookups        

### Changed
- Modernized `CekEditSurveyPage` AppBar styling with a sleek two-tone green gradient design
- Replaced legacy `monGreenMid` color with `AppTheme.primary` across `CekEditSurveyPage` UI elements (checkboxes, radio buttons, inputs, loading indicators) for better design system consistency

---

## [1.3.2] - 2026-04-13
### Added
- Automated client logo synchronization in `DashboardProvider`: projects now automatically inherit logos from the client list if missing in the API response
- Logout confirmation dialog (pop-up) to `DashboardPage` and `SettingsPage` to prevent accidental logout        
- Metadata persistence (Client Slug, Project Slug, Survey Title) to local drafts for full recovery
- Enhanced `ArchivePage` with original survey titles, "Last Updated" timestamps, and direct navigation to resume kuis
- Configurable `baseUrl` detection logic in `endpoints.dart` to support physical device testing via local IP    
- Detailed JSON debug logging in `SubmissionService` for better payload monitoring

### Fixed
- Fixed missing client logos in `SurveyBpkPage` header when navigating from "Active Projects"
- Enhanced `UserProject` model with `copyWith` and robust multi-key image detection (image, client_image, logo, etc.)
- Stabilized JSON encoding for Matrix questions by implementing recursive key normalization in `StorageHelper`  
- Fixed data type inconsistencies (String vs Int keys) ensuring responses are correctly restored from local storage
- Resolved "Error 302" redirect issues by refining API endpoint and protocol handling for local environments    
- Fixed asset loading paths by adding dynamic `storageUrl` resolution in `Endpoints` and `Client` model

### Technical Changes
- Refactored `_loadDraftIfExists` in `SubmissionPage` for more robust data restoration
- Moved Matrix-to-JSON encoding logic to the page layer to prevent payload corruption of non-matrix data        
- Implemented data enrichment pattern in `DashboardProvider` to link disparate API models (Client & Project)    

---

## [1.3.1] - 2026-04-09
### Fixed
- Shrink grid spacing on survey bento card to remove empty whitespace between action buttons ("Cek / Edit" and "Monitor")
- Tightened `crossAxisSpacing`, `mainAxisSpacing`, and `childAspectRatio` in the bento grid layout for a cleaner, compact appearance

---

## [1.3.1] - 2026-04-10
fix: improve dashboard & view survey UI

- fix overflow on client grid
- add animDelay to ProjectCard
- improve layout & spacing
- enhance overall UI consistency

## [1.3.0] - 2026-04-08
### Features
- Modernized survey analytics interface with a premium **bento-style grid layout** aligned to the "Digital Architect" design system
- Replaced legacy table-based survey list with responsive, interactive `SurveyBentoCard` widgets
- Implemented animated bento grid with staggered card reveal and hover effects
- Added action buttons ("Cek / Edit" & "Monitor") directly on each survey card for quick access
- Progress fitur camera: add camera capture functionality with `camera_capture_page.dart`
- Add camera plugin integration for Android and iOS

### Changes
- Removed SIS branding from survey-specific pages to maintain dashboard exclusivity
- Fine-tuned color palette to Emerald/Mint tones for a more polished, professional aesthetic
- Adjusted grid spacing and card proportions for a consistent, premium layout

### Technical Changes
- Updated platform-specific configurations for camera plugin (AndroidManifest.xml, Info.plist)
- Added camera dependencies to pubspec.yaml
- Updated platform generated files for Linux, macOS, and Windows

---

## [1.2.9] - 2026-04-07
### Features
- Redesign dashboard: update client card and project card design for better UI/UX
- Redesign monitor page: improve responsive layout and data presentation

### Investigation
- Investigate survey edit issue: answers not showing when returning to cek/edit page
- Added debug logging to trace API response keys
- Added fallback to /report/{responseId} endpoint when /edit-answer/{userId} returns empty answer
- Tried /responses/{responseId} endpoint but got 500 error (not available in backend)

### Changes
- Added surveyResponses endpoint in endpoints.dart (commented out for now)
- Added fallback logic in edit_answer_service.dart to try /report endpoint when primary returns empty

### Backend Issue Found
- Identified bug in Laravel EnumEditAnswer: uses $authUser->id instead of $userId parameter
- Fix required in backend Laravel controller (not a Flutter issue)
- Root cause found: answers table empty for response_id=362, meaning answers not being saved during submission  

### Known Issues
- Answers not persisting to database - this is a backend issue, not Flutter


---

## [1.2.8] - 2026-04-06
### Features
- Add Biodata page for respondent data input before survey
- Dynamic button labels (Isi Kuisioner / Cek Edit) based on answer status
- Local storage helper draft for answers (saves before database submission)
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
