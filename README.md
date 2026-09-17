# City Search App

A simple Flutter application that provides **real-time city search with autocomplete suggestions** using an API.

## Features

* 🔍 Search cities by typing
* ⚡ Debounced API requests
* 📍 City autocomplete suggestions
* ✨ Floating autocomplete dropdown
* ❌ Clear search button
* ⏳ Loading indicator
* ⚠️ Error handling
* Empty search result message
* 🌆 Popular city cards
* 🖼️ City images
* 👉 Select a city from suggestions
* 📱 Responsive UI
* 📌 Fixed current location: Bengaluru, India

## Technologies Used

* Flutter
* Dart
* HTTP package
* REST API

## Project Structure

```text
city_search_app/
│
├── assets/
│   └── cities/
│       ├── bangalore.jpg
│       ├── bandung.jpg
│       ├── bangkok.jpg
│       ├── banff.jpg
│       ├── dubai.jpg
│       ├── london.jpg
│       ├── paris.png
│       ├── singapore.jpg
│       ├── sydney.jpg
│       └── tokyo.jpg
│
├── lib/
│   └── main.dart
│
├── pubspec.yaml
└── README.md
```

## How to Run

### 1. Get the project

```bash
git clone <your-github-repository-url>
cd city_search_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

```bash
flutter run
```

For Windows:

```bash
flutter run -d windows
```

## How It Works

1. User enters a city name in the search field.
2. The app waits for **500 milliseconds** using debounce.
3. The API is called with the entered text.
4. Related cities are displayed in a floating autocomplete dropdown.
5. User selects a city.
6. The selected city is displayed as a city card.
7. Clicking the clear button resets the search and displays the popular cities again.

