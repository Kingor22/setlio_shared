import 'dart:convert';

import 'package:setlio_shared/setlio_shared.dart';
import 'package:test/test.dart';

/// Setronome-Medley-Map wie `Medley.toMap()`: Parts als JSON-Blob.
Map<String, dynamic> setronomeMedleyMap() => {
      'id': 'medley-1',
      'name': '80s Medley',
      'count_in_bars': 1,
      'song_change_cue': 'ready_count',
      'parts': jsonEncode([
        {
          'id': 'part-1',
          'song_id': 'song-1',
          'bar_count': 16,
          'transition_mode': 'automatic',
        },
        {
          'id': 'part-2',
          'song_id': 'song-2',
          'bar_count': 24,
          'transition_mode': 'countdown',
        },
      ]),
    };

void main() {
  test('Blob → Tabellen-Zeilen: position aus dem Listenindex', () {
    final shared =
        SharedMedley.fromSetronomeMap(setronomeMedleyMap(), bandId: 'band-1');
    final rows = shared.toSetlioRows();

    expect(rows.medley, {
      'id': 'medley-1',
      'band_id': 'band-1',
      'name': '80s Medley',
      'count_in_bars': 1,
      'song_change_cue': 'ready_count',
      // SETLIO-14: Die Pause zum naechsten Show-Teil geht jetzt mit.
      'next_entry_delay': 0,
    });
    expect(rows.parts, hasLength(2));
    expect(rows.parts[0]['position'], 0);
    expect(rows.parts[1]['position'], 1);
    expect(rows.parts[1]['medley_id'], 'medley-1');
    expect(rows.parts[1]['transition_mode'], 'countdown');
  });

  test('Tabellen-Zeilen → Blob: sortiert nach position, Roundtrip verlustfrei',
      () {
    final original = setronomeMedleyMap();
    final rows = SharedMedley.fromSetronomeMap(original, bandId: 'band-1')
        .toSetlioRows();

    // Absichtlich verdrehte Reihenfolge – fromSetlioRows sortiert.
    final back = SharedMedley.fromSetlioRows(
      rows.medley,
      rows.parts.reversed.toList(),
    );
    expect(back.parts.first.songId, 'song-1');
    // SETLIO-14: Die Pause kommt jetzt mit zurueck (Standard 0), der
    // Rest ist unveraendert.
    expect(back.toSetronomeMap(), {...original, 'next_entry_delay': 0});
  });

  test('leeres Medley (kein Blob) bleibt leer', () {
    final shared = SharedMedley.fromSetronomeMap(
      {'id': 'medley-2', 'name': 'Leer', 'parts': null},
      bandId: 'band-1',
    );
    expect(shared.parts, isEmpty);
    expect(shared.toSetlioRows().parts, isEmpty);
  });
}
