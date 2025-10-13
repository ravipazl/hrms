import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../models/form_builder/form_template.dart';
import '../models/form_builder/form_data.dart' as form_models;
import '../models/form_builder/form_submission.dart';
import '../models/form_builder/file_metadata.dart';
import '../utils/json_schema_generator.dart';

/// FormBuilder API Service - handles all API communication with Django backend
class FormBuilderAPIService {
  final Dio _dio;
  final CookieJar? _cookieJar;
  static const String baseUrl = 'http://127.0.0.1:8000/form-builder/api';

  FormBuilderAPIService()
      : _dio = Dio(),
        _cookieJar = CookieJar() {
    try {
      if (_cookieJar != null) {
        _dio.interceptors.add(CookieManager(_cookieJar));
      }
    } catch (e) {
      print('Cookie manager not available (web platform): $e');
    }
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Get CSRF Token from cookies
  Future<String?> _getCSRFToken() async {
    if (_cookieJar == null) return null;
    
    try {
      final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
      final csrfCookie = cookies.firstWhere(
        (cookie) => cookie.name == 'csrftoken',
        orElse: () => Cookie('', ''),
      );
      return csrfCookie.value.isNotEmpty ? csrfCookie.value : null;
    } catch (e) {
      print('Error getting CSRF token: $e');
      return null;
    }
  }

  /// Add CSRF token to headers for state-changing requests
  Future<Options> _getOptionsWithCSRF() async {
    final csrfToken = await _getCSRFToken();
    return Options(
      headers: {
        if (csrfToken != null) 'X-CSRFToken': csrfToken,
      },
    );
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

  /// Save new template
  Future<FormTemplate> saveTemplate(form_models.FormData formData) async {
    try {
      final options = await _getOptionsWithCSRF();

      // Generate unique name
      final name = formData.name ?? formData.generateName();

      // Generate JSON Schema and UI Schema
      final jsonSchema = JSONSchemaGenerator.generateJSONSchema(formData);
      final uiSchema = JSONSchemaGenerator.generateUISchema(formData);

      final requestData = {
        'name': name,
        'title': formData.formTitle,
        'description': formData.formDescription,
        'react_form_data': formData.toJson(),
        'json_schema': jsonSchema,
        'ui_schema': uiSchema,
      };

      final response = await _dio.post(
        '/save/',
        data: requestData,
        options: options,
      );

      if (response.data['success'] == true) {
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save template');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['errors'] != null) {
          final errors = errorData['errors'] as List;
          throw Exception('Validation errors: ${errors.join(', ')}');
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save template: $e');
    }
  }

  /// Update existing template
  Future<FormTemplate> updateTemplate(String templateId, form_models.FormData formData) async {
    try {
      final options = await _getOptionsWithCSRF();

      // Generate JSON Schema and UI Schema
      final jsonSchema = JSONSchemaGenerator.generateJSONSchema(formData);
      final uiSchema = JSONSchemaGenerator.generateUISchema(formData);

      final requestData = {
        'title': formData.formTitle,
        'description': formData.formDescription,
        'react_form_data': formData.toJson(),
        'json_schema': jsonSchema,
        'ui_schema': uiSchema,
      };

      final response = await _dio.put(
        '/templates/$templateId/',
        data: requestData,
        options: options,
      );

      if (response.data['success'] == true) {
        return FormTemplate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update template');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update template: $e');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      final options = await _getOptionsWithCSRF();

      final response = await _dio.delete(
        '/templates/$templateId/',
        options: options,
      );

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
      final options = await _getOptionsWithCSRF();

      final response = await _dio.post(
        '/submit/$templateId/',
        data: {
          'formData': formData,
          'metadata': {
            'submittedAt': DateTime.now().toIso8601String(),
            'platform': 'Flutter',
          },
        },
        options: options,
      );

      if (response.data['success'] == true) {
        return response.data['data']['submission_id'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit form');
      }
    } on DioException catch (e) {
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

  // ========== FILE UPLOAD OPERATIONS ==========

  /// Upload single file
  Future<FileMetadata> uploadFile(File file, String fieldId) async {
    try {
      final options = await _getOptionsWithCSRF();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        'field_id': fieldId,
      });

      final response = await _dio.post(
        '/upload-file/',
        data: formData,
        options: options,
      );

      if (response.data['success'] == true) {
        return FileMetadata.fromJson(response.data['file']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload file');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload multiple files
  Future<List<FileMetadata>> uploadFiles(List<File> files, String fieldId) async {
    final List<FileMetadata> uploadedFiles = [];

    for (final file in files) {
      try {
        final metadata = await uploadFile(file, fieldId);
        uploadedFiles.add(metadata);
      } catch (e) {
        print('Failed to upload ${file.path}: $e');
        // Continue with other files
      }
    }

    return uploadedFiles;
  }

  /// Get file view URL
  String getFileViewUrl(String accessToken, String storedPath) {
    return '$baseUrl/view-file/?token=$accessToken&path=${Uri.encodeComponent(storedPath)}';
  }

  /// Get file download URL
  String getFileDownloadUrl(String accessToken, String storedPath) {
    return '$baseUrl/download-file/?token=$accessToken&path=${Uri.encodeComponent(storedPath)}';
  }

  // ========== VALIDATION OPERATIONS ==========

  /// Validate form data against schema
  Future<Map<String, dynamic>> validateFormData(
    String templateId,
    Map<String, dynamic> formData,
  ) async {
    try {
      final options = await _getOptionsWithCSRF();

      final response = await _dio.post(
        '/validate/',
        data: {
          'template_id': templateId,
          'form_data': formData,
        },
        options: options,
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Validation failed');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to validate form: $e');
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

  /// Generate public form URL
  String generatePublicFormUrl(String templateId) {
    return 'http://127.0.0.1:5173/public/form/$templateId';
  }
}
