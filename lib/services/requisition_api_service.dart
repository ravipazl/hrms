// lib/services/requisition_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:hrms/models/requisition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/file_preview.dart';
import 'api_config.dart';

class RequisitionApiService {
  /// Test API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🧪 Testing API connection...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.referenceDataEndpoint}'),
      );
      
      if (response.statusCode == 200) {
        print('✅ API connection successful: ${response.statusCode}');
        return {
          'success': true,
          'status': response.statusCode,
          'data': json.decode(response.body)
        };
      } else {
        throw Exception('API connection failed: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ API connection failed: $error');
      print('🛠️ API unavailable, using fallback data for development');
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
      
      final queryParams = <String, String>{};
      if (search?.isNotEmpty == true) queryParams['search'] = search!;
      if (department?.isNotEmpty == true) queryParams['department'] = department!;
      if (status?.isNotEmpty == true) queryParams['status'] = status!;
      queryParams['page'] = page.toString();
      queryParams['page_size'] = pageSize.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requisitionEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
          requisitions = data.map((req) => Requisition.fromJson(req as Map<String, dynamic>)).toList();
          total = requisitions.length;
        }

        print('✅ Requisitions fetched: ${requisitions.length} of $total');
        
        return {
          'results': requisitions,
          'count': total,
          'success': true,
        };
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
      print('📡 API URL: ${ApiConfig.baseUrl}${ApiConfig.requisitionEndpoint}$id/');
      
      // Use the detail endpoint which returns complete requisition data
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requisitionEndpoint}$id/'),
      );
      
      print('✅ API Response received:');
      print('   - Status Code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch requisition: ${response.statusCode}');
      }
      
      if (response.body.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final data = json.decode(response.body);
      
      // Log raw response data for debugging
      print('📥 Raw API Response:');
      print('   - ID: ${data['id']}');
      print('   - Job Position: ${data['job_position'] ?? data['jobPosition']}');
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
      
      // For development, provide a basic requisition object
      print('🛠️ Creating fallback requisition for development');
      return _createFallbackRequisition(id);
    }
  }
  
  /// Create a fallback requisition for development
  Requisition _createFallbackRequisition(int id) {
    print('🛠️ Creating fallback requisition with ID: $id');
    
    return Requisition(
      id: id,
      requisitionId: 'DEV-REQ-$id',
      jobPosition: 'Sample Job Position $id',
      department: '1',
      qualification: 'Bachelor\'s Degree in Computer Science',
      experience: '2-3 years of relevant experience',
      essentialSkills: 'Communication, Problem Solving, Technical Skills',
      desiredSkills: 'Leadership, Project Management',
      jobDescription: 'Sample job description for requisition $id',
      justificationText: 'Sample justification for this position',
      positions: [
        RequisitionPosition(
          id: 1,
          typeRequisition: '1',
          requisitionQuantity: 1,
          vacancyToBeFilled: DateTime.now().add(Duration(days: 30)).toIso8601String().split('T')[0],
          employmentType: '1',
          justificationText: 'Sample position justification',
        ),
      ],
      skills: [
        RequisitionSkill(id: 1, skill: 'Communication', skillType: 'essential'),
        RequisitionSkill(id: 2, skill: 'Problem Solving', skillType: 'essential'),
        RequisitionSkill(id: 3, skill: 'Leadership', skillType: 'desired'),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create new requisition with multiple files support
  Future<Requisition> createRequisition(
    Requisition requisition, {
    List<FilePreview>? jobDocuments,
  }) async {
    try {
      print('\n' + '='*80);
      print('📝 API SERVICE - CREATE REQUISITION');
      print('='*80);
      print('Requisition.justificationText: "${requisition.justificationText}"');
      print('='*80);
      
      print('📝 Creating requisition...');
      print('📤 Files to upload: ${jobDocuments?.length ?? 0}');
      
      final mappedData = _mapFormDataToBackend(requisition);
      print('\n📦 MAPPED DATA TO SEND:');
      print('='*80);
      mappedData.forEach((key, value) {
        if (key == 'preference_justification') {
          print('✨ $key: "$value"');
        } else if (value is List || value is Map) {
          print('$key: ${value.runtimeType}');
        } else {
          print('$key: $value');
        }
      });
      print('='*80);
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
        
        // Add multiple files
        for (var i = 0; i < jobDocuments.length; i++) {
          final filePreview = jobDocuments[i];
          if (filePreview.isNew) {
            if (kIsWeb && filePreview.platformFile?.bytes != null) {
              // Web platform
              request.files.add(
                http.MultipartFile.fromBytes(
                  'job_documents', // Use same field name for all files
                  filePreview.platformFile!.bytes!,
                  filename: filePreview.name,
                ),
              );
              print('🔌 Added web file ${i + 1}: ${filePreview.name}');
            } else if (!kIsWeb && filePreview.file != null) {
              // Mobile platform
              request.files.add(
                await http.MultipartFile.fromPath(
                  'job_documents',
                  filePreview.file!.path,
                  filename: filePreview.name,
                ),
              );
              print('🔌 Added mobile file ${i + 1}: ${filePreview.name}');
            }
          }
        }
        
        print('🚀 Sending multipart request with ${request.files.length} file(s)');
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Requisition created with ${request.files.length} file(s)');
          return Requisition.fromJson(json.decode(response.body));
        } else {
          print('❌ Failed: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to create requisition: ${response.statusCode}');
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
          throw Exception('Failed to create requisition: ${response.statusCode}');
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
            existingFiles.map((f) => f.toJson()).toList()
          );
          print('📦 Sent ${existingFiles.length} existing file(s) metadata');
        }
        
        // Add new files
        for (var i = 0; i < jobDocuments.length; i++) {
          final filePreview = jobDocuments[i];
          if (filePreview.isNew) {
            if (kIsWeb && filePreview.platformFile?.bytes != null) {
              // Web platform
              request.files.add(
                http.MultipartFile.fromBytes(
                  'job_documents',
                  filePreview.platformFile!.bytes!,
                  filename: filePreview.name,
                ),
              );
              print('🔌 Added web file ${i + 1}: ${filePreview.name}');
            } else if (!kIsWeb && filePreview.file != null) {
              // Mobile platform
              request.files.add(
                await http.MultipartFile.fromPath(
                  'job_documents',
                  filePreview.file!.path,
                  filename: filePreview.name,
                ),
              );
              print('🔌 Added mobile file ${i + 1}: ${filePreview.name}');
            }
          }
        }
        
        print('🚀 Sending multipart update with ${request.files.length} new file(s)');
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          print('✅ Requisition updated with files');
          return Requisition.fromJson(json.decode(response.body));
        } else {
          print('❌ Failed: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to update requisition: ${response.statusCode}');
        }
      } else {
        // Regular JSON request (no new files)
        print('🚀 Sending JSON update data to API');
        
        // Add existing files metadata if provided
        if (existingFiles != null && existingFiles.isNotEmpty) {
          mappedData['existing_files'] = existingFiles.map((f) => f.toJson()).toList();
          print('📦 Including ${existingFiles.length} existing file(s) in JSON');
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
          throw Exception('Failed to update requisition: ${response.statusCode}');
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

  /// Update requisition status - EXACTLY like workflow_api_service.dart
  Future<Map<String, dynamic>> updateRequisitionStatus(int id, String status) async {
    try {
      print('🔄 Updating requisition $id status to: $status');
      
      // ✅ EXACTLY like workflow_api_service.dart - plain http with only Content-Type
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/requisition/$id/status/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Requisition status updated successfully');
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
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
      
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.referenceDataEndpoint}')
          .replace(queryParameters: {'reference_type': referenceTypeId.toString()});
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      } else {
        throw Exception('Failed to fetch reference data: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error fetching reference data: $error');
      
      // For development, provide hardcoded reference data based on Django models
      print('🛠️ Providing fallback reference data for development');
      return _getFallbackReferenceData(referenceTypeId);
    }
  }
  
  /// Provide fallback reference data based on Django model structure
  List<ReferenceData> _getFallbackReferenceData(int referenceTypeId) {
    switch (referenceTypeId) {
      case 1: // ReferenceType: Type of Requisition
        return [
          ReferenceData(id: 1, referenceValue: 'New Hire'),
          ReferenceData(id: 2, referenceValue: 'Replacement'),
        ];
      case 2: // ReferenceType: Requirements for New Hire
        return [
          ReferenceData(id: 1, referenceValue: 'Business Expansion'),
          ReferenceData(id: 2, referenceValue: 'Increased Workload'),
          ReferenceData(id: 3, referenceValue: 'New Project'),
          ReferenceData(id: 4, referenceValue: 'Skill Gap'),
        ];
      case 3: // ReferenceType: Requirements for Replacement
        return [
          ReferenceData(id: 1, referenceValue: 'Resignation'),
          ReferenceData(id: 2, referenceValue: 'Termination'),
          ReferenceData(id: 3, referenceValue: 'Retirement'),
          ReferenceData(id: 4, referenceValue: 'Transfer'),
        ];
      case 4: // ReferenceType: Employment Type
        return [
          ReferenceData(id: 1, referenceValue: 'Full-time'),
          ReferenceData(id: 2, referenceValue: 'Part-time'),
          ReferenceData(id: 3, referenceValue: 'Contract'),
          ReferenceData(id: 4, referenceValue: 'Temporary'),
        ];
      case 5: // ReferenceType: Gender
        return [
          ReferenceData(id: 1, referenceValue: 'Male'),
          ReferenceData(id: 2, referenceValue: 'Female'),
          ReferenceData(id: 3, referenceValue: 'Any'),
        ];
      case 9: // ReferenceType: Department
        return [
          ReferenceData(id: 1, referenceValue: 'Software Development'),
          ReferenceData(id: 2, referenceValue: 'UI/UX Design'),
          ReferenceData(id: 3, referenceValue: 'Quality Assurance'),
          ReferenceData(id: 4, referenceValue: 'Human Resources'),
          ReferenceData(id: 5, referenceValue: 'Medical Services'),
          ReferenceData(id: 6, referenceValue: 'Administration'),
        ];
      default:
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
    
    // Map positions to Django expected format
    final positionsArray = requisition.positions
        .map((position) => {
          'type_requisition': position.typeRequisition,
          'requirements_requisition_newhire': position.typeRequisition == '1' 
              ? (position.requirementsRequisitionNewhire ?? '')
              : '',
          'requirements_requisition_replacement': position.typeRequisition == '2' 
              ? (position.requirementsRequisitionReplacement ?? '')
              : '',
          'requisition_quantity': position.requisitionQuantity,
          'vacancy_to_be_filled_on': position.vacancyToBeFilled,
          'employment_type': position.employmentType ?? '',
          'employee_name': position.employeeName ?? '',
          'employee_no': position.employeeNo ?? '',
          'date_of_resignation': position.dateOfResignation,
          'resignation_reason': position.resignationReason ?? '',
          'justification_text': position.justificationText ?? '',
        })
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
