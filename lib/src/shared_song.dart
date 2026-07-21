import 'codecs.dart';
import 'enums.dart';
import 'schema_version.dart';
import 'shared_tempo_change.dart';

/// Song im geteilten Format – abgeleitet aus dem Setronome-Modell und
/// 1:1 kompatibel zur Setlio-Tabelle `songs` (0001_init.sql).
///
/// Feld-Abweichungen zwischen den Apps übernimmt dieses Modell:
/// Setronome `name` ↔ Setlio `title`, Setronome `key` ↔ Setlio
/// `song_key`; Setronomes freies Text-Feld `band` entfällt (ersetzt
/// durch die echte [bandId]). [durationSec], [tempoChanges] und [parts]
/// sind Setlio-only und gehen beim Weg nach Setronome verloren.
class SharedSong {
  const SharedSong({
    required this.id,
    required this.bandId,
    this.addedBy,
    required this.title,
    this.artist = '',
    required this.bpm,
    this.beatsPerBar = 4,
    this.noteValue = 4,
    this.countInBars = 0,
    this.subdivision = SharedSubdivision.quarter,
    this.accentBeats = const {1},
    this.clickSound,
    this.songKey = '',
    this.capo = 0,
    this.tags = const [],
    this.notes = '',
    this.durationSec,
    this.tempoChanges = const [],
    this.parts = const [],
    this.isActive = true,
    this.schemaVersion = sharedSchemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stabile, client-generierte UUID – nie neu erzeugen (Upsert-Anker).
  final String id;
  final String bandId;

  /// Uploader (profiles.id) – beim Upload aus Setronome gesetzt.
  final String? addedBy;
  final String title;
  final String artist;

  /// Immer double – nie auf int runden (Setronome speichert z. B. 138.5).
  final double bpm;
  final int beatsPerBar;
  final int noteValue;

  /// Einzähler in TAKTEN (nicht Schlägen).
  final int countInBars;
  final SharedSubdivision subdivision;

  /// 1-basierte betonte Schläge; leer = bewusst kein Akzent.
  final Set<int> accentBeats;
  final String? clickSound;
  final String songKey;
  final int capo;
  final List<String> tags;
  final String notes;

  /// Setlio-only (Setronome ignoriert sie).
  final int? durationSec;
  final List<SharedTempoChange> tempoChanges;
  final List<String> parts;

  /// Setlio status active/nirvana – Setronome sieht nur active-Songs.
  final bool isActive;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get timeSignature => timeSignatureOf(beatsPerBar, noteValue);

  /// Stammt der Datensatz von einer neueren Format-Version? Dann ist er
  /// nur soweit-möglich gelesen und der Aufrufer sollte warnen.
  bool get hasNewerSchema => schemaVersion > sharedSchemaVersion;

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.parse(value as String);

  /// Supabase-Zeile → Modell. Tolerant gegenüber numeric-als-String
  /// (REST) und fehlenden optionalen Spalten.
  factory SharedSong.fromSetlioRow(Map<String, dynamic> row) {
    return SharedSong(
      id: row['id'] as String,
      bandId: row['band_id'] as String,
      addedBy: row['added_by'] as String?,
      title: row['title'] as String,
      artist: row['artist'] as String? ?? '',
      bpm: _toDouble(row['bpm']),
      beatsPerBar: (row['beats_per_bar'] as num?)?.toInt() ?? 4,
      noteValue: (row['note_value'] as num?)?.toInt() ?? 4,
      countInBars: (row['count_in_bars'] as num?)?.toInt() ?? 0,
      subdivision:
          SharedSubdivision.fromDb((row['subdivision'] as num?)?.toInt()),
      accentBeats: accentBeatsFromCsv(row['accent_beats'] as String?),
      clickSound: row['click_sound'] as String?,
      songKey: row['song_key'] as String? ?? '',
      capo: (row['capo'] as num?)?.toInt() ?? 0,
      tags: tagsFromDynamic(row['tags']),
      notes: row['notes'] as String? ?? '',
      durationSec: (row['duration_sec'] as num?)?.toInt(),
      tempoChanges: [
        for (final change in row['tempo_changes'] as List<dynamic>? ?? const [])
          SharedTempoChange.fromJson(change as Map<String, dynamic>),
      ],
      parts: [
        for (final part in row['parts'] as List<dynamic>? ?? const [])
          part as String,
      ],
      isActive: (row['status'] as String? ?? 'active') == 'active',
      schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Modell → Supabase-Zeile zum Schreiben. Ohne Server-Felder
  /// (created_at/updated_at setzt der Server); schema_version ist immer
  /// die Version dieses Packages.
  Map<String, dynamic> toSetlioRow() {
    return {
      'id': id,
      'band_id': bandId,
      if (addedBy != null) 'added_by': addedBy,
      'title': title,
      'artist': artist,
      'bpm': bpm,
      'beats_per_bar': beatsPerBar,
      'note_value': noteValue,
      'count_in_bars': countInBars,
      'subdivision': subdivision.dbValue,
      'accent_beats': accentBeatsToCsv(accentBeats),
      'click_sound': clickSound,
      'song_key': songKey,
      'capo': capo,
      'tags': tags,
      'notes': notes,
      'duration_sec': durationSec,
      'tempo_changes': [for (final change in tempoChanges) change.toJson()],
      'parts': parts,
      'status': isActive ? 'active' : 'nirvana',
      'schema_version': sharedSchemaVersion,
    };
  }

  /// Setronome-SQLite-Map → Modell. [bandId]/[addedBy] kommen vom
  /// Upload-Kontext; das Setronome-Text-Feld `band` entfällt bewusst.
  factory SharedSong.fromSetronomeMap(
    Map<String, dynamic> map, {
    required String bandId,
    String? addedBy,
  }) {
    return SharedSong(
      id: map['id'] as String,
      bandId: bandId,
      addedBy: addedBy,
      title: map['name'] as String,
      artist: map['artist'] as String? ?? '',
      bpm: (map['bpm'] as num).toDouble(),
      beatsPerBar: (map['beats_per_bar'] as num?)?.toInt() ?? 4,
      noteValue: (map['note_value'] as num?)?.toInt() ?? 4,
      countInBars: (map['count_in_bars'] as num?)?.toInt() ?? 0,
      subdivision:
          SharedSubdivision.fromDb((map['subdivision'] as num?)?.toInt()),
      accentBeats: accentBeatsFromCsv(map['accent_beats'] as String?),
      clickSound: map['click_sound'] as String?,
      songKey: map['key'] as String? ?? '',
      capo: (map['capo'] as num?)?.toInt() ?? 0,
      tags: tagsFromDynamic(map['tags']),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Modell → Setronome-SQLite-Map (Spiegel-Cache bzw. Import).
  /// Setlio-only-Felder entfallen; `band` bleibt leer (Setronome zeigt
  /// die Band über die aktive Setlio-Band an, nicht über dieses Feld).
  Map<String, dynamic> toSetronomeMap() {
    return {
      'id': id,
      'name': title,
      'artist': artist,
      'band': '',
      'bpm': bpm,
      'beats_per_bar': beatsPerBar,
      'note_value': noteValue,
      'count_in_bars': countInBars,
      'click_sound': clickSound,
      'accent_beats': accentBeatsToCsv(accentBeats),
      'subdivision': subdivision.dbValue,
      'notes': notes,
      'key': songKey,
      'capo': capo,
      'tags': tagsToJson(tags),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
