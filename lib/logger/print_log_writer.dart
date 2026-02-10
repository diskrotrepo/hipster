// ignore_for_file: avoid_print
import 'dart:developer' as developer;

import 'package:hipster/logger/log_writer.dart';

class PrintLogWriter implements LogWriter {
  @override
  void write({
    required LogType type,
    dynamic message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic> properties = const {},
  }) {
    final ts = DateTime.now().toIso8601String();
    developer.log('$ts [$type] $message');
  }
}
