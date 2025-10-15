import 'package:flutter/material.dart';
import 'package:hrms/models/requisition.dart';
import 'package:hrms/providers/requisition_provider.dart';
import 'package:hrms/screens/requisition_form_screen.dart';
import 'package:hrms/screens/requisition_view_screen.dart';
import 'package:hrms/screens/approval_action_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:html' as html;
import 'providers/workflow_provider.dart';
import 'providers/form_builder_provider.dart';
import 'providers/template_list_provider.dart';
import 'screens/workflow_creation_screen.dart';
import 'screens/form_builder/form_list_screen.dart';
// import 'screens/home_screen.dart';
import 'screens/form_builder/form_builder_screen.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildErrorScreen(String title, String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  html.window.location.href =
                      'http://127.0.0.1:8000/workflow/templates/';
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Templates'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkflowProvider()),
        ChangeNotifierProvider(create: (_) => RequisitionProvider()),
        ChangeNotifierProvider(create: (_) => FormBuilderProvider()),
      ],
      child: MaterialApp(
        title: 'HRMS Workflow Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: MaterialStateProperty.all(true),
            thickness: MaterialStateProperty.all(8),
            radius: const Radius.circular(4),
          ),
        ),
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          final path = uri.path.replaceAll(RegExp(r'/$'), '');
          final queryParams = uri.queryParameters;
          final templateId = int.tryParse(queryParams['id'] ?? '');

          // ✅ NEW: Handle /reqview/{id} - Requisition View Page
          if (path.contains('/reqview/')) {
            final regex = RegExp(r'/reqview/(\d+)');
            final match = regex.firstMatch(path);
            if (match != null) {
              final requisitionId = int.parse(match.group(1)!);
              print(
                '✅ Requisition view route detected with ID: $requisitionId',
              );
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) =>
                        RequisitionViewScreen(requisitionId: requisitionId),
              );
            }
          }

          // ✅ NEW: Handle /approval/{stepId}?action=approved - Approval Action Page
          if (path.contains('/approval/')) {
            final regex = RegExp(r'/approval/(\d+)');
            final match = regex.firstMatch(path);
            if (match != null) {
              final stepId = int.parse(match.group(1)!);
              final suggestedAction = queryParams['action'] ?? 'approved';
              print(
                '✅ Approval action route detected with stepId: $stepId, action: $suggestedAction',
              );
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) => ApprovalActionScreen(
                      stepId: stepId,
                      suggestedAction: suggestedAction,
                    ),
              );
            }
          }

          // Handle requisition edit route pattern with ID in path
          if (path.contains('/reqfrom/')) {
            final regex = RegExp(r'/reqfrom/(\d+)');
            final match = regex.firstMatch(path);
            if (match != null) {
              final id = int.parse(match.group(1)!);
              print('✅ Requisition edit route detected with ID: $id');
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => RequisitionEditWrapper(requisitionId: id),
              );
            }
          }

          // ✅ EXACT MATCH ROUTING
          switch (path) {
            case '/workflow-creation':
            case '/create':
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) => const WorkflowCreationScreen(mode: 'create'),
              );

            case '/edit':
              if (templateId == null) {
                return MaterialPageRoute(
                  settings: settings,
                  builder:
                      (context) => _buildErrorScreen(
                        'Template ID Required',
                        'Edit mode requires ?id=123 parameter',
                      ),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) => WorkflowCreationScreen(
                      templateId: templateId,
                      mode: 'edit',
                    ),
              );

            case '/view':
              if (templateId == null) {
                return MaterialPageRoute(
                  settings: settings,
                  builder:
                      (context) => _buildErrorScreen(
                        'Template ID Required',
                        'View mode requires ?id=123 parameter',
                      ),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) => WorkflowCreationScreen(
                      templateId: templateId,
                      mode: 'view',
                    ),
              );

            // Requisition create route
            case '/reqfrom':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const RequisitionFormScreen(),
              );

            // Form Builder routes
            case '/form-builder':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const FormBuilderScreen(),
              );

            case '/form-builder/list':
              return MaterialPageRoute(
                builder:
                    (_) => ChangeNotifierProvider(
                      create: (_) => TemplateListProvider()..loadTemplates(),
                      child: const FormListScreen(),
                    ),
              );

            case '/form-builder/edit':
              final formId = queryParams['id'];
              if (formId == null) {
                return MaterialPageRoute( 
                  settings: settings,
                  builder:
                      (context) => _buildErrorScreen(
                        'Form ID Required',
                        'Edit mode requires ?id=xxx parameter',
                      ),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => FormBuilderScreen(templateId: formId),
              );

            case '/form-builder/view':
              final formId = queryParams['id'];
              if (formId == null) {
                return MaterialPageRoute(
                  settings: settings,
                  builder:
                      (context) => _buildErrorScreen(
                        'Form ID Required',
                        'View mode requires ?id=xxx parameter',
                      ),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => FormBuilderScreen(templateId: formId),
              );

            case '':
            default:
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const WorkflowListScreen(),
              );
          }
        },
        initialRoute: '/',
      ),
    );
  }
}

class WorkflowListScreen extends StatelessWidget {
  const WorkflowListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HRMS Workflow Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_tree, size: 120, color: Colors.blue),
                const SizedBox(height: 32),
                const Text(
                  'Workflow Management System',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create and manage workflow templates for your organization',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(
                              context,
                              '/workflow-creation',
                            ),
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text(
                          'Create Workflow',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/edit'),
                        icon: const Icon(Icons.edit, size: 24),
                        label: const Text(
                          'Edit Template',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/view'),
                        icon: const Icon(Icons.visibility, size: 24),
                        label: const Text(
                          'View Template',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(context, '/form-builder'),
                        icon: const Icon(Icons.dynamic_form, size: 24),
                        label: const Text(
                          'Form Builder',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'Connected to Django API at http://127.0.0.1:8000',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RouterWidget extends StatefulWidget {
  const RouterWidget({Key? key}) : super(key: key);

  @override
  State<RouterWidget> createState() => _RouterWidgetState();
}

class _RouterWidgetState extends State<RouterWidget> {
  bool _isLoading = true;
  Widget? _targetWidget;

  @override
  void initState() {
    super.initState();
    _checkCurrentRoute();
  }

  void _checkCurrentRoute() async {
    // Get current URL
    final uri = Uri.base;
    final path = uri.path;

    print('🌐 Current URL: ${uri.toString()}');
    print('📍 Current path: $path');

    // Check for requisition view route pattern
    if (path.contains('/reqview/')) {
      final regex = RegExp(r'/reqview/(\d+)');
      final match = regex.firstMatch(path);
      if (match != null) {
        final id = int.parse(match.group(1)!);
        print('✅ View route detected with ID: $id');
        _targetWidget = RequisitionViewScreen(requisitionId: id);
        setState(() => _isLoading = false);
        return;
      }
    }

    // Check for edit route pattern
    if (path.contains('/reqfrom/')) {
      final regex = RegExp(r'/reqfrom/(\d+)');
      final match = regex.firstMatch(path);
      if (match != null) {
        final id = int.parse(match.group(1)!);
        print('✅ Edit route detected with ID: $id');
        _targetWidget = RequisitionEditWrapper(requisitionId: id);
        setState(() => _isLoading = false);
        return;
      }
    }

    // Default to create form
    print('🏠 Default route, showing create form');
    _targetWidget = const RequisitionFormScreen();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _targetWidget ?? const RequisitionFormScreen();
  }
}

class RequisitionEditWrapper extends StatelessWidget {
  final int requisitionId;

  const RequisitionEditWrapper({Key? key, required this.requisitionId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔧 Building RequisitionEditWrapper for ID: $requisitionId');

    return FutureBuilder<Requisition?>(
      future: _loadRequisitionForEdit(context, requisitionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Loading requisition data for edit...');
          return Scaffold(
            appBar: AppBar(
              title: Text('Loading Requisition $requisitionId'),
              backgroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading requisition data...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Error loading requisition: ${snapshot.error}');
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading requisition: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pushReplacementNamed('/'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show edit form with loaded data
        print(
          '✅ Showing edit form with loaded data for ID: ${snapshot.data!.id}',
        );
        return RequisitionFormScreen(requisition: snapshot.data);
      },
    );
  }
}

// Data loading functions
Future<Requisition?> _loadRequisitionForEdit(
  BuildContext context,
  int requisitionId,
) async {
  try {
    print('\n' + '=' * 80);
    print('🔍 _loadRequisitionForEdit CALLED');
    print('=' * 80);
    print('🎯 Requisition ID to load: $requisitionId');

    print('🔍 Loading requisition for edit: $requisitionId');
    final provider = Provider.of<RequisitionProvider>(context, listen: false);

    // Initialize provider if not already done
    print('🛠️ Initializing provider...');
    if (provider.departments.isEmpty) {
      await provider.initialize();
      print('✅ Provider initialized');
    } else {
      print('ℹ️ Provider already initialized');
    }

    // Wait a moment for initialization
    await Future.delayed(const Duration(milliseconds: 500));

    // Get the specific requisition
    print(
      '📡 Fetching requisition data from API: /api/v1/requisition/$requisitionId/',
    );
    final requisition = await provider.getRequisition(requisitionId);

    if (requisition != null) {
      print('\n✅ SUCCESSFULLY LOADED REQUISITION:');
      print('   - ID: ${requisition.id}');
      print('   - Job Position: ${requisition.jobPosition}');
      print('   - Department: ${requisition.department}');
      print('   - Qualification: ${requisition.qualification}');
      print('   - Essential Skills: ${requisition.essentialSkills}');
      print('   - Positions count: ${requisition.positions.length}');

      // CRITICAL: Check file-related fields
      print('\n📄 FILE-RELATED FIELDS:');
      print('   - jobDescription: ${requisition.jobDescription}');
      print('   - jobDescriptionType: ${requisition.jobDescriptionType}');
      print('   - jobDocument: ${requisition.jobDocument}');
      print('   - jobDocumentUrl: ${requisition.jobDocumentUrl}');
      print(
        '   - jobDocuments array: ${requisition.jobDocuments?.length ?? 0} items',
      );

      if (requisition.jobDocuments != null &&
          requisition.jobDocuments!.isNotEmpty) {
        print('   📎 Files in jobDocuments:');
        for (var i = 0; i < requisition.jobDocuments!.length; i++) {
          print('      ${i + 1}. ${requisition.jobDocuments![i]}');
        }
      }

      print('=' * 80);
      print('');
    } else {
      print('\n❌ REQUISITION $requisitionId NOT FOUND!');
      print('=' * 80);
      print('');
    }

    return requisition;
  } catch (e, stackTrace) {
    print('\n❌ ERROR IN _loadRequisitionForEdit:');
    print('   Error: $e');
    print('   Stack trace: $stackTrace');
    print('=' * 80);
    print('');
    return null;
  }
}
