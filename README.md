# Mira — Voice Assistant Prototype

Mira is a real-time AI voice assistant Android application built with Flutter and Dart. 

This prototype focuses on **one thing only: natural, real-time voice conversations like talking to a human**. It employs a thin-client architecture where no heavy AI models run locally on the phone—the audio streams directly to Google's Gemini Live servers over a bidirectional WebSocket.

---

## 🌟 Key Features

1. **English UI Everywhere**:
   - All labels, buttons, dialogs, settings, transcripts, and status indicators are in clear, clean English.
   - The UI always stays in English regardless of which spoken voice language is selected.

2. **Long List of Spoken Voice Languages**:
   - Choose from a comprehensive list of spoken languages supported by Gemini Live (English, Hindi, Bengali/Bangla, Urdu, Nepali, Tamil, Telugu, Marathi, Punjabi, Malayalam, Gujarati, Kannada, Arabic, French, German, Spanish, Portuguese, Italian, Japanese, Korean, Chinese, Russian, Turkish, Indonesian, Vietnamese, Thai, Dutch, Polish, Ukrainian, Filipino, Swedish, Greek, Romanian, Czech, Hungarian, Danish, Finnish, Norwegian, Malay).
   - **Default spoken language is English** on first run.
   - The selected language is sent directly to Gemini Live (both in session configuration and system instructions) so Mira speaks and understands fluently in that language.

3. **Gemini Live Engine (One WebSocket)**:
   - Connects directly to Google's real-time multimodal Live service (`BidiGenerateContent`).
   - Streams 16 kHz 16-bit mono PCM microphone audio up to Gemini.
   - Receives and plays back 24 kHz raw PCM audio responses with gapless streaming via `flutter_sound`.
   - Uses `models/gemini-3.8-live` with automatic fallback to `models/gemini-2.5-flash-native-audio-preview-12-2025`.

4. **Real-time Barge-in**:
   - If you interrupt Mira by speaking while she is talking, audio playback halts immediately and Mira switches to listening mode instantly.

5. **Live Conversation Transcript**:
   - Displays bidirectional text transcription in real time on screen as you and Mira talk.

6. **Animated Orb & Audio Visualizer**:
   - Multi-layer glowing orb and audio visualizer reflecting engine states: `Ready`, `Connecting...`, `Listening...`, `Thinking...`, `Mira is speaking`, and `Connection Error`.

7. **Voice Picker**:
   - Full picker with official Gemini Live prebuilt voices (`Aoede`, `Kore` [default], `Puck`, `Fenrir`, `Charon`, `Zephyr`, `Autonoe`, `Callirrhoe`, `Despina`, `Erinome`, `Gacrux`, `Laomedeia`, `Leda`, `Sulafat`, `Vindemiatrix`).
   - Friendly system instruction making Mira a helpful, empathetic conversational voice assistant.

8. **BYOK & Hardware Encryption**:
   - First-run setup screen to enter your own free Gemini API key.
   - Validates the key with a lightweight Google API call before saving.
   - Key is stored locally in Android Keystore via `flutter_secure_storage`.
   - **The key stays strictly on your device and is never sent to any server other than Google's official endpoints.**

---

## 🔑 How to Get a Free Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/apikey).
2. Sign in with your Google account.
3. Click **Create API Key**.
4. Copy the key, open Mira, and paste it into the setup screen.

---

## 🚀 Building the APK (GitHub Actions)

Local Android builds can be subject to proxy and environment inconsistencies. The canonical build pipeline is configured via GitHub Actions in [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml).

### Build Pipeline Specifications
- **Runner**: `ubuntu-latest`
- **Java**: Temurin JDK 17
- **Flutter**: Pinned to version `3.32.8` (stable)
- **Android Gradle Plugin (AGP)**: `8.7.3`
- **Gradle Wrapper**: `8.11.1`
- **Kotlin**: `2.1.0`
- **Android SDK**: `minSdk 23`, `targetSdk 35`
- **Application ID**: `com.salman.mira`

### Triggering a Build
Push this repository or trigger the **Build Android Debug APK** workflow manually in the GitHub Actions tab. The resulting debug APK is uploaded as an artifact named `app-debug`.

---

## 🛡️ Privacy & Permissions

- **`RECORD_AUDIO`**: Used strictly for capturing microphone PCM stream while a voice session is active.
- **`INTERNET`**: Used exclusively to establish direct HTTPS / WebSocket connections with Google's Generative Language API.
- **100% Free**: No ads, no analytics, no third-party trackers, no subscription gates.
