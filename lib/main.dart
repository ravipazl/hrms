import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:html' as html;
import 'providers/workflow_provider.dart';
import 'screens/workflow_creation_screen.dart';

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
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  html.window.location.href = 'http://127.0.0.1:8000/workflow/templates/';
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Templates'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          
          print('🔍 Route: ${settings.name}');
          print('📂 Path: $path');
          print('📊 Query: $queryParams');
          if (templateId != null) print('🎯 Template ID: $templateId');
          
          // ✅ EXACT MATCH ROUTING
          switch (path) {
            case '/workflow-creation':
            case '/create':
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => const WorkflowCreationScreen(mode: 'create'),
              );
            
            case '/edit':
              if (templateId == null) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => _buildErrorScreen(
                    'Template ID Required',
                    'Edit mode requires ?id=123 parameter',
                  ),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => WorkflowCreationScreen(
                  templateId: templateId,
                  mode: 'edit',
                ),
              );
            
            case '/view':
              if (templateId == null) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => _buildErrorScreen(
                    'Template ID Required',
                    'View mode requires ?id=123 parameter',
                  ),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => WorkflowCreationScreen(
                  templateId: templateId,
                  mode: 'view',
                ),
              );
            
            case '/':
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}, tooltip: 'Refresh'),
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
                const Text('Workflow Management System', 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text('Create and manage workflow templates for your organization',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center),
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
                        onPressed: () => Navigator.pushNamed(context, '/workflow-creation'),
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text('Create Workflow', style: TextStyle(fontSize: 16)),
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
                        label: const Text('Edit Template', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/view'),
                        icon: const Icon(Icons.visibility, size: 24),
                        label: const Text('View Template', style: TextStyle(fontSize: 16)),
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
                      const Text('Connected to Django API at http://127.0.0.1:8000',
                        style: TextStyle(fontSize: 14)),
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
