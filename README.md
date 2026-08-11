# Downpour

A minimalist native macOS YouTube downloader built with SwiftUI.

Downpour uses an original rain-soaked sheep mascot, packaged as a complete macOS `.icns` app icon.

## Features

- Video downloads in Best, 1080p, 720p, or 480p
- QuickTime-compatible H.264 video with AAC audio
- Strict codec selection: incompatible AV1/VP9 and Opus fallbacks are rejected
- MP3 audio extraction
- Destination folder picker
- Live progress and cancellation
- Safe single-video mode (playlists are not downloaded accidentally)

## Requirements

- macOS 13 or newer
- [Homebrew](https://brew.sh)
- `yt-dlp` and `ffmpeg`

Install the runtime dependencies:

```sh
brew install yt-dlp ffmpeg
```

## Build a Mac app

```sh
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/Downpour.app
```

The script builds a release binary, creates `dist/Downpour.app`, and applies an ad-hoc local signature. Full Xcode is not required.

## Development

```sh
swift run Downpour
swift test
```

Only download videos you created, public-domain media, or content whose owner has granted permission. YouTube's terms and local copyright law may restrict downloading.
