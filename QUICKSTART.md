# 🚀 Quick Start Guide - Flutter Workflow

## ⚡ 5-Minute Setup

### Step 1: Install Flutter (if not already installed)
```bash
# Check if Flutter is installed
flutter --version

# If not installed, download from:
# https://flutter.dev/docs/get-started/install/windows
```

### Step 2: Setup Project
```bash
# Navigate to project directory
cd D:\hrms

# Install dependencies
flutter pub get
```

### Step 3: Run Application
```bash
# Run on Chrome (recommended)
flutter run -d chrome

# Or run on Windows Desktop
flutter run -d windows
```

### Step 4: Test Workflow Creation
1. Click "Create New Workflow"
2. Fill in name: "Test Workflow"
3. Fill in description: "My first workflow"
4. Select a stage from dropdown
5. Click nodes from palette to add them
6. Drag nodes to arrange
7. Click "Save Template"

## ✅ That's it! Your workflow system is running!

---

## 🔧 Troubleshooting

### Issue: "Flutter command not found"
**Solution**: Add Flutter to PATH or reinstall Flutter SDK

### Issue: "chrome not found"
**Solution**: 
```bash
flutter config --enable-web
flutter devices  # Check available devices
```

### Issue: "API connection failed"
**Solution**: 
1. Start Django backend: `python manage.py runserver`
2. Check API URL in `lib/services/workflow_api_service.dart`
3. Verify CORS is configured in Django

### Issue: "Dependencies error"
**Solution**:
```bash
flutter clean
flutter pub get
```

---

## 📱 Building for Production

### Web Build
```bash
flutter build web --release
# Output: build/web/
```

### Windows Build
```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

---

## 🎯 Quick Reference

### Project Structure
```
lib/
├── main.dart              # Start here
├── models/                # Data models
├── services/              # API calls
├── providers/             # State management
├── widgets/               # Reusable widgets
└── screens/               # Full screens
```

### Key Files
- **API Config**: `lib/services/workflow_api_service.dart` (line 4)
- **Main Screen**: `lib/screens/workflow_creation_screen.dart`
- **State**: `lib/providers/workflow_provider.dart`
- **Models**: `lib/models/*.dart`

### Commands
```bash
flutter run              # Run in debug mode
flutter run --release    # Run optimized
flutter build web        # Build for web
flutter test            # Run tests
flutter doctor          # Check setup
```

---

## 📚 Learn More

- **README.md** - Full documentation
- **IMPLEMENTATION_GUIDE.md** - Technical details
- **COMPLETE_SUMMARY.md** - Feature overview

---

**Need help?** Check the documentation files or contact the development team!

Happy coding! 🎉
