import 'package:flutter_test/flutter_test.dart';
import 'package:hipster/logger/log_writer.dart';
import 'package:hipster/logger/logger.dart';

class _MockLogWriter implements LogWriter {
  final List<_LogEntry> entries = [];

  @override
  void write({
    required LogType type,
    dynamic message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic> properties = const {},
  }) {
    entries.add(_LogEntry(
      type: type,
      message: message,
      error: error,
      stackTrace: stackTrace,
      properties: properties,
    ));
  }
}

class _ThrowingLogWriter implements LogWriter {
  @override
  void write({
    required LogType type,
    dynamic message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic> properties = const {},
  }) {
    throw Exception('Writer failed');
  }
}

class _LogEntry {
  _LogEntry({
    required this.type,
    this.message,
    this.error,
    this.stackTrace,
    this.properties = const {},
  });

  final LogType type;
  final dynamic message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic> properties;
}

void main() {
  group('Logger', () {
    late Logger testLogger;
    late _MockLogWriter mockWriter;

    setUp(() {
      testLogger = Logger();
      mockWriter = _MockLogWriter();
      testLogger.addWriter(mockWriter);
    });

    test('starts with no writers by default', () {
      final emptyLogger = Logger();
      expect(emptyLogger.writers, isEmpty);
    });

    test('can be initialized with writers', () {
      final writer = _MockLogWriter();
      final loggerWithWriters = Logger(writers: {writer});
      expect(loggerWithWriters.writers, contains(writer));
    });

    group('writer management', () {
      test('addWriter adds a writer', () {
        final newWriter = _MockLogWriter();
        testLogger.addWriter(newWriter);
        expect(testLogger.writers, contains(newWriter));
      });

      test('removeWriter removes by type', () {
        testLogger.removeWriter(_MockLogWriter);
        expect(testLogger.hasWriter<_MockLogWriter>(), isFalse);
      });

      test('hasWriter returns true when writer type exists', () {
        expect(testLogger.hasWriter<_MockLogWriter>(), isTrue);
      });

      test('hasWriter returns false when writer type does not exist', () {
        expect(testLogger.hasWriter<_ThrowingLogWriter>(), isFalse);
      });
    });

    group('log methods', () {
      test('e() logs with LogType.error', () {
        testLogger.e(message: 'error msg', error: 'err', properties: {'k': 'v'});
        expect(mockWriter.entries, hasLength(1));
        expect(mockWriter.entries.first.type, LogType.error);
        expect(mockWriter.entries.first.message, 'error msg');
        expect(mockWriter.entries.first.error, 'err');
        expect(mockWriter.entries.first.properties, {'k': 'v'});
      });

      test('w() logs with LogType.warn', () {
        testLogger.w(message: 'warn msg');
        expect(mockWriter.entries.first.type, LogType.warn);
        expect(mockWriter.entries.first.message, 'warn msg');
      });

      test('i() logs with LogType.info', () {
        testLogger.i(message: 'info msg');
        expect(mockWriter.entries.first.type, LogType.info);
        expect(mockWriter.entries.first.message, 'info msg');
      });

      test('d() logs with LogType.debug', () {
        testLogger.d(message: 'debug msg');
        expect(mockWriter.entries.first.type, LogType.debug);
        expect(mockWriter.entries.first.message, 'debug msg');
      });

      test('v() logs with LogType.verbose', () {
        testLogger.v(message: 'verbose msg');
        expect(mockWriter.entries.first.type, LogType.verbose);
        expect(mockWriter.entries.first.message, 'verbose msg');
      });

      test('writes to all registered writers', () {
        final secondWriter = _MockLogWriter();
        testLogger.addWriter(secondWriter);
        testLogger.i(message: 'multi');
        expect(mockWriter.entries, hasLength(1));
        expect(secondWriter.entries, hasLength(1));
      });
    });

    group('error handling', () {
      test('does not throw when a writer throws', () {
        final throwingLogger = Logger(writers: {_ThrowingLogWriter()});
        expect(() => throwingLogger.e(message: 'test'), returnsNormally);
        expect(() => throwingLogger.w(message: 'test'), returnsNormally);
        expect(() => throwingLogger.i(message: 'test'), returnsNormally);
        expect(() => throwingLogger.d(message: 'test'), returnsNormally);
        expect(() => throwingLogger.v(message: 'test'), returnsNormally);
      });
    });
  });

  group('LogType', () {
    test('has correct levels', () {
      expect(LogType.error.level, 6);
      expect(LogType.warn.level, 5);
      expect(LogType.info.level, 4);
      expect(LogType.debug.level, 3);
      expect(LogType.verbose.level, 2);
    });
  });
}
