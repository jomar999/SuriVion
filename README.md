# surivion

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Chat endpoint switching

The chatbot endpoint can be changed without editing source code by using
`--dart-define=CHAT_ENDPOINT=...`.

- USB mode (with `adb reverse tcp:5000 tcp:5000`):
	`flutter run --dart-define=CHAT_ENDPOINT=http://127.0.0.1:5000/chat`
- Wi-Fi mode (replace with your PC LAN IP):
	`flutter run --dart-define=CHAT_ENDPOINT=http://192.168.1.109:5000/chat`

## One-command USB start

To avoid retyping backend + adb reverse + flutter run every session, use:

`powershell -ExecutionPolicy Bypass -File .\scripts\start_usb_dev.ps1`

This script will:
- start backend server in a new PowerShell window
- run `adb reverse tcp:5000 tcp:5000`
- auto-detect the connected Android device
- run Flutter with `CHAT_ENDPOINT=http://127.0.0.1:5000/chat`
