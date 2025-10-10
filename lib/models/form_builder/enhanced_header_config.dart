/// Enhanced Header configuration for forms with full React parity
class HeaderConfig {
  // Core Settings
  final bool enabled;
  
  // Logo Configuration
  final LogoConfig logo;
  
  // Title Configuration
  final TitleConfig title;
  
  // Description Configuration
  final DescriptionConfig description;
  
  // Styling Configuration
  final HeaderStyling styling;
  
  // Layout Configuration
  final LayoutConfig layout;
  
  // Custom Fields
  final List<CustomHeaderField> customFields;
  
  // Advanced Settings
  final AdvancedConfig advanced;

  HeaderConfig({
    this.enabled = true,
    LogoConfig? logo,
    TitleConfig? title,
    DescriptionConfig? description,
    HeaderStyling? styling,
    LayoutConfig? layout,
    List<CustomHeaderField>? customFields,
    AdvancedConfig? advanced,
  })  : logo = logo ?? LogoConfig(),
        title = title ?? TitleConfig(),
        description = description ?? DescriptionConfig(),
        styling = styling ?? HeaderStyling(),
        layout = layout ?? LayoutConfig(),
        customFields = customFields ?? [],
        advanced = advanced ?? AdvancedConfig();

  /// Default configuration matching React defaults
  factory HeaderConfig.defaultConfig() {
    return HeaderConfig(
      enabled: true,
      logo: LogoConfig.defaultConfig(),
      title: TitleConfig.defaultConfig(),
      description: DescriptionConfig.defaultConfig(),
      styling: HeaderStyling.defaultConfig(),
      layout: LayoutConfig.defaultConfig(),
      customFields: [],
      advanced: AdvancedConfig.defaultConfig(),
    );
  }

  /// Create from JSON (React-compatible format)
  factory HeaderConfig.fromJson(Map<String, dynamic> json) {
    return HeaderConfig(
      enabled: json['enabled'] as bool? ?? true,
      logo: json['logo'] != null 
          ? LogoConfig.fromJson(json['logo'] as Map<String, dynamic>) 
          : LogoConfig(),
      title: json['title'] != null 
          ? TitleConfig.fromJson(json['title'] as Map<String, dynamic>) 
          : TitleConfig(),
      description: json['description'] != null 
          ? DescriptionConfig.fromJson(json['description'] as Map<String, dynamic>) 
          : DescriptionConfig(),
      styling: json['styling'] != null 
          ? HeaderStyling.fromJson(json['styling'] as Map<String, dynamic>) 
          : HeaderStyling(),
      layout: json['layout'] != null 
          ? LayoutConfig.fromJson(json['layout'] as Map<String, dynamic>) 
          : LayoutConfig(),
      customFields: json['customFields'] != null
          ? (json['customFields'] as List)
              .map((field) => CustomHeaderField.fromJson(field as Map<String, dynamic>))
              .toList()
          : [],
      advanced: json['advanced'] != null 
          ? AdvancedConfig.fromJson(json['advanced'] as Map<String, dynamic>) 
          : AdvancedConfig(),
    );
  }

  /// Convert to JSON (React-compatible format)
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'logo': logo.toJson(),
      'title': title.toJson(),
      'description': description.toJson(),
      'styling': styling.toJson(),
      'layout': layout.toJson(),
      'customFields': customFields.map((field) => field.toJson()).toList(),
      'advanced': advanced.toJson(),
    };
  }

  /// Create a copy with modified properties
  HeaderConfig copyWith({
    bool? enabled,
    LogoConfig? logo,
    TitleConfig? title,
    DescriptionConfig? description,
    HeaderStyling? styling,
    LayoutConfig? layout,
    List<CustomHeaderField>? customFields,
    AdvancedConfig? advanced,
  }) {
    return HeaderConfig(
      enabled: enabled ?? this.enabled,
      logo: logo ?? this.logo,
      title: title ?? this.title,
      description: description ?? this.description,
      styling: styling ?? this.styling,
      layout: layout ?? this.layout,
      customFields: customFields ?? List.from(this.customFields),
      advanced: advanced ?? this.advanced,
    );
  }
}

/// Logo Configuration
class LogoConfig {
  final bool enabled;
  final String? src;
  final String? alt;
  final String? fileName;
  final String width;
  final String height;
  final String position; // 'left', 'center', 'right'

  LogoConfig({
    this.enabled = false,
    this.src,
    this.alt,
    this.fileName,
    this.width = 'auto',
    this.height = 'auto',
    this.position = 'left',
  });

  factory LogoConfig.defaultConfig() {
    return LogoConfig(
      enabled: false,
      width: 'auto',
      height: 'auto',
      position: 'left',
    );
  }

  factory LogoConfig.fromJson(Map<String, dynamic> json) {
    return LogoConfig(
      enabled: json['enabled'] as bool? ?? false,
      src: json['src'] as String?,
      alt: json['alt'] as String?,
      fileName: json['fileName'] as String?,
      width: json['width'] as String? ?? 'auto',
      height: json['height'] as String? ?? 'auto',
      position: json['position'] as String? ?? 'left',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (src != null) 'src': src,
      if (alt != null) 'alt': alt,
      if (fileName != null) 'fileName': fileName,
      'width': width,
      'height': height,
      'position': position,
    };
  }

  LogoConfig copyWith({
    bool? enabled,
    String? src,
    String? alt,
    String? fileName,
    String? width,
    String? height,
    String? position,
  }) {
    return LogoConfig(
      enabled: enabled ?? this.enabled,
      src: src ?? this.src,
      alt: alt ?? this.alt,
      fileName: fileName ?? this.fileName,
      width: width ?? this.width,
      height: height ?? this.height,
      position: position ?? this.position,
    );
  }
}

/// Title Configuration
class TitleConfig {
  final bool visible;
  final String style; // 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
  final String align; // 'left', 'center', 'right'

  TitleConfig({
    this.visible = true,
    this.style = 'h1',
    this.align = 'center',
  });

  factory TitleConfig.defaultConfig() {
    return TitleConfig(
      visible: true,
      style: 'h1',
      align: 'center',
    );
  }

  factory TitleConfig.fromJson(Map<String, dynamic> json) {
    return TitleConfig(
      visible: json['visible'] as bool? ?? true,
      style: json['style'] as String? ?? 'h1',
      align: json['align'] as String? ?? 'center',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visible': visible,
      'style': style,
      'align': align,
    };
  }

  TitleConfig copyWith({
    bool? visible,
    String? style,
    String? align,
  }) {
    return TitleConfig(
      visible: visible ?? this.visible,
      style: style ?? this.style,
      align: align ?? this.align,
    );
  }
}

/// Description Configuration
class DescriptionConfig {
  final bool visible;
  final String align; // 'left', 'center', 'right'

  DescriptionConfig({
    this.visible = true,
    this.align = 'center',
  });

  factory DescriptionConfig.defaultConfig() {
    return DescriptionConfig(
      visible: true,
      align: 'center',
    );
  }

  factory DescriptionConfig.fromJson(Map<String, dynamic> json) {
    return DescriptionConfig(
      visible: json['visible'] as bool? ?? true,
      align: json['align'] as String? ?? 'center',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visible': visible,
      'align': align,
    };
  }

  DescriptionConfig copyWith({
    bool? visible,
    String? align,
  }) {
    return DescriptionConfig(
      visible: visible ?? this.visible,
      align: align ?? this.align,
    );
  }
}

/// Header Styling Configuration
class HeaderStyling {
  // Background
  final String backgroundType; // 'solid', 'gradient', 'image', 'none'
  final String backgroundColor;
  final String? gradientStart;
  final String? gradientEnd;
  
  // Typography
  final String titleColor;
  final String descriptionColor;
  final String fontFamily;
  
  // Border & Effects
  final String border;
  final String borderRadius;
  final String boxShadow;
  
  // Spacing
  final String padding;
  final String margin;

  HeaderStyling({
    this.backgroundType = 'solid',
    this.backgroundColor = '#ffffff',
    this.gradientStart,
    this.gradientEnd,
    this.titleColor = '#333333',
    this.descriptionColor = '#666666',
    this.fontFamily = 'system',
    this.border = 'none',
    this.borderRadius = '0px',
    this.boxShadow = 'none',
    this.padding = '20px',
    this.margin = '0 0 20px 0',
  });

  factory HeaderStyling.defaultConfig() {
    return HeaderStyling(
      backgroundType: 'solid',
      backgroundColor: '#ffffff',
      titleColor: '#333333',
      descriptionColor: '#666666',
      fontFamily: 'system',
      border: 'none',
      borderRadius: '0px',
      boxShadow: 'none',
      padding: '20px',
      margin: '0 0 20px 0',
    );
  }

  factory HeaderStyling.fromJson(Map<String, dynamic> json) {
    return HeaderStyling(
      backgroundType: json['backgroundType'] as String? ?? 'solid',
      backgroundColor: json['backgroundColor'] as String? ?? '#ffffff',
      gradientStart: json['gradientStart'] as String?,
      gradientEnd: json['gradientEnd'] as String?,
      titleColor: json['titleColor'] as String? ?? '#333333',
      descriptionColor: json['descriptionColor'] as String? ?? '#666666',
      fontFamily: json['fontFamily'] as String? ?? 'system',
      border: json['border'] as String? ?? 'none',
      borderRadius: json['borderRadius'] as String? ?? '0px',
      boxShadow: json['boxShadow'] as String? ?? 'none',
      padding: json['padding'] as String? ?? '20px',
      margin: json['margin'] as String? ?? '0 0 20px 0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundType': backgroundType,
      'backgroundColor': backgroundColor,
      if (gradientStart != null) 'gradientStart': gradientStart,
      if (gradientEnd != null) 'gradientEnd': gradientEnd,
      'titleColor': titleColor,
      'descriptionColor': descriptionColor,
      'fontFamily': fontFamily,
      'border': border,
      'borderRadius': borderRadius,
      'boxShadow': boxShadow,
      'padding': padding,
      'margin': margin,
    };
  }

  HeaderStyling copyWith({
    String? backgroundType,
    String? backgroundColor,
    String? gradientStart,
    String? gradientEnd,
    String? titleColor,
    String? descriptionColor,
    String? fontFamily,
    String? border,
    String? borderRadius,
    String? boxShadow,
    String? padding,
    String? margin,
  }) {
    return HeaderStyling(
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      titleColor: titleColor ?? this.titleColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      fontFamily: fontFamily ?? this.fontFamily,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
    );
  }
}

/// Layout Configuration
class LayoutConfig {
  final String type; // 'stacked', 'inline', 'centered', 'split', 'custom'
  final String maxWidth;
  final String align; // 'left', 'center', 'right'
  final bool responsive;
  final String mobileLayout; // 'stacked', 'compact', 'minimal', 'hidden'
  final bool hideMobileLogo;

  LayoutConfig({
    this.type = 'stacked',
    this.maxWidth = '100%',
    this.align = 'center',
    this.responsive = true,
    this.mobileLayout = 'stacked',
    this.hideMobileLogo = false,
  });

  factory LayoutConfig.defaultConfig() {
    return LayoutConfig(
      type: 'stacked',
      maxWidth: '100%',
      align: 'center',
      responsive: true,
      mobileLayout: 'stacked',
      hideMobileLogo: false,
    );
  }

  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      type: json['type'] as String? ?? 'stacked',
      maxWidth: json['maxWidth'] as String? ?? '100%',
      align: json['align'] as String? ?? 'center',
      responsive: json['responsive'] as bool? ?? true,
      mobileLayout: json['mobileLayout'] as String? ?? 'stacked',
      hideMobileLogo: json['hideMobileLogo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'maxWidth': maxWidth,
      'align': align,
      'responsive': responsive,
      'mobileLayout': mobileLayout,
      'hideMobileLogo': hideMobileLogo,
    };
  }

  LayoutConfig copyWith({
    String? type,
    String? maxWidth,
    String? align,
    bool? responsive,
    String? mobileLayout,
    bool? hideMobileLogo,
  }) {
    return LayoutConfig(
      type: type ?? this.type,
      maxWidth: maxWidth ?? this.maxWidth,
      align: align ?? this.align,
      responsive: responsive ?? this.responsive,
      mobileLayout: mobileLayout ?? this.mobileLayout,
      hideMobileLogo: hideMobileLogo ?? this.hideMobileLogo,
    );
  }
}

/// Custom Header Field
class CustomHeaderField {
  final String id;
  final String type; // 'text', 'date', 'number', 'email', 'url'
  final String label;
  final String value;
  final bool visible;
  final Map<String, dynamic> styling;

  CustomHeaderField({
    required this.id,
    required this.type,
    required this.label,
    required this.value,
    this.visible = true,
    this.styling = const {},
  });

  factory CustomHeaderField.fromJson(Map<String, dynamic> json) {
    return CustomHeaderField(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'text',
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      visible: json['visible'] as bool? ?? true,
      styling: json['styling'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'value': value,
      'visible': visible,
      'styling': styling,
    };
  }

  CustomHeaderField copyWith({
    String? id,
    String? type,
    String? label,
    String? value,
    bool? visible,
    Map<String, dynamic>? styling,
  }) {
    return CustomHeaderField(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      value: value ?? this.value,
      visible: visible ?? this.visible,
      styling: styling ?? Map.from(this.styling),
    );
  }
}

/// Advanced Configuration
class AdvancedConfig {
  final String? customClasses;
  final String? customCSS;
  final Map<String, dynamic>? htmlAttributes;

  AdvancedConfig({
    this.customClasses,
    this.customCSS,
    this.htmlAttributes,
  });

  factory AdvancedConfig.defaultConfig() {
    return AdvancedConfig();
  }

  factory AdvancedConfig.fromJson(Map<String, dynamic> json) {
    return AdvancedConfig(
      customClasses: json['customClasses'] as String?,
      customCSS: json['customCSS'] as String?,
      htmlAttributes: json['htmlAttributes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (customClasses != null) 'customClasses': customClasses,
      if (customCSS != null) 'customCSS': customCSS,
      if (htmlAttributes != null) 'htmlAttributes': htmlAttributes,
    };
  }

  AdvancedConfig copyWith({
    String? customClasses,
    String? customCSS,
    Map<String, dynamic>? htmlAttributes,
  }) {
    return AdvancedConfig(
      customClasses: customClasses ?? this.customClasses,
      customCSS: customCSS ?? this.customCSS,
      htmlAttributes: htmlAttributes ?? this.htmlAttributes,
    );
  }
}
