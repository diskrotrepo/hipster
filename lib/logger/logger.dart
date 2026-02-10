import 'dart:developer' as developer;

import 'package:hipster/logger/log_writer.dart';
import 'package:hipster/logger/print_log_writer.dart';

Logger? _logger;

Logger get logger {
  if (_logger == null) {
    _logger = Logger();
    _logger!.addWriter(PrintLogWriter());
  }
  return _logger!;
}

set logger(Logger logger) {
  _logger = logger;
}

class Logger {
  Logger({Set<LogWriter> writers = const {}}) {
    this.writers.addAll(writers);
  }

  final Set<LogWriter> writers = {};

  void addWriter(LogWriter writer) {
    writers.add(writer);
  }

  void removeWriter(Type writer) {
    writers.removeWhere((element) => element.runtimeType == writer);
  }

  bool hasWriter<T>() {
    return writers.any((element) => element.runtimeType == T);
  }

  void e({
    dynamic message,
    dynamic error,
    dynamic stackTrace,
    Map<String, dynamic> properties = const {},
  }) {
    try {
      for (final writer in writers) {
        writer.write(
          type: LogType.error,
          message: message,
          error: error,
          stackTrace: stackTrace as StackTrace?,
          properties: properties,
        );
      }
    } catch (e, s) {
      developer.log('Failed to write to log', error: e, stackTrace: s);
    }
  }

  void w({dynamic message, Map<String, dynamic> properties = const {}}) {
    try {
      for (final writer in writers) {
        writer.write(
          type: LogType.warn,
          message: message,
          properties: properties,
        );
      }
    } catch (e, s) {
      developer.log('Failed to write to log', error: e, stackTrace: s);
    }
  }

  void i({dynamic message, Map<String, dynamic> properties = const {}}) {
    try {
      for (final writer in writers) {
        writer.write(
          type: LogType.info,
          message: message,
          properties: properties,
        );
      }
    } catch (e, s) {
      developer.log('Failed to write to log', error: e, stackTrace: s);
    }
  }

  void d({dynamic message, Map<String, dynamic> properties = const {}}) {
    try {
      for (final writer in writers) {
        writer.write(
          type: LogType.debug,
          message: message,
          properties: properties,
        );
      }
    } catch (e, s) {
      developer.log('Failed to write to log', error: e, stackTrace: s);
    }
  }

  void v({dynamic message, Map<String, dynamic> properties = const {}}) {
    try {
      for (final writer in writers) {
        writer.write(
          type: LogType.verbose,
          message: message,
          properties: properties,
        );
      }
    } catch (e, s) {
      developer.log('Failed to write to log', error: e, stackTrace: s);
    }
  }
}
