# Frontend Móvil - Control de Gastos

Aplicación móvil desarrollada en Flutter para el Sistema de Control de Gastos Personales.

## Prerrequisitos

- Flutter SDK >= 3.0
- Dart >= 3.0
- Android Studio / VS Code

## Instalación Local (Windows)

```powershell
flutter pub get
```

Configurar URL de la API en `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
// static const String _baseUrl = 'http://localhost:8000/api'; // iOS Simulator
```

```powershell
flutter run
```

## Generar AAB para Google Play

```powershell
flutter build appbundle
```

El archivo se generará en `build\app\outputs\bundle\release\app-release.aab`.
