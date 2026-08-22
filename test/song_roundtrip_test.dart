import 'package:setlio_shared/setlio_shared.dart';
import 'package:test/test.dart';

/// Setronome-SQLite-Map wie sie `Song.toMap()` erzeugt.
Map<String, dynamic> setronomeSongMap() => {
      'id': '4be0a924-0000-4000-8000-000000000001',
      'name': 'Beat It',
      'artist': 'Michael Jackson',
      'band': 'Goodbeats',
      'bpm': 138.5,
      'beats_per_bar': 4,
      'note_value': 4,
      'count_in_bars': 2,
      'total_bars': 96,
      'click_sound': 'woodblock',
      'accent_beats': '1,3',
      'subdivision': 2,
      'notes': 'Solo kürzen',
      'key': 'Em',
      'capo': 3,
      'tags': '["Party","Set 1"]',
      // SETLIO-14: Gruppierung und Sondertakte gehen jetzt mit — vorher
      // blieben sie auf dem Geraet und das zweite klang falsch.
      'beat_pattern': '2,2,3',
      'bar_overrides': '{"9":[6,4,0,2,1,1]}',
      'created_at': '2026-07-01T20:15:00.000',
      'updated_at': '2026-07-02T21:00:00.000',
    };

void main() {
  test('Setronome → Shared → Setlio-Row: Rename-Mappings und Typen', () {
    final shared = SharedSong.fromSetronomeMap(
      setronomeSongMap(),
      bandId: 'band-1',
      addedBy: 'user-1',
    );
    expect(shared.title, 'Beat It');
    expect(shared.songKey, 'Em');
    expect(shared.bpm, 138.5);
    expect(shared.timeSignature, '4/4');

    final row = shared.toSetlioRow();
    expect(row['title'], 'Beat It');
    expect(row['song_key'], 'Em');
    expect(row['bpm'], 138.5); // double, nie gerundet
    expect(row['accent_beats'], '1,3');
    expect(row['tags'], ['Party', 'Set 1']); // jsonb-Array, kein String
    // SETLIO-14: Was Setronome nicht fuehrt, steht NICHT in der Zeile —
    // sonst setzte jeder Push Setlios Werte auf ihren Standard zurueck.
    expect(row.containsKey('status'), isFalse);
    expect(row.containsKey('duration_sec'), isFalse);
    expect(row.containsKey('tempo_changes'), isFalse);
    expect(row.containsKey('parts'), isFalse);
    expect(row['schema_version'], sharedSchemaVersion);
    expect(row.containsKey('created_at'), isFalse); // Server-Feld
    expect(row.containsKey('name'), isFalse);
    expect(row.containsKey('band'), isFalse);
    // Und die zwei Felder, die es bisher nur lokal gab.
    expect(row['beat_pattern'], [2, 2, 3]);
    expect(row['bar_overrides'], {
      '9': [6, 4, 0, 2, 1, 1],
    });
  });

  test(
      'kompletter Roundtrip Setronome → Setlio → Setronome ist verlustfrei '
      'für die gemeinsamen Felder', () {
    final original = setronomeSongMap();
    final shared = SharedSong.fromSetronomeMap(original, bandId: 'band-1');

    // Serverseite simulieren: geschriebene Zeile + Server-Timestamps.
    final serverRow = {
      ...shared.toSetlioRow(),
      'created_at': original['created_at'],
      'updated_at': original['updated_at'],
    };
    final back = SharedSong.fromSetlioRow(serverRow).toSetronomeMap();

    // `band` entfällt konzeptbedingt (ersetzt durch echte band_id) — und
    // wird seit SETLIO-14 gar nicht mehr geschrieben, damit der lokale
    // Wert den Abgleich überlebt.
    final erwartet = {...original}..remove('band');
    expect(back, erwartet);
  });

  test('leere Akzent-Menge überlebt den Roundtrip (kein erfundener Akzent)',
      () {
    final map = {...setronomeSongMap(), 'accent_beats': ''};
    final shared = SharedSong.fromSetronomeMap(map, bandId: 'band-1');
    expect(shared.accentBeats, isEmpty);
    final back = SharedSong.fromSetlioRow({
      ...shared.toSetlioRow(),
      'created_at': map['created_at'],
      'updated_at': map['updated_at'],
    });
    expect(back.toSetronomeMap()['accent_beats'], '');
  });

  test(
      'Setlio-Row-Eigenheiten: numeric-als-String, jsonb-Tags, Nirvana, '
      'Setlio-only-Felder', () {
    final row = {
      'id': 'song-2',
      'band_id': 'band-1',
      'added_by': 'user-9',
      'title': 'Thriller',
      'artist': 'Michael Jackson',
      'bpm': '118', // REST liefert numeric teils als String
      'beats_per_bar': 4,
      'note_value': 4,
      'count_in_bars': 0,
      'subdivision': 1,
      'accent_beats': '1',
      'song_key': '',
      'capo': 0,
      'tags': ['Halloween'],
      'notes': '',
      'duration_sec': 222,
      'tempo_changes': [
        {'atBar': 33, 'bpm': 140},
      ],
      'parts': ['Intro', 'Verse'],
      'status': 'nirvana',
      'schema_version': 1,
      'created_at': '2026-07-01T18:00:00.000Z',
      'updated_at': '2026-07-01T18:00:00.000Z',
    };
    final shared = SharedSong.fromSetlioRow(row);
    expect(shared.bpm, 118.0);
    expect(shared.isActive, isFalse);
    expect(shared.durationSec, 222);
    expect(shared.tempoChanges!.single.atBar, 33);
    expect(shared.tempoChanges!.single.bpm, 140.0);
    expect(shared.parts, ['Intro', 'Verse']);

    // Setlio-only-Felder tauchen in der Setronome-Map nicht auf.
    final map = shared.toSetronomeMap();
    expect(map.containsKey('duration_sec'), isFalse);
    expect(map.containsKey('tempo_changes'), isFalse);
    expect(map.containsKey('parts'), isFalse);
    expect(map.containsKey('status'), isFalse);
  });

  test('höhere schema_version wird erkannt (lesbar, aber warnen)', () {
    final shared = SharedSong.fromSetlioRow({
      'id': 'song-3',
      'band_id': 'band-1',
      'title': 'Future Song',
      'bpm': 120,
      'schema_version': sharedSchemaVersion + 1,
      'created_at': '2026-07-01T18:00:00.000Z',
      'updated_at': '2026-07-01T18:00:00.000Z',
    });
    expect(shared.hasNewerSchema, isTrue);
    // Schreiben stempelt immer die eigene Package-Version.
    expect(shared.toSetlioRow()['schema_version'], sharedSchemaVersion);
  });
}
