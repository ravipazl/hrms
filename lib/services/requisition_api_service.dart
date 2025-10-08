// lib/services/requisition_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/requisition/requisition.dart';

class RequisitionApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  late final Dio _dio;

  RequisitionApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Request interceptor for logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 ${options.method.toUpperCase()} ${options.path}');
        if (options.data != null) {
          print('📤 Request payload: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.path} - ${response.statusCode}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ API Error: ${error.message}');
        if (error.response?.data != null) {
          print('🔍 Error response: ${error.response?.data}');
        }
        handler.next(error);
      },
    ));
  }

  /// Test API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🧪 Testing API connection...');
      final response = await _dio.get('/reference-data/');
      print('✅ API connection successful: ${response.statusCode}');
      return {
        'success': true,
        'status': response.statusCode,
        'data': response.data
      };
    } catch (error) {
      print('❌ API connection failed: $error');
      return {
        'success': false,
        'error': error.toString(),
      };
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
      if (department?.isNotEmpty == true) queryParams['department'] = department;
      if (status?.isNotEmpty == true) queryParams['status'] = status;
      queryParams['page'] = page;
      queryParams['page_size'] = pageSize;

      final response = await _dio.get('/requisition/', queryParameters: queryParams);
      
      final data = response.data;
      List<Requisition> requisitions = [];
      int total = 0;

      if (data['results'] != null && data['results'] is List) {
        // Paginated response
        requisitions = (data['results'] as List)
            .map((req) => Requisition.fromJson(req))
            .toList();
        total = data['count'] ?? 0;
      } else if (data is List) {
        // Non-paginated response
        requisitions = data.map((req) => Requisition.fromJson(req)).toList();
        total = requisitions.length;
      }

      print('✅ Requisitions fetched: ${requisitions.length} of $total');
      
      return {
        'results': requisitions,
        'count': total,
        'success': true,
      };
    } catch (error) {
      print('❌ Error fetching requisitions: $error');
      throw _handleApiError(error);
    }
  }

  /// Get specific requisition by ID
  Future<Requisition> getRequisition(int id) async {
    try {
      print('🔍 Fetching requisition with ID: $id');
      final response = await _dio.get('/requisition/$id/');
      print('✅ Requisition fetched');
      
      return Requisition.fromJson(response.data);
    } catch (error) {
      print('❌ Error fetching requisition $id: $error');
      throw _handleApiError(error);
    }
  }

  /// Create new requisition
  Future<Requisition> createRequisition(Requisition requisition, {File? jobDocument}) async {
    try {
      print('📝 Creating requisition...');
      
      final mappedData = _mapFormDataToBackend(requisition);
      print('📤 Mapped data structure: $mappedData');

      if (jobDocument != null) {
        // File upload with FormData
        print('📎 File upload detected, using FormData');
        
        final formData = FormData();
        
        // Add all fields
        mappedData.forEach((key, value) {
          if (key != 'job_document' && value != null) {
            if (value is List || value is Map) {
              formData.fields.add(MapEntry(key, jsonEncode(value)));
            } else {
              formData.fields.add(MapEntry(key, value.toString()));
            }
          }
        });
        
        // Add file
        formData.files.add(MapEntry(
          'job_document',
          await MultipartFile.fromFile(jobDocument.path),
        ));
        
        final response = await _dio.post(
          '/requisition/',
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );
        
        print('✅ Requisition created with file upload');
        return Requisition.fromJson(response.data);
      } else {
        // Regular JSON request
        print('🚀 Sending JSON data to API');
        
        final response = await _dio.post('/requisition/', data: mappedData);
        print('✅ Requisition created successfully');
        print('📥 Response data type: ${response.data.runtimeType}');
        print('📥 Response data: ${response.data}');
        
        try {
          return Requisition.fromJson(response.data);
        } catch (parseError) {
          print('❌ Error parsing response: $parseError');
          print('📥 Raw response: ${response.data}');
          rethrow;
        }
      }
    } catch (error) {
      print('❌ Error creating requisition: $error');
      throw _handleApiError(error);
    }
  }

  /// Update requisition
  Future<Requisition> updateRequisition(int id, Requisition requisition, {File? jobDocument}) async {
    try {
      print('📝 Updating requisition $id');
      
      final mappedData = _mapFormDataToBackend(requisition);
      print('📤 Mapped data for update: $mappedData');

      if (jobDocument != null) {
        // File upload with FormData
        print('📎 File upload detected for update, using FormData');
        
        final formData = FormData();
        
        // Add all fields
        mappedData.forEach((key, value) {
          if (key != 'job_document' && value != null) {
            if (value is List || value is Map) {
              formData.fields.add(MapEntry(key, jsonEncode(value)));
            } else {
              formData.fields.add(MapEntry(key, value.toString()));
            }
          }
        });
        
        // Add file
        formData.files.add(MapEntry(
          'jobDocument',
          await MultipartFile.fromFile(jobDocument.path),
        ));
        
        final response = await _dio.put(
          '/requisition/$id/',
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );
        
        print('✅ Requisition updated with file');
        return Requisition.fromJson(response.data);
      } else {
        // Regular JSON request
        print('🚀 Sending JSON update data to API');
        
        final response = await _dio.put('/requisition/$id/', data: mappedData);
        print('✅ Requisition updated successfully');
        print('📥 Response data type: ${response.data.runtimeType}');
        print('📥 Response data: ${response.data}');
        
        try {
          return Requisition.fromJson(response.data);
        } catch (parseError) {
          print('❌ Error parsing response: $parseError');
          print('📥 Raw response: ${response.data}');
          rethrow;
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
      await _dio.delete('/requisition/$id/');
      print('✅ Requisition deleted successfully');
    } catch (error) {
      print('❌ Error deleting requisition $id: $error');
      throw _handleApiError(error);
    }
  }

  /// Update requisition status
  Future<Map<String, dynamic>> updateRequisitionStatus(int id, String status) async {
    try {
      print('🔄 Updating requisition $id status to: $status');
      
      final response = await _dio.patch('/requisition/$id/status/', data: {
        'status': status,
      });
      
      print('✅ Requisition status updated successfully');
      return response.data;
    } catch (error) {
      print('❌ Error updating requisition $id status: $error');
      throw _handleApiError(error);
    }
  }

  /// Get reference data for dropdowns
  Future<List<ReferenceData>> getReferenceData(int referenceTypeId) async {
    try {
      print('📋 Fetching reference data for type: $referenceTypeId');
      
      final response = await _dio.get('/reference-data/', queryParameters: {
        'reference_type': referenceTypeId,
      });
      
      final data = response.data;
      List<dynamic> referenceList;
      
      if (data['results'] != null) {
        referenceList = data['results'];
      } else if (data is List) {
        referenceList = data;
      } else {
        throw Exception('Invalid reference data format');
      }

      final references = referenceList
          .map((ref) => ReferenceData.fromJson(ref))
          .toList();
      
      print('✅ Reference data fetched: ${references.length} items');
      return references;
    } catch (error) {
      print('❌ Error fetching reference data: $error');
      return [];
    }
  }

  /// Map frontend form data to backend API format
  Map<String, dynamic> _mapFormDataToBackend(Requisition requisition) {
    print('📤 Mapping frontend form data to backend format');
    
    // Map skills to proper format
    final skillsArray = <Map<String, dynamic>>[];
    
    // Handle essential skills
    if (requisition.essentialSkills.isNotEmpty) {
      final essentialSkillsList = requisition.essentialSkills
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty);
      
      for (final skill in essentialSkillsList) {
        skillsArray.add({
          'skill': skill,
          'skill_type': 'essential',
        });
      }
    }
    
    // Handle desired skills
    if (requisition.desiredSkills?.isNotEmpty == true) {
      final desiredSkillsList = requisition.desiredSkills!
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty);
      
      for (final skill in desiredSkillsList) {
        skillsArray.add({
          'skill': skill,
          'skill_type': 'desired',
        });
      }
    }
    
    // Map positions to proper format
    final positionsArray = requisition.positions
        .map((position) => position.toJson())
        .toList();
    
    final mappedData = {
      'jobPosition': requisition.jobPosition,
      'department': requisition.department,
      'qualification': requisition.qualification,
      'experience': requisition.experience,
      'jobDescription': requisition.jobDescription ?? '',
      'skills': skillsArray,
      'positions': positionsArray,
      'mentionThreeMonths': requisition.mentionThreeMonths ?? {
        'month1': '',
        'month2': '',
        'month3': ''
      },
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
    if (error is DioException) {
      final response = error.response;
      
      if (response != null) {
        final data = response.data;
        String message = 'An error occurred';
        
        if (data is Map<String, dynamic>) {
          message = data['error'] ?? 
                   data['message'] ?? 
                   data['detail'] ?? 
                   'Server error: ${response.statusCode}';
        } else if (data is String) {
          message = data;
        }
        
        return Exception('API Error: $message');
      } else {
        return Exception('Network error: ${error.message}');
      }
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
      
      if (position.typeRequisition == '2') { // Replacement
        if (position.employeeName?.trim().isEmpty != false) {
          errors.add('$prefix Employee name is required for replacement');
        }
        if (position.employeeNo?.trim().isEmpty != false) {
          errors.add('$prefix Employee number is required for replacement');
        }
      }
    }

    return errors;
  }
}
