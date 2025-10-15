import 'package:uuid/uuid.dart';

/// Enum for all supported field types
enum FieldType {
  text,
  email,
  password,
  number,
  textarea,
  tel,
  url,
  select,
  radio,
  checkbox,
  checkboxGroup,
  date,
  time,
  file,
  signature,
  richText,
  table,
}

/// Extension to convert FieldType to string and vice versa
extension FieldTypeExtension on FieldType {
  String toShortString() {
    return toString().split('.').last;
  }

  static FieldType fromString(String value) {
    return FieldType.values.firstWhere(
      (e) => e.toShortString() == value,
      orElse: () => FieldType.text,
    );
  }
}

/// FormField model - represents a single field in the form
class FormField {
  final String id;
  final FieldType type;
  final String label;
  final String? placeholder;
  final bool required;
  final int width; // 1-12 (grid columns)
  final int height; // 1-n (row span)
  final dynamic value;
  final dynamic defaultValue;
  final Map<String, dynamic> props; // Type-specific properties

  FormField({
    required this.id,
    required this.type,
    required this.label,
    this.placeholder,
    this.required = false,
    this.width = 12,
    this.height = 1,
    this.value,
    this.defaultValue,
    Map<String, dynamic>? props,
  }) : props = props ?? {};

  /// Create a default field of a specific type
  factory FormField.createDefault(FieldType type) {
    final uuid = Uuid();
    final id =
        'field_${DateTime.now().millisecondsSinceEpoch}_${uuid.v4().substring(0, 8)}';

    switch (type) {
      case FieldType.text:
        return FormField(
          id: id,
          type: type,
          label: 'Text Field',
          placeholder: 'Enter text...',
          required: false,
          props: {'maxLength': 100, 'minLength': null},
        );

      case FieldType.email:
        return FormField(
          id: id,
          type: type,
          label: 'Email',
          placeholder: 'Enter email...',
          required: false,
        );

      case FieldType.password:
        return FormField(
          id: id,
          type: type,
          label: 'Password',
          placeholder: 'Enter password...',
          required: false,
          props: {
            'minLength': 8,
            'showStrengthIndicator': true,
            'confirmPassword': false,
          },
        );

      case FieldType.number:
        return FormField(
          id: id,
          type: type,
          label: 'Number',
          placeholder: 'Enter number...',
          required: false,
          props: {'min': 0, 'max': 1000, 'step': 1},
        );

      case FieldType.textarea:
        return FormField(
          id: id,
          type: type,
          label: 'Description',
          placeholder: 'Enter text...',
          required: false,
          props: {'rows': 4, 'maxLength': 500},
        );

      case FieldType.select:
        return FormField(
          id: id,
          type: type,
          label: 'Select Option',
          required: false,
          props: {
            'options': ['Option 1', 'Option 2', 'Option 3'],
          },
        );

      case FieldType.radio:
        return FormField(
          id: id,
          type: type,
          label: 'Choose One',
          required: false,
          props: {
            'options': ['Option 1', 'Option 2', 'Option 3'],
          },
        );

      case FieldType.checkbox:
        return FormField(
          id: id,
          type: type,
          label: 'Check this box',
          required: false,
          value: false,
          defaultValue: false,
        );

      case FieldType.checkboxGroup:
        return FormField(
          id: id,
          type: type,
          label: 'Select Options',
          required: false,
          value: [],
          defaultValue: [],
          props: {
            'options': ['Option 1', 'Option 2', 'Option 3'],
            'minSelections': 0,
            'maxSelections': null,
            'layout': 'vertical',
            'allowOther': false,
            'otherLabel': 'Other',
          },
        );

      case FieldType.date:
        return FormField(id: id, type: type, label: 'Date', required: false);

      case FieldType.time:
        return FormField(id: id, type: type, label: 'Time', required: false);

      case FieldType.tel:
        return FormField(
          id: id,
          type: type,
          label: 'Phone Number',
          placeholder: 'Enter phone number...',
          required: false,
        );

      case FieldType.url:
        return FormField(
          id: id,
          type: type,
          label: 'Website URL',
          placeholder: 'https://example.com',
          required: false,
        );

      case FieldType.file:
        return FormField(
          id: id,
          type: type,
          label: 'Upload File',
          required: false,
          value: null,
          props: {
            'accept': '*',
            'multiple': false,
            'maxFileSize': 10 * 1024 * 1024, // 10MB
            'maxFiles': 5,
            'allowedTypes': ['*'],
            'showPreview': true,
            'allowRemove': true,
            'allowReorder': true,
            'showFileSize': true,
            'compressionEnabled': false,
            'compressionQuality': 0.8,
          },
        );

      case FieldType.signature:
        return FormField(
          id: id,
          type: type,
          label: 'Signature',
          required: false,
          height: 3,
          props: {
            'penColor': '#000000',
            'backgroundColor': '#ffffff',
            'clearButton': true,
            'downloadButton': false,
          },
        );

      case FieldType.richText:
        return FormField(
          id: id,
          type: type,
          label: 'Rich Text',
          required: false,
          height: 1,
          props: {
            'content': [
              {
                'type': 'paragraph',
                'children': [
                  {'text': ''},
                ],
              },
            ],
            'embeddedFields': [],
            'toolbar': {
              'bold': true,
              'italic': true,
              'underline': true,
              'strike': true,
              'code': true,
              'headings': true,
              'align': true,
              'lists': true,
              'link': true,
              'quote': true,
              'insertFields': [
                'text',
                'number',
                'email',
                'date',
                'select',
                'checkbox',
                'radio',
                'textarea',
              ],
            },
          },
        );

      case FieldType.table:
        return FormField(
          id: id,
          type: type,
          label: 'Dynamic Table',
          required: false,
          value: [],
          props: {
            'columns': [
              {
                'id': 'col1',
                'name': 'Text Column',
                'type': 'text',
                'label': 'Text Column',
                'required': false,
                'width': 'auto',
                'fieldProps': {'placeholder': 'Enter text...'},
              },
              {
                'id': 'col2',
                'name': 'Number Column',
                'type': 'number',
                'label': 'Number Column',
                'required': false,
                'width': 'auto',
                'fieldProps': {
                  'placeholder': 'Enter number...',
                  'min': 0,
                  'max': 1000,
                },
              },
            ],
            'rows': [
              {'id': 'row1', 'data': {}},
              {'id': 'row2', 'data': {}},
            ],
            'minRows': 1,
            'maxRows': 50,
            'allowAddRows': true,
            'allowDeleteRows': true,
            'allowReorderRows': true,
            'allowAddColumns': true,
            'allowDeleteColumns': true,
            'allowReorderColumns': true,
            'showRowNumbers': true,
            'showSerialNumbers': false,
            'striped': true,
            'bordered': true,
            'compact': false,
            'exportable': true,
          },
        );

      default:
        return FormField(
          id: id,
          type: FieldType.text,
          label: 'Text Field',
          placeholder: 'Enter text...',
        );
    }
  }

  /// Create from JSON
  factory FormField.fromJson(Map<String, dynamic> json) {
    return FormField(
      id: json['id'] as String,
      type: FieldTypeExtension.fromString(json['type'] as String),
      label: json['label'] as String,
      placeholder: json['placeholder'] as String?,
      required: json['required'] as bool? ?? false,
      width: json['width'] as int? ?? 12,
      height: json['height'] as int? ?? 1,
      value: json['value'],
      defaultValue: json['defaultValue'],
      props: Map<String, dynamic>.from(json)..removeWhere(
        (key, value) => [
          'id',
          'type',
          'label',
          'placeholder',
          'required',
          'width',
          'height',
          'value',
          'defaultValue',
        ].contains(key),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toShortString(),
      'label': label,
      'placeholder': placeholder,
      'required': required,
      'width': width,
      'height': height,
      'value': value,
      'defaultValue': defaultValue,
      ...props,
    };
  }

  /// Create a copy with modified properties
  FormField copyWith({
    String? id,
    FieldType? type,
    String? label,
    String? placeholder,
    bool? required,
    int? width,
    int? height,
    dynamic value,
    dynamic defaultValue,
    Map<String, dynamic>? props,
  }) {
    return FormField(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      required: required ?? this.required,
      width: width ?? this.width,
      height: height ?? this.height,
      value: value ?? this.value,
      defaultValue: defaultValue ?? this.defaultValue,
      props: props ?? Map<String, dynamic>.from(this.props),
    );
  }

  /// Update from map (for property panel updates)
  FormField updateFromMap(Map<String, dynamic> updates) {
    final updatedProps = Map<String, dynamic>.from(props);

    updates.forEach((key, value) {
      if ([
        'id',
        'type',
        'label',
        'placeholder',
        'required',
        'width',
        'height',
        'value',
        'defaultValue',
      ].contains(key)) {
        // Skip - these are handled by copyWith
      } else {
        updatedProps[key] = value;
      }
    });

    return copyWith(
      label: updates['label'] as String?,
      placeholder: updates['placeholder'] as String?,
      required: updates['required'] as bool?,
      width: updates['width'] as int?,
      height: updates['height'] as int?,
      value: updates.containsKey('value') ? updates['value'] : value,
      defaultValue:
          updates.containsKey('defaultValue')
              ? updates['defaultValue']
              : defaultValue,
      props: updatedProps,
    );
  }

  /// Validate field configuration and return errors
  List<String> validate() {
    final errors = <String>[];

    if (label.trim().isEmpty) {
      errors.add('Label is required');
    }

    switch (type) {
      case FieldType.text:
      case FieldType.textarea:
      case FieldType.richText:
      case FieldType.email:
      case FieldType.password:
      case FieldType.number:
      case FieldType.tel:
      case FieldType.url:
      case FieldType.time:
      case FieldType.date:
        // No additional validation for simple fields yet
        break;
      case FieldType.select:
      case FieldType.radio:
      case FieldType.checkboxGroup:
        final options = props['options'];
        if (options is! List || options.isEmpty) {
          errors.add('At least one option is required');
        }
        break;
      case FieldType.checkbox:
        // Checkbox can be standalone, no extra validation
        break;
      case FieldType.file:
        final maxFileSize = props['maxFileSize'];
        if (maxFileSize is int && maxFileSize <= 0) {
          errors.add('Max file size must be greater than zero');
        }
        break;
      case FieldType.signature:
        // No extra validation
        break;
      case FieldType.table:
        final columns = props['columns'];
        if (columns is! List || columns.isEmpty) {
          errors.add('At least one column is required');
        }
        break;
    }

    return errors;
  }
}
