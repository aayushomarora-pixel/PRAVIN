# PRAVIN

A cross-platform personal assistant app built with Flutter — your calendar, tasks, notes, planning, and an AI chat, all in one place.

## Features

- **Tasks** — create and track to-dos
- **Calendar** — see what's coming up
- **Notes** — jot things down quickly
- **Planning** — map out your time
- **AI Chat** — powered by the Kimi (Moonshot AI) API
- **Voice** — speech-to-text input and text-to-speech output
- **Google integration** — Google sign-in and Google API access
- **Offline-first** — data stored locally with SQLite
- **Dark mode** — follows your system theme

## Tech Stack

- **Flutter** (Dart) with Material 3
- **GoRouter** for navigation
- **SQLite** (sqflite) for local storage
- **speech_to_text** and **flutter_tts** for voice
- **google_sign_in** + **googleapis** for Google services
- **http** client with dotenv-based configuration

## Getting Started

1. Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

2. Clone the repo:

   ```bash
   git clone https://github.com/aayushomarora-pixel/PRAVIN.git
   cd PRAVIN
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Set up your environment:

   ```bash
   cp .env.example .env
   ```

   Then fill in your own values in `.env`:

   | Variable | Description |
   | --- | --- |
   | `KIMI_API_KEY` | API key for the Kimi (Moonshot AI) API |
   | `GOOGLE_CLIENT_ID` | Google OAuth client ID |
   | `GOOGLE_CLIENT_SECRET` | Google OAuth client secret |
   | `APP_NAME` | Display name for the app |

5. Run the app:

   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/           # Shared utilities and constants
├── data/           # Repositories and data sources
├── features/       # Feature modules
│   ├── calendar/
│   ├── chat/
│   ├── notes/
│   ├── planning/
│   └── tasks/
├── navigation/     # GoRouter configuration
├── presentation/   # Shared widgets and themes
└── main.dart
```

## Platforms

Android, iOS, and Windows are configured in the repo. Run `flutter run` with your device or emulator of choice.
