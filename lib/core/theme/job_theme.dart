// lib/core/theme/job_theme.dart
//
// Per-job visual theme configuration.
// Read from the "theme" block in each job entry in jobs_config.json.
// Passed to AppTheme.build() which applies it to Flutter's ThemeData.
// Zero screen or widget changes needed — all values flow through ThemeData.
//
// Lives in lib/core/theme/ so that app_theme.dart (also in core) can import it
// without violating the Blueprint rule: core files must not import from engine/.
//
// engine/config/job_definition.dart and engine/config/industry_config.dart
// import this from core/theme/ — engine → core imports are always allowed.

enum FontPersonality { rounded, modern, elegant, natural }

enum AppBarStyle { white, colored }

enum SpacingPreset { compact, standard, relaxed }

class JobTheme {
  const JobTheme({
    this.fontPersonality = FontPersonality.modern,
    this.cardRadius      = 12.0,
    this.buttonRadius    = 10.0,
    this.inputRadius     = 8.0,
    this.appBarStyle     = AppBarStyle.white,
    this.spacingPreset   = SpacingPreset.standard,
    this.navBarColored   = false,
  });

  final FontPersonality fontPersonality;
  final double          cardRadius;
  final double          buttonRadius;
  final double          inputRadius;
  final AppBarStyle     appBarStyle;
  final SpacingPreset   spacingPreset;
  final bool            navBarColored;

  /// Defaults used before any job is resolved (loading state, fallback).
  static const JobTheme defaults = JobTheme();

  factory JobTheme.fromJson(Map<String, dynamic> json) {
    return JobTheme(
      fontPersonality: _parseFont(json['font_family'] as String? ?? 'modern'),
      cardRadius:      (json['card_radius']   as num?)?.toDouble() ?? 12.0,
      buttonRadius:    (json['button_radius'] as num?)?.toDouble() ?? 10.0,
      inputRadius:     (json['input_radius']  as num?)?.toDouble() ?? 8.0,
      appBarStyle:     (json['appbar_style'] as String?) == 'colored'
                         ? AppBarStyle.colored : AppBarStyle.white,
      spacingPreset:   _parseSpacing(json['spacing_preset'] as String? ?? 'standard'),
      navBarColored:   json['nav_bar_colored'] as bool? ?? false,
    );
  }

  static FontPersonality _parseFont(String v) {
    switch (v) {
      case 'rounded': return FontPersonality.rounded;
      case 'elegant': return FontPersonality.elegant;
      case 'natural': return FontPersonality.natural;
      default:        return FontPersonality.modern;
    }
  }

  static SpacingPreset _parseSpacing(String v) {
    switch (v) {
      case 'compact':  return SpacingPreset.compact;
      case 'relaxed':  return SpacingPreset.relaxed;
      default:         return SpacingPreset.standard;
    }
  }
}
