/// Design-Tokens aus DESIGN.md (Setlio_build) – warmes Dunkel + Türkis-Akzent.
/// Bewusst nur Primitive (ARGB-int, double, Font-Namen als String): das
/// Package bleibt pure Dart, jede App baut daraus ihre eigenen Flutter-Typen
/// (`Color(DesignTokens.bg)`, `GoogleFonts.getFont(DesignTokens.bodyFont)`).
/// Setlio_build selbst bleibt die Ursprungsquelle (app/lib/core/theme/) und
/// bezieht diese Werte nicht – sie sind ein mechanischer Spiegel für
/// Setronomes Re-Skin (SYNC_PLAN.md-Nachbarschaft, aber kein Sync-Feature).
class DesignTokens {
  DesignTokens._();

  static const int bg = 0xFF1C1B1E;
  static const int panel = 0xFF211F23;
  static const int surface = 0xFF252329;
  static const int surface2 = 0xFF2D2B31;
  static const int line = 0xFF38353D;
  static const int lineSoft = 0xFF2A282E;
  static const int ink = 0xFFEAE8EC;
  static const int muted = 0xFF9E9AA2;
  static const int faint = 0xFF6C6872;

  static const int accent = 0xFF3EC6C0;
  static const int accentText = 0xFF64D4CE;
  static const int accentSoft = 0xFF1E3634;
  static const int accentLine = 0xFF2F4A47;
  static const int accentInk = 0xFF12201F;

  /// „yellowText" in Setlio – hier als warme Zweitfarbe (z. B. Setronomes
  /// Sub-Beat-Markierung), bewusst unterscheidbar vom Akzent-Türkis.
  static const int amber = 0xFFE4C05D;

  /// „redText" in Setlio.
  static const int red = 0xFFE9746F;

  static const double radiusCard = 16;
  static const double radiusButton = 11;
  static const double radiusChip = 8;

  static const String headingFont = 'Space Grotesk';
  static const String bodyFont = 'Inter';
  static const String monoFont = 'Space Mono';
}
