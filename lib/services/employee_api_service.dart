// lib/services/employee_api_service.dart
// ✅ UPDATED to use Dio with authentication

import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import '../widgets/dialogs/node_edit_dialog.dart';
import 'auth_service.dart';

class EmployeeApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  final Dio _dio;
  final AuthService _authService;
  
  EmployeeApiService({AuthService? authService}) 
    : _authService = authService ?? AuthService(),
      _dio = Dio() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = 'http://127.0.0.1:8000';
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // CRITICAL: Enable credentials for Flutter Web (session cookies)
    _dio.options.extra['withCredentials'] = true;
    
    // Configure browser adapter for web
    final adapter = _dio.httpClientAdapter;
    if (adapter is BrowserHttpClientAdapter) {
      adapter.withCredentials = true;
    }
    
    // Timeouts
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptor to include CSRF token (optional for public endpoint)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get CSRF token and add to headers
          final csrfToken = await _authService.getCsrfToken();
          if (csrfToken != null) {
            options.headers['X-CSRFToken'] = csrfToken;
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('❌ Employee API Error: ${error.response?.statusCode} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
    
    // Logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: true,
        responseHeader: false,
        logPrint: (obj) => print('🔄 [Employee API] $obj'),
      ),
    );
  }

  /// Load employees list from API (PUBLIC - no auth required)
  Future<List<Employee>> loadEmployees({String? search, String? department}) async {
    try {
      print('👥 Loading employees from API...');
      
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        print('🔍 Search query: $search');
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
        print('🏢 Department filter: $department');
      }
      
      final response = await _dio.get(
        '/api/employees-list/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'success' && data['employees'] != null) {
          final List<dynamic> employeesData = data['employees'];
          print('✅ Loaded ${employeesData.length} employees');
          
          return employeesData.map((json) => Employee.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load employees: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading employees: $e');
      // Return empty list instead of throwing to allow app to continue
      return [];
    }
  }
  
  /// Search employees by query (PUBLIC - no auth required)
  Future<List<Employee>> searchEmployees(String query) async {
    return await loadEmployees(search: query);
  }
  
  /// Get employees by department (PUBLIC - no auth required)
  Future<List<Employee>> getEmployeesByDepartment(String departmentId) async {
    return await loadEmployees(department: departmentId);
  }
}
