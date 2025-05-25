# Visual Impaired Assistant App

A Flutter application designed to assist visually impaired users with navigation and obstacle detection.

## Features

### Navigation Assistance
- Real-time location tracking
- Obstacle detection and alerts
- Voice-guided navigation
- Haptic feedback for obstacles
- Map visualization with current location

### Accessibility Features
- Voice commands for hands-free operation
- Text-to-speech feedback
- Vibration alerts
- Screen reader support
- High contrast UI elements

### User Management
- Secure authentication
- User profiles
- Role-based access control
- Session management
- Notification preferences

## Getting Started

### Prerequisites
- Flutter SDK (>=3.1.5)
- Dart SDK (>=3.1.5)
- Firebase account
- Android Studio / Xcode (for platform-specific development)

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/           # Data models
├── providers/        # State management
├── screens/          # UI screens
├── services/         # Business logic
├── utils/            # Utility functions
└── widgets/          # Reusable UI components
```

## Voice Commands

The app supports the following voice commands:
- "Start navigation" - Begins navigation mode
- "Stop navigation" - Ends navigation mode
- "Where am I" - Announces current location
- "Help" - Lists available commands

## Error Handling

The app includes comprehensive error handling for:
- Location services
- Network connectivity
- Firebase operations
- Voice recognition
- Text-to-speech

## Accessibility Guidelines

The app follows these accessibility best practices:
- WCAG 2.1 compliance
- Screen reader optimization
- High contrast mode support
- Adjustable text sizes
- Voice feedback customization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- OpenStreetMap for map data
- The accessibility community for valuable feedback
