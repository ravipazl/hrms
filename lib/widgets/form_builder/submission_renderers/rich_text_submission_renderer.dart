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
    
    // Extract all possible content fields
    final content = richTextData['content'] as String? ?? '';
    final textContent = richTextData['textContent'] as String? ?? '';
    final html = richTextData['html'] as String? ?? '';
    final inlineFields = richTextData['inlineFields'] as List? ?? [];
    final embeddedFields = richTextData['embeddedFields'] as List? ?? [];
    final inlineData = richTextData['inlineData'] as Map? ?? {};
    
    debugPrint('🎨 Content length: ${content.length}');
    debugPrint('🎨 TextContent length: ${textContent.length}');
    debugPrint('🎨 HTML length: ${html.length}');
    debugPrint('🎨 Inline fields: ${inlineFields.length}');
    
    // Determine which content to display (priority: content > html > textContent)
    String displayContent = content.isNotEmpty 
        ? content 
        : (html.isNotEmpty ? html : textContent);
    
    debugPrint('🎨 Display content length: ${displayContent.length}');
    
    if (displayContent.isEmpty && inlineFields.isEmpty && embeddedFields.isEmpty) {
      debugPrint('🎨 ⚠️ All content is empty!');
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main HTML content
          if (displayContent.isNotEmpty) ...[
            _buildHtmlContent(displayContent, context),
          ],
          
          // Inline data section (filled values from inline fields)
          if (inlineData.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Inline Field Responses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(inlineData as Map<String, dynamic>).entries.map((entry) => 
              _buildInlineDataField(entry.key, entry.value)
            ),
          ],
        ],
      ),
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

  Widget _buildInlineDataField(String fieldId, dynamic fieldData) {
    if (fieldData is! Map) {
      return const SizedBox.shrink();
    }
    
    final data = fieldData as Map<String, dynamic>;
    final label = data['label'] as String? ?? fieldId;
    final value = data['value'];
    
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
