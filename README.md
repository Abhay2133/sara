# Sara: Local AI Assistant

Sara is a modern, Flutter-based personal AI assistant that runs Google's Gemma models entirely on-device. Designed with privacy and performance in mind, Sara offers a sleek dark-themed interface with advanced capabilities like local LLM inference and function calling (tool use).

## 🚀 Key Features

-   **Local Inference:** Run Gemma models (2b, 7b) directly on your device using `flutter_gemma`. No internet required for chat.
-   **Tool Calling (Function Calling):** The AI can interact with your device to perform real-world actions:
    -   🔋 **Battery Status:** Check current battery level and charging state.
    -   🔦 **Flashlight Control:** Toggle the device flashlight on and off.
    -   🕒 **System Time:** Get the current system time and date.
-   **Model Management:**
    -   Download pre-configured models from HuggingFace.
    -   Load custom `.litertlm` and `.bin` model files from local storage.
    -   Persistent configuration for seamless model switching.
-   **Modern UI/UX:**
    -   Sleek dark theme with glassmorphism effects.
    -   Markdown support for rich AI responses using `flutter_markdown_plus`.
    -   Smooth animations with Lottie.
    -   Responsive chat interface with multi-line input support.

## 🛠️ Technology Stack

-   **Frontend:** [Flutter](https://flutter.dev) (v3.11.5+)
-   **State Management:** [Riverpod](https://riverpod.dev)
-   **LLM Engine:** [Gemma](https://github.com/google-deepmind/gemma) via `flutter_gemma`
-   **UI Components:** Material 3, Google Fonts, Lottie
-   **Device Integration:** `battery_plus`, `torch_light`

## 📂 Project Architecture

The project follows a clean, layered architecture:

-   `lib/services/`: Core logic for LLM management (`gemma_service.dart`) and configuration (`model_config_service.dart`).
-   `lib/ui/`: UI components, including the main `chat_screen.dart` and centralized `theme.dart`.
-   `lib/models/`: Data structures for model configurations and tool definitions.
-   `lib/main.dart`: Application entry point and provider initialization.

## 🚦 Getting Started

### Prerequisites

-   Flutter SDK (^3.11.5)
-   Android Studio / VS Code with Flutter extensions.
-   A device with sufficient RAM (at least 4GB recommended for Gemma 2b).

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/your-username/sara.git
    cd sara
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```

### Running the App

```bash
flutter run
```

## 🧪 Testing & Quality

-   **Unit Tests:** `flutter test`
-   **Integration Tests:** `flutter drive --target=integration_test/gemma_service_android_test.dart`
-   **Linting:** `flutter analyze`

## 📄 License

This project is private and for internal use.
