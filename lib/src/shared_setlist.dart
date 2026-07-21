import 'enums.dart';
import 'shared_setlist_entry.dart';

/// Setlist im geteilten Format – Setlio-Tabelle `setlists` inklusive der
/// Freigabe-Felder aus Migration 0014 (shared_to_setronome, origin,
/// origin_uploaded_by/at). [fromSetlioRow] toleriert Zeilen ohne diese
/// Spalten (DB-Stand vor 0014); [toSetlioRow] setzt sie voraus.
class SharedSetlist {
  const SharedSetlist({
    required this.id,
    required this.bandId,
    required this.name,
    this.transitionMode = SharedTransitionMode.immediate,
    this.gigId,
    this.isActive = true,
    this.sharedToSetronome = false,
    this.origin = SharedSetlistOrigin.setlio,
    this.originUploadedBy,
    this.originUploadedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.entries = const [],
  });

  final String id;
  final String bandId;
  final String name;
  final SharedTransitionMode transitionMode;
  final String? gigId;

  /// Setlio status active/nirvana.
  final bool isActive;

  /// Freigabe-Schalter „an Setronome senden".
  final bool sharedToSetronome;
  final SharedSetlistOrigin origin;

  /// Bei origin=setronome: wer hat wann hochgeladen („von … empfangen am …").
  final String? originUploadedBy;
  final DateTime? originUploadedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nach position sortierte Einträge – beim Row-Mapping separat, da
  /// eigene Tabelle; hier nur als bequemer Träger fürs Bundle.
  final List<SharedSetlistEntry> entries;

  factory SharedSetlist.fromSetlioRow(
    Map<String, dynamic> row, {
    List<SharedSetlistEntry> entries = const [],
  }) {
    final uploadedAt = row['origin_uploaded_at'] as String?;
    return SharedSetlist(
      id: row['id'] as String,
      bandId: row['band_id'] as String,
      name: row['name'] as String,
      transitionMode:
          SharedTransitionMode.fromDb(row['transition_mode'] as String?),
      gigId: row['gig_id'] as String?,
      isActive: (row['status'] as String? ?? 'active') == 'active',
      sharedToSetronome: row['shared_to_setronome'] as bool? ?? false,
      origin: SharedSetlistOrigin.fromDb(row['origin'] as String?),
      originUploadedBy: row['origin_uploaded_by'] as String?,
      originUploadedAt: uploadedAt == null ? null : DateTime.parse(uploadedAt),
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      entries: [...entries]..sort((a, b) => a.position.compareTo(b.position)),
    );
  }

  /// Zum Schreiben (Upsert per ID); ohne Server-Felder, ohne [entries].
  /// [gigId] wird nur bei einem echten Wert mitgeschickt (wie [createdBy]):
  /// Setronome kennt keine Gigs, ein Upload darf eine in Setlio bereits
  /// gesetzte Gig-Verknüpfung deshalb nie stillschweigend auf null ziehen.
  Map<String, dynamic> toSetlioRow() {
    return {
      'id': id,
      'band_id': bandId,
      'name': name,
      'transition_mode': transitionMode.dbValue,
      if (gigId != null) 'gig_id': gigId,
      'status': isActive ? 'active' : 'nirvana',
      'shared_to_setronome': sharedToSetronome,
      'origin': origin.dbValue,
      'origin_uploaded_by': originUploadedBy,
      'origin_uploaded_at': originUploadedAt?.toUtc().toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  /// Setronome-SQLite-Map; [bandId] kommt vom Upload-Kontext.
  factory SharedSetlist.fromSetronomeMap(
    Map<String, dynamic> map, {
    required String bandId,
    List<SharedSetlistEntry> entries = const [],
  }) {
    return SharedSetlist(
      id: map['id'] as String,
      bandId: bandId,
      name: map['name'] as String,
      transitionMode:
          SharedTransitionMode.fromDb(map['transition_mode'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      entries: [...entries]..sort((a, b) => a.position.compareTo(b.position)),
    );
  }

  Map<String, dynamic> toSetronomeMap() {
    return {
      'id': id,
      'name': name,
      'transition_mode': transitionMode.dbValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
