import 'shared_medley.dart';
import 'shared_setlist.dart';
import 'shared_song.dart';

/// Eine Setlist komplett zum Übertragen/Cachen/Abspielen: die Liste
/// selbst (mit Einträgen) plus alle referenzierten Songs und Medleys.
/// Ersetzt Setronomes bisherigen `setronome_setlist`-Sharepayload als
/// typisiertes Objekt.
class SetlistBundle {
  const SetlistBundle({
    required this.setlist,
    this.songsById = const {},
    this.medleysById = const {},
  });

  final SharedSetlist setlist;
  final Map<String, SharedSong> songsById;
  final Map<String, SharedMedley> medleysById;

  /// Referenzierte, aber im Bundle fehlende Songs (auch aus Medley-
  /// Teilen) – z. B. nachträglich im Nirvana. Aufrufer zeigt dann
  /// „Song nicht verfügbar" statt zu crashen.
  Set<String> get missingSongIds {
    final referenced = <String>{
      for (final entry in setlist.entries)
        if (entry.songId != null) entry.songId!,
      for (final medley in medleysById.values)
        for (final part in medley.parts) part.songId,
    };
    return referenced.difference(songsById.keys.toSet());
  }

  /// Referenzierte, aber fehlende Medleys.
  Set<String> get missingMedleyIds {
    final referenced = <String>{
      for (final entry in setlist.entries)
        if (entry.medleyId != null) entry.medleyId!,
    };
    return referenced.difference(medleysById.keys.toSet());
  }
}
