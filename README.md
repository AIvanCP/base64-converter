# Base64 Converter

A modern, cross-platform Base64 encoder and decoder application built with Flutter.

## Features

- Encode files to Base64 format
- Decode Base64 strings back to files
- Cross-platform support (Web, Android, iOS, Windows, macOS, Linux)
- Modern UI with animations and intuitive design
- Chunked processing support for large files
- Progress tracking for file processing
- File metadata preservation

## Web Version

The web version of this application allows users to:
- Upload files for Base64 encoding
- Paste Base64 strings for decoding
- Download decoded files directly from the browser

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.7.0)
- Dart SDK (>= 3.0.0)

### Installation

1. Clone this repository
```bash
git clone https://github.com/YOUR_USERNAME/base64-converter.git
```

2. Navigate to the project directory
```bash
cd base64-converter
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the application
```bash
flutter run
```

## Building for Web

To build the application for web deployment:

```bash
flutter build web --release
```

This will generate optimized web files in the `build/web` directory, which can be deployed to any web hosting service.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

