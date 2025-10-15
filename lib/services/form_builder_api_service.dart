import 'dart:io';
import 'package:dio/dio.dart';
import '../models/form_builder/form_template.dart';
import '../models/form_builder/form_data.dart' as form_models;
import '../models/form_builder/form_submission.dart';
import '../models/form_builder/file_metadata.dart';
import '../utils/json_schema_generator.dart';

/// FormBuilder API Service - handles all API communication with Django backend
class FormBuilderAPIService {
  final Dio _dio;
  static const String baseUrl = 'http://127.0.0.1:8000/form-builder/api';

  FormBuilderAPIService() : _dio = Dio() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
    ));
  }

  // ========== TEMPLATE CRUD OPERATIONS ==========

  /// Get all templates with optional search
  Future<List<FormTemplate>> getTemplates({String? searchQuery}) async {
    try {
      final endpoint = searchQuery != null ? '/templates/?search=$searchQuery' : '/templates/';

      final response = await _dio.get(endpoint);

      if (response.data['success'] == true) {
        final results = response.data['data']['results'] as List;
        return results.map((json) => FormTemplate.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load templates');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load templates: $e');
    }
  }

  /// Get specific template by ID
  Future<FormTemplate> getTemplate(String templateId) async {
    try {
      final response = await _dio.get('/templates/$templateId/');

      if (response.data['success'] == true) {
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load template');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load template: $e');
    }
  }

  /// Load template for editing (with schema regeneration)
  Future<form_models.FormData> loadTemplateForEditing(String templateId) async {
    try {
      final response = await _dio.get('/load/$templateId/');

      if (response.data['success'] == true) {
        return form_models.FormData.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load template');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load template for editing: $e');
    }
  }
/// Save new template - FIXED: Match backend expected format
/// Save new template - FIXED: Match backend expected format
Future<FormTemplate> saveTemplate(form_models.FormData formData) async {
  try {
    // Generate unique name
    final name = formData.name ?? formData.generateName();

    // Generate JSON Schema and UI Schema
    final jsonSchema = JSONSchemaGenerator.generateJSONSchema(formData);
    final uiSchema = JSONSchemaGenerator.generateUISchema(formData);

    // ✅ FIXED: Create request data in the EXACT format backend expects
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

    print('✅ Saving template with corrected format:');
    print('formTitle: ${formData.formTitle}');
    print('fields count: ${formData.fields.length}');

    final response = await _dio.post(
      '/save/',
      data: requestData,
    );

    if (response.data['success'] == true) {
      // ✅ FIXED: Safe response parsing with null checks
      final responseData = response.data['data'];
      if (responseData != null) {
        return FormTemplate.fromJson(responseData);
      } else {
        throw Exception('No data in response');
      }
    } else {
      throw Exception(response.data['message'] ?? 'Failed to save template');
    }
  } on DioException catch (e) {
    print('❌ Dio Error during save:');
    print('Message: ${e.message}');
    print('Status: ${e.response?.statusCode}');
    print('Data: ${e.response?.data}');
    
    if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['errors'] != null) {
        final errors = errorData['errors'] as List;
        final errorMessages = errors.map((error) {
          if (error is Map) {
            return error.entries.map((entry) => '${entry.key}: ${entry.value.join(", ")}').join("; ");
          }
          return error.toString();
        }).join("; ");
        throw Exception('Validation errors: $errorMessages');
      } else if (errorData != null && errorData['message'] != null) {
        throw Exception(errorData['message']);
      }
    }
    throw Exception('Network error: ${e.message}');
  } catch (e, stackTrace) {
    print('❌ Unexpected error during save: $e');
    print('Stack trace: $stackTrace');
    throw Exception('Failed to save template: $e');
  }
}

  /// Alternative save method with simpler structure
  Future<FormTemplate> saveTemplateSimple(form_models.FormData formData) async {
    try {
      // Generate unique name
      final name = formData.name ?? formData.generateName();

      // Create a simplified request structure that matches backend expectations
      final requestData = {
        'name': name,
        'formTitle': formData.formTitle,
        'formDescription': formData.formDescription,
        'fields': formData.fields.map((field) => field.toJson()).toList(),
        // Optionally include the full react_form_data if needed
        'react_form_data': formData.toJson(),
      };

      print('Saving template (simple format)');
      print('Form Title: ${formData.formTitle}');
      print('Fields: ${formData.fields.length}');

      final response = await _dio.post(
        '/save/',
        data: requestData,
      );

      if (response.data['success'] == true) {
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save template');
      }
    } on DioException catch (e) {
      print('Save error: ${e.response?.data}');
      rethrow;
    }
  }

  /// Update existing template
/// Update existing template - FIXED: Match backend expected format
  Future<FormTemplate> updateTemplate(String templateId, form_models.FormData formData) async {
    try {
      // Generate JSON Schema and UI Schema
      final jsonSchema = JSONSchemaGenerator.generateJSONSchema(formData);
      final uiSchema = JSONSchemaGenerator.generateUISchema(formData);

      // ✅ FIXED: Use the same format as saveTemplate
      final requestData = {
        'formTitle': formData.formTitle,
        'formDescription': formData.formDescription,
        'fields': formData.fields.map((field) => field.toJson()).toList(),
        'headerConfig': formData.headerConfig.toJson(),
        'react_form_data': formData.toJson(),
        'json_schema': jsonSchema,
        'ui_schema': uiSchema,
      };

      print('✅ Updating template with corrected format:');
      print('formTitle: ${formData.formTitle}');
      print('fields count: ${formData.fields.length}');

      final response = await _dio.put(
        '/templates/$templateId/',
        data: requestData,
      );

      if (response.data['success'] == true) {
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update template');
      }
    } on DioException catch (e) {
      print('❌ Dio Error during update:');
      print('Message: ${e.message}');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update template: $e');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      final response = await _dio.delete('/templates/$templateId/');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete template');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete template: $e');
    }
  }

  // ========== FORM SUBMISSION OPERATIONS ==========

  /// Submit form data
  Future<String> submitForm(String templateId, Map<String, dynamic> formData) async {
    try {
      final response = await _dio.post(
        '/submit/$templateId/',
        data: {
          'formData': formData,
          'metadata': {
            'submittedAt': DateTime.now().toIso8601String(),
            'platform': 'Flutter',
          },
        },
      );

      if (response.data['success'] == true) {
        return response.data['data']['submission_id'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit form');
      }
    } on DioException catch (e) {
      print('Submit form error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit form: $e');
    }
  }

  /// Get form submissions
  Future<List<FormSubmission>> getSubmissions(
    String templateId, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = filters != null ? '?${_buildQueryString(filters)}' : '';
      final endpoint = '/submissions/$templateId/$queryParams';

      final response = await _dio.get(endpoint);

      if (response.data['success'] == true) {
        final results = response.data['data']['results'] as List;
        return results.map((json) => FormSubmission.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load submissions');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load submissions: $e');
    }
  }

  /// Get single submission
  Future<FormSubmission> getSubmission(String submissionId) async {
    try {
      final response = await _dio.get('/submission/$submissionId/');

      if (response.data['success'] == true) {
        return FormSubmission.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load submission');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load submission: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  /// Build query string from map
  String _buildQueryString(Map<String, dynamic> params) {
    return params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&');
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/templates/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  /// Test API data format compatibility
Future<void> testDataFormat(form_models.FormData formData) async {
  final testData = {
    'name': formData.name ?? formData.generateName(),
    'formTitle': formData.formTitle,
    'formDescription': formData.formDescription,
    'fields': formData.fields.map((field) => field.toJson()).toList(),
    'headerConfig': formData.headerConfig.toJson(),
  };
  
  print('🔍 Testing data format:');
  print('Keys: ${testData.keys.toList()}');
  print('formTitle: ${testData['formTitle']}');
  print('fields type: ${testData['fields'].runtimeType}');
  print('fields length: ${(testData['fields'] as List).length}');
}

  /// Generate public form URL
  String generatePublicFormUrl(String templateId) {
    return 'http://127.0.0.1:5173/public/form/$templateId';
  }
}