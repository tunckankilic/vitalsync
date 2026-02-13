# VitalSync

**VitalSync** is a comprehensive health and fitness management application built with Flutter, designed to provide users with a unified view of their well-being. It combines health tracking (medications, symptoms) with fitness monitoring (workouts, steps) to deliver intelligent, actionable insights.

# Key Features

- **Unified Dashboard**: A central hub displaying both health and fitness metrics with smart insights.
- **Glassmorphic UI**: A modern, visually stunning interface with frosted glass effects and dynamic Material You theming.
- **Context-Aware Navigation**: A smart Floating Action Button (FAB) that adapts to the current screen, offering quick actions like adding medication, logging symptoms, or starting a workout.
- **Real-Time Sync Status**: An intelligent sync indicator that shows connection status (Online, Offline, Syncing) with smooth animations.
- **Bottom Navigation**: A persistent, glassmorphic bottom navigation bar for easy switching between Dashboard, Health, and Fitness sections.
- **Smooth Animations**: Built-in Flutter animations for transitions, FAB expansion, and sync status indicators.

# Getting Started

# Prerequisites

- **Flutter**: Ensure you have Flutter installed and configured.
- **Android Studio / VS Code**: With Flutter and Dart plugins.
- **Physical Device**: Recommended for testing Material You dynamic colors and sensors.

# Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd vitalsync
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    flutter run
    ```

# Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod (ConsumerWidget, ConsumerStatefulWidget)
- **Navigation**: GoRouter (Declarative routing)
- **UI Components**:
    - Glassmorphism: BackdropFilter, Opacity, BorderRadius
    - Animations: AnimatedSlide, AnimatedBuilder, CurvedAnimation
    - Material You: dynamic_color package

# Project Structure

```
vitalsync/
├── lib/
│   ├── core/
│   │   ├── theme/              # Theme configuration
│   │   └── utils/              # Utility functions
│   ├── data/                   # Data layer (Models, Repositories, Providers)
│   ├── presentation/
│   │   ├── pages/              # Main screens (Dashboard, Health, Fitness)
│   │   ├── widgets/            # Reusable UI components
│   │   └── screens/            # App shell and navigation
│   └── main.dart               # App entry point
├── assets/
│   └── icons/                  # App icons
└── pubspec.yaml                # Dependencies and project configuration
```

# Design System

VitalSync follows a modern design system with:

- **Primary Colors**: Health (Green), Fitness (Red), Wellness (Blue)
- **Typography**: Roboto (Default Flutter font)
- **Iconography**: Material Icons (Rounded)
- **Visual Effects**: Frosted glass, subtle shadows, and smooth gradients.

# Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

# License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
