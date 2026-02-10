abstract class LogWriter {
  void write({
    required LogType type,
    dynamic message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic> properties = const {},
  });
}

enum LogType {
  error(6),
  warn(5),
  info(4),
  debug(3),
  verbose(2);

  const LogType(this.level);

  final int level;
}
