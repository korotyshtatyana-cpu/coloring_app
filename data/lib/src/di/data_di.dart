abstract class DataDI {
  static Future<void> initDependencies() async {
    await _initApi();
    _initProviders();
    _initServices();
    _initRepositories();
  }

  static Future<void> _initApi() async {}

  static void _initServices() {}

  static void _initProviders() {}

  static void _initRepositories() {}
}
