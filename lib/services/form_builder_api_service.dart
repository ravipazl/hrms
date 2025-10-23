import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import '../models/form_builder/form_template.dart';
import '../models/form_builder/form_submission.dart';
import '../models/form_builder/form_data.dart' as form_models;
import '../models/form_builder/form_submission.dart';
import '../models/form_builder/file_metadata.dart';
import '../utils/json_schema_generator.dart';
import 'auth_service.dart';

/// Complete Form Builder API Service
/// Handles all API calls to Django backend with proper authentication
class FormBuilderAPIService {
  final Dio _dio;
  final AuthService _authService;
  
  static const String baseUrl = 'http://127.0.0.1:8000/form-builder/api';

  FormBuilderAPIService(this._authService) : _dio = Dio() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // CRITICAL: Enable credentials for Flutter Web
    _dio.options.extra['withCredentials'] = true;
    
    // Configure browser adapter for web
    final adapter = _dio.httpClientAdapter;
    if (adapter is BrowserHttpClientAdapter) {
      adapter.withCredentials = true;
    }
    
    // Auth interceptor - Check Django session authentication and add CSRF token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check auth before each request
        final authData = await _authService.checkAuthentication();
        if (authData == null) {
          print('❌ Not authenticated for: ${options.path}');
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Not authenticated. Please login via Django.',
            ),
          );
        }
        
        // Add CSRF token for POST/PUT/DELETE/PATCH requests
        if (['POST', 'PUT', 'DELETE', 'PATCH'].contains(options.method.toUpperCase())) {
          final csrfToken = await _authService.getCsrfToken();
          if (csrfToken != null) {
            options.headers['X-CSRFToken'] = csrfToken;
            print('✅ CSRF token added to ${options.method} request: ${csrfToken.substring(0, 10)}...');
          } else {
            print('⚠️ No CSRF token available for ${options.method} request');
          }
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 || 
            error.response?.statusCode == 403) {
          print('🔒 Auth error - clearing cache');
          _authService.clearCache();
        }
        return handler.next(error);
      },
    ));
    
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // Too verbose
        responseBody: false,
        request: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (obj) => print('🌐 [API] $obj'),
      ),
    );
  }

  // ==================== TEMPLATE OPERATIONS ====================
  
  /// Get all templates with optional search
  Future<List<FormTemplate>> getTemplates({String? searchQuery}) async {
    try {
      final endpoint = searchQuery != null && searchQuery.isNotEmpty
          ? '/templates/?search=${Uri.encodeComponent(searchQuery)}' 
          : '/templates/';

      print('📋 Fetching templates...');
      final response = await _dio.get(endpoint);

      if (response.data['success'] == true) {
        final results = response.data['data']['results'] as List;
        print('✅ Got ${results.length} templates');
        return results.map((json) => FormTemplate.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load templates');
      }
    } on DioException catch (e) {
      print('❌ Network error: ${e.message}');
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  /// Get specific template by ID
  Future<FormTemplate> getTemplate(String templateId) async {
    try {
      print('📄 Fetching template: $templateId');
      final response = await _dio.get('/templates/$templateId/');

      if (response.data['success'] == true) {
        print('✅ Template loaded');
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load template');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Load template for editing
  Future<form_models.FormData> loadTemplateForEditing(String templateId) async {
    try {
      print('✏️ Loading for edit: $templateId');
      final response = await _dio.get('/load/$templateId/');

      if (response.data['success'] == true) {
        print('✅ Loaded for editing');
        return form_models.FormData.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Save new template
  Future<FormTemplate> saveTemplate(form_models.FormData formData) async {
    try {
      final name = formData.name ?? formData.generateName();
      final jsonSchema = JSONSchemaGenerator.generateJSONSchema(formData);
      final uiSchema = JSONSchemaGenerator.generateUISchema(formData);

      final requestData = {
        'name': name,
        'formTitle': formData.formTitle,
        'formDescription': formData.formDescription,
        'fields': formData.fields.map((field) => field.toJson()).toList(),
        'headerConfig': formData.headerConfig.toJson(),
        'react_form_data': formData.toJson(),
        'json_schema': jsonSchema,
        'ui_schema': uiSchema,
      };

      print('💾 Saving template: ${formData.formTitle}');
      final response = await _dio.post('/save/', data: requestData);

      if (response.data['success'] == true) {
        print('✅ Template saved!');
        final responseData = response.data['data'];
        if (responseData != null) {
          return FormTemplate.fromJson(responseData);
        } else {
          throw Exception('No data in response');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['errors'] != null) {
          final errors = errorData['errors'] as List;
          final errorMessages = errors.map((error) {
            if (error is Map) {
              return error.entries
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join('; ');
            }
            return error.toString();
          }).join('; ');
          throw Exception('Validation: $errorMessages');
        }
      }
      
      throw Exception('Save failed: ${e.message}');
    }
  }

  /// Update existing template
  Future<FormTemplate> updateTemplate(
      String templateId, form_models.FormData formData) async {
    try {
      final jsonSchema = JSONSchemaGenerator.generateJSONSchema(formData);
      final uiSchema = JSONSchemaGenerator.generateUISchema(formData);

      final requestData = {
        'formTitle': formData.formTitle,
        'formDescription': formData.formDescription,
        'fields': formData.fields.map((field) => field.toJson()).toList(),
        'headerConfig': formData.headerConfig.toJson(),
        'react_form_data': formData.toJson(),
        'json_schema': jsonSchema,
        'ui_schema': uiSchema,
      };

      print('📝 Updating template: $templateId');
      final response = await _dio.put('/templates/$templateId/', data: requestData);

      if (response.data['success'] == true) {
        print('✅ Template updated!');
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Update failed: ${e.message}');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      print('🗑️ Deleting template: $templateId');
      final response = await _dio.delete('/templates/$templateId/');
      
      if (response.data['success'] == true) {
        print('✅ Template deleted');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Delete failed: ${e.message}');
    }
  }

  // ==================== FORM SUBMISSION OPERATIONS ====================

  /// Submit form data
  Future<String> submitForm(
      String templateId, Map<String, dynamic> formData) async {
    try {
      print('📤 Submitting form: $templateId');
      final response = await _dio.post(
        '/submit/$templateId/',
        data: {
          'formData': formData,
          'metadata': {
            'submittedAt': DateTime.now().toIso8601String(),
            'platform': 'Flutter Web',
            'userAgent': 'Flutter/Web',
          },
        },
      );

      if (response.data['success'] == true) {
        final submissionId = response.data['data']['submission_id'] as String;
        print('✅ Submitted: $submissionId');
        return submissionId;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Submit failed: ${e.message}');
    }
  }

  /// Get form submissions with filters
  Future<List<FormSubmission>> getSubmissions(
    String templateId, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = filters != null && filters.isNotEmpty
          ? '?${_buildQueryString(filters)}' 
          : '';
      final endpoint = '/submissions/$templateId/$queryParams';

      print('📥 Fetching submissions for: $templateId');
      final response = await _dio.get(endpoint);

      if (response.data['success'] == true) {
        final results = response.data['data']['results'] as List;
        print('✅ Got ${results.length} submissions');
        return results.map((json) => FormSubmission.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Load failed: ${e.message}');
    }
  }

  /// Get single submission
  Future<FormSubmission> getSubmission(String submissionId) async {
    try {
      print('📄 Fetching submission: $submissionId');
      final response = await _dio.get('/submission/$submissionId/');

      if (response.data['success'] == true) {
        print('✅ Submission loaded');
        return FormSubmission.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Load failed: ${e.message}');
    }
  }

  // ==================== FILE UPLOAD OPERATIONS ====================

  /// Upload file for form field
  Future<FileMetadata> uploadFile(File file, String fieldId) async {
    try {
      print('📎 Uploading file: ${file.path}');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'field_id': fieldId,
      });

      final response = await _dio.post('/upload-file/', data: formData);

      if (response.data['success'] == true) {
        print('✅ File uploaded');
        return FileMetadata.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Upload failed: ${e.message}');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Build query string from parameters
  String _buildQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      print('🔌 Testing API connection...');
      final response = await _dio.get('/templates/');
      final success = response.statusCode == 200;
      print(success ? '✅ API connected' : '❌ API connection failed');
      return success;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Generate public form URL
  String generatePublicFormUrl(String templateId) {
    return 'http://127.0.0.1:5173/public/form/$templateId';
  }

  /// Get API statistics
  Future<Map<String, dynamic>> getApiStats() async {
    try {
      final authData = await _authService.getCurrentUser();
      final connected = await testConnection();
      
      return {
        'base_url': baseUrl,
        'authenticated': authData != null,
        'username': authData?['username'],
        'connected': connected,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
