# Drivy - Device Space Analyzer

Drivy is a utility to analyze the storage space on your device. It helps you to understand what is taking up space and to manage your files and folders effectively.

## Features

* **Detailed Space Analysis:** Get a comprehensive overview of your device's storage usage with detailed statistics for every folder and file type.
* **Interactive Visual Treemaps:** Navigate your storage visually. Larger files and folders appear as larger rectangles, making it easy to spot what's consuming the most space.
* **Duplicate File Finder:** Scan your drives to find and safely remove duplicate files, freeing up valuable space.
* **Largest Files & Folders Identification:** Quickly list the top 100 largest files and folders on your device to target for cleanup.

## Supported Platforms

This application is designed to be cross-platform. Based on the technologies used (Dart/Flutter for the UI, C++ for the core engine, Swift/Java for native integrations), the supported platforms are:

* **Windows:** Supported
* **macOS:** Supported
* **Linux:** Supported
* **Android:** Supported
* **iOS:** Supported

## Installation

Currently, Drivy is available by building it directly from the source code. Non ci sono ancora pacchetti di installazione pre-compilati. Per le istruzioni, fai riferimento alla sezione "Building from source".

## Usage

1.  **Launch the Drivy application.**
2.  **Select a Drive or Folder:** Choose the storage drive or specific folder you wish to analyze.
3.  **Start Scan:** The application will perform a high-speed scan of the selected path.
4.  **Explore Results:** Once the scan is complete, you can navigate the interactive treemap to explore your data.
5.  **Clean Up:** Use the built-in tools like the "Duplicate Finder" to manage and delete unnecessary files.

## Building from source

To compile the project, you need a development environment configured for Flutter with support for native C++ compilation.

**Prerequisites:**

* **Flutter SDK:** Version 3.0 or higher.
* **C++ Compiler:**
    * Windows: Visual Studio with "Desktop development with C++" workload.
    * macOS: Xcode Command Line Tools.
    * Linux: `build-essential` package (or equivalent).
* **CMake:** Version 3.16 or higher.
* **Git:** For cloning the repository.

**Steps:**

1.  Clone the repository:
    ```sh
    git clone [https://github.com/evemilano/drivy.git](https://github.com/evemilano/drivy.git)
    ```

2.  Navigate to the project directory:
    ```sh
    cd drivy
    ```

3.  Get Flutter dependencies:
    ```sh
    flutter pub get
    ```

4.  Build and run the application:
    ```sh
    flutter run
    ```

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## License

This project is released under a proprietary license.

Copyright (c) 2025 Giovanni Sacheli (evemilano)

All rights reserved. The use, reproduction, modification, distribution, or sublicensing of this software, in whole or in part, is strictly prohibited without the prior express written permission of the copyright holder.

For licensing inquiries, please contact the author.
