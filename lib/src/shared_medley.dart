import 'dart:convert';

import 'enums.dart';

/// Ein Medley-Teil: [barCount] Takte eines Songs samt Übergangsart.
/// In Setlio eine eigene Zeile in `medley_parts` (mit [position]); in
/// Setronome eingebettet im Parts-JSON-Blob des Medleys (Reihenfolge =
/// Listenindex, ohne position/medley_id).
class SharedMedleyPart {
  const SharedMedleyPart({
    required this.id,
    required this.medleyId,
    required this.songId,
    required this.position,
    required this.barCount,
    this.transition = SharedMedleyTransition.manual,
  });

  final String id;
  final String medleyId;
  final String songId;
  final int position;
  final int barCount;
  final SharedMedleyTransition transition;

  factory SharedMedleyPart.fromSetlioRow(Map<String, dynamic> row) {
    return SharedMedleyPart(
      id: row['id'] as String,
      medleyId: row['medley_id'] as String,
      songId: row['song_id'] as String,
      position: (row['position'] as num?)?.toInt() ?? 0,
      barCount: (row['bar_count'] as num).toInt(),
      transition:
          SharedMedleyTransition.fromDb(row['transition_mode'] as String?),
    );
  }

  Map<String, dynamic> toSetlioRow() {
    return {
      'id': id,
      'medley_id': medleyId,
      'song_id': songId,
      'position': position,
      'bar_count': barCount,
      'transition_mode': transition.dbValue,
    };
  }

  /// Eingebettete Form im Setronome-Blob ([position]/[medleyId] ergeben
  /// sich dort aus Listenindex und umgebendem Medley).
  factory SharedMedleyPart.fromSetronomeMap(
    Map<String, dynamic> map, {
    required String medleyId,
    required int position,
  }) {
    return SharedMedleyPart(
      id: map['id'] as String,
      medleyId: medleyId,
      songId: map['song_id'] as String,
      position: position,
      barCount: (map['bar_count'] as num).toInt(),
      transition:
          SharedMedleyTransition.fromDb(map['transition_mode'] as String?),
    );
  }

  Map<String, dynamic> toSetronomeMap() {
    return {
      'id': id,
      'song_id': songId,
      'bar_count': barCount,
      'transition_mode': transition.dbValue,
    };
  }
}

/// Medley = benannte Abfolge von Song-Teilen. Format-Brücke: Setronome
/// speichert die Teile als JSON-Blob in der Medley-Zeile, Setlio als
/// eigene Tabelle `medley_parts` – dieses Modell übersetzt beides.
class SharedMedley {
  const SharedMedley({
    required this.id,
    required this.bandId,
    required this.name,
    this.countInBars = 1,
    this.songChangeCue = 'ready_count',
    this.parts = const [],
  });

  final String id;
  final String bandId;
  final String name;

  /// Count-In vor dem ersten Teil, in Takten (0 = keiner). Default 1
  /// erhält das historische Verhalten (Medleys erzwangen einen Takt).
  final int countInBars;

  /// SET-13: Songwechsel-Cue innerhalb des Medleys — 'off' | 'count'
  /// (nur Zähl-Takt im letzten Takt) | 'ready_count' (ready-Ansage im
  /// vorletzten + Zähl-Takt im letzten Takt). Default 'ready_count'
  /// migriert Bestands-Medleys mit "an".
  final String songChangeCue;

  /// In Abspiel-Reihenfolge (position == Listenindex).
  final List<SharedMedleyPart> parts;

  /// Setlio: `medleys`-Zeile + zugehörige `medley_parts`-Zeilen
  /// (werden hier nach position sortiert).
  factory SharedMedley.fromSetlioRows(
    Map<String, dynamic> medleyRow,
    List<Map<String, dynamic>> partRows,
  ) {
    final parts = [
      for (final row in partRows) SharedMedleyPart.fromSetlioRow(row)
    ]..sort((a, b) => a.position.compareTo(b.position));
    return SharedMedley(
      id: medleyRow['id'] as String,
      bandId: medleyRow['band_id'] as String,
      name: medleyRow['name'] as String,
      countInBars: (medleyRow['count_in_bars'] as num?)?.toInt() ?? 1,
      songChangeCue: medleyRow['song_change_cue'] as String? ?? 'ready_count',
      parts: parts,
    );
  }

  /// Zerlegt in `medleys`-Zeile + `medley_parts`-Zeilen; position kommt
  /// aus dem Listenindex (kanonische Reihenfolge).
  ({Map<String, dynamic> medley, List<Map<String, dynamic>> parts})
      toSetlioRows() {
    return (
      medley: {
        'id': id,
        'band_id': bandId,
        'name': name,
        'count_in_bars': countInBars,
        'song_change_cue': songChangeCue,
      },
      parts: [
        for (final (index, part) in parts.indexed)
          SharedMedleyPart(
            id: part.id,
            medleyId: id,
            songId: part.songId,
            position: index,
            barCount: part.barCount,
            transition: part.transition,
          ).toSetlioRow(),
      ],
    );
  }

  /// Setronome-Zeile mit eingebettetem Parts-JSON-Blob. [bandId] kommt
  /// vom Upload-Kontext (Setronome-Medleys kennen keine Band).
  factory SharedMedley.fromSetronomeMap(
    Map<String, dynamic> map, {
    required String bandId,
  }) {
    final id = map['id'] as String;
    final blob = map['parts'] as String?;
    final decoded =
        blob == null || blob.isEmpty ? const <dynamic>[] : jsonDecode(blob);
    return SharedMedley(
      id: id,
      bandId: bandId,
      name: map['name'] as String,
      countInBars: (map['count_in_bars'] as num?)?.toInt() ?? 1,
      songChangeCue: map['song_change_cue'] as String? ?? 'ready_count',
      parts: [
        for (final (index, part) in (decoded as List<dynamic>).indexed)
          SharedMedleyPart.fromSetronomeMap(
            part as Map<String, dynamic>,
            medleyId: id,
            position: index,
          ),
      ],
    );
  }

  Map<String, dynamic> toSetronomeMap() {
    return {
      'id': id,
      'name': name,
      'parts': jsonEncode([for (final part in parts) part.toSetronomeMap()]),
      'count_in_bars': countInBars,
      'song_change_cue': songChangeCue,
    };
  }
}
