# Smart Landmarks (Flutter)
## CSE 489 Lab Exam - Final Submission

### University Submission Cover
| Field | Value |
| --- | --- |
| Student Name | Istiak Ahmed |
| Student ID | 24141210 |
| Section | 01 |
| Course | CSE489 (App Development) |
| Assessment | Lab Exam |
| Project Title | Smart Landmarks |
| Submission Date | April 19, 2026 |

Prepared for final academic submission.

<div style="page-break-after: always;"></div>

## 1. Project Overview
Smart Landmarks is a Flutter-based mobile application for managing geo-tagged landmarks through a REST API. Users can browse landmarks in map and list formats, submit visits using live GPS location, add landmarks with image upload, and continue key actions in offline mode through local storage and delayed synchronization.

## 2. Features Implemented
- Landmark retrieval from remote API and display in map and list interfaces.
- Score-based sorting and minimum-score filtering.
- OpenStreetMap integration through flutter_map.
- Visit workflow with device GPS capture and server-calculated distance.
- Create landmark integration with multipart image upload.
- Soft delete and restore operations for landmarks.
- Local visit history tracking with timestamp and distance.
- SQLite cache for offline landmark access.
- Pending visit queue for offline actions.
- Auto-sync of queued actions once connectivity is available.

## 3. API Usage
- Base URL: https://labs.anontech.info/cse489/exm3/api.php
- Authentication: All requests include query parameter key=24141210.

Endpoints:
- GET action=get_landmarks
  Purpose: Fetch all landmarks for list and map rendering.

- POST action=visit_landmark
  Purpose: Submit user visit with user_lat and user_lon.
  Body Type: JSON

- POST action=create_landmark
  Purpose: Create landmark with title, lat, lon, and image.
  Body Type: multipart/form-data

- POST action=delete_landmark
  Purpose: Soft-delete landmark by id.
  Body Type: form-data

- POST action=restore_landmark
  Purpose: Restore soft-deleted landmark by id.
  Body Type: form-data

<div style="page-break-after: always;"></div>

## 4. Offline Strategy
- Cached landmark data is persisted in SQLite table landmarks.
- Offline visit attempts are saved in pending_visits queue.
- Queued actions are retried on app startup/refresh when network returns.
- Cached landmarks and visit history remain available without internet.
- connectivity_plus is used to observe online and offline state changes.

## 5. Architecture Used
- State Management: Provider with ChangeNotifier.
- Service Layer: ApiService for REST communication and DatabaseService for SQLite.
- Data Layer: Typed models for landmark, visit history, and pending visit records.
- Presentation Layer: Feature-based Flutter screens and widgets.

Architectural principles:
- Separation of concerns across UI, state logic, API logic, and persistence.
- Offline-first fallback behavior for unstable network conditions.
- Reusable service classes to improve maintainability.

## 6. Challenges Faced
- Handling mixed request body formats across endpoints.
- Designing reliable queue/retry logic for offline actions.
- Preventing duplicate submissions during delayed synchronization.
- Managing location permission and availability edge cases.
- Keeping marker color rules consistent with score values.
- Safely parsing variable backend response shapes.

This report is prepared as the final submission document for CSE489 (App Development) lab exam.
