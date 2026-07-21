/// Version des geteilten Song-Formats. Wird beim Schreiben in
/// `songs.schema_version` abgelegt; beim Lesen prüft der Aufrufer über
/// `SharedSong.hasNewerSchema`, ob der Datensatz von einer neueren
/// App-Version stammt (dann: lesbar soweit möglich, Warnung anzeigen).
const int sharedSchemaVersion = 1;
