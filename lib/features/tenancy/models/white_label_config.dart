import 'package:flutter/material.dart';

/// Configuration model for White Label branding and SaaS customizations in AquatixLab.
/// Allows swimming schools to customize their visual identity, legal entity, and contact endpoints.
@immutable
class WhiteLabelConfig {
  final String organizationId;
  final String appName;
  final String legalEntityName;
  final String logoUrl;
  final String? splashLogoUrl;
  final int primaryColorValue;
  final int secondaryColorValue;
  final int accentColorValue;
  final String? customDomain;
  final String? websiteUrl;
  final String? supportEmail;
  final String? supportPhone;
  final String? privacyPolicyUrl;
  final String? termsOfServiceUrl;
  final Map<String, bool> featuresEnabled;

  const WhiteLabelConfig({
    required this.organizationId,
    required this.appName,
    required this.legalEntityName,
    required this.logoUrl,
    this.splashLogoUrl,
    this.primaryColorValue = 0xFF00E5FF, // Aquamarine
    this.secondaryColorValue = 0xFF001F3F, // Dark Navy Ocean
    this.accentColorValue = 0xFF10B981, // Emerald Green
    this.customDomain,
    this.websiteUrl,
    this.supportEmail,
    this.supportPhone,
    this.privacyPolicyUrl,
    this.termsOfServiceUrl,
    this.featuresEnabled = const {
      'multiBranch': true,
      'qrAttendance': true,
      'parentPortal': true,
      'coachJournal': true,
      'onlinePaymentMock': true,
      'automatedNotifications': true,
    },
  });

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);
  Color get accentColor => Color(accentColorValue);

  /// Default White Label configuration for CitySwim Swimming Academy
  static const WhiteLabelConfig citySwimDefault = WhiteLabelConfig(
    organizationId: 'cityswim',
    appName: 'CitySwim',
    legalEntityName: 'CitySwim International Group',
    logoUrl: 'assets/images/logo_light.png',
    splashLogoUrl: 'assets/images/logo_light.png',
    primaryColorValue: 0xFF00E5FF,
    secondaryColorValue: 0xFF001F3F,
    accentColorValue: 0xFF10B981,
    customDomain: 'cityswim.app',
    websiteUrl: 'https://cityswim.app',
    supportEmail: 'support@cityswim.app',
    supportPhone: '+43 1 234 5678',
    privacyPolicyUrl: 'https://cityswim.app/privacy',
    termsOfServiceUrl: 'https://cityswim.app/terms',
  );

  WhiteLabelConfig copyWith({
    String? organizationId,
    String? appName,
    String? legalEntityName,
    String? logoUrl,
    String? splashLogoUrl,
    int? primaryColorValue,
    int? secondaryColorValue,
    int? accentColorValue,
    String? customDomain,
    String? websiteUrl,
    String? supportEmail,
    String? supportPhone,
    String? privacyPolicyUrl,
    String? termsOfServiceUrl,
    Map<String, bool>? featuresEnabled,
  }) {
    return WhiteLabelConfig(
      organizationId: organizationId ?? this.organizationId,
      appName: appName ?? this.appName,
      legalEntityName: legalEntityName ?? this.legalEntityName,
      logoUrl: logoUrl ?? this.logoUrl,
      splashLogoUrl: splashLogoUrl ?? this.splashLogoUrl,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      customDomain: customDomain ?? this.customDomain,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      termsOfServiceUrl: termsOfServiceUrl ?? this.termsOfServiceUrl,
      featuresEnabled: featuresEnabled ?? this.featuresEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'appName': appName,
    'legalEntityName': legalEntityName,
    'logoUrl': logoUrl,
    'splashLogoUrl': splashLogoUrl,
    'primaryColorValue': primaryColorValue,
    'secondaryColorValue': secondaryColorValue,
    'accentColorValue': accentColorValue,
    'customDomain': customDomain,
    'websiteUrl': websiteUrl,
    'supportEmail': supportEmail,
    'supportPhone': supportPhone,
    'privacyPolicyUrl': privacyPolicyUrl,
    'termsOfServiceUrl': termsOfServiceUrl,
    'featuresEnabled': featuresEnabled,
  };

  factory WhiteLabelConfig.fromJson(Map<String, dynamic> json) {
    return WhiteLabelConfig(
      organizationId: json['organizationId'] as String? ?? 'cityswim',
      appName: json['appName'] as String? ?? 'CitySwim',
      legalEntityName: json['legalEntityName'] as String? ?? 'CitySwim International Group',
      logoUrl: json['logoUrl'] as String? ?? 'assets/images/logo_light.png',
      splashLogoUrl: json['splashLogoUrl'] as String?,
      primaryColorValue: (json['primaryColorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
      secondaryColorValue: (json['secondaryColorValue'] as num?)?.toInt() ?? 0xFF001F3F,
      accentColorValue: (json['accentColorValue'] as num?)?.toInt() ?? 0xFF10B981,
      customDomain: json['customDomain'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      supportEmail: json['supportEmail'] as String?,
      supportPhone: json['supportPhone'] as String?,
      privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
      termsOfServiceUrl: json['termsOfServiceUrl'] as String?,
      featuresEnabled: (json['featuresEnabled'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {
            'multiBranch': true,
            'qrAttendance': true,
            'parentPortal': true,
            'coachJournal': true,
            'onlinePaymentMock': true,
            'automatedNotifications': true,
          },
    );
  }
}
