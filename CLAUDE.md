# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.Your partner is Japanese. so you should use Japanese to communicate with him.

## Project Overview

**earsmile** — 聴覚障害・難聴の高齢者向け音声テキスト化アプリ (Speech-to-text app for elderly users with hearing impairment). iOS/iPadOS 16+ only.

## Common Commands

```bash
# Install dependencies
~/flutter/bin/ flutter pub get

# Run code generators (required after modifying ObjectBox entities or Riverpod providers)
~/flutter/bin/ flutter pub run build_runner build --delete-conflicting-outputs

# Lint
~/flutter/bin/ flutter analyze

# Run all tests
~/flutter/bin/ flutter test

# Run a single test file
~/flutter/bin/ flutter test test/models/models_test.dart

# Run on iOS simulator
~/flutter/bin/ flutter run
```

## Architecture

### State Management: Riverpod
Uses `flutter_riverpod` with code generation (`riverpod_annotation` + `riverpod_generator`). Providers live in `lib/providers/`. After defining any new provider with `@riverpod` annotation, run `build_runner` to regenerate `.g.dart` files.

### Data Layer: Two-Tier Storage
1. **Local (ObjectBox)** — embedded NoSQL database at `{DocumentsDirectory}/objectbox`. Initialized in `LocalStorageService` (`lib/services/local_storage_service.dart`). Models are in `lib/models/` and use `@Entity()` annotations; `lib/objectbox.g.dart` is generated code.
2. **Cloud (Firebase Firestore)** — optional sync; conversations track sync state via `isSyncedToCloud`. Firebase config is in `lib/firebase_options.dart` (generated) and `ios/Runner/GoogleService-Info.plist`.

### Authentication
Anonymous Firebase Auth only — no user registration. The same UID persists across restarts.

### Routing
`go_router` ^17.1.0 is included but not yet configured. Routes should be defined in `lib/config/`.

### Core Entities
- **AppSettings** — singleton (id=1); `fontSize` (1.0/2.0/3.0 mapped to 24/32/48pt), `isHighContrast`
- **Conversation** — has a UUID for Firestore sync, `isFavorite`, `isSyncedToCloud`
- **Message** — belongs to a Conversation via `conversationId` (UUID), stores `text`, `confidence` (0.0–1.0), `isFinal`

### Speech Recognition
Planned to use native iOS `SFSpeechRecognizer` framework (on-device, no cloud). Implementation is pending; the service should live in `lib/services/`.

## Key Design Constraints

- **Accessibility first**: Minimum font 24pt, touch targets ≥80pt, high-contrast color mode support. All UI decisions must accommodate elderly users.
- **Offline-first**: All features must work without network. Cloud sync is optional.
- **iOS only**: No Android or web targets.

## Documentation

Design documents in `docs/`:
- `RDD.md` — functional requirements
- `DetailedDesign.md` — full technical design (directory structure, Riverpod provider specs, widget specs, Firestore schema)
- `MVP_Implementation_Steps.md` — phased implementation roadmap (Steps 1–2 complete; Steps 3–5 pending)
