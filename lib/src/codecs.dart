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

/// Takt-Abweichungen: {"12": [6, 4, …]} → {12: [6, 4, …]}.
///
/// SETLIO-14: Dieselbe Form bei Songs und bei Medley-Teilen, deshalb
/// steht die Übersetzung hier und nicht zweimal daneben. Akzeptiert
/// sowohl eine JSON-Zeichenkette (Setronomes lokale Spalte) als auch
/// eine fertige Map (Supabase jsonb).
Map<int, List<int>> barOverridesFromDynamic(dynamic raw) {
  if (raw == null) return const {};
  final decoded = raw is String
      ? (raw.trim().isEmpty ? const <String, dynamic>{} : jsonDecode(raw))
      : raw;
  if (decoded is! Map) return const {};
  return {
    for (final entry in decoded.entries)
      if (int.tryParse(entry.key.toString()) != null && entry.value is List)
        int.parse(entry.key.toString()): [
          for (final v in entry.value as List) (v as num).toInt(),
        ],
  };
}

/// Und zurück — die Schlüssel als Text, wie jsonb es verlangt.
Map<String, dynamic> barOverridesToJson(Map<int, List<int>> overrides) => {
      for (final entry in overrides.entries) entry.key.toString(): entry.value,
    };

/// Wie lange läuft ein Song mit fester Taktzahl?
///
/// Nutzer-Vorgabe 22.08.: „Songlänge kann ja aus Taktanzahl und Tempo
/// ermittelt werden — das soll automatisch geschehen, wenn eine feste
/// Taktzahl angegeben ist."
///
/// Gerechnet wird in Vierteln, weil das Tempo in Setronome viertelbasiert
/// ist: Ein Takt hat `beatsPerBar × 4 / noteValue` Viertel — ein 4/4 also
/// vier, ein 6/8 drei, ein 7/8 dreieinhalb.
///
/// Ohne Taktzahl oder mit unsinnigem Tempo: null (= „weiß ich nicht"),
/// und dann bleibt ein von Hand eingetragener Wert stehen.
int? songDauerSekunden({
  required int? totalBars,
  required double bpm,
  required int beatsPerBar,
  required int noteValue,
}) {
  if (totalBars == null || totalBars <= 0) return null;
  if (bpm <= 0 || beatsPerBar <= 0 || noteValue <= 0) return null;
  final viertelJeTakt = beatsPerBar * 4 / noteValue;
  return (totalBars * viertelJeTakt * 60 / bpm).round();
}
