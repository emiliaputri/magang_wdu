# SIS WDU - System Flowcharts

---

## 1️⃣ USER LOGIN FLOW

```
[START: User buka aplikasi]
         |
         v
[Tampil halaman Login]
         |
         v
[User input email & password]
         |
         v
[Submit login form]
         |
         v
[Laravel Fortify: Validate credentials]
         |
         +---> [Invalid?] --Yes--> [Show error message] --+
         |                                                 |
         No                                                |
         |                                                 |
         v                                                 |
[Check 2FA enabled?] --Yes--> [Redirect to 2FA page] ----+
         |                             |                  |
         No                            v                  |
         |                    [User input 2FA code]       |
         |                             |                  |
         |                             v                  |
         |                    [Validate 2FA code]         |
         |                             |                  |
         |                             +---> [Invalid?] --+
         |                             |
         |                            Valid
         |                             |
         v<----------------------------+
[Create session]
         |
         v
[Set current_team_id]
         |
         v
[Redirect to Dashboard]
         |
         v
[END: User logged in]
```

---

## 2️⃣ SURVEY CREATION FLOW

```
[START: Admin/PIC klik "Create Survey"]
         |
         v
[Route: /create-surveys]
         |
         v
[Tampil form CreateSurveys.vue]
         |
         v
[User input survey details:]
  - Title
  - Description
  - Status (published/closed/draft)
  - Target provinces (optional)
  - Public token status
  - Location status
  - N8n integration toggle
  - Progress bar toggle
  - IP restriction toggle
         |
         v
[Submit form via Inertia]
         |
         v
[SurveyController@store]
         |
         v
[Validate request data]
         |
         +---> [Validation fails?] --Yes--> [Return errors] --+
         |                                                      |
         No                                                     |
         |                                                      |
         v                                                      |
[Generate unique slug]                                         |
         |                                                      |
         v                                                      |
[Generate public_token (UUID)]                                 |
         |                                                      |
         v                                                      |
[Create Survey in database]                                    |
         |                                                      |
         v                                                      |
[Create default Question Page]                                 |
         |                                                      |
         v                                                      |
[Flash success message]                                        |
         |                                                      |
         v                                                      |
[Redirect to AddQuestions page] <-----------------------------+
         |
         v
[END: Survey created, ready untuk add questions]
```

---

## 3️⃣ QUESTION BUILDER FLOW

```
[START: User di halaman AddQuestions]
         |
         v
[Load survey data + pages + questions]
         |
         v
[Tampil drag-and-drop interface]
         |
         v
+---> [User action loop]
|        |
|        +---> [Add new question?] --Yes--> [Pilih question type]
|        |                                          |
|        |                                          v
|        |                                   [Render question form]
|        |                                          |
|        |                                          v
|        |                                   [Edit question text (TipTap)]
|        |                                          |
|        |                                          v
|        |                                   [Set options:]
|        |                                     - Required
|        |                                     - Weight
|        |                                     - Choices (if applicable)
|        |                                     - Matrix rows/cols (if matrix)
|        |                                          |
|        |                                          v
|        |                                   [Save question locally]
|        |                                          |
|        +<-----------------------------------------+
|        |
|        +---> [Drag to reorder?] --Yes--> [Update order locally] --+
|        |                                                           |
|        +<----------------------------------------------------------+
|        |
|        +---> [Delete question?] --Yes--> [Remove from local state] --+
|        |                                                              |
|        +<-------------------------------------------------------------+
|        |
|        +---> [Clone question?] --Yes--> [Duplicate question locally] --+
|        |                                                                |
|        +<---------------------------------------------------------------+
|        |
|        +---> [Add image/paragraph?] --Yes--> [Upload/configure] --+
|        |                                                           |
|        +<----------------------------------------------------------+
|        |
|        +---> [Add new page?] --Yes--> [Create new page] --+
|        |                                                   |
|        +<--------------------------------------------------+
|        |
|        +---> [Setup Flow Logic?] --Yes--> [Open Flow modal]
|        |                                          |
|        |                                          v
|        |                                   [Configure conditions:]
|        |                                     - Current page
|        |                                     - Next page
|        |                                     - Question condition
|        |                                     - Choice condition
|        |                                     - Custom field condition
|        |                                          |
|        |                                          v
|        |                                   [Save flow to database]
|        |                                          |
|        +<-----------------------------------------+
|        |
|        +---> [Setup Page Logic?] --Yes--> [Open Page Logic modal]
|        |                                          |
|        |                                          v
|        |                                   [Configure page rules:]
|        |                                     - Target page
|        |                                     - Logic type (AND/OR)
|        |                                     - Conditions (custom fields)
|        |                                          |
|        |                                          v
|        |                                   [Save page logic to database]
|        |                                          |
|        +<-----------------------------------------+
|        |
|        v
|   [Click "Save" button?] --No--> [Continue editing] --+
|        |                                               |
|       Yes                                              |
|        |                                               |
|        v                                               |
| [QuestionController@manualSave]                        |
|        |                                               |
|        v                                               |
| [Process all questions + pages]                        |
|        |                                               |
|        v                                               |
| [Update database (questions, choices, pages)]          |
|        |                                               |
|        v                                               |
| [Flash success message]                                |
|        |                                               |
|        v                                               |
| [Reload page with updated data] ----------------------+
         |
         v
[END: Questions saved]
```

---

## 4️⃣ SURVEY SUBMISSION FLOW

### Mode A: Authenticated User
```
[START: User sudah login]
         |
         v
[Submit to /submission]
         |
         v
[AnswerController@submission]
         |
         v
[Check: User punya akses?]
         |
         +---> [No access?] --Yes--> [403 Forbidden] --> [END]
         |
         No
         |
         v
[Check: Survey published?]
         |
         +---> [Not published?] --Yes--> [Show closed] --> [END]
         |
         No
         |
         v
[Render SubmissionSurvey.vue]
         |
         v
[User isi survey + auto-save]
         |
         v
[Evaluate conditional logic per question/page]
         |
         v
[Submit completed]
         |
         v
[Update response.status = "completed"]
         |
         v
[Redirect to Thank You page]
         |
         v
[END]
```

### Mode B: Public Token
```
[START: Guest buka /survey/{public_token}]
         |
         v
[Check: public_token_status enabled?]
         |
         +---> [Not enabled?] ---> [404] --> [END]
         |
         No
         |
         v
[Check: IP restriction?]
         |
         +---> [Yes] --> [Count IP responses]
         |                      |
         |                      v
         |              [>= 5?] --Yes--> [Max reached] --> [END]
         |                      |
         |                      No
         v<---------------------+
[Show biodata form if location_status enabled]
         |
         v
[Create Response with public_token + guest_session_id]
         |
         v
[... submission flow ...]
         |
         v
[END]
```

### Mode C: Campaign Token
```
[START: User klik /survey/by-token/{campaign_token}]
         |
         v
[Find campaign_recipient_tracking]
         |
         +---> [Not found?] ---> [404] --> [END]
         |
         No
         |
         v
[Check: Already submitted?]
         |
         +---> [Yes] ---> [Show "Already Submitted"] --> [END]
         |
         No
         |
         v
[Check: Opted out?]
         |
         +---> [Yes] ---> [Show "Unsubscribed"] --> [END]
         |
         No
         |
         v
[Update: opened = true, opened_at = now]
         |
         v
[Create Response with campaign_token]
         |
         v
[... submission flow ...]
         |
         v
[END]
```

---

## 5️⃣ CAMPAIGN CREATION & SENDING

```
[START: Create campaign]
         |
         v
[Input: name, subject, sender, survey, recipients]
         |
         v
[CampaignController@store]
         |
         v
[Create Campaign + link recipients]
         |
         v
[Redirect to Mail Builder]
         |
         v
[Drag-and-drop email elements:]
  - Text (TipTap)
  - Image
  - Button
  - Divider
  - 2-column
         |
         v
[Save mail_content_rows]
         |
         v
[Preview email]
         |
         v
[Click "Send Campaign"]
         |
         v
[Confirm dialog] --Cancel--> [END]
         |
        Yes
         |
         v
[CampaignController@send]
         |
         v
+---> [Loop each contact]
|        |
|        v
|   [Generate unique campaign_token]
|        |
|        v
|   [Create campaign_recipient_tracking]
|        |
|        v
|   [Build email HTML from mail_content_rows]
|        |
|        v
|   [Replace {survey_link} with /survey/by-token/{token}]
|        |
|        v
|   [Add tracking pixel + unsubscribe link]
|        |
|        v
|   [Send via Mail::send]
|        |
|        +---> [Failed?] --Yes--> [Log to failed_emails] --+
|        |                                                  |
|        No                                                 |
|        |                                                  |
|        v                                                  |
|   [Increment sent_count]                                 |
|        |                                                  |
|        v<-------------------------------------------------+
|   [Next contact?] --Yes--+
|        |                 |
+<-------+                 |
         |                 |
         v<----------------+
[Update CampaignSendLog with stats]
         |
         v
[Flash success notification]
         |
         v
[END]
```

---

## 6️⃣ CAMPAIGN TRACKING

```
[Email opened]
         |
         v
[Load tracking pixel: /campaign/track/open/{token}]
         |
         v
[Update: opened = true, opened_at = now]
         |
         v
[Click survey link]
         |
         v
[GET /campaign/track/link/{token}?url={survey_url}]
         |
         v
[Update: clicked = true, clicked_at = now]
         |
         v
[Redirect to survey]
         |
         v
[Admin views tracking dashboard]
         |
         v
[CampaignController@tracking]
         |
         v
[Calculate stats:]
  - Total sent
  - Opened %
  - Clicked %
  - Responded %
  - Failed count
         |
         v
[Display tracking dashboard]
         |
         v
[END]
```

---

## 7️⃣ AI SUMMARIZATION

```
[User klik "Summarize" on question]
         |
         v
[ResponseController@summarizeQuestion]
         |
         v
[Check: Summary exists in DB?]
         |
         +---> [Yes] --> [Return cached] --> [Display] --> [END]
         |
         No
         |
         v
[Determine question type]
         |
         +---> [Open Ended] --> [AISummaryService@summarizeOpenEndedQuestion]
         +---> [Single Choice] --> [AISummaryService@summarizeSingleChoiceQuestion]
         +---> [Multiple Choice] --> [AISummaryService@summarizeMultipleChoiceQuestion]
         +---> [Matrix] --> [AISummaryService@summarizeMatrixQuestion]
         |
         v
[Prepare data + build prompt]
         |
         v
[Call Groq API (llama-3.3-70b)]
         |
         v
[Parse JSON response:]
  {summary, insights, sentiment, recommendations, statistics}
         |
         v
[Save to question_summaries table]
         |
         v
[Return to frontend]
         |
         v
[Display in modal]
         |
         v
[END]
```

---

## 8️⃣ N8N INTEGRATION

```
[N8n workflow triggered]
         |
         v
[POST /api/login] --> [Get Sanctum token]
         |
         v
[GET /api/n8n/survey/{id}/export-data]
         |
         v
[N8nWebhookController@getExportData]
         |
         v
[Check: n8n_integration enabled?]
         |
         +---> [No] --> [403] --> [END]
         |
        Yes
         |
         v
[Format responses for spreadsheet]
         |
         v
[Return JSON data]
         |
         v
[N8n: Create Google Spreadsheet]
         |
         v
[N8n: Populate with data]
         |
         v
[N8n: POST /api/n8n/save-spreadsheet-url]
  {survey_id, spreadsheet_url}
         |
         v
[Update survey.spreadsheet_url]
         |
         v
[User sees "Access Spreadsheet" button]
         |
         v
[END]
```

---

## 9️⃣ CONDITIONAL LOGIC EVALUATION

### Question-Level Flow
```
[Load survey page]
         |
         v
+---> [Loop questions]
|        |
|        v
|   [Get flows for question]
|        |
|        v
|   [Condition type?]
|        |
|        +---> [Question-based]
|        |           |
|        |           v
|        |     [Check user's answer]
|        |           |
|        |           v
|        |     [Matches choice_id?]
|        |           |
|        |           +---> [Yes] --> [Show question]
|        |           |
|        |           No
|        |           |
|        |           v
|        |     [Hide question]
|        |
|        +---> [Custom field-based]
|                    |
|                    v
|              [Get custom field value]
|                    |
|                    v
|              [Evaluate operator (equals, contains, etc.)]
|                    |
|                    +---> [Met?] --Yes--> [Show]
|                    |
|                    No
|                    |
|                    v
|              [Hide question]
|        |
|        v<------+
|   [Next question?] --Yes--+
|        |
+<-------+
         |
         v
[Render visible questions]
         |
         v
[END]
```

### Page-Level Logic
```
[User klik "Next Page"]
         |
         v
[Get page_logic_rules]
         |
         +---> [No rules?] --> [Go to next page] --> [END]
         |
        Yes
         |
         v
+---> [Loop rules]
|        |
|        v
|   [Get conditions]
|        |
|        v
|   [Logic type?]
|        |
|        +---> [AND] --> [All conditions must be true]
|        |                      |
|        |                      v
|        |              [Evaluate each]
|        |                      |
|        |                      +---> [All true?] --Yes--> [Jump to target_page] --> [END]
|        |                      |
|        +---> [OR] --> [Any condition can be true]
|                             |
|                             v
|                     [Evaluate each]
|                             |
|                             +---> [Any true?] --Yes--> [Jump to target_page] --> [END]
|        |
|        v<------+
|   [Next rule?] --Yes--+
|        |
+<-------+
         |
         v
[No rules matched]
         |
         v
[Go to next page sequentially]
         |
         v
[END]
```

---

## 🔟 REPORTING

```
[Admin views survey]
         |
         v
[Click "View Responses"]
         |
         v
[ResponseController@index]
         |
         v
[Filter by role permissions]
         |
         v
[Display ResponseTable.vue]
         |
         v
[User actions]
         |
         +---> [Individual response]
         |           |
         |           v
         |     [ResponseController@report]
         |           |
         |           v
         |     [Show ReportSurvey.vue]
         |           |
         |           +---> [Export PDF?] --> [Generate PDF] --> [Download]
         |
         +---> [All Report]
         |           |
         |           v
         |     [ResponseController@allreport]
         |           |
         |           v
         |     [Calculate aggregate stats]
         |           |
         |           v
         |     [Display AllReport.vue with charts]
         |           |
         |           +---> [Summarize] --> [AI Flow]
         |
         +---> [Location Details]
                     |
                     v
               [SurveyController@location]
                     |
                     v
               [Calculate per-province progress]
                     |
                     v
               [Display map + progress bars]
                     |
                     v
                   [END]
```

---

## 1️⃣1️⃣ EXPORT

```
[User klik "Export"]
         |
         v
[Choose type]
         |
         +---> [Excel] --> [ResponseController@export]
         |                        |
         |                        v
         |                 [ResponseExport class]
         |                        |
         |                        v
         |                 [Build Excel with all data]
         |                        |
         |                        v
         |                 [Download .xlsx]
         |                        |
         |                        v
         |                      [END]
         |
         +---> [PDF] --> [ResponseController@exportPdf]
                                |
                                v
                         [Build HTML view]
                                |
                                v
                         [Generate PDF (dompdf)]
                                |
                                v
                         [Download .pdf]
                                |
                                v
                              [END]
```

