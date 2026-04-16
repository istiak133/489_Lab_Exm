# Smart Landmarks - CSE 489 Lab Exam

## 1. Project Overview
Smart Geo-Tagged Landmarks is a cross-platform mobile application built with Flutter (Dart) that interacts with a faculty-provided REST API to manage and visualize geo-tagged landmarks. The app runs on Android and supports viewing, visiting, filtering, and offline handling of landmarks.

## 2. Features Implemented
- Fetch and display landmarks from REST API (title, image, score)
- Interactive map view (OpenStreetMap via flutter_map) with score-based colored markers
- Visit feature with GPS location tracking and distance display
- Landmarks list with sorting by score and filtering by minimum score
- Add new landmark with image upload (multipart form-data), GPS auto-fill
- Soft delete and restore landmark functionality
- Visit history tracking (landmark name, time, distance)
- Complete offline support (SQLite caching, offline queue, auto-sync)
- Error handling with SnackBar/Dialog messages
- Bottom Navigation with 4 tabs (Map, Landmarks, Activity, Add/View)

## 3. API Usage
- Base URL: https://labs.anontech.info/cse489/exm3/api.php
- GET get_landmarks: Fetches all landmarks with details
- POST visit_landmark: Sends GPS coordinates, receives distance (JSON body)
- POST create_landmark: Creates new landmark with image (multipart form-data)
- POST delete_landmark: Soft deletes a landmark (form-data)
- POST restore_landmark: Restores soft-deleted landmark (form-data)
- All requests include student key as query parameter

## 4. Offline Strategy
- Cache: API responses cached in SQLite database (sqflite package)
- Display: When offline, app shows cached data from SQLite
- Queue: Visit requests made while offline are saved to pending_visits table
- Sync: On app startup or refresh, pending visits are automatically synced when online
- Connectivity detection via connectivity_plus package

## 5. Architecture Used
- Provider pattern for state management (ChangeNotifier)
- Service layer pattern (ApiService, DatabaseService)
- Feature-based folder organization (models, services, providers, screens)
- Libraries: http, sqflite, provider, flutter_map, geolocator, image_picker, connectivity_plus, cached_network_image

## 6. Challenges Faced
- Handling different body types (JSON for visit vs multipart form-data for create)
- Implementing offline queue and auto-sync on reconnection
- Score-based marker coloring on map
- Managing GPS permissions and fallbacks across different scenarios
- Robust JSON parsing for server responses (handling mixed types)
