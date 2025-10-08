import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'providers/workflow_provider.dart';
import 'providers/requisition_provider.dart';
import 'screens/workflow_creation_screen.dart';
import 'screens/requisition_management_screen.dart';
import 'screens/requisition_list_screen.dart';
import 'screens/requisition_form_screen.dart';

void main() {
  // Remove # from URL for web
  setPathUrlStrategy();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: MaterialStateProperty.all(true),
            thickness: MaterialStateProperty.all(8),
            radius: const Radius.circular(4),
          ),
        ),
        onGenerateRoute: (settings) {
          // Remove trailing slash
          final path = settings.name?.replaceAll(RegExp(r'/$'), '') ?? '/';
          
          print('🔍 Route requested: ${settings.name} -> $path');
          
          switch (path) {
            // Workflow routes
            case '/workflow-creation':
            case '/create':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const WorkflowCreationScreen(mode: 'create'),
              );
            case '/workflow-edit':
            case '/edit':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const WorkflowCreationScreen(mode: 'edit'),
              );
            case '/workflow-view':
            case '/view':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const WorkflowCreationScreen(mode: 'view'),
              );
            
            // Requisition routes
            case '/requisition':
            case '/requisition-management':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const RequisitionManagementScreen(),
              );
            case '/requisition-list':
            case '/list':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const RequisitionListScreen(),
              );
            case '/requisition-form':
            case '/reqfrom':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const RequisitionFormScreen(),
              );
            
            // Default route
            case '/':
            default:
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const HomeScreen(),
              );
          }
        },
        initialRoute: '/',
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HRMS Management System'),
        backgroundColor: Colors.white,
        elevation: 0,
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
                // Hero section
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'HRMS Management System',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage workflows and requisitions for your organization',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Feature cards
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        'Requisition Management',
                        'Create and manage talent requisition requests',
                        Icons.description,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/requisition'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        'Workflow Templates',
                        'Design and manage approval workflows',
                        Icons.account_tree,
                        Colors.green,
                        () => Navigator.pushNamed(context, '/workflow-creation'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Quick actions
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reqfrom');
                        },
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text(
                          'New Requisition',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/list');
                        },
                        icon: const Icon(Icons.list, size: 24),
                        label: const Text(
                          'View Requisitions',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/workflow-creation');
                        },
                        icon: const Icon(Icons.edit, size: 24),
                        label: const Text(
                          'Create Workflow',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          foregroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // API connection status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connected to Django API',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'http://127.0.0.1:8000/api',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
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

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
