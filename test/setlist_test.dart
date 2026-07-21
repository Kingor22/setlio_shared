import 'package:setlio_shared/setlio_shared.dart';
import 'package:test/test.dart';

SharedSetlistEntry _songEntry(String id, int position, String songId) =>
    SharedSetlistEntry.fromRow({
      'id': id,
      'setlist_id': 'set-1',
      'position': position,
      'type': 'song',
      'song_id': songId,
    });

void main() {
  test('Entry-Roundtrip: ein Row-Format für beide Apps', () {
    final row = {
      'id': 'entry-1',
      'setlist_id': 'set-1',
      'position': 2,
      'type': 'pause',
      'song_id': null,
      'medley_id': null,
      'pause_label': 'Umbau',
      'pause_duration_minutes': 15,
    };
    expect(SharedSetlistEntry.fromRow(row).toRow(), row);
  });

  test(
      'Setlist aus Setlio-Row: Einträge werden nach position sortiert, '
      '0014-Felder gelesen', () {
    final setlist = SharedSetlist.fromSetlioRow(
      {
        'id': 'set-1',
        'band_id': 'band-1',
        'name': 'Stadtfest',
        'transition_mode': 'end_of_bar',
        'gig_id': 'gig-7',
        'status': 'active',
        'shared_to_setronome': true,
        'origin': 'setronome',
        'origin_uploaded_by': 'user-1',
        'origin_uploaded_at': '2026-07-20T10:00:00.000Z',
        'created_by': 'user-1',
        'created_at': '2026-07-19T09:00:00.000Z',
        'updated_at': '2026-07-20T10:00:00.000Z',
      },
      entries: [
        _songEntry('entry-2', 1, 'song-2'),
        _songEntry('entry-1', 0, 'song-1'),
      ],
    );
    expect(setlist.entries.map((entry) => entry.position), [0, 1]);
    expect(setlist.sharedToSetronome, isTrue);
    expect(setlist.origin, SharedSetlistOrigin.setronome);
    expect(setlist.originUploadedAt, isNotNull);

    final row = setlist.toSetlioRow();
    expect(row['transition_mode'], 'end_of_bar');
    expect(row['shared_to_setronome'], true);
    expect(row['origin'], 'setronome');
    expect(row.containsKey('created_at'), isFalse);
  });

  test('Row ohne 0014-Spalten (alter DB-Stand) fällt auf Defaults zurück', () {
    final setlist = SharedSetlist.fromSetlioRow({
      'id': 'set-2',
      'band_id': 'band-1',
      'name': 'Probe-Set',
      'transition_mode': 'immediate',
      'status': 'active',
      'created_at': '2026-07-19T09:00:00.000Z',
      'updated_at': '2026-07-19T09:00:00.000Z',
    });
    expect(setlist.sharedToSetronome, isFalse);
    expect(setlist.origin, SharedSetlistOrigin.setlio);
  });

  test('Setronome-Roundtrip der Setlist-Kernfelder', () {
    final map = {
      'id': 'set-3',
      'name': 'Lokale Liste',
      'transition_mode': 'end_of_bar_with_countin',
      'created_at': '2026-07-10T19:00:00.000',
      'updated_at': '2026-07-11T19:00:00.000',
    };
    final shared = SharedSetlist.fromSetronomeMap(map, bandId: 'band-1');
    expect(shared.transitionMode, SharedTransitionMode.endOfBarWithCountIn);
    expect(shared.toSetronomeMap(), map);
  });

  test('SetlistBundle meldet fehlende Songs/Medleys (auch aus Medley-Teilen)',
      () {
    final medley = SharedMedley.fromSetlioRows(
      {'id': 'medley-1', 'band_id': 'band-1', 'name': 'Medley'},
      [
        {
          'id': 'part-1',
          'medley_id': 'medley-1',
          'song_id': 'song-9',
          'position': 0,
          'bar_count': 8,
          'transition_mode': 'manual',
        },
      ],
    );
    final bundle = SetlistBundle(
      setlist: SharedSetlist.fromSetlioRow(
        {
          'id': 'set-1',
          'band_id': 'band-1',
          'name': 'Show',
          'status': 'active',
          'created_at': '2026-07-19T09:00:00.000Z',
          'updated_at': '2026-07-19T09:00:00.000Z',
        },
        entries: [
          _songEntry('entry-1', 0, 'song-1'),
          SharedSetlistEntry.fromRow({
            'id': 'entry-2',
            'setlist_id': 'set-1',
            'position': 1,
            'type': 'medley',
            'medley_id': 'medley-1',
          }),
          SharedSetlistEntry.fromRow({
            'id': 'entry-3',
            'setlist_id': 'set-1',
            'position': 2,
            'type': 'medley',
            'medley_id': 'medley-404',
          }),
        ],
      ),
      songsById: {},
      medleysById: {'medley-1': medley},
    );
    expect(bundle.missingSongIds, {'song-1', 'song-9'});
    expect(bundle.missingMedleyIds, {'medley-404'});
  });
}
