# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android

# Build release
flutter build ios
flutter build apk

# Generate app icons (after modifying assets/icon/)
flutter pub run flutter_launcher_icons
```

## Architecture

This is a Flutter app for practicing darts checkout combinations. The package name is `checout_trainer` (note the typo).

### Core Components

- **`lib/main.dart`**: App entry point with route definitions (`/`, `/trainer`, `/checkouts`, `/settings`). Uses Provider for state management with `CustomCheckoutRepository` and `MyAppState`.

- **`lib/helpers/darts_checkouts.dart`**: Static `DartCheckouts` class containing a complete map of standard checkout combinations (scores 2-170 mapped to dart sequences like `['T20', 'T20', 'D20']`). Notation: `T` = treble, `D` = double, `Bull` = bullseye (50), `25` = outer bull.

- **`lib/repositories/custom_checkout_repository.dart`**: `ChangeNotifier` that manages user-customized checkouts. Persists to `SharedPreferences` as JSON. Custom checkouts override defaults.

### Pages

- **HomePage**: Landing screen with navigation to trainer and checkouts
- **TrainerPage**: Main training interface with 30-second timer, custom dartboard keyboard (numbers 1-20, modifiers Single/Double/Treble, Bull/Outer), input validation, and scoring logic
- **CheckoutsPage**: Searchable list of all checkouts with ability to edit/customize. `EditCheckoutDialog` validates that custom sequences sum to the correct score.
- **SettingsPage**: Placeholder (minimal implementation)

### Key Patterns

- Checkout validation: Calculates sum from notation (e.g., `T20` = 60, `D16` = 32, `Bull` = 50)
- Timer pauses on app lifecycle changes (background/inactive states)
- Portrait-only orientation enforced at startup
