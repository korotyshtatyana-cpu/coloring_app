import 'package:core/core.dart';

abstract class DomainDI {
  static void initDependencies() {
    _initUseCases();
  }

  static void _initUseCases() {}
}
