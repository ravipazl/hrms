# HRMS Workflow Management - Flutter Implementation

## 📋 Overview

This is a Flutter web implementation of the SRMC Requisition Workflow system, specifically focusing on workflow creation, editing, and execution features.

## 🏗️ Architecture

### Models (`lib/models/`)
- **workflow_node.dart** - Node model representing approval or outcome steps
- **workflow_edge.dart** - Edge model representing connections between nodes
- **workflow_template.dart** - Complete workflow template with stages and constraints

### Services (`lib/services/`)
- **workflow_api_service.dart** - REST API client for Django backend
  - Load stages, nodes, and constraints
  - Save and load workflow templates
  - Transform between database and UI formats

### Providers (`lib/providers/`)
- **workflow_provider.dart** - State management using Provider pattern
  - Manages workflow template state
  - Handles node/edge CRUD operations
  - Connection mode management
  - API integration

### Widgets (`lib/widgets/`)
- **workflow_canvas.dart** - Visual workflow canvas
  - Drag-and-drop node positioning
  - Edge rendering with arrows and labels
  - Grid background
  - Connection visualization

### Screens (`lib/screens/`)
- **workflow_creation_screen.dart** - Main workflow builder screen
  - Template information form
  - Node palette
  - Canvas interaction
  - Save/Edit/View modes

## 🚀 Features Implemented

### ✅ Core Features
1. **Workflow Creation**
   - Visual drag-and-drop interface
   - Dynamic node addition from palette
   - Stage-based node constraints
   - Auto-add required nodes

2. **Workflow Editing**
   - Load existing templates
   - Modify nodes and connections
   - Update template information
   - Save changes to backend

3. **Node Management**
   - Approval nodes (Process type)
   - Outcome nodes (Stop type)
   - Node validation against constraints
   - Employee assignment capability

4. **Connection Management**
   - Visual connection mode
   - Click-to-connect interface
   - Edge labels and conditions
   - Flow start/end detection

5. **Stage Management**
   - Load stages from database
   - Stage-specific node constraints
   - Stage change warnings
   - Auto-clear on stage change

6. **API Integration**
   - Full REST API integration with Django backend
   - Save workflow templates
   - Load templates for editing
   - Stage and node data loading

## 📦 Dependencies

```yaml
dependencies:
  flutter: sdk
  http: ^1.2.0           # HTTP client
  dio: ^5.4.0            # Advanced HTTP client
  provider: ^6.1.1       # State management
  flutter_svg: ^2.0.9    # SVG support
  uuid: ^4.3.3           # UUID generation
  intl: ^0.19.0          # Internationalization
```

## 🔧 Setup Instructions

### 1. Install Dependencies
```bash
cd D:\hrms
flutter pub get
```

### 2. Configure API Endpoint
Update the `baseUrl` in `lib/services/workflow_api_service.dart`:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

### 3. Run the Application
```bash
# For web
flutter run -d chrome

# For Windows
flutter run -d windows

# For development with hot reload
flutter run
```

## 📱 Usage

### Creating a New Workflow
1. Click "Create New Workflow" button
2. Fill in template name and description
3. Select workflow stage
4. Add nodes from the palette
5. Create connections between nodes
6. Click "Save Template"

### Editing Existing Workflow
1. Navigate with templateId parameter
2. Make desired changes
3. Click "Save Template"

### Viewing Workflow
1. Open in view mode
2. Canvas is read-only
3. Can view all nodes and connections

## 🎨 UI Components

### Workflow Canvas
- **Grid Background**: 40px grid for alignment
- **Node Dimensions**: 200px × 80px
- **Node Types**:
  - Approval: Blue (Process nodes)
  - Outcome: Green/Yellow/Red (Stop nodes)
- **Edges**: Straight lines with arrow heads and labels

### Node Palette
- Shows available nodes for selected stage
- Displays current count / max count
- Disabled when max count reached
- Color-coded by availability

### Node Properties
- Label/Title
- Assigned employee
- Department
- Step order
- Comments
- Outcome type (for Stop nodes)

## 🔄 Workflow Execution Flow

### 1. Template Creation
```
User Input → WorkflowProvider → API Service → Django Backend
```

### 2. Node Addition
```
Click Palette → Validate Constraints → Add to Canvas → Update State
```

### 3. Connection Creation
```
Click Source Node → Enter Connection Mode → Click Target Node → Create Edge
```

### 4. Template Save
```
Validate Template → Transform to API Format → POST to Backend → Save Layout
```

## 🗄️ Data Flow

### Template Structure
```dart
WorkflowTemplate {
  id, name, description,
  stage, selectedStage,
  department, isGlobalDefault,
  nodes: [WorkflowNode],
  edges: [WorkflowEdge],
  metadata
}
```

### Node Structure
```dart
WorkflowNode {
  id, type, position,
  data: {
    label, title, color,
    dbNodeId, nodeType,
    employee info,
    outcome
  }
}
```

### Edge Structure
```dart
WorkflowEdge {
  id, source, target,
  label, type,
  data: { condition },
  isStart, isEnd
}
```

## 🔐 API Endpoints Used

### Stages
- `GET /api/workflow/stages/` - Load all stages

### Nodes
- `GET /api/workflow/nodes/` - Load available node types
- `GET /api/workflow/stage-nodes/?stage={id}` - Load stage constraints

### Templates
- `GET /api/workflow/templates/` - List templates
- `GET /api/workflow/templates/{id}/` - Get single template
- `POST /api/workflow/templates/` - Create template
- `PUT /api/workflow/templates/{id}/` - Update template
- `POST /api/workflow/templates/{id}/save_layout/` - Save nodes/edges

## 🎯 Key Differences from React Implementation

### 1. State Management
- **React**: useState, useEffect hooks
- **Flutter**: Provider pattern with ChangeNotifier

### 2. UI Framework
- **React**: HTML/CSS with Tailwind
- **Flutter**: Widget-based with Material Design

### 3. Rendering
- **React**: Virtual DOM
- **Flutter**: Widget tree with direct rendering

### 4. Drag & Drop
- **React**: @dnd-kit library
- **Flutter**: GestureDetector with manual position tracking

### 5. Canvas Drawing
- **React**: SVG or Canvas API
- **Flutter**: CustomPaint with Canvas API

## 🐛 Known Limitations

1. **Grid Pattern**: Currently using a simple background, needs grid asset
2. **Connection Line**: Dynamic connection line while dragging not yet implemented
3. **Multi-selection**: Not yet implemented (Ctrl+Click)
4. **Undo/Redo**: Not implemented
5. **Zoom/Pan**: Canvas zoom and pan not yet added
6. **Employee Picker**: Employee selection UI needs enhancement

## 🔮 Future Enhancements

### Planned Features
1. **Advanced Canvas Controls**
   - Zoom in/out
   - Pan/scroll
   - Mini-map
   - Fit to screen

2. **Enhanced Node Editing**
   - Rich text editor for comments
   - Employee search and selection
   - Department picker
   - Validation rules

3. **Connection Improvements**
   - Curved edges
   - Multiple connection paths
   - Connection labels editor
   - Conditional routing

4. **Workflow Execution**
   - Real-time status updates
   - Execution history
   - Approval actions
   - Notifications

5. **Template Management**
   - Template library
   - Template categories
   - Search and filter
   - Template duplication

6. **Collaboration**
   - Multi-user editing
   - Comments and annotations
   - Version control
   - Change history

## 📝 Code Structure Best Practices

### Models
- Immutable data classes
- JSON serialization
- copyWith methods for updates

### Services
- Async/await for API calls
- Error handling
- Response transformation

### Providers
- ChangeNotifier for state updates
- Computed getters
- Action methods

### Widgets
- Stateless where possible
- Composition over inheritance
- Const constructors for performance

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widgets/
```

### Integration Tests
```bash
flutter test integration_test/
```

## 📚 Resources

### Flutter Documentation
- [Flutter Web](https://flutter.dev/web)
- [Provider Package](https://pub.dev/packages/provider)
- [Custom Paint](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)

### API Documentation
- Django REST Framework endpoints
- Workflow database schema
- Authentication methods

## 🤝 Contributing

1. Follow Flutter style guide
2. Write tests for new features
3. Update documentation
4. Use meaningful commit messages

## 📄 License

Part of SRMC HRMS System

## 👥 Team

Developed by HRMS Development Team

---

**Status**: ✅ Core workflow creation and editing implemented
**Next Steps**: Workflow execution and approval features
