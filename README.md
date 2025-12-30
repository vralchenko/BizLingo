# BizLingo 🚀

**BizLingo** is a mobile application designed for professionals to master Essential Business English. It focuses on 100 high-impact business phrases using a smart repetition system and active recall through typing practice.

## ✨ Key Features
* **Buffer-Based Learning**: Focus on 5 phrases at a time. A new phrase enters the "learning zone" only after one of the current phrases is fully mastered.
* **Mastery System**: Phrases are moved to the "Learned" category only after 3 consecutive correct translations.
* **Smart Randomization**: Phrases within the active buffer are shuffled randomly, ensuring you never get the same phrase twice in a row.
* **Voice Integration (TTS)**: Automatic English pronunciation upon correct answers to improve listening and speaking skills.
* **Progress Persistence**: Your learning history, error counts, and streaks are saved locally and persist after app restarts.
* **Detailed Statistics**: A dedicated dashboard to track mastery and errors for every phrase in the 100-word library.

## 🛠 Tech Stack
* **Flutter & Dart**
* **shared_preferences**: For persistent local data storage.
* **flutter_tts**: For high-quality text-to-speech synthesis.
* **JSON Serialization**: For structured data management.

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/bizlingo.git](https://github.com/yourusername/bizlingo.git)
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    Ensure you have an emulator running or a physical device connected.
    ```bash
    flutter run
    ```

## 📱 Build Instructions

To generate a production-ready APK for Android:
```bash
flutter build apk --split-per-abi