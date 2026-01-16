class TimestampService {
  /// Hora local
  DateTime now() => DateTime.now();

  /// Hora en UTC (útil para ordenaciones consistentes)
  DateTime nowUtc() => DateTime.now().toUtc();
}
