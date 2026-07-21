/// Übergang zwischen Setlist-Einträgen. Die dbValue-Strings sind in
/// Setronome (SQLite) und Setlio (Postgres) identisch gespeichert.
enum SharedTransitionMode {
  immediate('immediate'),
  endOfBar('end_of_bar'),
  endOfBarWithCountIn('end_of_bar_with_countin');

  const SharedTransitionMode(this.dbValue);

  final String dbValue;

  static SharedTransitionMode fromDb(String? value) => values.firstWhere(
        (mode) => mode.dbValue == value,
        orElse: () => SharedTransitionMode.immediate,
      );
}

/// Typ eines Setlist-Eintrags (dbValue-Strings in beiden Apps identisch).
enum SharedEntryType {
  song('song'),
  medley('medley'),
  pause('pause');

  const SharedEntryType(this.dbValue);

  final String dbValue;

  static SharedEntryType fromDb(String value) =>
      values.firstWhere((type) => type.dbValue == value);
}

/// Übergang zwischen Medley-Teilen: manuell (Tap/Fußschalter), automatisch
/// nach barCount Takten oder automatisch mit Countdown-Anzeige.
enum SharedMedleyTransition {
  manual('manual'),
  automatic('automatic'),
  countdown('countdown');

  const SharedMedleyTransition(this.dbValue);

  final String dbValue;

  static SharedMedleyTransition fromDb(String? value) => values.firstWhere(
        (transition) => transition.dbValue == value,
        orElse: () => SharedMedleyTransition.manual,
      );
}

/// Metronom-Unterteilung zwischen den Hauptschlägen (Setronome-Konvention).
enum SharedSubdivision {
  quarter(1, 'Viertel'),
  eighth(2, 'Achtel'),
  triplet(3, 'Triole'),
  sixteenth(4, 'Sechzehntel');

  const SharedSubdivision(this.dbValue, this.label);

  final int dbValue;
  final String label;

  static SharedSubdivision fromDb(int? value) => values.firstWhere(
        (subdivision) => subdivision.dbValue == value,
        orElse: () => SharedSubdivision.quarter,
      );
}

/// Herkunft einer Setlist: in Setlio gebaut oder aus Setronome hochgeladen.
enum SharedSetlistOrigin {
  setlio('setlio'),
  setronome('setronome');

  const SharedSetlistOrigin(this.dbValue);

  final String dbValue;

  static SharedSetlistOrigin fromDb(String? value) => values.firstWhere(
        (origin) => origin.dbValue == value,
        orElse: () => SharedSetlistOrigin.setlio,
      );
}
