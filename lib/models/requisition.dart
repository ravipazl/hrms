// lib/models/requisition/requisition.dart

import 'dart:convert';

/// Main Requisition Model
class Requisition {
  final int? id;
  final String? requisitionId;
  final String jobPosition;
  final String department;
  final String? departmentName;
  final String? jobDescription;
  final String? jobDocument;
  final String? jobDocumentUrl;
  final List<Map<String, dynamic>>? jobDocuments; // Multiple documents as JSON
  final String jobDescriptionType; // 'text' or 'upload'
  final String? preferredGender;
  final String? preferredGenderDisplay; // Display value for gender
  final String? preferredAgeGroup;
  final String qualification;
  final String experience;
  final String? justificationText;
  final String essentialSkills;
  final String? desiredSkills;
  final String status;
  final List<RequisitionPosition> positions;
  final List<RequisitionSkill> skills;
  final Map<String, dynamic>? mentionThreeMonths;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Requisition({
    this.id,
    this.requisitionId,
    required this.jobPosition,
    required this.department,
    this.departmentName,
    this.jobDescription,
    this.jobDocument,
    this.jobDocumentUrl,
    this.jobDocuments,
    this.jobDescriptionType = 'text',
    this.preferredGender,
    this.preferredGenderDisplay,
    this.preferredAgeGroup,
    required this.qualification,
    required this.experience,
    this.justificationText,
    required this.essentialSkills,
    this.desiredSkills,
    this.status = 'Pending',
    required this.positions,
    required this.skills,
    this.mentionThreeMonths,
    this.createdAt,
    this.updatedAt,
  });

  /// Helper method to safely parse map fields
  static Map<String, dynamic>? _parseMapField(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Extract status from API response (handles both string and object)
  static String _extractStatus(dynamic status) {
    if (status == null) return 'Pending';
    if (status is String) return status;
    if (status is Map && status['reference_value'] != null) {
      return status['reference_value'].toString();
    }
    return 'Pending';
  }

  /// Extract essential skills from skills array
  static String _extractEssentialSkills(List<dynamic> skills) {
    final essentialSkills = skills
        .where((skill) => skill['skill_type'] == 'essential')
        .map((skill) => skill['skill']?.toString() ?? '')
        .where((skill) => skill.isNotEmpty)
        .toList();
    return essentialSkills.join(', ');
  }

  /// Extract desired skills from skills array
  static String? _extractDesiredSkills(List<dynamic> skills) {
    final desiredSkills = skills
        .where((skill) => skill['skill_type'] == 'desired')
        .map((skill) => skill['skill']?.toString() ?? '')
        .where((skill) => skill.isNotEmpty)
        .toList();
    return desiredSkills.isNotEmpty ? desiredSkills.join(', ') : null;
  }

  /// Helper method to construct complete URLs from relative paths
  static String? _constructCompleteUrlIfNeeded(String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) {
      return null;
    }
    
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    
    const String baseUrl = 'http://127.0.0.1:8000';
    String path = urlOrPath.startsWith('/') ? urlOrPath : '/$urlOrPath';
    final completeUrl = '$baseUrl$path';
    print('🔗 Constructed complete URL: $completeUrl (from: $urlOrPath)');
    return completeUrl;
  }

  factory Requisition.fromJson(Map<String, dynamic> json) {
    print('📝 Parsing requisition from Django API response...');
    
    List<Map<String, dynamic>>? documentsData;
    if (json['job_documents'] != null) {
      if (json['job_documents'] is List) {
        documentsData = (json['job_documents'] as List)
            .map((doc) => doc is Map<String, dynamic> ? doc : <String, dynamic>{})
            .where((doc) => doc.isNotEmpty)
            .toList();
      } else if (json['job_documents'] is String) {
        try {
          final parsed = jsonDecode(json['job_documents']);
          if (parsed is List) {
            documentsData = (parsed as List)
                .map((doc) => doc is Map<String, dynamic> ? doc : <String, dynamic>{})
                .where((doc) => doc.isNotEmpty)
                .toList();
          }
        } catch (e) {
          print('⚠️ Could not parse job_documents JSON: $e');
        }
      }
    }
    
    final skillsData = json['skills'] as List? ?? [];
    final essentialSkills = _extractEssentialSkills(skillsData);
    final desiredSkills = _extractDesiredSkills(skillsData);
    
    final positionsData = json['positions'] as List? ?? [];
    
    final requisition = Requisition(
      id: json['id'],
      requisitionId: json['requisition_id'],
      jobPosition: json['jobPosition'] ?? json['job_position'] ?? '',
      department: json['department']?.toString() ?? '',
      departmentName: json['department_display'] ?? json['department_name'],
      jobDescription: json['jobDescription'] ?? json['job_description'],
      jobDocument: _constructCompleteUrlIfNeeded(json['job_document']?.toString()),
      jobDocumentUrl: _constructCompleteUrlIfNeeded(json['job_document_url']?.toString()),
      jobDocuments: documentsData,
      jobDescriptionType: json['job_description_type'] ?? 'text',
      preferredGender: json['preferred_gender']?.toString(),
      preferredGenderDisplay: json['preferred_gender_display'], // NEW: Display value
      preferredAgeGroup: json['preferredAgeGroup'] ?? json['preferred_age_group']?.toString(),
      qualification: json['qualification'] ?? '',
      experience: json['experience']?.toString() ?? '',
      justificationText: json['justificationText'] ?? json['preference_justification'],
      essentialSkills: essentialSkills,
      desiredSkills: desiredSkills,
      status: _extractStatus(json['status']),
      positions: positionsData
          .map((pos) => RequisitionPosition.fromJson(pos))
          .toList(),
      skills: skillsData
          .map((skill) => RequisitionSkill.fromJson(skill))
          .toList(),
      mentionThreeMonths: _parseMapField(json['mentionThreeMonths'] ?? json['phased_months']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
    
    return requisition;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobPosition': jobPosition,
      'department': department,
      'job_description': jobDescription,
      'preferred_gender': preferredGender,
      'preferredAgeGroup': preferredAgeGroup,
      'qualification': qualification,
      'experience': experience,
      'justificationText': justificationText,
      'essential_skills': essentialSkills,
      'desired_skills': desiredSkills,
      'mentionThreeMonths': mentionThreeMonths ?? {
        'month1': '',
        'month2': '',
        'month3': ''
      },
      'skills': skills.map((skill) => skill.toJson()).toList(),
      'positions': positions.map((pos) => pos.toJson()).toList(),
    };
  }

  Requisition copyWith({
    int? id,
    String? requisitionId,
    String? jobPosition,
    String? department,
    String? departmentName,
    String? jobDescription,
    String? jobDocument,
    String? jobDocumentUrl,
    List<Map<String, dynamic>>? jobDocuments,
    String? jobDescriptionType,
    String? preferredGender,
    String? preferredGenderDisplay,
    String? preferredAgeGroup,
    String? qualification,
    String? experience,
    String? justificationText,
    String? essentialSkills,
    String? desiredSkills,
    String? status,
    List<RequisitionPosition>? positions,
    List<RequisitionSkill>? skills,
    Map<String, dynamic>? mentionThreeMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Requisition(
      id: id ?? this.id,
      requisitionId: requisitionId ?? this.requisitionId,
      jobPosition: jobPosition ?? this.jobPosition,
      department: department ?? this.department,
      departmentName: departmentName ?? this.departmentName,
      jobDescription: jobDescription ?? this.jobDescription,
      jobDocument: jobDocument ?? this.jobDocument,
      jobDocumentUrl: jobDocumentUrl ?? this.jobDocumentUrl,
      jobDocuments: jobDocuments ?? this.jobDocuments,
      jobDescriptionType: jobDescriptionType ?? this.jobDescriptionType,
      preferredGender: preferredGender ?? this.preferredGender,
      preferredGenderDisplay: preferredGenderDisplay ?? this.preferredGenderDisplay,
      preferredAgeGroup: preferredAgeGroup ?? this.preferredAgeGroup,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      justificationText: justificationText ?? this.justificationText,
      essentialSkills: essentialSkills ?? this.essentialSkills,
      desiredSkills: desiredSkills ?? this.desiredSkills,
      status: status ?? this.status,
      positions: positions ?? this.positions,
      skills: skills ?? this.skills,
      mentionThreeMonths: mentionThreeMonths ?? this.mentionThreeMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Requisition Position Model (Multi-position support)
class RequisitionPosition {
  final int? id;
  final String typeRequisition;
  final String? typeRequisitionDisplay; // NEW: Display value
  final String? requirementsRequisitionNewhire;
  final String? requirementsRequisitionNewhireDisplay; // NEW: Display value
  final String? requirementsRequisitionReplacement;
  final String? requirementsRequisitionReplacementDisplay; // NEW: Display value
  final int requisitionQuantity;
  final String? vacancyToBeFilled;
  final String? employmentType;
  final String? employmentTypeDisplay; // NEW: Display value
  final String? justificationText;
  final String? employeeName;
  final String? employeeNo;
  final String? dateOfResignation;
  final String? resignationReason;

  RequisitionPosition({
    this.id,
    required this.typeRequisition,
    this.typeRequisitionDisplay,
    this.requirementsRequisitionNewhire,
    this.requirementsRequisitionNewhireDisplay,
    this.requirementsRequisitionReplacement,
    this.requirementsRequisitionReplacementDisplay,
    required this.requisitionQuantity,
    this.vacancyToBeFilled,
    this.employmentType,
    this.employmentTypeDisplay,
    this.justificationText,
    this.employeeName,
    this.employeeNo,
    this.dateOfResignation,
    this.resignationReason,
  });

  factory RequisitionPosition.fromJson(Map<String, dynamic> json) {
    return RequisitionPosition(
      id: json['id'],
      typeRequisition: json['type_requisition']?.toString() ?? '1',
      typeRequisitionDisplay: json['type_requisition_display'],
      requirementsRequisitionNewhire: json['requirements_requisition_newhire']?.toString(),
      requirementsRequisitionNewhireDisplay: json['requirements_requisition_newhire_display'],
      requirementsRequisitionReplacement: json['requirements_requisition_replacement']?.toString(),
      requirementsRequisitionReplacementDisplay: json['requirements_requisition_replacement_display'],
      requisitionQuantity: json['requisition_quantity'] ?? 1,
      vacancyToBeFilled: json['vacancy_to_be_filled_on'],
      employmentType: json['employment_type']?.toString(),
      employmentTypeDisplay: json['employment_type_display'],
      justificationText: json['justification_text'],
      employeeName: json['employee_name'],
      employeeNo: json['employee_no'],
      dateOfResignation: json['date_of_resignation'],
      resignationReason: json['resignation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_requisition': typeRequisition,
      'requirements_requisition_newhire': requirementsRequisitionNewhire ?? '',
      'requirements_requisition_replacement': requirementsRequisitionReplacement ?? '',
      'requisition_quantity': requisitionQuantity,
      'vacancy_to_be_filled_on': vacancyToBeFilled,
      'employment_type': employmentType ?? '',
      'employee_name': employeeName ?? '',
      'employee_no': employeeNo ?? '',
      'date_of_resignation': dateOfResignation,
      'resignation_reason': resignationReason ?? '',
      'justification_text': justificationText ?? '',
    };
  }

  RequisitionPosition copyWith({
    int? id,
    String? typeRequisition,
    String? typeRequisitionDisplay,
    String? requirementsRequisitionNewhire,
    String? requirementsRequisitionNewhireDisplay,
    String? requirementsRequisitionReplacement,
    String? requirementsRequisitionReplacementDisplay,
    int? requisitionQuantity,
    String? vacancyToBeFilled,
    String? employmentType,
    String? employmentTypeDisplay,
    String? justificationText,
    String? employeeName,
    String? employeeNo,
    String? dateOfResignation,
    String? resignationReason,
  }) {
    return RequisitionPosition(
      id: id ?? this.id,
      typeRequisition: typeRequisition ?? this.typeRequisition,
      typeRequisitionDisplay: typeRequisitionDisplay ?? this.typeRequisitionDisplay,
      requirementsRequisitionNewhire: requirementsRequisitionNewhire ?? this.requirementsRequisitionNewhire,
      requirementsRequisitionNewhireDisplay: requirementsRequisitionNewhireDisplay ?? this.requirementsRequisitionNewhireDisplay,
      requirementsRequisitionReplacement: requirementsRequisitionReplacement ?? this.requirementsRequisitionReplacement,
      requirementsRequisitionReplacementDisplay: requirementsRequisitionReplacementDisplay ?? this.requirementsRequisitionReplacementDisplay,
      requisitionQuantity: requisitionQuantity ?? this.requisitionQuantity,
      vacancyToBeFilled: vacancyToBeFilled ?? this.vacancyToBeFilled,
      employmentType: employmentType ?? this.employmentType,
      employmentTypeDisplay: employmentTypeDisplay ?? this.employmentTypeDisplay,
      justificationText: justificationText ?? this.justificationText,
      employeeName: employeeName ?? this.employeeName,
      employeeNo: employeeNo ?? this.employeeNo,
      dateOfResignation: dateOfResignation ?? this.dateOfResignation,
      resignationReason: resignationReason ?? this.resignationReason,
    );
  }
}

/// Requisition Skill Model
class RequisitionSkill {
  final int? id;
  final String skill;
  final String skillType; // 'essential' or 'desired'

  RequisitionSkill({
    this.id,
    required this.skill,
    required this.skillType,
  });

  factory RequisitionSkill.fromJson(Map<String, dynamic> json) {
    return RequisitionSkill(
      id: json['id'],
      skill: json['skill'] ?? '',
      skillType: json['skill_type'] ?? 'essential',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'skill_type': skillType,
    };
  }
}

/// Reference Data Model for dropdowns
class ReferenceData {
  final int id;
  final String referenceValue;
  final String? description;

  ReferenceData({
    required this.id,
    required this.referenceValue,
    this.description,
  });

  factory ReferenceData.fromJson(Map<String, dynamic> json) {
    return ReferenceData(
      id: json['id'] ?? 0,
      referenceValue: json['reference_value'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_value': referenceValue,
      'description': description,
    };
  }
}

/// Requisition Status Constants
class RequisitionStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String hold = 'hold';
  
  static String getDisplayText(String status) {
    switch (status.toLowerCase()) {
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case hold:
        return 'On Hold';
      default:
        return 'Unknown';
    }
  }
}
