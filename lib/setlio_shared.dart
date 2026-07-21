/// Geteiltes Song-/Setlisten-Format für Setlio und Setronome.
///
/// Kanonisches Austauschformat sind die Supabase-Zeilen (snake_case-Maps,
/// `fromSetlioRow`/`toSetlioRow`); dazu kommen Konverter von/zu Setronomes
/// SQLite-Maps (`fromSetronomeMap`/`toSetronomeMap`). Alle Klassen tragen
/// das `Shared`-Präfix, damit sie in beiden Apps neben den bestehenden
/// Modellen leben können.
library;

export 'src/codecs.dart';
export 'src/design_tokens.dart';
export 'src/enums.dart';
export 'src/schema_version.dart';
export 'src/setlist_bundle.dart';
export 'src/shared_medley.dart';
export 'src/shared_setlist.dart';
export 'src/shared_setlist_entry.dart';
export 'src/shared_song.dart';
export 'src/shared_tempo_change.dart';
