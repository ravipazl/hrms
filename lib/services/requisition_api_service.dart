// lib/services/requisition_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:hrms/models/requisition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/file_preview.dart';
import 'api_config.dart';
import 'auth_service.dart';

class RequisitionApiService {
  final Dio _dio;
  final AuthService _authService;

  RequisitionApiService({AuthService? authService})
    : _authService = authService ?? AuthService(),
      _dio = Dio() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = ApiConfig.djangoBaseUrl;
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

    // Add interceptor to include CSRF token
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
          print(
            '❌ API Error: ${error.response?.statusCode} - ${error.message}',
          );
          if (error.response?.statusCode == 403 ||
              error.response?.statusCode == 401) {
            print('🔐 Authentication required - please login');
          }
          return handler.next(error);
        },
      ),
    );

    // Logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        requestHeader: true,
        responseHeader: true,
        logPrint: (obj) => print('🌐 [API] $obj'),
      ),
    );
  }

  /// Test API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🧪 Testing API connection...');
      final response = await _dio.get('${ApiConfig.baseUrl}/reference-data/');

      if (response.statusCode == 200) {
        print('✅ API connection successful: ${response.statusCode}');
        return {
          'success': true,
          'status': response.statusCode,
          'data': response.data,
        };
      } else {
        throw Exception('API connection failed: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ API connection failed: $error');
      print('🛠️ API unavailable, using fallback data for development');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Get all requisitions with filters
  Future<Map<String, dynamic>> getRequisitions({
    String? search,
    String? department,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('📋 Fetching requisitions with filters');

      final queryParams = <String, dynamic>{};
      if (search?.isNotEmpty == true) queryParams['search'] = search;
      if (department?.isNotEmpty == true)
        queryParams['department'] = department;
      if (status?.isNotEmpty == true) queryParams['status'] = status;
      queryParams['page'] = page.toString();
      queryParams['page_size'] = pageSize.toString();

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/requisition/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<Requisition> requisitions = [];
        int total = 0;

        if (data['results'] != null && data['results'] is List) {
          // Paginated response
          requisitions =
              (data['results'] as List)
                  .map(
                    (req) => Requisition.fromJson(req as Map<String, dynamic>),
                  )
                  .toList();
          total = data['count'] ?? 0;
        } else if (data is List) {
          // Non-paginated response
          requisitions =
              data
                  .map(
                    (req) => Requisition.fromJson(req as Map<String, dynamic>),
                  )
                  .toList();
          total = requisitions.length;
        }

        print('✅ Requisitions fetched: ${requisitions.length} of $total');

        return {'results': requisitions, 'count': total, 'success': true};
      } else {
        throw Exception('Failed to fetch requisitions: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error fetching requisitions: $error');

      // For development, return empty list instead of mock data
      print('🛠️ Returning empty results for development');
      return {
        'results': <Requisition>[],
        'count': 0,
        'success': false,
        'error': error.toString(),
      };
    }
  }

  /// Get specific requisition by ID for editing (detailed data)
  Future<Requisition> getRequisition(int id) async {
    try {
      print('🔍 Fetching DETAILED requisition for editing - ID: $id');
      print('📡 API URL: ${ApiConfig.baseUrl}/requisition/$id/');

      // Use the detail endpoint which returns complete requisition data
      final response = await _dio.get('${ApiConfig.baseUrl}/requisition/$id/');

      print('✅ API Response received:');
      print('   - Status Code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch requisition: ${response.statusCode}');
      }

      final data = response.data;

      // Log raw response data for debugging
      print('📥 Raw API Response:');
      print('   - ID: ${data['id']}');
      print(
        '   - Job Position: ${data['job_position'] ?? data['jobPosition']}',
      );
      print('   - Department: ${data['department']}');
      print('   - Qualification: ${data['qualification']}');
      print('   - Positions: ${data['positions']?.length ?? 0}');

      // Parse the detailed response into Requisition model
      final requisition = Requisition.fromJson(data);

      print('✅ Requisition parsed successfully:');
      print('   - ID: ${requisition.id}');
      print('   - Job Position: ${requisition.jobPosition}');
      print('   - Department: ${requisition.department}');
      print('   - Qualification: ${requisition.qualification}');
      print('   - Essential Skills: ${requisition.essentialSkills}');
      print('   - Positions count: ${requisition.positions.length}');
      print('   - Skills count: ${requisition.skills.length}');

      return requisition;
    } catch (error) {
      print('❌ Error fetching detailed requisition $id: $error');
      print('⚠️ API unavailable - throwing error');
      throw Exception('Failed to fetch requisition: $error');
    }
  }

  /// Create new requisition with multiple files support
  Future<Requisition> createRequisition(
    Requisition requisition, {
    List<FilePreview>? jobDocuments,
  }) async {
    try {
      print('\n' + '=' * 80);
      print('📝 API SERVICE - CREATE REQUISITION');
      print('=' * 80);
      print(
        'Requisition.justificationText: "${requisition.justificationText}"',
      );
      print('=' * 80);

      print('📝 Creating requisition...');
      print('📤 Files to upload: ${jobDocuments?.length ?? 0}');

      final mappedData = _mapFormDataToBackend(requisition);
      print('\n📦 MAPPED DATA TO SEND:');
      print('=' * 80);
      mappedData.forEach((key, value) {
        if (key == 'preference_justification') {
          print('✨ $key: "$value"');
        } else if (value is List || value is Map) {
          print('$key: ${value.runtimeType}');
        } else {
          print('$key: $value');
        }
      });
      print('=' * 80);
      print('');

      if (jobDocuments != null && jobDocuments.isNotEmpty) {
        // File upload with MultipartRequest
        print('📎 Multiple files detected, using MultipartRequest');

        final uri = Uri.parse('${ApiConfig.baseUrl}/requisition/');
        final request = http.MultipartRequest('POST', uri);

        // Add headers
        request.headers['Content-Type'] = 'multipart/form-data';

        // Add fields
        mappedData.forEach((key, value) {
          if (value != null) {
            if (value is List || value is Map) {
              request.fields[key] = jsonEncode(value);
            } else {
              request.fields[key] = value.toString();
            }
          }
        });

        // Add multiple files with indexed field names (job_document_0, job_document_1, etc.)
        for (var i = 0; i < jobDocuments.length; i++) {
          final filePreview = jobDocuments[i];
          if (filePreview.isNew) {
            if (kIsWeb && filePreview.platformFile?.bytes != null) {
              // Web platform
              request.files.add(
                http.MultipartFile.fromBytes(
                  'job_document_$i', // ✅ FIXED: Use indexed field name
                  filePreview.platformFile!.bytes!,
                  filename: filePreview.name,
                ),
              );
              print(
                '🔌 Added web file ${i + 1}: ${filePreview.name} as job_document_$i',
              );
            } else if (!kIsWeb && filePreview.file != null) {
              // Mobile platform
              request.files.add(
                await http.MultipartFile.fromPath(
                  'job_document_$i', // ✅ FIXED: Use indexed field name
                  filePreview.file!.path,
                  filename: filePreview.name,
                ),
              );
              print(
                '🔌 Added mobile file ${i + 1}: ${filePreview.name} as job_document_$i',
              );
            }
          }
        }

        print(
          '🚀 Sending multipart request with ${request.files.length} file(s)',
        );
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Requisition created with ${request.files.length} file(s)');
          return Requisition.fromJson(json.decode(response.body));
        } else {
          print('❌ Failed: ${response.statusCode} - ${response.body}');
          throw Exception(
            'Failed to create requisition: ${response.statusCode}',
          );
        }
      } else {
        // Regular JSON request (no files)
        print('🚀 Sending JSON data to API (no files)');

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/requisition/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(mappedData),
        );

        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Requisition created successfully');
          return Requisition.fromJson(json.decode(response.body));
        } else {
          print('❌ Failed: ${response.statusCode} - ${response.body}');
          throw Exception(
            'Failed to create requisition: ${response.statusCode}',
          );
        }
      }
    } catch (error) {
      print('❌ Error creating requisition: $error');
      throw _handleApiError(error);
    }
  }

  /// Update requisition with multiple files support
  Future<Requisition> updateRequisition(
    int id,
    Requisition requisition, {
    List<FilePreview>? jobDocuments,
    List<FilePreview>? existingFiles,
  }) async {
    try {
      print('📝 Updating requisition $id');
      print('📤 New files: ${jobDocuments?.length ?? 0}');
      print('📤 Existing files: ${existingFiles?.length ?? 0}');

      final mappedData = _mapFormDataToBackend(requisition);
      print('📤 Mapped data for update: $mappedData');

      if (jobDocuments != null && jobDocuments.isNotEmpty) {
        // File upload with MultipartRequest
        print('📎 Files detected for update, using MultipartRequest');

        final uri = Uri.parse('${ApiConfig.baseUrl}/requisition/$id/');
        final request = http.MultipartRequest('PUT', uri);

        // Add headers
        request.headers['Content-Type'] = 'multipart/form-data';

        // Add fields
        mappedData.forEach((key, value) {
          if (value != null) {
            if (value is List || value is Map) {
              request.fields[key] = jsonEncode(value);
            } else {
              request.fields[key] = value.toString();
            }
          }
        });

        // Add existing files metadata
        if (existingFiles != null && existingFiles.isNotEmpty) {
          request.fields['existing_files'] = jsonEncode(
            existingFiles.map((f) => f.toJson()).toList(),
          );
          print('📦 Sent ${existingFiles.length} existing file(s) metadata');
        }

        // Add new files with indexed field names (job_document_0, job_document_1, etc.)
        for (var i = 0; i < jobDocuments.length; i++) {
          final filePreview = jobDocuments[i];
          if (filePreview.isNew) {
            if (kIsWeb && filePreview.platformFile?.bytes != null) {
              // Web platform
              request.files.add(
                http.MultipartFile.fromBytes(
                  'job_document_$i', // ✅ FIXED: Use indexed field name
                  filePreview.platformFile!.bytes!,
                  filename: filePreview.name,
                ),
              );
              print(
                '🔌 Added web file ${i + 1}: ${filePreview.name} as job_document_$i',
              );
            } else if (!kIsWeb && filePreview.file != null) {
              // Mobile platform
              request.files.add(
                await http.MultipartFile.fromPath(
                  'job_document_$i', // ✅ FIXED: Use indexed field name
                  filePreview.file!.path,
                  filename: filePreview.name,
                ),
              );
              print(
                '🔌 Added mobile file ${i + 1}: ${filePreview.name} as job_document_$i',
              );
            }
          }
        }

        print(
          '🚀 Sending multipart update with ${request.files.length} new file(s)',
        );
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          print('✅ Requisition updated with files');
          return Requisition.fromJson(json.decode(response.body));
        } else {
          print('❌ Failed: ${response.statusCode} - ${response.body}');
          throw Exception(
            'Failed to update requisition: ${response.statusCode}',
          );
        }
      } else {
        // Regular JSON request (no new files)
        print('🚀 Sending JSON update data to API');

        // Add existing files metadata if provided
        if (existingFiles != null && existingFiles.isNotEmpty) {
          mappedData['existing_files'] =
              existingFiles.map((f) => f.toJson()).toList();
          print(
            '📦 Including ${existingFiles.length} existing file(s) in JSON',
          );
        }

        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/requisition/$id/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(mappedData),
        );

        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ Requisition updated successfully');
          return Requisition.fromJson(json.decode(response.body));
        } else {
          print('❌ Failed: ${response.statusCode} - ${response.body}');
          throw Exception(
            'Failed to update requisition: ${response.statusCode}',
          );
        }
      }
    } catch (error) {
      print('❌ Error updating requisition $id: $error');
      throw _handleApiError(error);
    }
  }

  /// Delete requisition
  Future<void> deleteRequisition(int id) async {
    try {
      print('🗑️ Deleting requisition $id');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/requisition/$id/'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Requisition deleted successfully');
      } else {
        throw Exception('Failed to delete requisition: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error deleting requisition $id: $error');
      throw _handleApiError(error);
    }
  }

  /// Update requisition status - Fixed to use correct PATCH endpoint
  Future<Requisition> updateRequisitionStatus(int id, String status) async {
    try {
      print('🔄 Updating requisition $id status to: $status');

      // ✅ FIXED: Use the correct endpoint ${ApiConfig.baseUrl}/requisition/$id/ with PATCH method
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/requisition/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Requisition status updated successfully');
        // Return the full updated requisition object
        return Requisition.fromJson(json.decode(response.body));
      } else {
        print('❌ Failed: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to update status: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (error) {
      print('❌ Error updating requisition $id status: $error');
      throw _handleApiError(error);
    }
  }

  /// Get reference data for dropdowns
  Future<List<ReferenceData>> getReferenceData(int referenceTypeId) async {
    try {
      print('📋 Fetching reference data for type: $referenceTypeId');

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/reference-data/',
        queryParameters: {'reference_type': referenceTypeId.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> referenceList;

        if (data['results'] != null) {
          referenceList = data['results'];
        } else if (data is List) {
          referenceList = data;
        } else {
          throw Exception('Invalid reference data format');
        }

        final references =
            referenceList
                .map(
                  (ref) => ReferenceData.fromJson(ref as Map<String, dynamic>),
                )
                .toList();

        print('✅ Reference data fetched: ${references.length} items');
        return references;
      } else {
        throw Exception(
          'Failed to fetch reference data: ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Error fetching reference data: $error');
      print('⚠️ API unavailable - returning empty list');
      return [];
    }
  }

  /// Map frontend form data to backend API format compatible with Django
  Map<String, dynamic> _mapFormDataToBackend(Requisition requisition) {
    print('📤 Mapping frontend form data to Django backend format');

    // Map skills to Django expected format
    final skillsArray = <Map<String, dynamic>>[];

    // Handle essential skills
    if (requisition.essentialSkills.isNotEmpty) {
      final essentialSkillsList = requisition.essentialSkills
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty);

      for (final skill in essentialSkillsList) {
        skillsArray.add({'skill': skill, 'skill_type': 'essential'});
      }
    }

    // Handle desired skills
    if (requisition.desiredSkills?.isNotEmpty == true) {
      final desiredSkillsList = requisition.desiredSkills!
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty);

      for (final skill in desiredSkillsList) {
        skillsArray.add({'skill': skill, 'skill_type': 'desired'});
      }
    }

    // Map positions to Django expected format
    final positionsArray =
        requisition.positions
            .map(
              (position) => {
                'type_requisition': position.typeRequisition,
                'requirements_requisition_newhire':
                    position.requirementsRequisitionNewhire ?? '',
                'requirements_requisition_replacement':
                    position.requirementsRequisitionReplacement ?? '',
                'requisition_quantity': position.requisitionQuantity.toString(),
                'vacancy_to_be_filled_on': position.vacancyToBeFilled,
                'employment_type': position.employmentType ?? '',
                'employee_name': position.employeeName ?? '',
                'employee_no': position.employeeNo ?? '',
                'date_of_resignation': position.dateOfResignation,
                'resignation_reason': position.resignationReason ?? '',
                'justification_text': position.justificationText ?? '',
              },
            )
            .toList();

    // Create Django-compatible payload
    final mappedData = {
      'jobPosition': requisition.jobPosition,
      'department': requisition.department,
      'qualification': requisition.qualification,
      'experience': requisition.experience,
      'jobDescription': requisition.jobDescription ?? '',
      'skills': skillsArray,
      'positions': positionsArray,
      'mentionThreeMonths':
          requisition.mentionThreeMonths ??
          {'month1': '', 'month2': '', 'month3': ''},
    };

    // Add optional fields only if not empty
    if (requisition.preferredGender?.isNotEmpty == true) {
      mappedData['preferred_gender'] = requisition.preferredGender!;
    }
    if (requisition.preferredAgeGroup?.isNotEmpty == true) {
      mappedData['preferredAgeGroup'] = requisition.preferredAgeGroup!;
    }
    if (requisition.justificationText?.isNotEmpty == true) {
      mappedData['justificationText'] = requisition.justificationText!;
    }

    print('📤 Final mapped data keys: ${mappedData.keys}');
    print('📤 Skills array length: ${skillsArray.length}');
    print('📤 Positions array length: ${positionsArray.length}');

    return mappedData;
  }

  /// Handle API errors consistently
  Exception _handleApiError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('Unexpected error: $error');
  }

  /// Validate form data before submission
  List<String> validateFormData(Requisition requisition) {
    final errors = <String>[];

    if (requisition.jobPosition.trim().isEmpty) {
      errors.add('Job position is required');
    }

    if (requisition.department.trim().isEmpty) {
      errors.add('Department is required');
    }

    if (requisition.qualification.trim().isEmpty) {
      errors.add('Qualification is required');
    }

    if (requisition.experience.trim().isEmpty) {
      errors.add('Experience requirement is required');
    }

    if (requisition.essentialSkills.trim().isEmpty) {
      errors.add('Essential skills are required');
    }

    if (requisition.positions.isEmpty) {
      errors.add('At least one position is required');
    }

    // Validate each position
    for (int i = 0; i < requisition.positions.length; i++) {
      final position = requisition.positions[i];
      final prefix = 'Position ${i + 1}:';

      if (position.typeRequisition.isEmpty) {
        errors.add('$prefix Requisition type is required');
      }

      if (position.requisitionQuantity <= 0) {
        errors.add('$prefix Quantity must be greater than 0');
      }

      // Skip replacement validation - backend will handle it based on typeRequisition
      // The validation is now done on the backend based on the actual type value
    }

    return errors;
  }
}
