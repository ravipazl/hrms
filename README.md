# HRMS Workflow Management System - Web Application

This Flutter web application provides comprehensive workflow management and requisition management for healthcare organizations.

## 🚀 Quick Start

### 1. Prerequisites
- Flutter 3.7.2 or higher
- Django backend running on http://127.0.0.1:8000

### 2. Run the Application
```bash
# Easy setup (Windows)
run_requisition_app.bat

# Manual setup
flutter pub get
flutter run -d chrome
```

### 3. Access the System
- Home: http://localhost:port/
- Requisitions: http://localhost:port/requisition
- Workflow Builder: http://localhost:port/workflow-creation

## 🎯 Features

### ✅ Requisition Management (NEW)
- **Complete CRUD Operations**: Create, read, update, delete requisitions
- **Multi-Position Support**: Handle multiple positions in one requisition
- **File Upload**: Job description documents (PDF, DOC, images)
- **Advanced Form**: Dynamic cards, validation, skills management
- **API Integration**: Full Django backend integration
- **Search & Filter**: Advanced filtering and pagination
- **Status Tracking**: Real-time status updates

### ✅ Workflow Management (Existing)
- **Visual Workflow Designer**: Drag-and-drop workflow creation
- **Template Management**: Reusable workflow templates
- **Node-Based Design**: Approval and outcome nodes
- **Stage Management**: Different workflow stages
- **Employee Assignment**: Assign approvers to workflow steps

## 📁 Project Structure

```
lib/
├── main.dart                              # App entry & routing
├── models/
│   ├── requisition/requisition.dart      # 🆕 Requisition models
│   ├── workflow_node.dart                # Workflow models
│   ├── workflow_edge.dart
│   └── workflow_template.dart
├── providers/
│   ├── requisition_provider.dart         # 🆕 Requisition state
│   └── workflow_provider.dart            # Workflow state
├── screens/
│   ├── requisition_management_screen.dart # 🆕 Main dashboard
│   ├── requisition_list_screen.dart      # 🆕 Data table
│   ├── requisition_form_screen.dart      # 🆕 Form with upload
│   └── workflow_creation_screen.dart     # Workflow builder
├── services/
│   ├── requisition_api_service.dart      # 🆕 Requisition API
│   ├── workflow_api_service.dart         # Workflow API
│   └── employee_api_service.dart         # Employee API
└── widgets/
    ├── common/                            # 🆕 Reusable components
    ├── dialogs/
    └── workflow_canvas.dart
```

## 🔄 Workflow Management

### Creating Workflows
1. Navigate to `/workflow-creation`
2. Select workflow stage
3. Add approval and outcome nodes
4. Connect nodes with edges
5. Assign employees to approval nodes
6. Save template

### Workflow Features
- **Node Types**: Approval nodes and outcome nodes
- **Visual Editor**: Drag-and-drop interface
- **Employee Management**: Assign specific employees to nodes
- **Template System**: Save and reuse workflow templates
- **Stage Constraints**: Different node types per stage

## 📋 Requisition Management

### Creating Requisitions
1. Navigate to `/requisition` or `/reqfrom`
2. Fill in job position and department
3. Choose job description method (text or upload)
4. Add requisition cards for positions
5. Specify employee details for replacements
6. Add skills and qualifications
7. Submit to Django backend

### Requisition Features
- **Multi-Position Cards**: Handle multiple positions
- **File Upload**: Job description documents
- **Employee Information**: Replacement employee details
- **Skills Management**: Essential and desired skills
- **Status Tracking**: Pending, approved, rejected, etc.
- **Search & Filter**: Find requisitions quickly

## 🌐 API Integration

### Backend Endpoints
```
Base URL: http://127.0.0.1:8000/api

Workflow Endpoints:
- GET/POST /workflow/templates/
- GET/POST/PUT /workflow/stages/
- GET/POST /workflow/nodes/

Requisition Endpoints:
- GET/POST /requisition/
- GET/PUT/DELETE /requisition/{id}/
- PATCH /requisition/{id}/status/
- GET /reference-data/
```

### Data Flow
```
Flutter UI → Provider State → API Service → Django Backend
     ↑                                           ↓
User Actions ← UI Updates ← State Changes ← API Response
```

## 🎨 UI/UX Features

- **Material Design 3**: Modern, consistent UI
- **Responsive Design**: Works on all screen sizes
- **Dark/Light Theme**: Automatic theme switching
- **Loading States**: Progress indicators for async operations
- **Error Handling**: Graceful error messages and recovery
- **Form Validation**: Real-time validation feedback

## 🔧 Configuration

### Environment Setup
1. Ensure Django backend is running on port 8000
2. Update API URLs in service files if needed
3. Configure CORS settings in Django for cross-origin requests

### Development Mode
- Use `flutter run -d chrome` for hot reload
- Check browser console for detailed API logs
- Use Flutter DevTools for debugging

### Production Build
```bash
flutter build web --release
# Deploy contents of build/web/ to your web server
```

## 🧪 Testing

### Manual Test Checklist
- [ ] Workflow creation and editing
- [ ] Node addition and connection
- [ ] Employee assignment to nodes
- [ ] Requisition CRUD operations
- [ ] File upload functionality
- [ ] Multi-position card management
- [ ] Search and filtering
- [ ] API error handling
- [ ] Responsive design testing

## 🚨 Troubleshooting

### Common Issues
1. **API Connection**: Ensure Django is running on port 8000
2. **CORS Errors**: Check Django CORS settings
3. **File Upload**: Verify file size limits and formats
4. **Provider State**: Ensure providers are properly initialized

### Debug Information
- Check browser console for detailed error logs
- Use network tab to inspect API calls
- Verify Django backend logs for server-side issues

## 📱 Platform Support

- ✅ **Web** (Primary): Chrome, Firefox, Safari, Edge
- ⏳ **Desktop**: Windows, macOS, Linux (future)
- ⏳ **Mobile**: iOS, Android (future)

## 🔮 Roadmap

### Near-term Enhancements
- [ ] Authentication & authorization
- [ ] Real-time notifications
- [ ] Advanced reporting
- [ ] Email integration

### Long-term Goals
- [ ] Mobile app versions
- [ ] Offline support
- [ ] Advanced workflow analytics
- [ ] Integration with external systems

## 📄 Documentation

- **Requisition Guide**: See `REQUISITION_README.md`
- **Workflow Guide**: See existing workflow documentation
- **API Documentation**: Check Django backend docs

## 🤝 Contributing

1. Follow Flutter/Dart style guidelines
2. Test all new features thoroughly
3. Update documentation for new features
4. Ensure backward compatibility

## 🆘 Support

For technical support:
1. Check troubleshooting section
2. Review browser console errors
3. Verify Django backend status
4. Contact development team

---

**Built with Flutter & Django for SRMC Healthcare Management** 🏥
