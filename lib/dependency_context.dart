import 'package:get_it/get_it.dart';
import 'package:hipster/hipster/suno_service.dart';
import 'package:hipster/logger/logger.dart';

final di = GetIt.I;
final logger = Logger();

Future<void> dependencySetup() async {
  di.registerSingleton<SunoService>(SunoService());
}
