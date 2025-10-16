Clarus Watchface
================

Clarus is a clean Garmin watchface that I am building with Monkey C. It shows big, easy-to-read time digits, a slim seconds ring, and a small date banner that fits modern devices like the fēnix 7.

## Features
- High-contrast hour and minute digits with a red accent on the minutes
- Fonts automatically adjust so the time always fits the screen
- Optional animated seconds ring that keeps battery use low
- Day and date banner with tight spacing for easy reading
- Works with Connect IQ API 4.0.0 and newer (tested on fēnix 7)

## Project Structure
- `manifest.xml` – core application metadata and target device list
- `monkey.jungle` – build configuration consumed by the Monkey C toolchain
- `source/` – Monkey C application (`clarus-watchfaceApp.mc`) and view (`clarus-watchfaceView.mc`)
- `resources/` – drawables, layouts, and string resources surfaced to the app
- `bin/` – output directory for compiled PRG builds (ignored by Git)

## Prerequisites
- Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) and download the 4.x SDK
- Make sure the Monkey C tools (`monkeyc`, `monkeydo`, `monkeygraph`) are in your PATH
- Optional: Visual Studio Code with the Garmin Connect IQ extension
- A developer key file (`developer_key.der`) for signing local builds

## Getting Started
1. Clone your fork:
   ```bash
   git clone https://github.com/SanderNilsen/clarus-watchface
   cd clarus-watchface
   ```
2. Copy your developer key into the project root (or keep note of its full path).
3. Build a debug PRG:
   ```bash
   monkeyc -f monkey.jungle -o bin/clarus.prg -d fenix7 -y developer_key.der
   ```
4. Launch in the Connect IQ emulator:
   ```bash
   monkeydo bin/clarus.prg fenix7
   ```
5. If you prefer Visual Studio Code, open the workspace folder and use the `Monkey C: Build` and `Monkey C: Run` commands from the command palette.