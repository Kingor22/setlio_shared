import 'package:setlio_shared/setlio_shared.dart';
import 'package:test/test.dart';

void main() {
  group('timeSignatureOf', () {
    test('baut die Taktart-Zeichenkette aus Zähler/Nenner', () {
      expect(timeSignatureOf(4, 4), '4/4');
      expect(timeSignatureOf(6, 8), '6/8');
      expect(timeSignatureOf(12, 8), '12/8');
    });
  });

  group('accentBeats-Codec', () {
    test('sortiert kanonisch aufsteigend', () {
      expect(accentBeatsToCsv({3, 1}), '1,3');
    });

    test('null (Feld fehlt) ergibt den Default {1}', () {
      expect(accentBeatsFromCsv(null), {1});
    });

    test('leer bleibt leer (Setronome: „kein Schlag betont")', () {
      expect(accentBeatsFromCsv(''), <int>{});
      expect(accentBeatsToCsv({}), '');
    });

    test('Roundtrip verlustfrei inkl. Leerzeichen-Toleranz', () {
      expect(accentBeatsFromCsv(accentBeatsToCsv({2, 4})), {2, 4});
      expect(accentBeatsFromCsv('1, 3'), {1, 3});
    });
  });

  group('tags-Codec', () {
    test('akzeptiert jsonb-Array, JSON-String und null', () {
      expect(tagsFromDynamic(['Party', 'Set 1']), ['Party', 'Set 1']);
      expect(tagsFromDynamic('["Party","Set 1"]'), ['Party', 'Set 1']);
      expect(tagsFromDynamic(null), isEmpty);
      expect(tagsFromDynamic(''), isEmpty);
    });

    test('Roundtrip über den Setronome-JSON-String', () {
      expect(tagsFromDynamic(tagsToJson(['Ballade'])), ['Ballade']);
      expect(tagsToJson([]), '[]');
    });
  });

  group('Enums', () {
    test('dbValues entsprechen den gespeicherten Strings beider Apps', () {
      expect(SharedTransitionMode.endOfBarWithCountIn.dbValue,
          'end_of_bar_with_countin');
      expect(SharedTransitionMode.fromDb('end_of_bar'),
          SharedTransitionMode.endOfBar);
      expect(SharedMedleyTransition.fromDb('countdown'),
          SharedMedleyTransition.countdown);
      expect(SharedEntryType.fromDb('pause'), SharedEntryType.pause);
      expect(SharedSubdivision.fromDb(3), SharedSubdivision.triplet);
      expect(SharedSetlistOrigin.fromDb('setronome'),
          SharedSetlistOrigin.setronome);
    });

    test('unbekannte/fehlende Werte fallen auf sichere Defaults zurück', () {
      expect(
          SharedTransitionMode.fromDb('???'), SharedTransitionMode.immediate);
      expect(
          SharedMedleyTransition.fromDb(null), SharedMedleyTransition.manual);
      expect(SharedSubdivision.fromDb(99), SharedSubdivision.quarter);
      expect(SharedSetlistOrigin.fromDb(null), SharedSetlistOrigin.setlio);
    });
  });
}
