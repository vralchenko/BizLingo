# BizLingo AI 🚀

**BizLingo AI** is an intelligent application for mastering professional business
English. It utilizes local neural networks to evaluate not just the text accuracy,
but the semantic depth of your translations. It combines strict verification
with the flexibility of real-world communication.

## ✨ Key Features

* **Semantic AI Validation**: Uses the local Llama-3.2-1B model (via WebLLM)
  to analyze the semantics of your translation. If you use
  a synonym, the AI confirms correctness and explains the context.
* **Two-Level Verification**: The system first performs an instant string
  comparison with the master target in the code, only engaging the AI if no
  direct match is found.
* **Universal Storage (Cross-Platform)**: Uses `shared_preferences` to ensure
  your progress (streaks, learned phrases) is saved in the browser (LocalStorage)
  and on Android.
* **Voice Integration (TTS)**: Automatic high-quality pronunciation of correct
  answers in the target language to train listening and speaking.
* **Smart Flow Management**: For exact matches, the app advances to the next
  phrase automatically after 2.5 seconds. For semantic matches,
  it waits for you to click "NEXT" so you can read the AI feedback.



## 🛠 Tech Stack

* **Flutter & Dart**: The core application engine.
* **WebLLM (MLC-AI)**: To run neural networks directly in the browser without
  external API dependencies.
* **SharedPreferences**: For persistent cross-platform local data storage.
* **Flutter TTS**: Synthesis for high-impact auditory learning.
* **JSON Assets**: External storage for a library of thousands of professional
  business phrases.

## 🚀 Getting Started

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Generate icons and splash screen:**
    ```bash
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
    ```

3.  **Run the application (Web/Chrome):**
    ```bash
    flutter run -d chrome --web-renderer canvaskit
    ```
    *Note: On first run, the browser will download the AI model (~800MB)
    into the local cache.*

## 📱 Build Instructions (Android)

To generate a production-ready APK for Android:
```bash
flutter build apk --release
```

## 🛠 Troubleshooting

* **Model Loading Stuck**: Ensure your browser supports WebGPU or WebAssembly. 
  Check the browser console (F12) for any "Out of memory" or "CORS" errors 
  related to the model download.
* **No Sound**: On some browsers, text-to-speech requires a user interaction 
  (like a click) before it can play audio. Ensure your system volume is 
  on and the correct language pack is installed.
* **RangeError (index 0)**: This usually indicates that the `phrases.json` 
  file is missing, empty, or formatted incorrectly. Verify the file path 
  in `pubspec.yaml`.
* **SharedPrefs Persistence**: If your progress disappears in Web, ensure 
  you are not using "Incognito/Private" mode, which clears LocalStorage 
  after the session.

© 2025-2026 Viktor Ralchenko. All rights reserved.