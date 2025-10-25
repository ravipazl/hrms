import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';

/// Specialized renderer for rich text field values in submission view
/// Handles the complex structure: { content, inlineFields, textContent, etc. }
class RichTextSubmissionRenderer extends StatelessWidget {
  final dynamic value;
  final Map<String, dynamic>? schema;
  final Map<String, dynamic>? uiSchema;

  const RichTextSubmissionRenderer({
    super.key,
    required this.value,
    this.schema,
    this.uiSchema,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 ========== RICH TEXT RENDERER ==========');
    debugPrint('🎨 Value type: ${value.runtimeType}');
    
    try {
      debugPrint('🎨 Value: ${value != null ? jsonEncode(value) : "null"}');
    } catch (e) {
      debugPrint('🎨 Could not encode value: $e');
    }
    
    // Handle null or empty value
    if (value == null) {
      return _buildEmptyState();
    }

    // Handle different value formats
    if (value is Map<String, dynamic>) {
      return _buildFromMap(value, context);
    } else if (value is String) {
      return _buildFromString(value, context);
    } else {
      debugPrint('🎨 ⚠️ Unexpected value type: ${value.runtimeType}');
      return _buildFromString(value.toString(), context);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'No response',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildFromMap(Map<String, dynamic> richTextData, BuildContext context) {
    debugPrint('🎨 Building from Map');
    debugPrint('🎨 Map keys: ${richTextData.keys.toList()}');
    
    // Extract structured content (NEW FORMAT)
    final content = richTextData['content'];  // Slate.js structure (list of nodes)
    final embeddedFields = richTextData['embeddedFields'] as List? ?? [];
    final embeddedFieldValues = richTextData['embeddedFieldValues'] as Map? ?? {};
    
    // Legacy fields (backward compatibility)
    final html = richTextData['html'] as String? ?? '';
    final textContent = richTextData['textContent'] as String? ?? '';
    
    debugPrint('🎨 Content type: ${content.runtimeType}');
    debugPrint('🎨 Embedded fields: ${embeddedFields.length}');
    debugPrint('🎨 Embedded values: ${embeddedFieldValues.length}');
    debugPrint('🎨 HTML length: ${html.length}');
    
    // Check if we have structured content
    if (content is List && content.isNotEmpty) {
      // Check if we have embedded values OR just display content
      if (embeddedFieldValues.isNotEmpty) {
        // NEW: Render structured Slate.js content with embedded values
        debugPrint('🎨 ✅ Rendering structured content WITH embedded values');
        return _buildStructuredContent(content, embeddedFields, embeddedFieldValues, context);
      } else if (html.isNotEmpty) {
        // OLD SUBMISSION: Has HTML with merged values, use HTML instead of template
        debugPrint('🎨 🔙 Old submission: Rendering HTML (has merged embedded values)');
        return _buildFromHtmlOnly(html, context);
      } else {
        // Just display the structured content without values
        debugPrint('🎨 ✅ Rendering structured content WITHOUT embedded values');
        return _buildStructuredContent(content, embeddedFields, embeddedFieldValues, context);
      }
    }
    
    // Fallback: Render HTML if available
    if (html.isNotEmpty || textContent.isNotEmpty) {
      debugPrint('🎨 🔙 Rendering HTML fallback');
      String displayContent = html.isNotEmpty ? html : textContent;
      
      if (displayContent.isEmpty) {
        return _buildEmptyState();
      }

      return _buildFromHtmlOnly(displayContent, context);
    }
    
    // If no content at all, show empty state
    return _buildEmptyState();
  }
  
  Widget _buildFromHtmlOnly(String htmlContent, BuildContext context) {
    debugPrint('🎨 Building from HTML only, length: ${htmlContent.length}');
    
    if (htmlContent.trim().isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _buildHtmlContent(htmlContent, context),
    );
  }

  Widget _buildFromString(String htmlContent, BuildContext context) {
    debugPrint('🎨 Building from String, length: ${htmlContent.length}');
    
    if (htmlContent.trim().isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _buildHtmlContent(htmlContent, context),
    );
  }

  Widget _buildHtmlContent(String htmlContent, BuildContext context) {
    debugPrint('🎨 Rendering HTML content, length: ${htmlContent.length}');
    
    if (htmlContent.trim().isEmpty) {
      return Text(
        'No content',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    // Use flutter_html for proper HTML rendering
    try {
      return Html(
        data: htmlContent,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(15),
            lineHeight: const LineHeight(1.5),
          ),
          "p": Style(
            margin: Margins.only(bottom: 8),
          ),
          "h1": Style(
            fontSize: FontSize(24),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 12, top: 8),
          ),
          "h2": Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 10, top: 8),
          ),
          "h3": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 8, top: 6),
          ),
        },
      );
    } catch (e) {
      debugPrint('🎨 ⚠️ Error rendering HTML: $e');
      return _buildPlainText(htmlContent);
    }
  }

  Widget _buildPlainText(String htmlContent) {
    String plainText = htmlContent
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .trim();
    
    return Text(
      plainText,
      style: const TextStyle(fontSize: 15, height: 1.5),
    );
  }

  Widget _buildStructuredContent(
    List<dynamic> content,
    List<dynamic> embeddedFields,
    Map<dynamic, dynamic> embeddedValues,
    BuildContext context,
  ) {
    debugPrint('🎨 Building structured content with ${content.length} nodes');
    debugPrint('🎨 Embedded fields: ${embeddedFields.length}');
    debugPrint('🎨 Embedded values: $embeddedValues');
    
    // Create label lookup map: field ID -> field label
    final fieldLabels = <String, String>{};
    for (var field in embeddedFields) {
      if (field is Map) {
        final id = field['id'] as String?;
        final label = field['label'] as String?;
        if (id != null && label != null) {
          fieldLabels[id] = label;
        }
      }
    }
    debugPrint('🎨 Field labels map: $fieldLabels');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render each content node with field labels for placeholder replacement
          ...content.map((node) => _buildContentNode(node, embeddedValues, fieldLabels, context)),
          
          // Show embedded field values if any
          if (embeddedValues.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Embedded Field Responses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...embeddedValues.entries.map((entry) {
              final fieldId = entry.key.toString();
              final fieldLabel = fieldLabels[fieldId] ?? fieldId;  // Use label or fallback to ID
              return _buildEmbeddedFieldValue(fieldLabel, entry.value);
            }),
          ],
        ],
      ),
    );
  }
  
  Widget _buildContentNode(
    dynamic node,
    Map<dynamic, dynamic> embeddedValues,
    Map<String, String> fieldLabels,
    BuildContext context,
  ) {
    if (node is! Map<String, dynamic>) return const SizedBox.shrink();
    
    final type = node['type'] as String? ?? 'paragraph';
    final children = node['children'] as List<dynamic>? ?? [];
    final align = node['align'] as String?;
    
    // Get text alignment
    TextAlign textAlign = TextAlign.left;
    if (align == 'center') textAlign = TextAlign.center;
    if (align == 'right') textAlign = TextAlign.right;
    if (align == 'justify') textAlign = TextAlign.justify;
    
    // Build text with formatting
    final spans = <InlineSpan>[];
    for (var child in children) {
      if (child is Map<String, dynamic> && child.containsKey('text')) {
        final text = child['text'] as String;
        
        // Check if this text contains embedded field placeholder
        if (text.contains('[') && text.contains(']')) {
          // Replace [Field Name] with actual value using field labels
          final replaced = _replaceEmbeddedPlaceholders(text, embeddedValues, fieldLabels);
          spans.add(TextSpan(
            text: replaced,
            style: _getTextStyle(child),
          ));
        } else {
          spans.add(TextSpan(
            text: text,
            style: _getTextStyle(child),
          ));
        }
      }
    }
    
    // Different styles based on type
    TextStyle baseStyle = const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87);
    if (type == 'heading-one' || type == 'h1') {
      baseStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black87);
    } else if (type == 'heading-two' || type == 'h2') {
      baseStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black87);
    } else if (type == 'heading-three' || type == 'h3') {
      baseStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black87);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(children: spans, style: baseStyle),
        textAlign: textAlign,
      ),
    );
  }
  
  TextStyle _getTextStyle(Map<String, dynamic> formatting) {
    TextStyle style = const TextStyle();
    
    if (formatting['bold'] == true) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (formatting['italic'] == true) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (formatting['underline'] == true) {
      style = style.copyWith(decoration: TextDecoration.underline);
    }
    if (formatting['code'] == true) {
      style = style.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Colors.grey.shade200,
      );
    }
    
    return style;
  }
  
  String _replaceEmbeddedPlaceholders(
    String text, 
    Map<dynamic, dynamic> values,
    Map<String, String> fieldLabels,
  ) {
    debugPrint('🎨 Replacing placeholders in: $text');
    debugPrint('🎨 With values: $values');
    debugPrint('🎨 Using field labels: $fieldLabels');
    
    // Pattern to match: emoji + [Label] or just [Label]
    final pattern = RegExp(r'[📝🔢📧📅📋☑️🔘📄📌]?\s*\[([^\]]+)\]');
    
    final replaced = text.replaceAllMapped(pattern, (match) {
      final placeholder = match.group(0) ?? '';
      final fieldLabel = match.group(1);
      
      debugPrint('🎨 Found placeholder: $placeholder, label: $fieldLabel');
      
      // Find the field ID that has this label
      String? matchingFieldId;
      for (var entry in fieldLabels.entries) {
        if (entry.value == fieldLabel) {
          matchingFieldId = entry.key;
          break;
        }
      }
      
      if (matchingFieldId != null && values.containsKey(matchingFieldId)) {
        final value = values[matchingFieldId];
        debugPrint('🎨 ✅ Replaced with value: $value');
        return value?.toString() ?? '';
      }
      
      // If no value found, return empty string (hide placeholder)
      debugPrint('🎨 ⚠️ No value found, hiding placeholder');
      return '';
    });
    
    debugPrint('🎨 Result: $replaced');
    return replaced;
  }
  
  Widget _buildEmbeddedFieldValue(String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.green.shade900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'No response',
              style: TextStyle(
                fontSize: 13,
                color: value != null ? Colors.green.shade900 : Colors.grey.shade500,
                fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
