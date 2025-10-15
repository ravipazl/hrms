import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';

/// Converts between Slate JSON (React) and Quill Delta (Flutter)
class RichTextConverter {
  /// Convert Slate JSON to Quill Delta
  static Document slateToQuill(List<dynamic> slateContent, List<Map<String, dynamic>> embeddedFields) {
    final operations = <Map<String, dynamic>>[];
    
    for (var element in slateContent) {
      _convertSlateElement(element as Map<String, dynamic>, operations, embeddedFields);
    }
     
    // Create document from operations
    if (operations.isEmpty) {
      operations.add({'insert': '\n'});
    }
    
    return Document.fromJson(operations);
  }

  static void _convertSlateElement(
    Map<String, dynamic> element,
    List<Map<String, dynamic>> operations,
    List<Map<String, dynamic>> embeddedFields,
  ) {
    final type = element['type'] as String?;
    final children = element['children'] as List<dynamic>? ?? [];
    final align = element['align'] as String?;

    // Process children first to build text content
    for (var child in children) {
      if (child is Map<String, dynamic>) {
        if (child.containsKey('text')) {
          // Text node
          final text = child['text'] as String;
          if (text.isEmpty && children.length == 1) {
            // Empty paragraph - just skip for now, will add newline below
            continue;
          }

          final attributes = <String, dynamic>{};
          
          // Text formatting
          if (child['bold'] == true) attributes['bold'] = true;
          if (child['italic'] == true) attributes['italic'] = true;
          if (child['underline'] == true) attributes['underline'] = true;
          if (child['strike'] == true) attributes['strike'] = true;
          if (child['code'] == true) attributes['code'] = true;

          if (text.isNotEmpty) {
            final op = <String, dynamic>{'insert': text};
            if (attributes.isNotEmpty) {
              op['attributes'] = attributes;
            }
            operations.add(op);
          }
        } else if (child['type'] == 'embedded_field') {
          // Embedded field - insert as custom embed
          final fieldId = child['id'] as String;
          final fieldType = child['fieldType'] as String;
          final label = child['label'] as String;
          
          operations.add({
            'insert': {
              'embedded_field': {
                'id': fieldId,
                'fieldType': fieldType,
                'label': label,
              }
            },
          });
        }
      }
    }

    // Block formatting
    final blockAttributes = <String, dynamic>{};
    
    switch (type) {
      case 'heading-one':
        blockAttributes['header'] = 1;
        break;
      case 'heading-two':
        blockAttributes['header'] = 2;
        break;
      case 'heading-three':
        blockAttributes['header'] = 3;
        break;
      case 'block-quote':
        blockAttributes['blockquote'] = true;
        break;
      case 'numbered-list':
      case 'list-item':
        // Check if parent is numbered-list
        blockAttributes['list'] = 'ordered';
        break;
      case 'bulleted-list':
        blockAttributes['list'] = 'bullet';
        break;
    }

    if (align != null && align != 'left') {
      blockAttributes['align'] = align;
    }

    // Add newline with block attributes
    final op = <String, dynamic>{'insert': '\n'};
    if (blockAttributes.isNotEmpty) {
      op['attributes'] = blockAttributes;
    }
    operations.add(op);
  }

  /// Convert Quill Delta to Slate JSON
  static List<Map<String, dynamic>> quillToSlate(Document document) {
    final slateContent = <Map<String, dynamic>>[];
    final operations = document.toDelta().toList();
    
    var currentBlock = <String, dynamic>{
      'type': 'paragraph',
      'children': <Map<String, dynamic>>[],
    };

    for (var op in operations) {
      final data = op.data;
      final attributes = op.attributes ?? {};

      if (data is String) {
        if (data == '\n') {
          // End of block
          if ((currentBlock['children'] as List).isEmpty) {
            (currentBlock['children'] as List).add({'text': ''});
          }
          
          // Apply block-level attributes
          if (attributes['header'] != null) {
            final level = attributes['header'];
            currentBlock['type'] = level == 1
                ? 'heading-one'
                : level == 2
                    ? 'heading-two'
                    : 'heading-three';
          } else if (attributes['blockquote'] == true) {
            currentBlock['type'] = 'block-quote';
          } else if (attributes['list'] != null) {
            currentBlock['type'] = attributes['list'] == 'ordered'
                ? 'numbered-list'
                : 'bulleted-list';
          }

          if (attributes['align'] != null) {
            currentBlock['align'] = attributes['align'];
          }

          slateContent.add(currentBlock);
          currentBlock = {
            'type': 'paragraph',
            'children': <Map<String, dynamic>>[],
          };
        } else {
          // Text content
          final textNode = <String, dynamic>{'text': data};
          
          // Text formatting
          if (attributes['bold'] == true) textNode['bold'] = true;
          if (attributes['italic'] == true) textNode['italic'] = true;
          if (attributes['underline'] == true) textNode['underline'] = true;
          if (attributes['strike'] == true) textNode['strike'] = true;
          if (attributes['code'] == true) textNode['code'] = true;

          (currentBlock['children'] as List).add(textNode);
        }
      } else if (data is Map && data.containsKey('embedded_field')) {
        // Embedded field
        final fieldData = data['embedded_field'] as Map<String, dynamic>;
        (currentBlock['children'] as List).add({
          'type': 'embedded_field',
          'id': fieldData['id'],
          'fieldType': fieldData['fieldType'],
          'label': fieldData['label'],
          'props': fieldData['props'] ?? {},
          'children': [{'text': ''}],
        });
      }
    }

    // Add last block if not empty
    if ((currentBlock['children'] as List).isNotEmpty) {
      slateContent.add(currentBlock);
    }

    // Ensure at least one paragraph
    if (slateContent.isEmpty) {
      slateContent.add({
        'type': 'paragraph',
        'children': [{'text': ''}],
      });
    }

    return slateContent;
  }
}
