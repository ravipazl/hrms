// lib/models/requisition/requisition.dart

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
  final String jobDescriptionType; // 'text' or 'upload'
  final String? preferredGender;
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
    this.jobDescriptionType = 'text',
    this.preferredGender,
    this.preferredAgeGroup,
    required this.qualification,
    required this.experience,
    this.justificationText,
    required this.essentialSkills,
    this.desiredSkills,
    this.status = 'pending',
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
    if (status == null) return 'pending';
    if (status is String) return status;
    if (status is Map && status['reference_value'] != null) {
      return status['reference_value'].toString().toLowerCase().replaceAll(' ', '_');
    }
    return 'pending';
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

  factory Requisition.fromJson(Map<String, dynamic> json) {
    return Requisition(
      id: json['id'],
      requisitionId: json['requisition_id'],
      // Handle both frontend and backend field names
      jobPosition: json['jobPosition'] ?? json['job_position'] ?? '',
      department: json['department']?.toString() ?? '',
      departmentName: json['department_display'] ?? json['department_name'],
      // Handle both frontend and backend field names
      jobDescription: json['jobDescription'] ?? json['job_description'],
      jobDocument: json['job_document'],
      jobDocumentUrl: json['job_document_url'],
      jobDescriptionType: json['job_description_type'] ?? 'text',
      preferredGender: json['preferred_gender']?.toString(),
      // Handle both frontend and backend field names
      preferredAgeGroup: json['preferredAgeGroup'] ?? json['preferred_age_group']?.toString(),
      qualification: json['qualification'] ?? '',
      experience: json['experience']?.toString() ?? '',
      // Handle both frontend and backend field names
      justificationText: json['justificationText'] ?? json['preference_justification'],
      essentialSkills: _extractEssentialSkills(json['skills'] ?? []),
      desiredSkills: _extractDesiredSkills(json['skills'] ?? []),
      // Handle status object from API response
      status: _extractStatus(json['status']),
      positions: (json['positions'] as List?)
              ?.map((pos) => RequisitionPosition.fromJson(pos))
              .toList() ??
          [],
      skills: (json['skills'] as List?)
              ?.map((skill) => RequisitionSkill.fromJson(skill))
              .toList() ??
          [],
      // Handle both frontend and backend field names
      mentionThreeMonths: _parseMapField(json['mentionThreeMonths'] ?? json['phased_months']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
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
    String? jobDescriptionType,
    String? preferredGender,
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
      jobDescriptionType: jobDescriptionType ?? this.jobDescriptionType,
      preferredGender: preferredGender ?? this.preferredGender,
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
  final String? requirementsRequisitionNewhire;
  final String? requirementsRequisitionReplacement;
  final int requisitionQuantity;
  final String? vacancyToBeFilled;
  final String? employmentType;
  final String? justificationText;
  final String? employeeName;
  final String? employeeNo;
  final String? dateOfResignation;
  final String? resignationReason;

  RequisitionPosition({
    this.id,
    required this.typeRequisition,
    this.requirementsRequisitionNewhire,
    this.requirementsRequisitionReplacement,
    required this.requisitionQuantity,
    this.vacancyToBeFilled,
    this.employmentType,
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
      requirementsRequisitionNewhire: json['requirements_requisition_newhire']?.toString(),
      requirementsRequisitionReplacement: json['requirements_requisition_replacement']?.toString(),
      requisitionQuantity: json['requisition_quantity'] ?? 1,
      vacancyToBeFilled: json['vacancy_to_be_filled_on'],
      employmentType: json['employment_type']?.toString(),
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
    String? requirementsRequisitionNewhire,
    String? requirementsRequisitionReplacement,
    int? requisitionQuantity,
    String? vacancyToBeFilled,
    String? employmentType,
    String? justificationText,
    String? employeeName,
    String? employeeNo,
    String? dateOfResignation,
    String? resignationReason,
  }) {
    return RequisitionPosition(
      id: id ?? this.id,
      typeRequisition: typeRequisition ?? this.typeRequisition,
      requirementsRequisitionNewhire: requirementsRequisitionNewhire ?? this.requirementsRequisitionNewhire,
      requirementsRequisitionReplacement: requirementsRequisitionReplacement ?? this.requirementsRequisitionReplacement,
      requisitionQuantity: requisitionQuantity ?? this.requisitionQuantity,
      vacancyToBeFilled: vacancyToBeFilled ?? this.vacancyToBeFilled,
      employmentType: employmentType ?? this.employmentType,
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
