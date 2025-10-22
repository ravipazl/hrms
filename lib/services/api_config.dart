// lib/services/api_config.dart
import 'package:http/http.dart' as http;

class ApiConfig {
  // API Configuration - Based on actual Django URL structure
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String fallbackUrl = 'http://127.0.0.1:8000/api'; 
  
  // Test if API is available
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/test/'));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ API connection test failed: $e');
      return false;
    }
  }
  
  // Django Backend URLs (for redirects)
  static const String djangoBaseUrl = 'http://127.0.0.1:8000';
  
  // Timeout Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Debug Configuration
  static const bool enableLogging = true;
  static const bool enableMockData = false; // Use real Django API
  
  // Endpoint Paths - Based on actual Django horilla_api structure
  static const String requisitionEndpoint = '/requisition/';
  static const String referenceDataEndpoint = '/reference-data/';
  static const String workflowStatusEndpoint = '/requisition/{id}/workflow-status/';
  
  // Flutter Dev Server Configuration
  static const String flutterPort = '54649'; // As specified in your setup
  static const String flutterBaseUrl = 'http://localhost:54649';
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'network': 'Unable to connect to server. Please check your internet connection.',
    'timeout': 'Request timed out. Please try again.',
    'server': 'Server error occurred. Please try again later.',
    'notFound': 'Requested data not found.',
    'unauthorized': 'You are not authorized to access this resource.',
    'unknown': 'An unexpected error occurred. Please try again.',
  };
  
  // Mock Data for Development (disabled by default)
  static bool get shouldUseMockData => enableMockData;
  
  static String getErrorMessage(String type) {
    return errorMessages[type] ?? errorMessages['unknown']!;
  }
  
  // Helper method to get workflow status endpoint with ID
  static String getWorkflowStatusEndpoint(int requisitionId) {
    return workflowStatusEndpoint.replaceAll('{id}', requisitionId.toString());
  }
}
