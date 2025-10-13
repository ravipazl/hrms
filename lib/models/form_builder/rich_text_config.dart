/// Rich text embedded field definition
class EmbeddedField {
  final String id;
  final String fieldType;
  final String label;
  final Map<String, dynamic> props;

  EmbeddedField({
    required this.id,
    required this.fieldType,
    required this.label,
    Map<String, dynamic>? props,
  }) : props = props ?? {};

  factory EmbeddedField.fromJson(Map<String, dynamic> json) {
    return EmbeddedField(
      id: json['id'] as String,
      fieldType: json['fieldType'] as String,
      label: json['label'] as String,
      props: json['props'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldType': fieldType,
      'label': label,
      'props': props,
    };
  }
}

/// Toolbar configuration
class RichTextToolbar {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final bool headings;
  final bool align;
  final bool lists;
  final bool link;
  final bool quote;
  final List<String> insertFields;

  RichTextToolbar({
    this.bold = true,
    this.italic = true,
    this.underline = true,
    this.strike = true,
    this.code = true,
    this.headings = true,
    this.align = true,
    this.lists = true,
    this.link = true,
    this.quote = true,
    this.insertFields = const [],
  });

  factory RichTextToolbar.fromJson(Map<String, dynamic> json) {
    return RichTextToolbar(
      bold: json['bold'] as bool? ?? true,
      italic: json['italic'] as bool? ?? true,
      underline: json['underline'] as bool? ?? true,
      strike: json['strike'] as bool? ?? true,
      code: json['code'] as bool? ?? true,
      headings: json['headings'] as bool? ?? true,
      align: json['align'] as bool? ?? true,
      lists: json['lists'] as bool? ?? true,
      link: json['link'] as bool? ?? true,
      quote: json['quote'] as bool? ?? true,
      insertFields: (json['insertFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'strike': strike,
      'code': code,
      'headings': headings,
      'align': align,
      'lists': lists,
      'link': link,
      'quote': quote,
      'insertFields': insertFields,
    };
  }
}
