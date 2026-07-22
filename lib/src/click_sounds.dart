/// Click-Sound-Optionen für den Metronom-Klick (Song-Editor beider Apps).
const List<String> kClickSoundOptions = ['digital_1', 'digital_2', 'digital_3'];

/// Absoluter Fallback, wenn ein click_sound-Wert null, leer oder unbekannt
/// ist (z. B. importierte Setlio-Songs ohne eigenen Override, oder ein
/// alter/entfernter Sound-Name aus Bestandsdaten) – nie Stille, nie Fehler.
const String kDefaultClickSound = 'digital_3';

String clickSoundLabel(String? value) {
  switch (value) {
    case 'digital_1':
      return 'Digital 1';
    case 'digital_2':
      return 'Digital 2';
    case 'digital_3':
      return 'Digital 3';
    default:
      return 'Globaler Sound';
  }
}

/// Normalisiert einen rohen click_sound-Wert auf eine der aktuell gültigen
/// Optionen. Gibt [raw] unverändert zurück, wenn es einer der aktuell
/// gültigen Werte ist – sonst [kDefaultClickSound]. Bewusst KEIN Sonderfall
/// für null: null bedeutet an anderer Stelle "folge dem globalen Sound",
/// das muss der Aufrufer vor diesem Aufruf schon aufgelöst haben.
String resolveClickSound(String? raw) {
  if (raw != null && kClickSoundOptions.contains(raw)) return raw;
  return kDefaultClickSound;
}
