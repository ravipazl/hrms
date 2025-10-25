import 'package:flutter/material.dart';
import '../services/form_builder_api_service.dart';
import '../models/form_builder/form_field.dart' as form_models;
import 'dart:convert';

/// Form Submission Handler
/// Handles form data submission from preview mode to Django backend
class FormSubmissionHandler {
  final FormBuilderAPIService _apiService;
  
  FormSubmissionHandler(this._apiService);

  /// Submit form data to backend
  /// Returns submission ID on success, throws exception on failure
  Future<String> submitFormData({
    required String templateId,
    required Map<String, dynamic> formData,
    required BuildContext context,
  }) async {
    try {
      debugPrint('📤 ===== FORM SUBMISSION START =====');
      debugPrint('📋 Template ID: $templateId');
      debugPrint('📊 Total fields in form: ${formData.keys.length}');
      debugPrint('📊 Field IDs and values being sent:');
      formData.forEach((key, value) {
        final valueStr = value.toString().length > 50 
            ? '${value.toString().substring(0, 50)}...' 
            : value.toString();
        debugPrint('   ✓ $key = $valueStr (${value.runtimeType})');
      });
      
      // Validate form data before submission
      final validationErrors = _validateFormData(formData);
      if (validationErrors.isNotEmpty) {
        debugPrint('❌ Validation failed: $validationErrors');
        throw FormSubmissionException(
          'Validation failed',
          errors: validationErrors,
        );
      }
      
      debugPrint('✅ Validation passed');
      
      // Process special field types
      final processedData = _processFormDataForSubmission(formData);
      
      debugPrint('');
      debugPrint('🔄 AFTER PROCESSING:');
      debugPrint('🔄 Processed fields count: ${processedData.keys.length}');
      debugPrint('🔄 Field IDs after processing:');
      processedData.forEach((key, value) {
        final valueStr = value.toString().length > 50 
            ? '${value.toString().substring(0, 50)}...' 
            : value.toString();
        debugPrint('   ✓ $key = $valueStr (${value.runtimeType})');
      });
      
      debugPrint('');
      debugPrint('📡 Sending to backend...');
      debugPrint('📦 Full JSON payload:');
      try {
        final jsonStr = jsonEncode(processedData);
        debugPrint(jsonStr);
      } catch (e) {
        debugPrint('⚠️ Could not encode to JSON: $e');
      }
      
      // ✅ Submit to backend - API service now wraps data correctly
      final submissionId = await _apiService.submitForm(
        templateId,
        processedData,
      );
      
      debugPrint('');
      debugPrint('✅ Form submitted successfully!');
      debugPrint('🎯 Submission ID: $submissionId');
      debugPrint('📤 ===== FORM SUBMISSION END =====');
      return submissionId;
      
    } on FormSubmissionException {
      debugPrint('❌ FormSubmissionException caught, rethrowing');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ ===== FORM SUBMISSION ERROR =====');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('❌ ===== END ERROR =====');
      throw FormSubmissionException(
        'Failed to submit form: ${e.toString()}',
      );
    }
  }

  /// Validate form data structure
  List<String> _validateFormData(Map<String, dynamic> formData) {
    final errors = <String>[];
    
    if (formData.isEmpty) {
      errors.add('Form data is empty');
    }
    
    return errors;
  }

  /// Process form data for submission
  /// Handles special field types (files, rich text, tables, etc.)
  Map<String, dynamic> _processFormDataForSubmission(
    Map<String, dynamic> formData,
  ) {
    debugPrint('');
    debugPrint('🔄 PROCESSING FORM DATA:');
    debugPrint('📊 Initial field count: ${formData.keys.length}');
    
    // Process form data - no flattening needed, backend expects this structure
    final processed = <String, dynamic>{};
    int skipped = 0;
    
    formData.forEach((key, value) {
      // ✅ Skip null or empty string values (but keep false, 0, empty arrays if they're meaningful)
      if (value == null || (value is String && value.trim().isEmpty)) {
        skipped++;
        debugPrint('   ⏭️  Skipped: $key (null or empty string)');
        return;
      }
      
      // ✅ Skip empty arrays UNLESS they're checkbox groups (which can be intentionally empty)
      if (value is List && value.isEmpty) {
        // Let backend handle empty arrays - they might be valid for checkbox groups
        debugPrint('   ⚠️  Empty array: $key (sending to backend for validation)');
      }
      
      // Handle different field types
      if (value is Map) {
        final mapValue = Map<String, dynamic>.from(value);
        
        if (mapValue.containsKey('content') || mapValue.containsKey('inlineFields')) {
          debugPrint('   📝 Rich text: $key');
          processed[key] = _processRichTextField(mapValue);
        } 
        else if (mapValue.containsKey('fileUrl') || mapValue.containsKey('fileName')) {
          debugPrint('   📎 File: $key');
          processed[key] = _processFileField(mapValue);
        }
        else if (mapValue.containsKey('signature')) {
          debugPrint('   ✍️  Signature: $key');
          processed[key] = mapValue;
        }
        else {
          // This shouldn't happen after flattening, but keep as fallback
          debugPrint('   ⚠️  Unexpected nested object: $key (may cause validation error)');
          processed[key] = mapValue;
        }
      } 
      else if (value is List) {
        // ✅ Clean empty rows from tables before sending
        final cleanedList = _cleanTableRows(value);
        
        // Only skip if cleaned list is empty AND it's not a checkbox group
        if (cleanedList.isEmpty) {
          // Check if this might be a checkbox group by examining the first item
          if (value.isNotEmpty && value.first is! Map) {
            skipped++;
            debugPrint('   ⏭️  Skipped: $key (empty list after cleaning)');
            return;
          }
        }
        
        debugPrint('   📋 List: $key (${cleanedList.length} items after cleaning)');
        processed[key] = _processList(cleanedList);
      }
      else {
        // ✅ Include all scalar values (strings, numbers, booleans)
        debugPrint('   ✅ Value: $key = $value (${value.runtimeType})');
        processed[key] = value;
      }
    });
    
    debugPrint('   Summary: ${processed.length} sent, $skipped skipped');
    return processed;
  }

  /// ✅ NEW: Flatten nested field groups to match backend expectations
  /// Converts: {"groupField": {"nestedField": "value"}}
  /// To: {"nestedField": "value"}
  Map<String, dynamic> _flattenNestedFieldGroups(Map<String, dynamic> formData) {
    final flattened = <String, dynamic>{};
    int groupsFlattened = 0;
    
    debugPrint('');
    debugPrint('🔄 FLATTENING NESTED FIELD GROUPS:');
    
    formData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // Check if this is a field group (nested object with field IDs as keys)
        final nestedKeys = value.keys.toList();
        
        // Heuristic: If all keys start with 'field_', it's likely a field group
        final looksLikeFieldGroup = nestedKeys.every((k) => 
          k.toString().startsWith('field_') || 
          k.toString().startsWith('col_')
        );
        
        // Also check if it has special structure (not a known data type)
        final isKnownDataType = value.containsKey('content') || // Rich text
                                value.containsKey('fileUrl') || // File
                                value.containsKey('signature') || // Signature
                                value.containsKey('id') && value.containsKey('data'); // Table row
        
        if (looksLikeFieldGroup && !isKnownDataType && nestedKeys.isNotEmpty) {
          // This is a field group - flatten it
          debugPrint('   📦 Flattening field group: $key');
          groupsFlattened++;
          
          // Add all nested fields to the flattened map
          value.forEach((nestedKey, nestedValue) {
            debugPrint('      ↳ Extracting: $nestedKey = $nestedValue');
            flattened[nestedKey] = nestedValue;
          });
        } else {
          // Not a field group - keep as is
          flattened[key] = value;
        }
      } else {
        // Not a map - keep as is
        flattened[key] = value;
      }
    });
    
    debugPrint('   Summary: Flattened $groupsFlattened field groups');
    debugPrint('   Fields before: ${formData.keys.length}, after: ${flattened.keys.length}');
    
    return flattened;
  }

  /// Process rich text field data - PRESERVE ALL FIELDS
  Map<String, dynamic> _processRichTextField(Map<String, dynamic> richTextData) {
    debugPrint('   🔍 Processing rich text field:');
    debugPrint('      Input keys: ${richTextData.keys.toList()}');
    debugPrint('      Has embeddedFieldValues: ${richTextData.containsKey("embeddedFieldValues")}');
    if (richTextData.containsKey('embeddedFieldValues')) {
      debugPrint('      embeddedFieldValues: ${richTextData["embeddedFieldValues"]}');
    }
    
    // ✅ Return complete rich text object with ALL fields
    final processed = {
      'content': richTextData['content'] ?? '',
      'embeddedFields': richTextData['embeddedFields'] ?? [],  // ✅ Keep field definitions
      'embeddedFieldValues': richTextData['embeddedFieldValues'] ?? {},  // ✅ Keep user values!
      'inlineFields': richTextData['inlineFields'] ?? [],
    };
    
    debugPrint('      Output keys: ${processed.keys.toList()}');
    debugPrint('      Output embeddedFieldValues: ${processed["embeddedFieldValues"]}');
    
    return processed;
  }

  /// Process file field data
  Map<String, dynamic> _processFileField(Map<String, dynamic> fileData) {
    return {
      'fileUrl': fileData['fileUrl'] ?? '',
      'fileName': fileData['fileName'] ?? '',
      'fileSize': fileData['fileSize'],
      'fileType': fileData['fileType'] ?? '',
      'uploadedAt': fileData['uploadedAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  /// Clean table rows - remove rows with empty data
  List<dynamic> _cleanTableRows(List<dynamic> listData) {
    return listData.where((item) {
      if (item is Map) {
        final mapItem = Map<String, dynamic>.from(item);
        
        // Check if this is a table row
        if (mapItem.containsKey('id') && mapItem.containsKey('data')) {
          final data = mapItem['data'] as Map<String, dynamic>?;
          
          // Keep row only if data has actual values (not empty)
          if (data == null || data.isEmpty) {
            return false; // Skip empty row
          }
          
          // Check if all values in data are empty
          final hasValue = data.values.any((v) => 
            v != null && v.toString().trim().isNotEmpty
          );
          
          return hasValue; // Keep only if has at least one value
        }
      }
      return true; // Keep non-table items
    }).toList();
  }
  
  /// Process list data (handle tables, checkbox groups, etc.)
  List<dynamic> _processList(List<dynamic> listData) {
    return listData.map((item) {
      if (item is Map) {
        final mapItem = Map<String, dynamic>.from(item);
        
        // Handle table row data
        if (mapItem.containsKey('id') && mapItem.containsKey('data')) {
          return {
            'id': mapItem['id'],
            'data': mapItem['data'] ?? {},
          };
        }
        return mapItem;
      }
      return item;
    }).toList();
  }

  /// Show success dialog
  static void showSuccessDialog(
    BuildContext context,
    String submissionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Form Submitted Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your form has been submitted successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submission ID:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    submissionId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static void showErrorDialog(
    BuildContext context,
    String message, {
    List<String>? errors,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Submission Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (errors != null && errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...errors.map((error) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(error)),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Custom exception for form submission errors
class FormSubmissionException implements Exception {
  final String message;
  final List<String>? errors;
  
  FormSubmissionException(this.message, {this.errors});
  
  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return '$message: ${errors!.join(', ')}';
    }
    return message;
  }
}
