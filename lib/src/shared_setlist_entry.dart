import 'enums.dart';

/// Setlist-Eintrag: Song ODER Medley ODER Pause. Spaltennamen sind in
/// Setronome (SQLite) und Setlio (`setlist_entries`) identisch, deshalb
/// gibt es hier nur EIN Row-Format ([fromRow]/[toRow]) für beide Seiten.
class SharedSetlistEntry {
  const SharedSetlistEntry({
    required this.id,
    required this.setlistId,
    required this.position,
    required this.type,
    this.songId,
    this.medleyId,
    this.pauseLabel,
    this.pauseDurationMinutes,
  });

  final String id;
  final String setlistId;
  final int position;
  final SharedEntryType type;
  final String? songId;
  final String? medleyId;
  final String? pauseLabel;
  final int? pauseDurationMinutes;

  factory SharedSetlistEntry.fromRow(Map<String, dynamic> row) {
    return SharedSetlistEntry(
      id: row['id'] as String,
      setlistId: row['setlist_id'] as String,
      position: (row['position'] as num?)?.toInt() ?? 0,
      type: SharedEntryType.fromDb(row['type'] as String),
      songId: row['song_id'] as String?,
      medleyId: row['medley_id'] as String?,
      pauseLabel: row['pause_label'] as String?,
      pauseDurationMinutes: (row['pause_duration_minutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'setlist_id': setlistId,
      'position': position,
      'type': type.dbValue,
      'song_id': songId,
      'medley_id': medleyId,
      'pause_label': pauseLabel,
      'pause_duration_minutes': pauseDurationMinutes,
    };
  }
}
