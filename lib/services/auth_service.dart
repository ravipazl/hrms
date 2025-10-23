import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

/// Complete Authentication Service
/// Handles Django session-based authentication for Flutter Web
/// Updated to work with requisition API authentication endpoints
class AuthService {
  final Dio _dio;
  
  static const String djangoBackendUrl = 'http://127.0.0.1:8000';
  
  // User data cache
  Map<String, dynamic>? _cachedUserData;
  DateTime? _lastAuthCheck;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // CSRF token cache
  String? _csrfToken;

  AuthService() : _dio = Dio() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = djangoBackendUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // CRITICAL: Enable credentials for Flutter Web
    // This allows cookies to be sent with requests
    _dio.options.extra['withCredentials'] = true;
    
    // Configure browser adapter for web
    final adapter = _dio.httpClientAdapter;
    if (adapter is BrowserHttpClientAdapter) {
      adapter.withCredentials = true;
    }
    
    // Timeouts
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false, // Too verbose
        requestHeader: true,
        responseHeader: true,
        logPrint: (obj) => print('🔐 [AUTH] $obj'),
      ),
    );
  }

  /// Fetch CSRF token from Django
  /// Tries requisition API endpoint first, then falls back to form-builder
  Future<String?> _fetchCsrfToken() async {
    try {
      print('🔑 Fetching CSRF token from Django...');
      
      // Try requisition API endpoint first (newly created)
      try {
        final response = await _dio.get(
          '/api/requisition/get-csrf-token/',
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['csrfToken'] != null) {
            _csrfToken = data['csrfToken'];
            print('✅ CSRF token obtained from requisition API: ${_csrfToken?.substring(0, 10)}...');
            return _csrfToken;
          }
        }
      } catch (e) {
        print('⚠️ Requisition API CSRF endpoint not available, trying form-builder...');
      }
      
      // Fallback to form-builder endpoint
      try {
        final response = await _dio.get(
          '/form-builder/api/get-csrf-token/',
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['csrfToken'] != null) {
            _csrfToken = data['csrfToken'];
            print('✅ CSRF token obtained from form-builder: ${_csrfToken?.substring(0, 10)}...');
            return _csrfToken;
          }
        }
        
        // Try to extract from response headers
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (var cookie in cookies) {
            if (cookie.startsWith('csrftoken=')) {
              _csrfToken = cookie.split('=')[1].split(';')[0];
              print('✅ CSRF token from cookie: ${_csrfToken?.substring(0, 10)}...');
              return _csrfToken;
            }
          }
        }
      } catch (e) {
        print('⚠️ Form-builder CSRF endpoint also not available');
      }
      
      print('⚠️ Could not get CSRF token from any endpoint');
      return null;
    } catch (e) {
      print('❌ Error fetching CSRF token: $e');
      return null;
    }
  }

  /// Check if user is authenticated via Django session
  /// Tries requisition API endpoint first, then falls back to form-builder
  Future<Map<String, dynamic>?> checkAuthentication({bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh && 
        _cachedUserData != null && 
        _lastAuthCheck != null &&
        DateTime.now().difference(_lastAuthCheck!) < _cacheTimeout) {
      print('✅ Using cached auth data');
      return _cachedUserData;
    }

    try {
      print('🔐 Checking Django session...');
      
      // Try requisition API endpoint first
      try {
        final response = await _dio.get(
          '/api/requisition/check-auth/',
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          
          // Get CSRF token if we don't have it
          if (_csrfToken == null) {
            await _fetchCsrfToken();
          }
          
          // Check if authenticated
          if (data is Map<String, dynamic> && data['authenticated'] == true) {
            // Normalize the data structure
            final user = data['user'] as Map<String, dynamic>?;
            if (user != null) {
              _cachedUserData = {
                'authenticated': true,
                'id': user['id'],
                'username': user['username'],
                'email': user['email'],
                'first_name': user['first_name'],
                'last_name': user['last_name'],
                'is_staff': user['is_staff'],
                'is_superuser': user['is_superuser'],
              };
              _lastAuthCheck = DateTime.now();
              print('✅ Authenticated via requisition API as: ${user['username']}');
              return _cachedUserData;
            }
          }
        }
      } catch (e) {
        print('⚠️ Requisition API check-auth not available, trying form-builder...');
      }
      
      // Fallback to form-builder endpoint
      final response = await _dio.get(
        '/form-builder/user-context/',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Get CSRF token if we don't have it
        if (_csrfToken == null) {
          await _fetchCsrfToken();
        }
        
        // Check if authenticated
        if (data is Map<String, dynamic> && data['authenticated'] == true) {
          _cachedUserData = data;
          _lastAuthCheck = DateTime.now();
          print('✅ Authenticated via form-builder as: ${data['username']}');
          return data;
        }
      }
      
      // Clear cache if not authenticated
      _cachedUserData = null;
      _lastAuthCheck = null;
      print('❌ Not authenticated');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ Auth check error: $e');
      print('Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      
      // Clear cache on error
      _cachedUserData = null;
      _lastAuthCheck = null;
      return null;
    }
  }

  /// Get CSRF token for POST/PUT/DELETE requests
  Future<String?> getCsrfToken() async {
    if (_csrfToken == null) {
      await _fetchCsrfToken();
    }
    return _csrfToken;
  }

  /// Get current user info (uses cache)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await checkAuthentication();
  }

  /// Force refresh authentication status
  Future<Map<String, dynamic>?> refreshAuth() async {
    return await checkAuthentication(forceRefresh: true);
  }

  /// Check if user is currently authenticated (from cache)
  bool get isAuthenticated => _cachedUserData != null;

  /// Get cached user data without API call
  Map<String, dynamic>? get cachedUserData => _cachedUserData;

  /// Get Django login URL
  String getDjangoLoginUrl({String? nextUrl}) {
    final next = nextUrl ?? '/';
    return '$djangoBackendUrl/login/?next=$next';
  }

  /// Get Django logout URL
  String getDjangoLogoutUrl() {
    return '$djangoBackendUrl/logout/';
  }

  /// Clear cached auth data
  void clearCache() {
    _cachedUserData = null;
    _lastAuthCheck = null;
    _csrfToken = null;
    print('🧹 Auth cache cleared');
  }

  /// Test if Django backend is reachable
  Future<bool> testConnection() async {
    try {
      // Try requisition API first
      try {
        final response = await _dio.get(
          '/api/requisition/check-auth/',
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );
        if (response.statusCode == 200) {
          print('✅ Requisition API is reachable');
          return true;
        }
      } catch (e) {
        print('⚠️ Requisition API not reachable, trying form-builder...');
      }
      
      // Fallback to form-builder
      final response = await _dio.get(
        '/form-builder/test-session/',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Get detailed debug info
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'backend_url': djangoBackendUrl,
      'cached_auth': _cachedUserData != null,
      'last_check': _lastAuthCheck?.toIso8601String(),
      'is_authenticated': isAuthenticated,
      'with_credentials': _dio.options.extra['withCredentials'],
      'csrf_token': _csrfToken != null ? '${_csrfToken?.substring(0, 10)}...' : null,
      'user_id': _cachedUserData?['id'],
      'username': _cachedUserData?['username'],
    };
  }
}
