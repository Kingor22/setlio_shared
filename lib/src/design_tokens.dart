/// Design-Tokens aus DESIGN.md (Setlio_build) – warmes Dunkel + Türkis-Akzent.
/// Bewusst nur Primitive (ARGB-int, double, Font-Namen als String): das
/// Package bleibt pure Dart, jede App baut daraus ihre eigenen Flutter-Typen
/// (`Color(DesignTokens.bg)`, `GoogleFonts.getFont(DesignTokens.bodyFont)`).
/// Setlio_build selbst bleibt die Ursprungsquelle (app/lib/core/theme/) und
/// bezieht diese Werte nicht – sie sind ein mechanischer Spiegel für
/// Setronomes Re-Skin (SYNC_PLAN.md-Nachbarschaft, aber kein Sync-Feature).
class DesignTokens {
  DesignTokens._();

  // 24.08.2026 (Nutzer-Vorgabe): „Systemweit weniger Grau auf Schwarz,
  // eher Richtung Weiss auf Schwarz. Alle Linien doppelt so breit wie
  // jetzt — das ist zu fein so."
  //
  // Also beides: Die Schriftgraus ruecken an ink heran (muted 6,3 -> 9,5
  // und faint 3,5 -> 6,2 WCAG gegen die Karte), und die Linien werden
  // sichtbar (1,5 -> 2,8). Die Breite steckt in kLinie (app_theme).
  //
  // SET-76/2 (Setronome, 21.08.2026): Grau-Skala eine Nuance auseinander-
  // gezogen — Grund dunkler, Karte/zweite Ebene heller, Linien kraeftiger,
  // Sekundaertext heller (Karte/Grund 1,10→1,21, Linie/Karte 1,29→1,53,
  // Hinweistext/Karte 2,9→3,5 WCAG). ink unveraendert. Setlio und
  // Sheetlio lesen diese Klasse nicht (0 Stellen) — wirkt nur in Setronome.

  static const int bg = 0xFF19181B;
  static const int panel = 0xFF222025;
  static const int surface = 0xFF2A282E;
  static const int surface2 = 0xFF343238;
  static const int line = 0xFF6E6A78;
  static const int lineSoft = 0xFF4B4854;
  static const int ink = 0xFFEAE8EC;
  static const int muted = 0xFFD2CFD8;
  static const int faint = 0xFFABA7B3;

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
