# Flutter HRMS Requisition Management System

A complete Flutter web application for managing recruitment requisitions with workflow management, built to work with the existing Django backend.

## 🚀 Features

### ✅ Implemented Features

- **Complete Requisition Management**
  - Create, read, update, delete requisitions
  - Multi-position support (new hire vs replacement)
  - Dynamic skills management (essential/desired)
  - File upload for job descriptions
  - Form validation and error handling

- **Advanced Form Handling**
  - Multi-card requisition support
  - Dynamic employee information for replacements
  - File upload with preview
  - Real-time validation

- **Data Management**
  - Full CRUD operations via Django API
  - Reference data loading (departments, genders, etc.)
  - Pagination and filtering
  - Search functionality

- **User Interface**
  - Material Design 3 components
  - Responsive design
  - Dark/light theme support
  - Professional healthcare UI

- **API Integration**
  - RESTful API with Django backend
  - File upload support
  - Error handling and retry logic
  - Connection testing

## 🏗️ Architecture

```
lib/
├── main.dart                              # App entry point with routing
├── models/
│   ├── requisition/
│   │   └── requisition.dart              # Requisition data models
│   ├── workflow_node.dart                # Workflow models (existing)
│   ├── workflow_edge.dart
│   └── workflow_template.dart
├── providers/
│   ├── requisition_provider.dart         # Requisition state management
│   └── workflow_provider.dart            # Workflow state (existing)
├── screens/
│   ├── requisition_management_screen.dart # Main dashboard with tabs
│   ├── requisition_list_screen.dart      # Data table with CRUD
│   ├── requisition_form_screen.dart      # Complex form with file upload
│   └── workflow_creation_screen.dart     # Workflow builder (existing)
├── services/
│   ├── requisition_api_service.dart      # API service layer
│   ├── workflow_api_service.dart         # Workflow API (existing)
│   └── employee_api_service.dart         # Employee API (existing)
└── widgets/
    └── (reusable components as needed)
```

## 📋 API Endpoints Used

The Flutter app connects to the same Django backend endpoints:

```
Base URL: http://127.0.0.1:8000/api

Requisition Endpoints:
GET    /requisition/              # List requisitions
POST   /requisition/              # Create requisition
GET    /requisition/{id}/         # Get specific requisition
PUT    /requisition/{id}/         # Update requisition
DELETE /requisition/{id}/         # Delete requisition
PATCH  /requisition/{id}/status/  # Update status

Reference Data:
GET    /reference-data/?reference_type={id}  # Dropdown data
```

## 🔧 Setup Instructions

### 1. Prerequisites

- Flutter 3.7.2 or higher
- Dart SDK
- Django backend running on http://127.0.0.1:8000

### 2. Install Dependencies

```bash
cd D:\hrms_final\hrms
flutter pub get
```

### 3. Verify Dependencies

The following packages are required (already added to `pubspec.yaml`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1      # State management
  http: ^1.2.0          # HTTP requests
  dio: ^5.4.0           # Advanced HTTP client
  file_picker: ^8.0.0   # File upload
  shared_preferences: ^2.2.2  # Local storage
  url_strategy: ^0.2.0  # Web URL handling
  intl: ^0.19.0         # Date formatting
  uuid: ^4.3.3          # ID generation
```

### 4. Run the Application

```bash
# For web development
flutter run -d chrome

# For production web build
flutter build web
```

### 5. Backend Setup

Ensure your Django backend is running:

```bash
cd D:\hrms_final\srmc_requisition_workflow
python manage.py runserver
```

## 🎯 Usage Guide

### Main Features

1. **Dashboard Navigation**
   - Navigate to `/` for home screen
   - Navigate to `/requisition` for full management dashboard
   - Navigate to `/list` for requisitions list
   - Navigate to `/reqfrom` for requisition form

2. **Creating Requisitions**
   - Use the "New Requisition" button
   - Fill in job position and department
   - Choose between text description or file upload
   - Add requisition cards for different positions
   - Specify skills and qualifications
   - Submit to Django backend

3. **Managing Requisitions**
   - View, edit, and delete requisitions
   - Filter by department, status, or search terms
   - Paginated results for large datasets
   - Real-time status updates

4. **File Handling**
   - Upload job description documents (PDF, DOC, images)
   - File size validation (5MB limit)
   - Preview existing files
   - Support for both text and file descriptions

## 🔄 Data Flow

```
Flutter UI → Provider (State) → API Service → Django Backend
     ↑                                              ↓
User Interaction ← UI Updates ← State Updates ← API Response
```

### State Management Pattern

- **RequisitionProvider**: Manages all requisition-related state
- **API Service**: Handles HTTP communication with Django
- **Models**: Type-safe data structures with JSON serialization
- **Screens**: UI components that consume provider state

## 🔧 Configuration

### API Configuration

Update the API base URL in `lib/services/requisition_api_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

### Web Configuration

For production deployment, update `web/index.html` with your domain.

## 🧪 Testing

### Manual Testing Checklist

- [ ] Create new requisition with text description
- [ ] Create requisition with file upload
- [ ] Edit existing requisition
- [ ] Delete requisition with confirmation
- [ ] Test form validation
- [ ] Test file upload (PDF, DOC, images)
- [ ] Test multi-position cards
- [ ] Test replacement employee information
- [ ] Test search and filtering
- [ ] Test pagination
- [ ] Verify API error handling
- [ ] Test responsive design

### API Connection Testing

Use the "Test API" button in the UI or check browser developer console for API call logs.

## 🚨 Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Ensure Django backend is running on port 8000
   - Check CORS settings in Django
   - Verify API URLs match backend endpoints

2. **File Upload Issues**
   - Check file size (max 5MB)
   - Verify supported formats: PDF, DOC, DOCX, JPG, PNG
   - Ensure Django handles multipart/form-data

3. **Provider State Issues**
   - Check provider initialization in main.dart
   - Verify provider is wrapped around necessary widgets
   - Check for proper state updates with notifyListeners()

4. **Routing Issues**
   - Verify route definitions in main.dart
   - Check URL strategy for web deployment
   - Ensure MaterialPageRoute configurations

### Debug Mode

Enable detailed logging by checking browser console when running in debug mode.

## 🔮 Future Enhancements

### Potential Additions

1. **Authentication & Authorization**
   - User login/logout
   - Role-based permissions
   - JWT token handling

2. **Advanced Features**
   - Real-time notifications
   - Email integration
   - Advanced reporting
   - Export functionality

3. **Mobile Support**
   - iOS and Android builds
   - Mobile-specific UI optimizations
   - Offline support

4. **Integration Features**
   - Calendar integration
   - Document management
   - Advanced workflow designer

## 📱 Platform Support

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Windows Desktop (future)
- ✅ macOS Desktop (future)
- ✅ iOS Mobile (future)
- ✅ Android Mobile (future)

## 🤝 Development Guidelines

### Code Structure

- Follow Flutter/Dart style guidelines
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Maintain consistent file organization

### API Integration

- Always handle API errors gracefully
- Provide user feedback for all operations
- Validate data before sending to backend
- Use proper HTTP status code handling

### UI/UX Guidelines

- Follow Material Design principles
- Ensure responsive design for all screen sizes
- Provide loading states for async operations
- Use consistent color schemes and typography

## 📄 License

This project is part of SRMC Horilla healthcare management system.

## 🆘 Support

For technical support or feature requests:
1. Check the troubleshooting section above
2. Review browser console for errors
3. Verify Django backend is properly configured
4. Contact the development team for advanced issues

---

**Built with Flutter for the SRMC Healthcare Management System** 🏥
