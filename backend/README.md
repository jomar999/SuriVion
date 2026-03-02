# Gemini Backend for SuriVion

## 1) Create and activate a Python environment

Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

## 2) Install dependencies

```powershell
pip install -r requirements.txt
```

If you previously installed `google-generativeai`, remove it:

```powershell
pip uninstall google-generativeai -y
```

## 3) Set your API key (do not hardcode in source)

```powershell
$env:GEMINI_API_KEY="YOUR_REAL_KEY_HERE"
```

## 4) Run the server

```powershell
python gemini_server.py
```

Server URL:

- Local: `http://127.0.0.1:5000/chat`
- LAN (phone on same Wi-Fi): `http://<PC_LAN_IP>:5000/chat`

## 5) Update Flutter endpoint

In `lib/chat_screen.dart`, change `_chatEndpoint` to your PC LAN IP, for example:

```dart
static const String _chatEndpoint = 'http://192.168.1.5:5000/chat';
```

## Notes

- Keep `GEMINI_API_KEY` private. Never commit it to git.
- For Android emulator, use `http://10.0.2.2:5000/chat`.
