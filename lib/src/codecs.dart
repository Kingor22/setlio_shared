import 'dart:convert';

/// Taktart-Zeichenkette („4/4") aus Zähler/Nenner – bisher in beiden Apps
/// inline abgeleitet, hier die eine gemeinsame Stelle.
String timeSignatureOf(int beatsPerBar, int noteValue) =>
    '$beatsPerBar/$noteValue';

/// Akzent-Schläge als CSV („1,3") – kanonisch aufsteigend sortiert.
String accentBeatsToCsv(Set<int> beats) => (beats.toList()..sort()).join(',');

/// CSV → Menge der 1-basierten Akzent-Schläge. null (Feld fehlt) ⇒ {1}
/// wie der Setronome-/DB-Default; ein leerer String bleibt die leere
/// Menge, denn in Setronome heißt leer ausdrücklich „kein Schlag betont"
/// – sonst wäre der Roundtrip nicht verlustfrei.
Set<int> accentBeatsFromCsv(String? csv) {
  if (csv == null) return {1};
  final trimmed = csv.trim();
  if (trimmed.isEmpty) return {};
  return trimmed.split(',').map((part) => int.parse(part.trim())).toSet();
}

/// Tags als JSON-String für Setronomes SQLite-Spalte.
String tagsToJson(List<String> tags) => jsonEncode(tags);

/// Tags aus Setlios jsonb-Array (List), Setronomes JSON-String oder null.
List<String> tagsFromDynamic(dynamic value) {
  if (value == null) return const [];
  final decoded = value is String
      ? (value.isEmpty ? const <dynamic>[] : jsonDecode(value))
      : value;
  return [for (final tag in decoded as List<dynamic>) tag as String];
}
