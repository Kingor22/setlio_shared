import 'dart:convert';
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
    this.totalBars,
    this.subdivision = SharedSubdivision.quarter,
    this.accentBeats = const {1},
    this.clickSound,
    this.songKey = '',
    this.capo = 0,
    this.tags = const [],
    this.notes = '',
    this.beatPattern = const [],
    this.barOverrides = const {},
    this.durationSec,
    this.tempoChanges,
    this.parts,
    this.isActive,
    this.schemaVersion = sharedSchemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stabile, client-generierte UUID – nie neu erzeugen (Upsert-Anker).
  final String id;
  final String bandId;

  /// Uploader (profiles.id) – beim Upload aus Setronome gesetzt.
  ///
  /// PROVENIENZ, und die wird nie überschrieben (CLAUDE.md §4). Der
  /// Wert gehört deshalb ausschließlich an einen Song, den es auf dem
  /// Server noch NICHT gibt: `songs.added_by` ist `not null`, und die
  /// Insert-Policy verlangt `added_by = auth.uid()` – ein neuer Song
  /// kommt ohne ihn nicht durch. Bei einem Song, der schon drüben
  /// steht, muss der Aufrufer hier `null` übergeben; dann lässt
  /// [toSetlioRow] die Spalte aus (wie bei den anderen „weiß ich
  /// nicht"-Feldern), und der Eintrag „hinzugefügt von …" bleibt bei
  /// dem, der ihn wirklich angelegt hat.
  final String? addedBy;
  final String title;
  final String artist;

  /// Immer double – nie auf int runden (Setronome speichert z. B. 138.5).
  final double bpm;
  final int beatsPerBar;
  final int noteValue;

  /// Einzähler in TAKTEN (nicht Schlägen).
  final int countInBars;

  /// Feste Taktzahl des Songs (optional, von Setronome gepflegt): treibt
  /// dort Auto-Count-In, Auto-Weiterschaltung und Loop-Button. Null =
  /// unbegrenzt.
  final int? totalBars;
  final SharedSubdivision subdivision;

  /// 1-basierte betonte Schläge; leer = bewusst kein Akzent.
  final Set<int> accentBeats;
  final String? clickSound;
  final String songKey;
  final int capo;
  final List<String> tags;
  final String notes;

  /// SETLIO-14: Gruppierung ungerader Achtel-Taktarten, z. B. [2,2,3]
  /// für 7/8. Leer = ungruppiert. Ohne dieses Feld klingt derselbe Song
  /// auf einem zweiten Gerät falsch.
  final List<int> beatPattern;

  /// SETLIO-14: Takt-Abweichungen und Formmarken des Songs —
  /// Takt (1-basiert) → [Schläge, Notenwert, Unterteilung, Form-Code,
  /// Ansage, Vorlauf]. Dasselbe Format wie bei Medley-Teilen.
  final Map<int, List<int>> barOverrides;

  /// Setlio-only. NULL heißt hier ausdrücklich „weiß ich nicht" — und
  /// dann wird das Feld beim Schreiben AUSGELASSEN, statt den
  /// Server-Wert mit einem Standard zu überschreiben (SETLIO-14, der
  /// gefährlichste Punkt des Tickets: „Unbekannte Felder müssen
  /// unverändert erhalten bleiben.").
  final int? durationSec;
  final List<SharedTempoChange>? tempoChanges;
  final List<String>? parts;

  /// Setlio status active/nirvana. null = unbekannt → nicht anfassen.
  final bool? isActive;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get timeSignature => timeSignatureOf(beatsPerBar, noteValue);

  /// Stammt der Datensatz von einer neueren Format-Version? Dann ist er
  /// nur soweit-möglich gelesen und der Aufrufer sollte warnen.
  bool get hasNewerSchema => schemaVersion > sharedSchemaVersion;

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.parse(value as String);

  /// jsonb-Liste (Supabase) → Liste von Ganzzahlen.
  static List<int> _intListe(dynamic roh) {
    if (roh is List) return [for (final v in roh) (v as num).toInt()];
    if (roh is String && roh.trim().isNotEmpty) return _csvZuInts(roh);
    return const [];
  }

  /// Setronome legt die Gruppierung lokal als CSV ab („2,2,3").
  static List<int> _csvZuInts(String? roh) {
    if (roh == null || roh.trim().isEmpty) return const [];
    return [
      for (final teil in roh.split(','))
        if (int.tryParse(teil.trim()) != null) int.parse(teil.trim()),
    ];
  }

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
      totalBars: (row['total_bars'] as num?)?.toInt(),
      subdivision:
          SharedSubdivision.fromDb((row['subdivision'] as num?)?.toInt()),
      accentBeats: accentBeatsFromCsv(row['accent_beats'] as String?),
      clickSound: row['click_sound'] as String?,
      songKey: row['song_key'] as String? ?? '',
      capo: (row['capo'] as num?)?.toInt() ?? 0,
      tags: tagsFromDynamic(row['tags']),
      notes: row['notes'] as String? ?? '',
      beatPattern: _intListe(row['beat_pattern']),
      barOverrides: barOverridesFromDynamic(row['bar_overrides']),
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
  ///
  /// Achtung beim UPSERT: PostgREST schreibt jede mitgelieferte Spalte
  /// auch im Konfliktfall, ein Upsert ist hier also zugleich ein
  /// Update. Ob `added_by` mitgeht, entscheidet deshalb der Aufrufer
  /// über [addedBy] – siehe dort. Wer für einen bereits vorhandenen
  /// Song die eigene Nutzer-Id mitgibt, schreibt die Provenienz um.
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
      'total_bars': totalBars,
      'subdivision': subdivision.dbValue,
      'accent_beats': accentBeatsToCsv(accentBeats),
      'click_sound': clickSound,
      'song_key': songKey,
      'capo': capo,
      'tags': tags,
      'notes': notes,
      'beat_pattern': beatPattern,
      'bar_overrides': barOverridesToJson(barOverrides),
      // SETLIO-14: Diese vier gehoeren Setlio. Kommen sie nicht mit,
      // werden sie AUSGELASSEN — sonst setzte jeder Setronome-Push
      // Spieldauer, Tempowechsel und Songform zurueck und holte
      // geloeschte Songs aus dem Papierkorb.
      if (durationSec != null) 'duration_sec': durationSec,
      if (tempoChanges != null)
        'tempo_changes': [for (final change in tempoChanges!) change.toJson()],
      if (parts != null) 'parts': parts,
      if (isActive != null) 'status': isActive! ? 'active' : 'nirvana',
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
      totalBars: (map['total_bars'] as num?)?.toInt(),
      subdivision:
          SharedSubdivision.fromDb((map['subdivision'] as num?)?.toInt()),
      accentBeats: accentBeatsFromCsv(map['accent_beats'] as String?),
      clickSound: map['click_sound'] as String?,
      songKey: map['key'] as String? ?? '',
      capo: (map['capo'] as num?)?.toInt() ?? 0,
      tags: tagsFromDynamic(map['tags']),
      notes: map['notes'] as String? ?? '',
      beatPattern: _csvZuInts(map['beat_pattern'] as String?),
      barOverrides: barOverridesFromDynamic(map['bar_overrides']),
      // Steht eine feste Taktzahl da, ergibt sich die Spieldauer aus
      // Takten und Tempo (Vorgabe 22.08.). Ohne Taktzahl bleibt das Feld
      // null — und ein in Setlio von Hand eingetragener Wert damit
      // unangetastet.
      durationSec: songDauerSekunden(
        totalBars: (map['total_bars'] as num?)?.toInt(),
        bpm: (map['bpm'] as num).toDouble(),
        beatsPerBar: (map['beats_per_bar'] as num?)?.toInt() ?? 4,
        noteValue: (map['note_value'] as num?)?.toInt() ?? 4,
      ),
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
      // KEIN 'band': Das Feld gehoert dem Geraet („mein Projekt") und
      // steht in Setlio nirgends. Frueher stand hier ein leerer String —
      // und loeschte den von Hand eingetippten Bandnamen bei JEDEM
      // Abgleich (SETLIO-14).
      'bpm': bpm,
      'beats_per_bar': beatsPerBar,
      'note_value': noteValue,
      'count_in_bars': countInBars,
      'total_bars': totalBars,
      'click_sound': clickSound,
      'accent_beats': accentBeatsToCsv(accentBeats),
      'subdivision': subdivision.dbValue,
      'notes': notes,
      'key': songKey,
      'capo': capo,
      'tags': tagsToJson(tags),
      'beat_pattern': beatPattern.isEmpty ? null : beatPattern.join(','),
      'bar_overrides': barOverrides.isEmpty
          ? null
          : jsonEncode(barOverridesToJson(barOverrides)),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
