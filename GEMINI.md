# Project: Sara AI Assistant

Sara is a modern Flutter-based personal AI assistant that runs Google's Gemma models locally on the device. It features a sleek, dark-themed UI with glassmorphism effects and supports advanced capabilities like local LLM inference and function calling (tools).

## Project Overview

- **Purpose:** To provide a private, local AI assistant experience using Google's Gemma models.
- **Main Technologies:**
  - **Flutter:** UI and cross-platform framework.
  - **Gemma (flutter_gemma):** Local LLM inference using `.litertlm` and `.bin` model files.
  - **Riverpod:** State management and dependency injection.
  - **Material 3:** Modern design system with custom dark theme.
  - **Markdown:** AI responses are rendered using `flutter_markdown_plus`.
  - **Device Integration:** Uses `battery_plus` and `torch_light` for tool-calling functionality.

## Architecture

The project follows a standard Flutter architectural pattern, organized by layer:

- `lib/main.dart`: The entry point of the application, initializing the `ProviderScope`.
- `lib/ui/`: Contains the user interface components.
  - `chat_screen.dart`: The primary interface for AI interaction and model configuration.
  - `theme.dart`: Centralized theme definitions (Dark Mode).
- `lib/services/`: Core business logic and external integrations.
  - `gemma_service.dart`: Manages model initialization, chat sessions, and tool-calling execution.
  - `model_config_service.dart`: Handles persistence of model settings and local file paths.
- `lib/models/`: Data models and definitions.
  - `model_config.dart`: Defines the structure for model metadata and configuration.
  - `tool_definitions.dart`: Lists the tools available for the AI to call (e.g., battery, flashlight).

## Key Features

- **Local Inference:** Runs Gemma models directly on-device for privacy and offline capability.
- **Tool Calling (Function Calling):** The AI can interact with the device to:
  - Check battery levels.
  - Tell the current system time.
  - Control the flashlight (on/off).
- **Model Management:**
  - Download pre-configured models from HuggingFace.
  - Select local model files from device storage.
  - Persistent JSON configuration (`model_config.json`).
- **Interactive UI:** Supports multi-line input, Enter-to-send (with Shift+Enter for new lines), and auto-scrolling chat history.

## Building and Running

### Prerequisites
- Flutter SDK (version ^3.11.5)
- Android/Windows development environment.

### Commands
- **Install Dependencies:** `flutter pub get`
- **Run Application:** `flutter run`
- **Linting:** `flutter analyze`
- **Unit/Widget Tests:** `flutter test`
- **Integration Tests:** `flutter drive --target=integration_test/gemma_service_android_test.dart`

## Development Conventions

- **State Management:** Always use Riverpod providers for logic that needs to be shared or tested.
- **Async Logic:** Long-running tasks like model downloading or initialization should provide progress updates and handle errors gracefully in the UI.
- **Linting:** Adheres to the rules defined in `analysis_options.yaml` (based on `flutter_lints`).
- **Tool Definitions:** When adding new capabilities for the AI, update `lib/models/tool_definitions.dart` and the `_handleToolCall` logic in `chat_screen.dart`.
