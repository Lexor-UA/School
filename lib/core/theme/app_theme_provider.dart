import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';

enum AppThemeMode {
  darkOcean,
  lightAzure,
}

class AppThemeConfig {
  final AppThemeMode id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String titleKey;
  final String subKey;
  final String badgeKey;
  final bool isDark;

  // Backgrounds & Gradients
  final Color scaffoldBg;
  final List<Color> bgGradient;

  // Glassmorphic Cards & Containers
  final Color cardBg;
  final Color cardBorder;
  final Color cardShadow;
  final Color glassCardBg;

  // Typography
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Accents & Actions
  final Color accentPrimary;
  final Color accentSecondary;
  final List<Color> accentGradient;

  // Form elements, Chips & Modals
  final Color chipBg;
  final Color chipBorder;
  final Color inputBg;
  final Color inputBorder;
  final Color dialogBg;
  final Color dialogBorder;
  final Color dividerColor;

  // Status Badges (Juicy neon-pastel badges with high contrast)
  final Color statusActiveBadgeBg;
  final Color statusActiveBadgeText;
  final Color statusWarningBadgeBg;
  final Color statusWarningBadgeText;
  final Color statusErrorBadgeBg;
  final Color statusErrorBadgeText;
  final Color statusNeutralBadgeBg;
  final Color statusNeutralBadgeText;

  // Animated Water Painter Colors
  final Color waterBgTop;
  final Color waterBgBottom;
  final Color waterWave1;
  final Color waterWave2;
  final Color waterWave3;

  // Ambient Volumetric Glow Orbs
  final Color orb1Color;
  final Color orb2Color;
  final Color orb3Color;

  // Thematic Jewel Action Badges for Grid (6 curated colors/gradients)
  final List<List<Color>> actionCardGradients;

  // Swatch Preview colors for Switcher UI
  final List<Color> previewColors;

  const AppThemeConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.titleKey,
    required this.subKey,
    required this.badgeKey,
    required this.isDark,
    required this.scaffoldBg,
    required this.bgGradient,
    required this.cardBg,
    required this.cardBorder,
    required this.cardShadow,
    required this.glassCardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentGradient,
    required this.chipBg,
    required this.chipBorder,
    required this.inputBg,
    required this.inputBorder,
    required this.dialogBg,
    required this.dialogBorder,
    required this.dividerColor,
    required this.statusActiveBadgeBg,
    required this.statusActiveBadgeText,
    required this.statusWarningBadgeBg,
    required this.statusWarningBadgeText,
    required this.statusErrorBadgeBg,
    required this.statusErrorBadgeText,
    required this.statusNeutralBadgeBg,
    required this.statusNeutralBadgeText,
    required this.waterBgTop,
    required this.waterBgBottom,
    required this.waterWave1,
    required this.waterWave2,
    required this.waterWave3,
    required this.orb1Color,
    required this.orb2Color,
    required this.orb3Color,
    required this.actionCardGradients,
    required this.previewColors,
  });

  ThemeData toThemeData() {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      brightness: brightness,
      primaryColor: accentPrimary,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accentPrimary,
        onPrimary: Colors.white,
        secondary: accentSecondary,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: cardBg,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: isDark ? 8 : 4,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: cardShadow,
        ),
      ),
    );
  }

  /// Harmonizes bright/neon accent or member colors for comfortable reading in Light Mode,
  /// while returning the exact original color untouched in Dark Mode.
  Color adaptColorForTheme(Color raw) {
    if (isDark) return raw;
    final v = raw.toARGB32();
    if (v == 0xFF00E5FF || v == 0xFF00D2FF || v == 0xFF00F2FE || v == 0xFF18FFFF || v == 0xFF00B4D8 || v == 0xFF38BDF8 || v == 0xFF0EA5E9) {
      return const Color(0xFF0284C7);
    }
    if (v == 0xFF00E676 || v == 0xFF69F0AE || v == 0xFF34D399 || v == 0xFF6EE7B7 || v == 0xFF10B981) {
      return const Color(0xFF059669);
    }
    if (v == 0xFF2DD4BF || v == 0xFF14B8A6 || v == 0xFF06B6D4) {
      return const Color(0xFF0D9488);
    }
    if (v == 0xFFFFD740 || v == 0xFFFFAB40 || v == 0xFFFBBF24 || v == 0xFFF59E0B || v == 0xFFFFB300) {
      return const Color(0xFFD97706);
    }
    if (v == 0xFFFF3366 || v == 0xFFFF2A55 || v == 0xFFFF4081 || v == 0xFFF43F5E || v == 0xFFFB7185 || v == 0xFFEC4899) {
      return const Color(0xFFE11D48);
    }
    if (v == 0xFFE040FB || v == 0xFFA855F7 || v == 0xFFC084FC || v == 0xFFA78BFA) {
      return const Color(0xFF7C3AED);
    }
    return raw;
  }

  // Preset 1: Deep Ocean Dark (The Standard Dark)
  static final AppThemeConfig darkOcean = AppThemeConfig(
    id: AppThemeMode.darkOcean,
    title: 'Океанічна ніч',
    subtitle: 'Фірмова темна тема з неоновими океанічними акцентами',
    badgeText: 'Темна',
    titleKey: 'theme_dark_ocean_title',
    subKey: 'theme_dark_ocean_sub',
    badgeKey: 'theme_badge_dark',
    isDark: true,
    scaffoldBg: const Color(0xFF09182B),
    bgGradient: [
      const Color(0xFF00B4DB).withValues(alpha: 0.20),
      const Color(0xFF0284C7).withValues(alpha: 0.12),
      const Color(0xFF0F172A).withValues(alpha: 0.72),
    ],
    cardBg: const Color(0xFF0F172A).withValues(alpha: 0.76),
    cardBorder: Colors.white.withValues(alpha: 0.16),
    cardShadow: const Color(0xFF00E5FF).withValues(alpha: 0.18),
    glassCardBg: const Color(0xFF0F172A).withValues(alpha: 0.72),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textMuted: Colors.white38,
    accentPrimary: const Color(0xFF00E5FF),
    accentSecondary: const Color(0xFF38BDF8),
    accentGradient: const [Color(0xFF00E5FF), Color(0xFF0077B6)],
    chipBg: Colors.white.withValues(alpha: 0.08),
    chipBorder: Colors.white.withValues(alpha: 0.18),
    inputBg: Colors.white.withValues(alpha: 0.07),
    inputBorder: Colors.white.withValues(alpha: 0.18),
    dialogBg: const Color(0xFF0B1B30),
    dialogBorder: Colors.white.withValues(alpha: 0.20),
    dividerColor: Colors.white.withValues(alpha: 0.12),
    statusActiveBadgeBg: const Color(0xFF10B981).withValues(alpha: 0.20),
    statusActiveBadgeText: const Color(0xFF34D399),
    statusWarningBadgeBg: const Color(0xFFF59E0B).withValues(alpha: 0.20),
    statusWarningBadgeText: const Color(0xFFFBBF24),
    statusErrorBadgeBg: const Color(0xFFF43F5E).withValues(alpha: 0.20),
    statusErrorBadgeText: const Color(0xFFFB7185),
    statusNeutralBadgeBg: Colors.white.withValues(alpha: 0.10),
    statusNeutralBadgeText: Colors.white70,
    waterBgTop: const Color(0xFF003B73),
    waterBgBottom: const Color(0xFF001B3A),
    waterWave1: const Color(0xFF0284C7).withValues(alpha: 0.22),
    waterWave2: const Color(0xFF0369A1).withValues(alpha: 0.28),
    waterWave3: const Color(0xFF002244).withValues(alpha: 0.90),
    orb1Color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
    orb2Color: const Color(0xFF00B4D8).withValues(alpha: 0.18),
    orb3Color: const Color(0xFF818CF8).withValues(alpha: 0.14),
    actionCardGradients: const [
      [Color(0xFF10B981), Color(0xFF059669)], // Створити
      [Color(0xFF38BDF8), Color(0xFF0284C7)], // Календар
      [Color(0xFFA855F7), Color(0xFF7C3AED)], // Клієнти
      [Color(0xFF06B6D4), Color(0xFF0891B2)], // Новий клієнт
      [Color(0xFF6366F1), Color(0xFF4338CA)], // Тренери
      [Color(0xFFF59E0B), Color(0xFFD97706)], // Оплата
    ],
    previewColors: const [Color(0xFF09182B), Color(0xFF00E5FF), Color(0xFF38BDF8), Color(0xFF0F172A)],
  );

  // Preset 2: Ocean Pearl (Light 1 — Vibrant Glassmorphism)
  static final AppThemeConfig lightAzure = AppThemeConfig(
    id: AppThemeMode.lightAzure,
    title: 'Океанічна Перлина',
    subtitle: 'Розкішний світлий дизайн з ефектом скла та живою водою.',
    badgeText: 'Світла',
    titleKey: 'theme_light_pearl_title',
    subKey: 'theme_light_pearl_sub',
    badgeKey: 'theme_badge_light',
    isDark: false,
    scaffoldBg: const Color(0xFFF0F9FF), // Calm airy pearl-azure
    bgGradient: [
      const Color(0xFF0284C7).withValues(alpha: 0.08),
      const Color(0xFF38BDF8).withValues(alpha: 0.06),
      const Color(0xFF0369A1).withValues(alpha: 0.12),
    ],
    cardBg: Colors.white.withValues(alpha: 0.82), // Soft frosted white glass
    cardBorder: Colors.white.withValues(alpha: 0.95), // Crisp white edges
    cardShadow: const Color(0xFF0284C7).withValues(alpha: 0.08), // Subtle sapphire shadow
    glassCardBg: Colors.white.withValues(alpha: 0.72), // Clean translucent glass
    textPrimary: const Color(0xFF0F172A), // Deep Slate Navy
    textSecondary: const Color(0xFF334155), // Slate Gray
    textMuted: const Color(0xFF64748B), // Slate gray
    accentPrimary: const Color(0xFF0284C7), // Noble Sapphire Azure
    accentSecondary: const Color(0xFF0D9488), // Calm Deep Teal
    accentGradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
    chipBg: Colors.white.withValues(alpha: 0.65),
    chipBorder: const Color(0xFFBAE6FD).withValues(alpha: 0.85),
    inputBg: Colors.white.withValues(alpha: 0.78),
    inputBorder: const Color(0xFFBAE6FD),
    dialogBg: const Color(0xFFF8FAFC),
    dialogBorder: Colors.white,
    dividerColor: const Color(0xFF0284C7).withValues(alpha: 0.10),
    statusActiveBadgeBg: const Color(0xFF059669).withValues(alpha: 0.12),
    statusActiveBadgeText: const Color(0xFF047857),
    statusWarningBadgeBg: const Color(0xFFD97706).withValues(alpha: 0.12),
    statusWarningBadgeText: const Color(0xFFB45309),
    statusErrorBadgeBg: const Color(0xFFE11D48).withValues(alpha: 0.12),
    statusErrorBadgeText: const Color(0xFFBE123C),
    statusNeutralBadgeBg: Colors.white.withValues(alpha: 0.65),
    statusNeutralBadgeText: const Color(0xFF475569),
    // Calm crystal water background with gentle dynamic waves
    waterBgTop: const Color(0xFFF0F9FF),
    waterBgBottom: const Color(0xFFE0F2FE),
    waterWave1: const Color(0xFF38BDF8).withValues(alpha: 0.22),
    waterWave2: const Color(0xFF0284C7).withValues(alpha: 0.18),
    waterWave3: const Color(0xFF0369A1).withValues(alpha: 0.14),
    orb1Color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
    orb2Color: const Color(0xFF7DD3FC).withValues(alpha: 0.16),
    orb3Color: const Color(0xFF5EEAD4).withValues(alpha: 0.12),
    actionCardGradients: const [
      [Color(0xFF059669), Color(0xFF047857)], // Emerald
      [Color(0xFF0284C7), Color(0xFF0369A1)], // Sapphire Blue
      [Color(0xFF7C3AED), Color(0xFF5B21B6)], // Royal Purple
      [Color(0xFFE11D48), Color(0xFFBE123C)], // Noble Rose
      [Color(0xFFD97706), Color(0xFFB45309)], // Warm Amber
      [Color(0xFF0891B2), Color(0xFF0E7490)], // Deep Cyan-Teal
    ],
    previewColors: const [Color(0xFFF0F9FF), Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF0F172A)],
  );

  static AppThemeConfig fromMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkOcean:
        return darkOcean;
      case AppThemeMode.lightAzure:
        return lightAzure;
    }
  }

  static List<AppThemeConfig> get allPresets => [
    darkOcean,
    lightAzure,
  ];
}

class AppThemeController extends Notifier<AppThemeConfig> {
  static const _prefsKey = 'selected_app_theme_mode';

  @override
  AppThemeConfig build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final savedModeStr = prefs.getString(_prefsKey);
    if (savedModeStr != null) {
      try {
        final mode = AppThemeMode.values.firstWhere(
          (e) => e.name == savedModeStr,
          orElse: () => savedModeStr.contains('light')
              ? AppThemeMode.lightAzure
              : AppThemeMode.darkOcean,
        );
        return AppThemeConfig.fromMode(mode);
      } catch (_) {}
    }
    return AppThemeConfig.darkOcean;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final config = AppThemeConfig.fromMode(mode);
    state = config;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_prefsKey, mode.name);
  }
}

final appThemeControllerProvider = NotifierProvider<AppThemeController, AppThemeConfig>(() {
  return AppThemeController();
});
