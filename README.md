# 🚶‍♀️ Walking Activity Tracker (Flutter App)

## Overview
This is a **Flutter-based walking activity tracker application** that allows users to track their walking activities using GPS.

The app records walking routes, calculates distance and duration, displays the route on Google Maps, and stores walking history locally on the device. It also includes a simple media feed for browsing shared moments.

---

## ✨ Features
- Live GPS tracking for walking activities
- Route visualization on Google Maps using polylines
- Start, pause, resume, and stop walking sessions
- Automatic calculation of walking distance and duration
- Map screenshot capture after walk completion
- Screen recording support (optional)
- Local walking history stored on device
- Walk detail view with route preview
- Media feed with infinite scrolling and pull-to-refresh

---

## 📱 Screens
- **Home Screen** – Start walking, view history, or open media feed
- **Tracking Screen** – Live GPS tracking with map view and controls
- **Walking History Screen** – View saved screenshots and recordings
- **Walk Detail Screen** – Walking summary with distance and duration
- **Map Viewer Screen** – Full route display with start and end markers
- **Feed Screen** – Infinite scrolling list of walking moments

---

## 🛠 Tech Stack
- Flutter
- Riverpod (State Management)
- Google Maps Flutter
- Geolocator
- Shared Preferences
- HTTP API

---

## 🔐 Permissions
- **Location** – Required to track walking routes
- **Storage / Media** – Used to save screenshots and screen recordings
- **App & Location Settings Access** – Helps resolve disabled permissions

---

## 🔒 Data & Privacy
- All walking data (routes, distance, duration, screenshots, recordings) are stored **locally on the device**
- No personal walking data is uploaded
- The media feed uses a public API for displaying content

---


## 📦 Download APK (Android)
You can download and test the app on an Android device using the link below:

👉 **[Download Android APK](https://drive.google.com/drive/folders/1oYCCNqTc7lqnEkXWT8iBVDlP9W45E7yO?usp=drive_link)**

> ⚠️ Make sure **Install unknown apps** is enabled on your Android phone before installing.

---

## 🚀 Run Locally
### Prerequisites
- Flutter SDK installed
- Android or iOS environment set up
- - Google Maps API key configured

### Steps
```bash
flutter pub get
flutter run
