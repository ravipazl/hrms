import 'package:flutter/material.dart';
import '../../../models/form_builder/enhanced_header_config.dart';
import 'dart:convert';

class FormHeaderPreview extends StatelessWidget {
  final String? formTitle;
  final String? formDescription;
  final HeaderConfig? headerConfig;
  final String? mode;
  
  const FormHeaderPreview({
    super.key,
    this.formTitle,
    this.formDescription,
    this.headerConfig,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final config = headerConfig ?? HeaderConfig.defaultConfig();
    
    // If header is disabled, don't show anything
    if (!config.enabled) {
      return const SizedBox.shrink();
    }

    final displayTitle = formTitle ?? '';
    final displayDescription = formDescription ?? '';
    
    // Parse styling values
    final bgColor = _parseColor(config.styling.backgroundColor);
    final titleColor = _parseColor(config.styling.titleColor);
    final descColor = _parseColor(config.styling.descriptionColor);
    final borderRadius = _parseBorderRadius(config.styling.borderRadius);
    final padding = _parsePadding(config.styling.padding);
    final margin = _parseMargin(config.styling.margin);
    
    // Build background decoration
    BoxDecoration decoration = BoxDecoration(
      color: config.styling.backgroundType == 'solid' ? bgColor : null,
      gradient: config.styling.backgroundType == 'gradient'
          ? LinearGradient(
              colors: [
                _parseColor(config.styling.gradientStart ?? config.styling.backgroundColor),
                _parseColor(config.styling.gradientEnd ?? config.styling.backgroundColor),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: borderRadius,
      border: config.styling.border != 'none' ? _parseBorder(config.styling.border) : null,
      boxShadow: config.styling.boxShadow != 'none' ? [_parseBoxShadow(config.styling.boxShadow)] : null,
    );

    // Determine text alignment
    TextAlign titleAlign = _parseTextAlign(config.title.align);
    TextAlign descAlign = _parseTextAlign(config.description.align);
    CrossAxisAlignment crossAlign = _parseCrossAxisAlignment(config.layout.align);

    return Container(
      margin: margin,
      decoration: decoration,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: _parseMaxWidth(config.layout.maxWidth),
        ),
        padding: padding,
        width: double.infinity, // CRITICAL: Full width for proper alignment
        child: _buildLayout(
          config,
          displayTitle,
          displayDescription,
          titleColor,
          descColor,
          titleAlign,
          descAlign,
          crossAlign,
        ),
      ),
    );
  }

  Widget _buildLayout(
    HeaderConfig config,
    String displayTitle,
    String displayDescription,
    Color titleColor,
    Color descColor,
    TextAlign titleAlign,
    TextAlign descAlign,
    CrossAxisAlignment crossAlign,
  ) {
    switch (config.layout.type) {
      case 'inline':
        return _buildInlineLayout(config, displayTitle, displayDescription, titleColor, descColor);
      case 'split':
        return _buildSplitLayout(config, displayTitle, displayDescription, titleColor, descColor);
      case 'centered':
        return _buildCenteredLayout(config, displayTitle, displayDescription, titleColor, descColor);
      case 'stacked':
      default:
        return _buildStackedLayout(
          config,
          displayTitle,
          displayDescription,
          titleColor,
          descColor,
          titleAlign,
          descAlign,
          crossAlign,
        );
    }
  }

  Widget _buildStackedLayout(
    HeaderConfig config,
    String displayTitle,
    String displayDescription,
    Color titleColor,
    Color descColor,
    TextAlign titleAlign,
    TextAlign descAlign,
    CrossAxisAlignment crossAlign,
  ) {
    return Column(
      crossAxisAlignment: crossAlign,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        if (config.logo.enabled && config.logo.src != null)
          _buildLogo(config.logo),
        
        // Spacing after logo
        if (config.logo.enabled && config.logo.src != null && 
            (displayTitle.isNotEmpty || displayDescription.isNotEmpty))
          const SizedBox(height: 16),
        
        // Title - wrapped in full-width container for proper alignment
        if (config.title.visible && displayTitle.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: _buildTitle(displayTitle, titleColor, config.title.style, titleAlign),
          ),
        
        // Spacing between title and description
        if (config.title.visible && displayTitle.isNotEmpty && 
            config.description.visible && displayDescription.isNotEmpty)
          const SizedBox(height: 12),
        
        // Description - wrapped in full-width container for proper alignment
        if (config.description.visible && displayDescription.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: _buildDescription(displayDescription, descColor, descAlign),
          ),
        
        // Custom Fields
        if (config.customFields.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...config.customFields.where((f) => f.visible).map((field) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCustomField(field),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineLayout(
    HeaderConfig config,
    String displayTitle,
    String displayDescription,
    Color titleColor,
    Color descColor,
  ) {
    return Row(
      children: [
        if (config.logo.enabled && config.logo.src != null) ...[
          _buildLogo(config.logo),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (config.title.visible && displayTitle.isNotEmpty)
                _buildTitle(displayTitle, titleColor, config.title.style, TextAlign.left),
              if (config.description.visible && displayDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildDescription(displayDescription, descColor, TextAlign.left),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitLayout(
    HeaderConfig config,
    String displayTitle,
    String displayDescription,
    Color titleColor,
    Color descColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Title & Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (config.title.visible && displayTitle.isNotEmpty)
                _buildTitle(displayTitle, titleColor, config.title.style, TextAlign.left),
              if (config.description.visible && displayDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildDescription(displayDescription, descColor, TextAlign.left),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right: Logo
        if (config.logo.enabled && config.logo.src != null)
          _buildLogo(config.logo),
      ],
    );
  }

  Widget _buildCenteredLayout(
    HeaderConfig config,
    String displayTitle,
    String displayDescription,
    Color titleColor,
    Color descColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (config.logo.enabled && config.logo.src != null) ...[
          _buildLogo(config.logo),
          const SizedBox(height: 16),
        ],
        if (config.title.visible && displayTitle.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: _buildTitle(displayTitle, titleColor, config.title.style, TextAlign.center),
          ),
        if (config.description.visible && displayDescription.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildDescription(displayDescription, descColor, TextAlign.center),
          ),
        ],
      ],
    );
  }

  Widget _buildLogo(LogoConfig logo) {
    if (logo.src == null) return const SizedBox.shrink();

    // Parse dimensions
    double? width = _parseDimension(logo.width);
    double? height = _parseDimension(logo.height);

    Widget logoWidget;

    // Check if it's a base64 image
    if (logo.src!.startsWith('data:image')) {
      try {
        final base64String = logo.src!.split(',')[1];
        final bytes = base64Decode(base64String);
        logoWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildLogoPlaceholder(width, height);
          },
        );
      } catch (e) {
        logoWidget = _buildLogoPlaceholder(width, height);
      }
    } else if (logo.src!.startsWith('http')) {
      // Network image
      logoWidget = Image.network(
        logo.src!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildLogoPlaceholder(width, height);
        },
      );
    } else {
      logoWidget = _buildLogoPlaceholder(width, height);
    }

    // Apply alignment
    return _alignWidget(logoWidget, logo.position);
  }

  Widget _buildLogoPlaceholder(double? width, double? height) {
    return Container(
      width: width ?? 100,
      height: height ?? 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 24, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Logo',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title, Color color, String style, TextAlign align) {
    double fontSize;
    FontWeight fontWeight;

    switch (style) {
      case 'h1':
        fontSize = 32;
        fontWeight = FontWeight.bold;
        break;
      case 'h2':
        fontSize = 28;
        fontWeight = FontWeight.bold;
        break;
      case 'h3':
        fontSize = 24;
        fontWeight = FontWeight.w600;
        break;
      case 'h4':
        fontSize = 20;
        fontWeight = FontWeight.w600;
        break;
      case 'h5':
        fontSize = 18;
        fontWeight = FontWeight.w500;
        break;
      case 'h6':
        fontSize = 16;
        fontWeight = FontWeight.w500;
        break;
      default:
        fontSize = 24;
        fontWeight = FontWeight.bold;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: align,
    );
  }

  Widget _buildDescription(String description, Color color, TextAlign align) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: color,
        height: 1.5,
      ),
      textAlign: align,
    );
  }

  Widget _buildCustomField(CustomHeaderField field) {
    return Row(
      children: [
        Text(
          '${field.label}: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          field.value,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  // ========== PARSING HELPERS ==========

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hex = colorString.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
    } catch (e) {
      // Fallback
    }
    return Colors.white;
  }

  BorderRadius? _parseBorderRadius(String borderRadius) {
    if (borderRadius == '0px' || borderRadius == 'none') return null;
    
    try {
      final value = double.parse(borderRadius.replaceAll(RegExp(r'[^0-9.]'), ''));
      return BorderRadius.circular(value);
    } catch (e) {
      return null;
    }
  }

  EdgeInsets _parsePadding(String padding) {
    try {
      final parts = padding.split(' ').map((p) => 
        double.parse(p.replaceAll(RegExp(r'[^0-9.]'), ''))
      ).toList();
      
      if (parts.length == 1) {
        return EdgeInsets.all(parts[0]);
      } else if (parts.length == 2) {
        return EdgeInsets.symmetric(vertical: parts[0], horizontal: parts[1]);
      } else if (parts.length == 4) {
        return EdgeInsets.fromLTRB(parts[3], parts[0], parts[1], parts[2]);
      }
    } catch (e) {
      // Fallback
    }
    return const EdgeInsets.all(20);
  }

  EdgeInsets _parseMargin(String margin) {
    try {
      final parts = margin.split(' ').map((p) => 
        double.parse(p.replaceAll(RegExp(r'[^0-9.]'), ''))
      ).toList();
      
      if (parts.length == 1) {
        return EdgeInsets.all(parts[0]);
      } else if (parts.length == 2) {
        return EdgeInsets.symmetric(vertical: parts[0], horizontal: parts[1]);
      } else if (parts.length == 4) {
        return EdgeInsets.fromLTRB(parts[3], parts[0], parts[1], parts[2]);
      }
    } catch (e) {
      // Fallback
    }
    return const EdgeInsets.only(bottom: 20);
  }

  Border? _parseBorder(String border) {
    if (border == 'none') return null;
    
    try {
      // Parse "1px solid #cccccc" format
      final parts = border.split(' ');
      if (parts.length >= 3) {
        final width = double.parse(parts[0].replaceAll(RegExp(r'[^0-9.]'), ''));
        final color = _parseColor(parts[2]);
        return Border.all(color: color, width: width);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  BoxShadow _parseBoxShadow(String shadow) {
    if (shadow == 'none') {
      return const BoxShadow(color: Colors.transparent);
    }
    
    try {
      // Parse "0px 2px 4px rgba(0,0,0,0.1)" format
      // For simplicity, return a default shadow
      return BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      );
    } catch (e) {
      return const BoxShadow(color: Colors.transparent);
    }
  }

  double _parseMaxWidth(String maxWidth) {
    if (maxWidth == '100%') return double.infinity;
    
    try {
      return double.parse(maxWidth.replaceAll(RegExp(r'[^0-9.]'), ''));
    } catch (e) {
      return double.infinity;
    }
  }

  double? _parseDimension(String dimension) {
    if (dimension == 'auto') return null;
    
    try {
      return double.parse(dimension.replaceAll(RegExp(r'[^0-9.]'), ''));
    } catch (e) {
      return null;
    }
  }

  TextAlign _parseTextAlign(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  CrossAxisAlignment _parseCrossAxisAlignment(String align) {
    switch (align) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'right':
        return CrossAxisAlignment.end;
      case 'center':
      default:
        return CrossAxisAlignment.center;
    }
  }

  Widget _alignWidget(Widget child, String position) {
    switch (position) {
      case 'left':
        return Align(alignment: Alignment.centerLeft, child: child);
      case 'right':
        return Align(alignment: Alignment.centerRight, child: child);
      case 'center':
      default:
        return Align(alignment: Alignment.center, child: child);
    }
  }
}
