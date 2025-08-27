# 🚀 Rishai - Flutter Fitness App

A modern Flutter fitness application with WHOOP integration for personalized health and nutrition tracking.

## 🔄 **WHOOP API Migration Status: 95% Complete**

### 📊 **Migration Progress**
- ✅ **Phase 1**: v2 Infrastructure Setup (100%)
- ✅ **Phase 2**: v2 Models Integration (100%) 
- ✅ **Phase 3**: Basic Functionality Testing (100%)
- ✅ **Phase 4**: Upper Layer Updates (95%)
- 🚧 **Phase 5**: Final Testing & Validation (Pending)
- 🚧 **Phase 6**: Production v2 Switch (Pending)

### 🎯 **What's Ready**
- v2 API models with UUID support
- Migration manager and feature flags
- Comprehensive logging and monitoring
- Backward compatibility maintained
- Rollback mechanisms ready

### 📚 **Migration Documentation**
- [Migration Guide](docs/whoop_api_migration.md)
- [Completion Guide](docs/whoop_migration_completion_guide.md)
- [Final Report](docs/whoop_migration_completion_report.md)

---

## 🏗️ **Project Structure**

```
lib/
├── core/                    # Core services and utilities
├── features/               # Feature modules
│   ├── whoop/             # WHOOP integration
│   │   ├── core/          # WHOOP core functionality
│   │   ├── data/          # Data layer (v1 + v2 models)
│   │   ├── domain/        # Business logic
│   │   └── presentation/  # UI components
│   ├── user/              # User management
│   └── chat/              # Chat functionality
└── main.dart              # App entry point
```

## 🚀 **Getting Started**

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- WHOOP API credentials

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd rishai

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### WHOOP API Configuration
```dart
// lib/features/whoop/core/config/whoop_api_config.dart
class WhoopApiConfig {
  // Enable v2 API for testing
  static const bool _enableV2Api = true;
  
  // Force v2 API for production
  static const bool _forceV2Api = false;
}
```

## 🔧 **Development**

### Running Tests
```bash
# Run all tests
flutter test

# Run WHOOP specific tests
flutter test test/whoop_v2_models_test.dart
```

### Code Analysis
```bash
# Analyze code
flutter analyze

# Analyze WHOOP module only
flutter analyze lib/features/whoop/
```

## 📱 **Features**

- **WHOOP Integration**: Real-time health data from WHOOP devices
- **Personalized Nutrition**: AI-powered meal planning and macro tracking
- **Health Metrics**: Comprehensive health and fitness tracking
- **User Management**: Secure user authentication and profile management
- **Chat Interface**: Interactive chat for nutrition guidance

## 🌟 **WHOOP API v2 Benefits**

- **UUID Support**: Modern ID format for better scalability
- **Enhanced Data Structure**: Improved data models and relationships
- **Better Performance**: Optimized API responses and caching
- **Future-Proof**: Ready for upcoming WHOOP features

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 **License**

This project is proprietary software. All rights reserved.

---

## 🆘 **Support**

For WHOOP API migration questions:
1. Check the migration documentation
2. Review logs with prefix: `WHOOP API v2 Migration:`
3. Use the migration manager: `whoopMigrationManager.getMigrationInfo()`
4. Contact the development team

**Ready to complete the WHOOP API v2 migration! 🚀**
