import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injectable.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: false,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();
}

Future<void> resetDependencies() async {
  await getIt.reset();
}
