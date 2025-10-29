import 'package:flutter/material.dart';
import 'package:hrms/models/requisition.dart';
import 'package:hrms/providers/requisition_provider.dart';
import 'package:hrms/screens/form_builder/form_builder_screen.dart';
import 'package:hrms/screens/requisition_form_screen.dart';
import 'package:hrms/screens/requisition_view_screen.dart';
import 'package:hrms/screens/approval_action_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:html' as html;
import 'providers/workflow_provider.dart';
import 'providers/template_list_provider.dart';
import 'screens/workflow_creation_screen.dart';
import 'screens/form_builder/form_list_screen.dart';
import 'screens/form_builder/form_builder_screen.dart';
// Authentication imports
import 'services/auth_service.dart';
import 'services/form_builder_api_service.dart';
import 'providers/form_builder_provider.dart';
import 'services/api_config.dart';
void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
                      '${ApiConfig.djangoBaseUrl}/workflow/templates/';
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Dashboard'),
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
        // Authentication providers (must be first)
        Provider<AuthService>(
          create: (_) {
            print('🔐 Creating AuthService');
            return AuthService();
          },
          dispose: (_, service) {
            print('🧹 Disposing AuthService');
          },
        ),

        // FormBuilderAPIService depends on AuthService
        ProxyProvider<AuthService, FormBuilderAPIService>(
          update: (_, authService, __) {
            print('🌐 Creating FormBuilderAPIService');
            return FormBuilderAPIService(authService);
          },
        ),

        // Other providers
        ChangeNotifierProvider(create: (_) => WorkflowProvider()),
        ChangeNotifierProvider(create: (_) => RequisitionProvider()),
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

          print('🛣️ Route: $path');
          print('📊 Query params: $queryParams');

          // ✅ Handle /reqview/{id} - Requisition View Page WITH AUTHENTICATION
          if (path.contains('/reqview/')) {
            final regex = RegExp(r'/reqview/(\d+)');
            final match = regex.firstMatch(path);
            if (match != null) {
              final requisitionId = int.parse(match.group(1)!);
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => AuthCheckWrapper(
                  child: RequisitionViewScreen(requisitionId: requisitionId),
                ),
              );
            }
          }

          // Handle /approval/{stepId}?action=approved - Approval Action Page
          if (path.contains('/approval/')) {
            final regex = RegExp(r'/approval/(\d+)');
            final match = regex.firstMatch(path);
            if (match != null) {
              final stepId = int.parse(match.group(1)!);
              final suggestedAction = queryParams['action'] ?? 'approved';
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

          // ✅ Handle requisition edit route pattern with ID in path WITH AUTHENTICATION
          if (path.contains('/reqfrom/')) {
            final regex = RegExp(r'/reqfrom/(\d+)');
            final match = regex.firstMatch(path);
            if (match != null) {
              final id = int.parse(match.group(1)!);
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => AuthCheckWrapper(
                      child: RequisitionEditWrapper(requisitionId: id),
                    ),
              );
            }
          }

          // EXACT MATCH ROUTING
          switch (path) {
            // ✅ Workflow routes - NOW WITH AUTHENTICATION
            case '/workflow-creation':
            case '/create':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const AuthCheckWrapper(
                      child: WorkflowCreationScreen(mode: 'create'),
                    ),
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
                builder: (context) => AuthCheckWrapper(
                      child: WorkflowCreationScreen(
                        templateId: templateId,
                        mode: 'edit',
                      ),
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
                builder: (context) => AuthCheckWrapper(
                      child: WorkflowCreationScreen(
                        templateId: templateId,
                        mode: 'view',
                      ),
                    ),
              );

            // ✅ Requisition create route - NOW WITH AUTHENTICATION
            case '/reqfrom':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const AuthCheckWrapper(
                  child: RequisitionFormScreen(),
                  ),
              );

            // ✅ Form Builder routes with authentication
            case '/form-builder/create':
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) => AuthCheckWrapper(
                      child: ChangeNotifierProvider(
                        create:
                            (context) => FormBuilderProvider(
                              context.read<AuthService>(),
                            ),
                        child: const FormBuilderScreen(),
                      ),
                    ),
              );

            case '/form-builder':
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) => AuthCheckWrapper(
                      child: ChangeNotifierProvider(
                        create:
                            (context) => FormBuilderProvider(
                              context.read<AuthService>(),
                            ),
                        child: const FormBuilderScreen(),
                      ),
                    ),
              );

            case '/form-builder/list':
              return MaterialPageRoute(
                settings: settings,
                builder:
                    (context) =>
                        const AuthCheckWrapper(child: FormListScreenWrapper()),
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
                builder:
                    (context) => AuthCheckWrapper(
                      child: ChangeNotifierProvider(
                        create:
                            (context) => FormBuilderProvider(
                              context.read<AuthService>(),
                            ),
                        child: FormBuilderScreen(templateId: formId),
                      ),
                    ),
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
                builder:
                    (context) => AuthCheckWrapper(
                      child: ChangeNotifierProvider(
                        create:
                            (context) => FormBuilderProvider(
                              context.read<AuthService>(),
                            ),
                        child: FormBuilderScreen(templateId: formId),
                      ),
                    ),
              );

            // 🔒 ROOT ROUTE - Redirect to Django if accessed directly
            case '':
            default:
              // Check if user accessed directly (not from Django redirect)
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const RootRedirectScreen(),
              );
          }
        },
        initialRoute: '/',
      ),
    );
  }
}

// ==================== ROOT REDIRECT SCREEN ====================

/// Screen that redirects to Django if accessed directly
class RootRedirectScreen extends StatefulWidget {
  const RootRedirectScreen({Key? key}) : super(key: key);

  @override
  State<RootRedirectScreen> createState() => _RootRedirectScreenState();
}

class _RootRedirectScreenState extends State<RootRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _checkAccessAndRedirect();
  }

  Future<void> _checkAccessAndRedirect() async {
    print('🔍 Checking if user accessed via Django...');

    final authService = context.read<AuthService>();

    // Check if user is authenticated
    final authData = await authService.checkAuthentication();

    if (authData != null) {
      // User is authenticated
      print('✅ User authenticated: ${authData['username']}');
      // ⚠️ REMOVED AUTO-REDIRECT - Stay on current page
      // Users will naturally be on /reqfrom or /workflow-creation pages
    } else {
      // Not authenticated - show message and redirect to Django
      print('❌ Not authenticated, must login via Django');
      // Stay on this screen to show the message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'This application must be accessed through the Django dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Login to Django dashboard'),
                    _buildStep('2', 'Click "Form Builder" in the sidebar'),
                    _buildStep(
                      '3',
                      'You will be redirected here automatically',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Redirect Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Redirect to Django login
                    html.window.location.href ='${ApiConfig.djangoBaseUrl}/login/';
                  },
                  icon: const Icon(Icons.arrow_forward, size: 24),
                  label: const Text(
                    'Go to Django Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Alternative link
              TextButton(
                onPressed: () {
                  html.window.location.href = '${ApiConfig.djangoBaseUrl}/';
                },
                child: Text(
                  'Or go to Django Dashboard',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== AUTH CHECK WRAPPER ====================

/// Authentication wrapper for protected routes
class AuthCheckWrapper extends StatefulWidget {
  final Widget child;

  const AuthCheckWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  bool _isChecking = true;
  bool _isAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      print('🔐 AuthCheckWrapper: Checking authentication...');

      final authService = context.read<AuthService>();

      // Small delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 300));

      final authData = await authService.checkAuthentication();

      if (mounted) {
        setState(() {
          _isAuthenticated = authData != null;
          _isChecking = false;
        });

        if (authData != null) {
          print('✅ User authenticated: ${authData['username']}');
        } else {
          print('❌ User not authenticated');
        }
      }
    } catch (e) {
      print('❌ Auth check error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Verifying Django session',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ If not authenticated, show login screen
    if (!_isAuthenticated) {
      return const RootRedirectScreen();
    }

    // ✅ If authenticated, show the protected content
    return widget.child;
  }
}

// ==================== FORM LIST WRAPPER ====================

/// Wrapper for FormListScreen with provider
class FormListScreenWrapper extends StatelessWidget {
  const FormListScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        print('📋 Creating TemplateListProvider');
        final authService = context.read<AuthService>();
        final provider = TemplateListProvider(authService);
        provider.loadTemplates();
        return provider;
      },
      child: const FormListScreen(),
    );
  }
}

// ==================== WORKFLOW LIST SCREEN ====================

class WorkflowListScreen extends StatelessWidget {
  const WorkflowListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RootRedirectScreen();
  }
}

// ==================== ROUTER WIDGET ====================

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
    final uri = Uri.base;
    final path = uri.path;

    if (path.contains('/reqview/')) {
      final regex = RegExp(r'/reqview/(\d+)');
      final match = regex.firstMatch(path);
      if (match != null) {
        final id = int.parse(match.group(1)!);
        _targetWidget = RequisitionViewScreen(requisitionId: id);
        setState(() => _isLoading = false);
        return;
      }
    }

    if (path.contains('/reqfrom/')) {
      final regex = RegExp(r'/reqfrom/(\d+)');
      final match = regex.firstMatch(path);
      if (match != null) {
        final id = int.parse(match.group(1)!);
        _targetWidget = RequisitionEditWrapper(requisitionId: id);
        setState(() => _isLoading = false);
        return;
      }
    }

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

// ==================== REQUISITION EDIT WRAPPER ====================

class RequisitionEditWrapper extends StatelessWidget {
  final int requisitionId;

  const RequisitionEditWrapper({Key? key, required this.requisitionId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Requisition?>(
      future: _loadRequisitionForEdit(context, requisitionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        return RequisitionFormScreen(requisition: snapshot.data);
      },
    );
  }
}

// ==================== DATA LOADING FUNCTIONS ====================

Future<Requisition?> _loadRequisitionForEdit(
  BuildContext context,
  int requisitionId,
) async {
  try {
    print('🔍 Loading requisition: $requisitionId');
    final provider = Provider.of<RequisitionProvider>(context, listen: false);

    if (provider.departments.isEmpty) {
      await provider.initialize();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    final requisition = await provider.getRequisition(requisitionId);

    if (requisition != null) {
      print('✅ Requisition loaded: ${requisition.id}');
    } else {
      print('❌ Requisition not found: $requisitionId');
    }

    return requisition;
  } catch (e, stackTrace) {
    print('❌ Load error: $e');
    print('Stack: $stackTrace');
    return null;
  }
}
