<div align="center">

# Campus Find Pakistan

**A Lost & Found platform for university students across Pakistan**

Report, discover, and reclaim lost or found items, filtered to your own campus community.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com)

[Download APK](../../releases) · [Report a Bug](../../issues) · [Request a Feature](../../issues)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Video Demonstration](#video-demonstration)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Push Notifications Setup](#push-notifications-setup)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Overview

Campus Find Pakistan solves a simple, everyday campus problem: lost items rarely make it back to their owners because there's no dedicated channel to report or search for them. This app gives every university its own private space where students can post what they've lost, what they've found, and message each other directly to arrange a return; all backed by verified student accounts.

---

## Video Demonstration

<div align="center"> <img src="demo.gif" width="300" alt="App Demo" /> </div>

---

## Features

- Email based signup with mandatory verification (Gmail only)
- University based content filtering; see posts relevant to your campus only
- Create, browse, and manage lost/found item posts with images
- In app real time chat between users
- Push notifications for new posts and chat messages
- Cloudinary powered image uploads
- Clean, modern Material 3 UI

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore) |
| Media Storage | Cloudinary |
| Push Notifications | Firebase Cloud Messaging + Vercel serverless functions |
| State/Architecture | Provider, layered `core` / `data` / `presentation` structure |

---

## Project Structure

```
lib/
 ├─ core/           # Constants, theming, validators, error handling
 ├─ data/           # Models, services (notifications, Cloudinary), repositories
 ├─ presentation/   # Screens — auth, chat, home, notifications, posts, profile
 └─ providers/      # App-wide state providers
```

---

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- A Firebase project (Auth + Firestore enabled)
- A Cloudinary account for media uploads

### Setup
```bash
git clone https://github.com/muddasirahmed-19/Campus-Find-Pakistan.git
cd Campus-Find-Pakistan
flutter pub get
```

You'll need to supply your own Firebase config files locally (not included in this repo for security reasons):
- `android/app/google-services.json`
- `lib/firebase_options.dart` (generate via `flutterfire configure`)

### Run
```bash
flutter run
```

### Build a release APK
```bash
flutter build apk --split-per-abi
```

---

## Push Notifications Setup

Notifications are delivered via a lightweight serverless function (Vercel) that calls Firebase Cloud Messaging whenever a new post or chat message is created. See `functions/` or the notify server code for reference if you're deploying your own instance.

---

## License

This project is open for learning and reference purposes.

---

## Acknowledgements

Built with Flutter and Firebase, designed for the university community in Pakistan.

---

<div align="center">

If you find this project useful, consider giving it a star.

</div>
