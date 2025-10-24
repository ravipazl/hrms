import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../models/form_builder/enhanced_header_config.dart';
import '../../../services/form_builder_api_service.dart';
import '../../../utils/form_submission_handler.dart';
import '../header/form_header_preview.dart';
import 'preview_field_renderer.dart';
import 'dart:convert'; // For JSON encoding debug

class FormPreviewScreen extends StatefulWidget {
  final List<form_models.FormField> fields;
  final String? formTitle;
  final String? formDescription;
  final HeaderConfig? headerConfig;
  final Function(Map<String, dynamic>)? onSubmit;
  final String? templateId;
   
  const FormPreviewScreen({
    super.key,
    required this.fields,
    this.formTitle,
    this.formDescription,
    this.headerConfig,
    this.onSubmit,
    this.templateId,
  });

  @override
  State<FormPreviewScreen> createState() => _FormPreviewScreenState();
}

class _FormPreviewScreenState extends State<FormPreviewScreen> {
  final Map<String, dynamic> _formData = {};
  final Map<String, List<String>> _validationErrors = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔧 Initializing form with ${widget.fields.length} fields');
    
    // Initialize form data with default values for fields
    for (final field in widget.fields) {
      if (field.defaultValue != null) {
        _formData[field.id] = field.defaultValue;
        debugPrint('  ✅ ${field.label} (${field.id}): ${field.defaultValue} (from default)');
      } else if (field.type == form_models.FieldType.checkbox) {
        _formData[field.id] = false;
        debugPrint('  ✅ ${field.label} (${field.id}): false (checkbox)');
      } else if (field.type == form_models.FieldType.checkboxGroup) {
        _formData[field.id] = [];
        debugPrint('  ✅ ${field.label} (${field.id}): [] (checkbox group)');
      } else if (field.type == form_models.FieldType.date) {
        // ✅ Initialize date fields as empty string (not null!)
        _formData[field.id] = '';
        debugPrint('  ✅ ${field.label} (${field.id}): "" (date field)');
      } else if (field.type == form_models.FieldType.table) {
        // Initialize table with configured rows or empty rows
        final minRows = field.props['minRows'] ?? 1;
        final configuredRows = field.props['rows'];
        if (configuredRows is List && configuredRows.isNotEmpty) {
          _formData[field.id] = configuredRows;
          debugPrint('  ✅ ${field.label} (${field.id}): ${configuredRows.length} rows (from config)');
        } else {
          _formData[field.id] = List.generate(minRows, (index) => {
            'id': 'row_${DateTime.now().millisecondsSinceEpoch}_$index',
            'data': <String, dynamic>{},
          });
          debugPrint('  ✅ ${field.label} (${field.id}): $minRows empty rows (table)');
        }
      } else {
        // ✅ Don't initialize other fields - only set when user enters data
        // This prevents sending empty strings for all fields
        debugPrint('  ⏭️  ${field.label} (${field.id}): not initialized (${field.type.name})');
      }
    }
    
    debugPrint('🎯 Form initialized with ${_formData.length} fields');
  }

  // Update field value WITHOUT rebuilding the entire form
  void _updateFieldValue(String fieldId, dynamic value) {
    // Directly update the map without setState to avoid full form rebuild
    _formData[fieldId] = value;
    debugPrint('📝 Field $fieldId updated to: $value');
  }

  // Only validate and rebuild when needed (on submit)
  bool _validateForm() {
    setState(() {
      _validationErrors.clear();
      
      for (final field in widget.fields) {
        // ✅ SKIP validation for rich text and table fields
        if (field.type == form_models.FieldType.richText || 
            field.type == form_models.FieldType.table) {
          debugPrint('⏭️  Skipping validation for ${field.type.name} field: ${field.label}');
          continue;
        }
        
        final value = _formData[field.id];
        final errors = <String>[];
        
        // Required field validation (skip for rich text and table)
        if (field.required) {
          if (value == null || 
              (value is String && value.trim().isEmpty) ||
              (value is List && value.isEmpty)) {
            errors.add('${field.label} is required');
          }
        }
        
        // Field-specific validation
        if (value != null && value != '') {
          // Email validation
          if (field.type == form_models.FieldType.email) {
            if (value is String && value.isNotEmpty && !_isValidEmail(value)) {
              errors.add('Invalid email format');
            }
          }
          
          // URL validation
          if (field.type == form_models.FieldType.url) {
            if (value is String && value.isNotEmpty && !_isValidUrl(value)) {
              errors.add('Invalid URL format');
            }
          }
          
          // Number validation
          if (field.type == form_models.FieldType.number) {
            final min = field.props['min'];
            final max = field.props['max'];
            if (value is num) {
              if (min != null && value < min) {
                errors.add('Minimum value is $min');
              }
              if (max != null && value > max) {
                errors.add('Maximum value is $max');
              }
            }
          }
          
          // Text length validation
          if (field.type == form_models.FieldType.text ||
              field.type == form_models.FieldType.textarea) {
            if (value is String) {
              final minLength = field.props['minLength'];
              final maxLength = field.props['maxLength'];
              if (minLength != null && value.length < minLength) {
                errors.add('Minimum length is $minLength characters');
              }
              if (maxLength != null && value.length > maxLength) {
                errors.add('Maximum length is $maxLength characters');
              }
            }
          }
        }
        
        if (errors.isNotEmpty) {
          _validationErrors[field.id] = errors;
        }
      }
    });
    
    debugPrint('📋 Validation complete. Errors: ${_validationErrors.length}');
    if (_validationErrors.isNotEmpty) {
      debugPrint('❌ Validation errors: $_validationErrors');
    }
    return _validationErrors.isEmpty;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidUrl(String url) {
    return RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    ).hasMatch(url);
  }

  // Handle form submission with detailed logging
  Future<void> _handleSubmit() async {
    debugPrint('🚀 Submit button clicked');
    debugPrint('📊 Current form data: ${jsonEncode(_formData)}');
    
    // Validate form first
    if (!_validateForm()) {
      _showValidationErrorSnackBar();
      return;
    }

    debugPrint('✅ Validation passed');

    // If custom onSubmit is provided, use it
    if (widget.onSubmit != null) {
      debugPrint('📤 Using custom onSubmit callback');
      widget.onSubmit!(_formData);
      return;
    }

    // Otherwise, submit to backend if templateId is provided
    if (widget.templateId == null) {
      debugPrint('❌ No template ID provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit: No template ID provided'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('📤 Submitting to backend. Template ID: ${widget.templateId}');
    
    // Submit to backend
    setState(() => _isSubmitting = true);

    try {
      // Get API service from context
      final apiService = Provider.of<FormBuilderAPIService>(
        context,
        listen: false,
      );

      debugPrint('🔧 API service obtained');
      
      final submissionHandler = FormSubmissionHandler(apiService);
      
      debugPrint('📨 Calling submitFormData...');
      final submissionId = await submissionHandler.submitFormData(
        templateId: widget.templateId!,
        formData: _formData,
        context: context,
      );

      debugPrint('✅ Submission successful: $submissionId');

      // Show success dialog
      if (mounted) {
        FormSubmissionHandler.showSuccessDialog(context, submissionId);
      }
    } on FormSubmissionException catch (e) {
      debugPrint('❌ FormSubmissionException: ${e.message}');
      debugPrint('   Errors: ${e.errors}');
      if (mounted) {
        FormSubmissionHandler.showErrorDialog(
          context,
          e.message,
          errors: e.errors,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (mounted) {
        FormSubmissionHandler.showErrorDialog(
          context,
          'An unexpected error occurred',
          errors: [e.toString()],
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showValidationErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please fix ${_validationErrors.length} error(s) before submitting',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with full configuration (scrolls with content)
          FormHeaderPreview(
            formTitle: widget.formTitle,
            formDescription: widget.formDescription,
            headerConfig: widget.headerConfig ?? HeaderConfig.defaultConfig(),
            mode: 'preview',
          ),
          
          // Fields (combined with header in same scroll)
          if (widget.fields.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(
                child: Text(
                  'No fields added yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGridLayout(widget.fields),
            ),
          
          // Submit button (scrolls with content)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Submitting...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build fields with automatic grid layout
  /// Fields flow inline based on their width (12-column grid)
  Widget _buildGridLayout(List<form_models.FormField> fields) {
    final List<Widget> rows = [];
    List<Widget> currentRow = [];
    int currentRowWidth = 0;

    for (final field in fields) {
      final fieldWidth = field.width;

      // If adding this field exceeds 12 columns, start a new row
      if (currentRowWidth + fieldWidth > 12 && currentRow.isNotEmpty) {
        rows.add(_buildRow(currentRow, currentRowWidth));
        currentRow = [];
        currentRowWidth = 0;
      }

      // Add field to current row
      currentRow.add(
        Expanded(
          flex: fieldWidth,
          child: PreviewFieldRenderer(
            key: ValueKey('renderer_${field.id}'),
            field: field,
            value: _formData[field.id],
            onChanged: (value) => _updateFieldValue(field.id, value),
            error: _validationErrors[field.id],
          ),
        ),
      );
      currentRowWidth += fieldWidth;

      // If row is complete (12 columns), finalize it
      if (currentRowWidth >= 12) {
        rows.add(_buildRow(currentRow, currentRowWidth));
        currentRow = [];
        currentRowWidth = 0;
      }
    }

    // Add remaining fields in the last row
    if (currentRow.isNotEmpty) {
      rows.add(_buildRow(currentRow, currentRowWidth));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildRow(List<Widget> fields, int totalWidth) {
    // If row doesn't fill 12 columns, add spacer
    final List<Widget> rowChildren = List.from(fields);
    
    if (totalWidth < 12) {
      rowChildren.add(Expanded(flex: 12 - totalWidth, child: const SizedBox()));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ),
    );
  }
}
