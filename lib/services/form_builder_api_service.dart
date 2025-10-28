import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import '../models/form_builder/form_template.dart';
import '../models/form_builder/form_submission.dart';
import '../models/form_builder/form_data.dart' as form_models;
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
    
    // Auth interceptor
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
          }
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 || 
            error.response?.statusCode == 403) {
          _authService.clearCache();
        }
        return handler.next(error);
      },
    ));
    
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
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
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<FormTemplate> getTemplate(String templateId) async {
    try {
      print('📄 Fetching template: $templateId');
      final response = await _dio.get('/templates/$templateId/');

      if (response.data['success'] == true) {
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load template');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<form_models.FormData> loadTemplateForEditing(String templateId) async {
    try {
      print('✏️ Loading for edit: $templateId');
      final response = await _dio.get('/load/$templateId/');

      if (response.data['success'] == true) {
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

  Future<void> deleteTemplate(String templateId) async {
    try {
      print('🗑️ Deleting template: $templateId');
      final response = await _dio.delete('/templates/$templateId/');
      
      if (response.data['success'] != true) {
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

  Future<String> submitForm(
      String templateId, Map<String, dynamic> formData) async {
    try {
      print('📤 Submitting form: $templateId');
      
      // FIX: Clean and convert rich text fields to strings
      print('🧹 Cleaning form data...');
      final cleanedFormData = _cleanFormData(formData);
      
      // Debug print cleaned data
      print('📋 Form data after cleaning:');
      cleanedFormData.forEach((key, value) {
        print('  ✅ $key: ${value.runtimeType} = ${value is String && value.length > 50 ? "${value.substring(0, 50)}..." : value}');
      });
      
      final requestBody = {
        'formData': cleanedFormData,
        'templateId': templateId,
        'metadata': {
          'submittedAt': DateTime.now().toIso8601String(),
          'platform': 'Flutter Mobile',
          'userAgent': 'Flutter/Mobile',
          'submission_method': 'flutter_mobile'
        },
      };
      
      final response = await _dio.post(
        '/submit/$templateId/',
        data: requestBody,
      );

      if (response.data['success'] == true) {
        final submissionId = response.data['data']['id'] as String;
        print('✅ Form submitted successfully: $submissionId');
        return submissionId;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      
      if (e.response?.data != null && e.response?.data is Map) {
        final responseData = e.response!.data as Map<String, dynamic>;
        final message = responseData['message'] ?? e.message;
        print('❌ Submission error: $message');
        throw Exception(message);
      }
      
      print('❌ DioException: ${e.message}');
      throw Exception('Submit failed: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error during submission: $e');
      rethrow;
    }
  }

  /// Helper method to clean form data and convert rich text fields to strings
  Map<String, dynamic> _cleanFormData(Map<String, dynamic> formData) {
    final cleaned = <String, dynamic>{};
    
    formData.forEach((key, value) {
      if (value == null) {
        cleaned[key] = '';  // Convert null to empty string
        print('  🧹 Cleaned null value for field: $key');
      } else if (value is String) {
        cleaned[key] = value;  // Keep strings as is
      } else if (value is bool) {
        cleaned[key] = value;  // Keep booleans as is
      } else if (value is num) {
        cleaned[key] = value;  // Keep numbers as is
      } else if (value is List) {
        // Clean list items
        cleaned[key] = value.map((item) {
          if (item == null) {
            return '';
          } else if (item is Map<String, dynamic>) {
            return _cleanFormData(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        final map = value as Map<String, dynamic>;
        
        // SPECIAL FIX: Detect rich text fields and convert to plain string
        // Rich text fields have inline field IDs as keys (field_xxxxx) 
        final hasInlineFields = map.keys.any((k) => k.toString().startsWith('field_'));
        final hasContent = map.containsKey('content');
        
        if (hasInlineFields && !hasContent) {
          // This is a rich text field with inline data (OLD FORMAT - shouldn't happen anymore)
          // Build HTML from inline fields as fallback
          print('  🔧 FIXING rich text field "$key": building HTML from inline data (OLD FORMAT)');
          
          final buffer = StringBuffer('<p>');
          var hasValues = false;
          map.forEach((fieldId, fieldValue) {
            if (fieldId.toString().startsWith('field_') && fieldValue != null && fieldValue.toString().isNotEmpty) {
              buffer.write('$fieldValue ');
              hasValues = true;
            }
          });
          buffer.write('</p>');
          
          cleaned[key] = hasValues ? buffer.toString() : '<p></p>';
          print('     📏 Generated HTML: ${cleaned[key]}');
        } else if (hasContent) {
          // Rich text with content - KEEP THE ENTIRE OBJECT WITH ALL FIELDS
          print('  🔧 Rich text field "$key": KEEPING complete object with embeddedFieldValues');
          print('     embeddedFieldValues: ${map["embeddedFieldValues"]}');
          cleaned[key] = map;  // ✅ Keep the complete rich text object!
        } else {
          // Recursively clean nested maps (for other complex fields)
          cleaned[key] = _cleanFormData(map);
        }
      } else {
        // Convert everything else to string
        cleaned[key] = value.toString();
      }
    });
    
    return cleaned;
  }

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

  /// Get single submission - FIXED to use new detail endpoint
  Future<FormSubmission> getSubmission(String submissionId) async {
    try {
      print('📄 Fetching submission: $submissionId');
      
      // Use the new submission detail endpoint
      final endpoint = '/submissions/detail/$submissionId/';
      print('🔄 Using endpoint: $endpoint');
      
      final response = await _dio.get(endpoint);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Submission loaded successfully');
        return FormSubmission.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load submission');
      }
      
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Status: ${e.response?.statusCode}');
      print('❌ Data: ${e.response?.data}');
      
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Submission not found (404). The submission ID "$submissionId" does not exist.'
        );
      }
      
      if (e.response?.statusCode == 403) {
        throw Exception('Access denied. You do not have permission to view this submission.');
      }
      
      throw Exception('Load failed: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  // ==================== FILE UPLOAD OPERATIONS ====================

  Future<String?> uploadSignature(Uint8List pngBytes, String fieldId) async {
    try {
      print('📤 Uploading signature...');
      print('✅ Signature bytes: ${pngBytes.length} bytes');
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          pngBytes,
          filename: 'signature.png',
        ),
        'field_id': fieldId,
      });

      final response = await _dio.post('/upload-signature/', data: formData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final filename = response.data['data']['signature'];
        print('✅ Upload successful! Filename: $filename');
        return filename;
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Not authenticated');
      }
      print('❌ Upload error: ${e.message}');
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      print('❌ Unexpected upload error: $e');
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  Future<FileMetadata> uploadFile(File file, String fieldId) async {
    try {
      print('📎 Uploading file: ${file.path}');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'field_id': fieldId,
      });

      final response = await _dio.post('/upload-file/', data: formData);

      if (response.data['success'] == true) {
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

  String _buildQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

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

  String generatePublicFormUrl(String templateId) {
    return 'http://127.0.0.1:5173/public/form/$templateId';
  }

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
