import 'package:domain/domain.dart';

import '../services/share_service.dart';

/// Implementation of [ShareRepository] using the static [ShareService].
class ShareRepositoryImpl implements ShareRepository {
  /// Creates a [ShareRepositoryImpl].
  const ShareRepositoryImpl();

  @override
  Future<void> shareFile(String filePath) async {
    await ShareService.shareFile(filePath);
  }
}
