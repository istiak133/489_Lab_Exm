# University Submission Cover

| Field | Value |
| --- | --- |
| Student Name | Istiak Ahmed |
| Student ID | 24141210 |
| Section | 01 |
| Course | CSE489 (App Development) |
| Assessment | CSE 489 Lab Exam |
| Project Title | Smart Landmarks (Flutter) |
| Submission Date | April 15, 2026 |

---

# Smart Landmarks (Flutter)
## CSE 489 Lab Exam - Final Submission

### Student Information
- Name: Istiak Ahmed
- ID: 24141210
- Section: 01
- Course: CSE489 (App Development)
- Submission Date: April 15, 2026

## 1. Project Overview
Smart Landmarks is a Flutter-based mobile application for managing geo-tagged landmarks through a REST API. Users can view landmarks in map and list formats, submit visits with live GPS coordinates, add landmarks with images, and continue key operations during offline conditions using local storage and deferred sync.

## 2. Features Implemented
- Fetch and display landmarks from the remote API.
- Show landmarks on OpenStreetMap using flutter_map.
- Score-based sorting and minimum-score filtering in landmark list.
- Visit landmark workflow with current GPS capture and server distance response.
- Add new landmark with title, coordinates, and image upload.
- Soft delete and restore landmark operations.
- Local visit history tracking with time and distance.
- Offline landmark cache using SQLite.
- Pending visit queue for offline actions.
- Auto-sync of queued visits when internet connectivity is restored.

## 3. API Usage
- Base URL: https://labs.anontech.info/cse489/exm3/api.php
- Authentication Strategy: All requests include query parameter key=24141210.

Endpoints used:
- GET action=get_landmarks
  Purpose: Retrieve all landmarks for list and map rendering.

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

## 4. Offline Strategy
- Local Cache: Landmark API data is stored in SQLite table landmarks.
- Offline Queue: Visit actions made without internet are stored in pending_visits.
- Deferred Synchronization: Pending visits are retried automatically on refresh/startup when network becomes available.
- Local Continuity: Cached landmarks and visit history remain available offline.
- Connectivity Detection: connectivity_plus is used to monitor network state.

## 5. Architecture Used
- State Management: Provider with ChangeNotifier.
- Service Layer: ApiService for network operations and DatabaseService for SQLite operations.
- Data Layer: Model classes for landmark, visit history, and pending visit.
- UI Layer: Feature-based screens and widgets in lib/screens and lib/widgets.

Architectural style followed:
- Separation of concerns between presentation, state, API, and persistence.
- Offline-first fallback path for network failures.
- Reusable service classes for maintainability and easier extension.

## 6. Challenges Faced
- Handling multiple payload formats (JSON, multipart/form-data, and form-data) across endpoints.
- Designing reliable offline queue logic without losing visit actions.
- Avoiding duplicate submission during delayed sync.
- Managing location permission and availability edge cases.
- Rendering marker colors consistently based on score values.
- Parsing variable response shapes safely from backend.

This document is prepared as the final submission summary for the CSE 489 lab exam project.
