import '../models/form_builder/form_data.dart';
import '../models/form_builder/form_field.dart' as form_models; 

/// JSON Schema Generator - Converts Flutter FormData to JSON Schema format for backend
/// Generates both JSON Schema and UI Schema
class JSONSchemaGenerator {
  /// Generate JSON Schema from FormData
  static Map<String, dynamic> generateJSONSchema(FormData formData) {
    final properties = <String, dynamic>{};
    final required = <String>{};
 
    for (final field in formData.fields) {
      // Add to required list if field is required
      if (field.required) {
        required.add(field.id);
      }

      // Generate schema for each field type
      properties[field.id] = _generateFieldSchema(field);
    }

    return <String, dynamic>{
      '\$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'title': formData.formTitle,
      'description': formData.formDescription,
      'properties': properties,
      if (required.isNotEmpty) 'required': required.toList(),
    };
  }

  /// Generate UI Schema from FormData
  static Map<String, dynamic> generateUISchema(FormData formData) {
    final uiSchema = <String, dynamic>{};

    for (final field in formData.fields) {
      uiSchema[field.id] = _generateFieldUISchema(field);
    }

    // Add form-level configuration
    uiSchema['ui:order'] = formData.fields.map((f) => f.id).toList();
    uiSchema['ui:submitButtonOptions'] = <String, dynamic>{
      'submitText': 'Submit',
      'norender': false,
      'props': <String, dynamic>{
        'disabled': false,
      },
    };

    return uiSchema;
  }

  /// Generate schema for individual field
  static Map<String, dynamic> _generateFieldSchema(form_models.FormField field) {
    switch (field.type) {
      case form_models.FieldType.text:
      case form_models.FieldType.email:
      case form_models.FieldType.password:
      case form_models.FieldType.tel:
      case form_models.FieldType.url:
        return _generateTextSchema(field);

      case form_models.FieldType.textarea:
        return _generateTextareaSchema(field);

      case form_models.FieldType.number:
        return _generateNumberSchema(field);

      case form_models.FieldType.select:
        return _generateSelectSchema(field);

      case form_models.FieldType.radio:
        return _generateRadioSchema(field);

      case form_models.FieldType.checkbox:
        return _generateCheckboxSchema(field);

      case form_models.FieldType.checkboxGroup:
        return _generateCheckboxGroupSchema(field);

      case form_models.FieldType.date:
        return _generateDateSchema(field);

      case form_models.FieldType.time:
        return _generateTimeSchema(field);

      case form_models.FieldType.file:
        return _generateFileSchema(field);

      case form_models.FieldType.signature:
        return _generateSignatureSchema(field);

      case form_models.FieldType.richText:
        return _generateRichTextSchema(field);

      case form_models.FieldType.table:
        return _generateTableSchema(field);

      default:
        return _generateTextSchema(field);
    }
  }

  /// Generate UI schema for individual field
  static Map<String, dynamic> _generateFieldUISchema(form_models.FormField field) {
    final uiSchema = <String, dynamic>{
      'ui:title': field.label,
      'ui:placeholder': field.placeholder ?? '',
      'ui:widget': _getUIWidget(field.type),
      'ui:options': {
        'width': field.width,
        'height': field.height,
        'required': field.required,
        ...field.props,
      },
    };

    // Add type-specific UI options
    switch (field.type) {
      case form_models.FieldType.textarea:
        uiSchema['ui:widget'] = 'textarea';
        uiSchema['ui:options']['rows'] = field.props['rows'] ?? 4;
        break;

      case form_models.FieldType.password:
        uiSchema['ui:widget'] = 'password';
        break;

      case form_models.FieldType.email:
        uiSchema['ui:widget'] = 'email';
        break;

      case form_models.FieldType.url:
        uiSchema['ui:widget'] = 'url';
        break;

      case form_models.FieldType.date:
        uiSchema['ui:widget'] = 'date';
        break;

      case form_models.FieldType.time:
        uiSchema['ui:widget'] = 'time';
        break;

      case form_models.FieldType.file:
        uiSchema['ui:widget'] = 'file';
        uiSchema['ui:options']['accept'] = field.props['accept'];
        uiSchema['ui:options']['multiple'] = field.props['multiple'];
        break;

      case form_models.FieldType.checkboxGroup:
        uiSchema['ui:widget'] = 'checkboxes';
        uiSchema['ui:options']['inline'] = field.props['layout'] == 'horizontal';
        break;

      case form_models.FieldType.radio:
        uiSchema['ui:widget'] = 'radio';
        break;

      case form_models.FieldType.richText:
        uiSchema['ui:widget'] = 'richText';
        break;

      case form_models.FieldType.table:
        uiSchema['ui:widget'] = 'table';
        break;

      default:
        break;
    }

    return uiSchema;
  }

  // ========== SCHEMA GENERATORS FOR EACH FIELD TYPE ==========

  static Map<String, dynamic> _generateTextSchema(form_models.FormField field) {
    final schema = <String, dynamic>{
      'type': 'string',
      'title': field.label,
    };

    if (field.placeholder != null) {
      schema['description'] = field.placeholder!;
    }

    if (field.defaultValue != null) {
      schema['default'] = field.defaultValue;
    }

    // Add validation rules
    if (field.props['minLength'] != null) {
      schema['minLength'] = field.props['minLength'];
    }

    if (field.props['maxLength'] != null) {
      schema['maxLength'] = field.props['maxLength'];
    }

    // Type-specific patterns
    if (field.type == form_models.FieldType.email) {
      schema['format'] = 'email';
    } else if (field.type == form_models.FieldType.url) {
      schema['format'] = 'uri';
    }

    return schema;
  }

  static Map<String, dynamic> _generateTextareaSchema(form_models.FormField field) {
    final schema = <String, dynamic>{
      'type': 'string',
      'title': field.label,
    };

    if (field.placeholder != null) {
      schema['description'] = field.placeholder!;
    }

    if (field.defaultValue != null) {
      schema['default'] = field.defaultValue;
    }

    if (field.props['minLength'] != null) {
      schema['minLength'] = field.props['minLength'];
    }

    if (field.props['maxLength'] != null) {
      schema['maxLength'] = field.props['maxLength'];
    }

    return schema;
  }

  static Map<String, dynamic> _generateNumberSchema(form_models.FormField field) {
    final schema = <String, dynamic>{
      'type': 'number',
      'title': field.label,
    };

    if (field.placeholder != null) {
      schema['description'] = field.placeholder!;
    }

    if (field.defaultValue != null) {
      schema['default'] = field.defaultValue;
    }

    if (field.props['min'] != null) {
      schema['minimum'] = field.props['min'];
    }

    if (field.props['max'] != null) {
      schema['maximum'] = field.props['max'];
    }

    if (field.props['step'] != null) {
      schema['multipleOf'] = field.props['step'];
    }

    return schema;
  }

  static Map<String, dynamic> _generateSelectSchema(form_models.FormField field) {
    final options = List<String>.from(field.props['options'] ?? []);

    return <String, dynamic>{
      'type': 'string',
      'title': field.label,
      'enum': options,
      if (field.defaultValue != null) 'default': field.defaultValue,
    };
  }

  static Map<String, dynamic> _generateRadioSchema(form_models.FormField field) {
    final options = List<String>.from(field.props['options'] ?? []);

    return <String, dynamic>{
      'type': 'string',
      'title': field.label,
      'enum': options,
      if (field.defaultValue != null) 'default': field.defaultValue,
    };
  }

  static Map<String, dynamic> _generateCheckboxSchema(form_models.FormField field) {
    return <String, dynamic>{
      'type': 'boolean',
      'title': field.label,
      if (field.defaultValue != null) 'default': field.defaultValue,
    };
  }

  static Map<String, dynamic> _generateCheckboxGroupSchema(form_models.FormField field) {
    final options = List<String>.from(field.props['options'] ?? []);

    final schema = <String, dynamic>{
      'type': 'array',
      'title': field.label,
      'items': <String, dynamic>{
        'type': 'string',
        'enum': options,
      },
      'uniqueItems': true,
    };

    if (field.defaultValue != null) {
      schema['default'] = field.defaultValue;
    }

    if (field.props['minSelections'] != null && field.props['minSelections'] > 0) {
      schema['minItems'] = field.props['minSelections'];
    }

    if (field.props['maxSelections'] != null) {
      schema['maxItems'] = field.props['maxSelections'];
    }

    return schema;
  }

  static Map<String, dynamic> _generateDateSchema(form_models.FormField field) {
    return <String, dynamic>{
      'type': 'string',
      'format': 'date',
      'title': field.label,
      if (field.defaultValue != null) 'default': field.defaultValue,
    };
  }

  static Map<String, dynamic> _generateTimeSchema(form_models.FormField field) {
    return <String, dynamic>{
      'type': 'string',
      'format': 'time',
      'title': field.label,
      if (field.defaultValue != null) 'default': field.defaultValue,
    };
  }

  static Map<String, dynamic> _generateFileSchema(form_models.FormField field) {
    final schema = <String, dynamic>{
      'type': field.props['multiple'] == true ? 'array' : 'string',
      'title': field.label,
      'format': 'data-url',
    };

    if (field.props['multiple'] == true) {
      schema['items'] = <String, dynamic>{
        'type': 'string',
        'format': 'data-url',
      };

      if (field.props['maxFiles'] != null) {
        schema['maxItems'] = field.props['maxFiles'];
      }
    }

    return schema;
  }

  static Map<String, dynamic> _generateSignatureSchema(form_models.FormField field) {
    return <String, dynamic>{
      'type': 'string',
      'title': field.label,
      'format': 'data-url',
    };
  }

  static Map<String, dynamic> _generateRichTextSchema(form_models.FormField field) {
    return <String, dynamic>{
      'type': 'object',
      'title': field.label,
      'properties': <String, dynamic>{
        'content': <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{'type': 'object'},
        },
      },
    };
  }

  static Map<String, dynamic> _generateTableSchema(form_models.FormField field) {
    final columns = List<Map<String, dynamic>>.from(field.props['columns'] ?? []);
    
    final rowSchema = <String, dynamic>{};
    for (final column in columns) {
      final columnId = column['id'];
      final columnType = column['type'];
      
      if (columnType == 'number') {
        rowSchema[columnId] = <String, dynamic>{'type': 'number'};
      } else if (columnType == 'checkbox') {
        rowSchema[columnId] = <String, dynamic>{'type': 'boolean'};
      } else if (columnType == 'select' || columnType == 'radio') {
        final options = List<String>.from(column['fieldProps']?['options'] ?? []);
        rowSchema[columnId] = <String, dynamic>{
          'type': 'string',
          'enum': options,
        };
      } else {
        rowSchema[columnId] = <String, dynamic>{'type': 'string'};
      }
    }

    return <String, dynamic>{
      'type': 'array',
      'title': field.label,
      'items': <String, dynamic>{
        'type': 'object',
        'properties': rowSchema,
      },
      if (field.props['minRows'] != null) 'minItems': field.props['minRows'],
      if (field.props['maxRows'] != null) 'maxItems': field.props['maxRows'],
    };
  }

  // ========== HELPER METHODS ==========

  static String _getUIWidget(form_models.FieldType type) {
    switch (type) {
      case form_models.FieldType.text:
        return 'text';
      case form_models.FieldType.email:
        return 'email';
      case form_models.FieldType.password:
        return 'password';
      case form_models.FieldType.number:
        return 'number';
      case form_models.FieldType.textarea:
        return 'textarea';
      case form_models.FieldType.tel:
        return 'tel';
      case form_models.FieldType.url:
        return 'url';
      case form_models.FieldType.select:
        return 'select';
      case form_models.FieldType.radio:
        return 'radio';
      case form_models.FieldType.checkbox:
        return 'checkbox';
      case form_models.FieldType.checkboxGroup:
        return 'checkboxes';
      case form_models.FieldType.date:
        return 'date';
      case form_models.FieldType.time:
        return 'time';
      case form_models.FieldType.file:
        return 'file';
      case form_models.FieldType.signature:
        return 'signature';
      case form_models.FieldType.richText:
        return 'richText';
      case form_models.FieldType.table:
        return 'table';
      default:
        return 'text';
    }
  }

  /// Generate complete form package with all schemas
  static Map<String, dynamic> generateCompleteSchema(FormData formData) {
    return <String, dynamic>{
      'react_form_data': formData.toJson(),
      'json_schema': generateJSONSchema(formData),
      'ui_schema': generateUISchema(formData),
      'header_config': formData.headerConfig.toJson(),
    };
  }
}
