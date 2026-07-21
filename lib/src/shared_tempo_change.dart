/// Tempowechsel innerhalb eines Songs: ab Takt [atBar] gilt [bpm].
/// JSON-Format wie in Setlios `songs.tempo_changes`: {"atBar":33,"bpm":140}.
/// Setlio-only – Setronome ignoriert das Feld vorerst.
class SharedTempoChange {
  const SharedTempoChange({required this.atBar, required this.bpm});

  final int atBar;
  final double bpm;

  factory SharedTempoChange.fromJson(Map<String, dynamic> json) {
    return SharedTempoChange(
      atBar: (json['atBar'] as num).toInt(),
      bpm: (json['bpm'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'atBar': atBar, 'bpm': bpm};
}
