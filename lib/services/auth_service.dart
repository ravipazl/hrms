import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'api_config.dart';

/// Complete Authentication Service
/// Handles Django session-based authentication for Flutter Web
/// Updated to use centralized authentication endpoints
class AuthService {
  final Dio _dio;

  static const String djangoBackendUrl = '${ApiConfig.djangoBaseUrl}';

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

  /// Fetch CSRF token from Django centralized endpoint
  Future<String?> _fetchCsrfToken() async {
    try {
      print('🔑 Fetching CSRF token from centralized endpoint...');

      // Use centralized authentication endpoint
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/v1/auth/csrf-token/',
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['csrfToken'] != null) {
          _csrfToken = data['csrfToken'];
          print('✅ CSRF token obtained: ${_csrfToken?.substring(0, 10)}...');
          return _csrfToken;
        }
      }

      // Fallback: Try to extract from response headers
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        for (var cookie in cookies) {
          if (cookie.startsWith('csrftoken=')) {
            _csrfToken = cookie.split('=')[1].split(';')[0];
            print(
              '✅ CSRF token from cookie: ${_csrfToken?.substring(0, 10)}...',
            );
            return _csrfToken;
          }
        }
      }

      print('⚠️ Could not get CSRF token');
      return null;
    } catch (e) {
      print('❌ Error fetching CSRF token: $e');
      return null;
    }
  }

  /// Check if user is authenticated via Django session
  /// Uses centralized authentication endpoint
  Future<Map<String, dynamic>?> checkAuthentication({
    bool forceRefresh = false,
  }) async {
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

      // Use centralized authentication endpoint
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/v1/auth/check/',
        options: Options(validateStatus: (status) => status! < 500),
      );

      // Get CSRF token if we don't have it
      if (_csrfToken == null) {
        await _fetchCsrfToken();
      }

      // Handle authenticated response (200 OK)
      if (response.statusCode == 200) {
        final data = response.data;

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
            print('✅ Authenticated as: ${user['username']}');
            return _cachedUserData;
          }
        }
      }

      // Handle not authenticated response (401 Unauthorized)
      if (response.statusCode == 401) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['authenticated'] == false) {
          print('❌ Not authenticated');
        }
      }

      // Clear cache if not authenticated
      _cachedUserData = null;
      _lastAuthCheck = null;
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
      // Use centralized authentication endpoint
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/v1/auth/check/',
        options: Options(validateStatus: (status) => status! < 500),
      );

      // 200 OK (authenticated) or 401 Unauthorized (not authenticated) are both valid
      if (response.statusCode == 200 || response.statusCode == 401) {
        print('✅ Backend is reachable');
        return true;
      }

      return false;
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
      'csrf_token':
          _csrfToken != null ? '${_csrfToken?.substring(0, 10)}...' : null,
      'user_id': _cachedUserData?['id'],
      'username': _cachedUserData?['username'],
    };
  }
}
