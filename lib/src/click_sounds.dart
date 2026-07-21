/// Click-Sound-Optionen für den Metronom-Klick (Song-Editor beider Apps).
const List<String> kClickSoundOptions = [
  'beep',
  'classic',
  'wood',
  'ableton_style',
  'logic_style',
];

String clickSoundLabel(String? value) {
  switch (value) {
    case 'beep':
      return 'Beep';
    case 'classic':
      return 'Classic';
    case 'wood':
      return 'Holz';
    case 'ableton_style':
      return 'Ableton-Style';
    case 'logic_style':
      return 'Logic-Style';
    default:
      return 'Globaler Sound';
  }
}
