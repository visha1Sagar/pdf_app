# PDF Dictionary Reader

A Flutter application that allows users to upload a PDF, read it, click on any word to see its definition, and save words to a local vocabulary list.

## Features

- **PDF Upload:** Open any PDF file from your device.
- **Text Extraction:** Extracts text from the PDF for interactive reading.
- **Instant Dictionary:** Click on any word to fetch its definition from the Free Dictionary API.
- **Vocabulary List:** Save words and definitions to a local database (Isar) for later review.

## Getting Started

### Prerequisites

- Flutter SDK installed.
- Android Studio or VS Code with Flutter extensions.

### Installation

1.  **Get Dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Generate Database Code:**
    This project uses `Isar` for the local database, which requires code generation. Run the following command:
    ```bash
    flutter pub run build_runner build
    ```

3.  **Run the App:**
    ```bash
    flutter run
    ```

## Tech Stack

-   **Framework:** Flutter
-   **PDF Extraction:** `syncfusion_flutter_pdf`
-   **Database:** `isar` (NoSQL)
-   **Networking:** `http`
-   **State Management:** `provider`
