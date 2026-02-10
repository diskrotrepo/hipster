# Hipster

A metadata analysis tool for the [Suno](https://suno.com) AI music platform. Paste a Suno song URL or ID to inspect its full creation history — prompts, tags, generation settings, and lineage across extends, covers, and upsamples.

Built with Flutter for web.

## Features

- **Song tree traversal** — Recursively walks a song's lineage (covers, upsamples, extends) to build the full creation history
- **Metadata display** — Title, artist, play count, likes, model version, duration, commercial use status, and more
- **Prompt & tag inspection** — View the positive and negative tags and full lyrics/prompt used for each segment
- **Audio playback** — Listen to any clip directly in the browser
- **Bearer token support** — Optionally provide a Suno bearer token (stored locally) to access private song data

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.4.0)

### Run

```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

### Test

```bash
flutter test
```

## Tech Stack

- **Flutter** (web)
- **audioplayers** — in-browser audio playback
- **get_it** — dependency injection
- **http** — API calls to the Suno studio API
- **shared_preferences** — local bearer token storage
- **Firebase Hosting** — deployment target
