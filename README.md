# 🎵 Groq Lyrics Visualizer Script

This PowerShell script allows you to transcribe and display synchronized lyrics from an audio file using the Groq API with OpenAI's `whisper-large-v3-turbo` model. It also plays the audio using VLC and highlights each lyric segment in sync with playback.

---

## ✨ Features

- Graceful handling of Ctrl+C interruptions
- Dynamic banners and formatting based on terminal size
- Synchronized VLC playback with real-time lyric highlighting
- Color-coded, timestamped lyrics display
- Uses Groq’s `whisper-large-v3-turbo` model for transcription

---

## 🚀 Requirements

- **VLC Media Player** installed (Default path: `C:\Program Files\VideoLAN\VLC\vlc.exe`)
- **Groq API key** (replace `your-api-key` with a valid key)
- **PowerShell** environment
- **Internet connection**

---

## 🔧 Setup

1. Install VLC Media Player from [https://www.videolan.org/vlc](https://www.videolan.org/vlc).
2. Get your **Groq API key** from [https://console.groq.com](https://console.groq.com).
3. Save the script as `groq-lyrics.ps1`.
4. Replace the placeholder API key in the script:
   ```powershell
   $apiKey = "your-api-key"
