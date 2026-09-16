import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../../data.dart';

/// Remote provider for submitting feedback to Supabase.
class FeedbackRemoteProvider {
  final SupabaseClient _client;

  /// Creates a [FeedbackRemoteProvider] with the given [_client].
  FeedbackRemoteProvider({required SupabaseClient client}) : _client = client;

  /// Submits feedback to the `feedback` table and uploads attachments.
  Future<void> submitFeedback({
    required String message,
    required String type,
    required String email,
    required List<File> attachments,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    final List<String> attachmentUrls = [];

    // 1. Upload attachments to storage
    for (final File file in attachments) {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final String storagePath = userId != null ? '$userId/$fileName' : 'anonymous/$fileName';

      await _client.storage.from(RequestConstants.feedbackBucket).upload(
            storagePath,
            file,
          );

      final String url = _client.storage
          .from(RequestConstants.feedbackBucket)
          .getPublicUrl(storagePath);
      attachmentUrls.add(url);
    }

    // 2. Insert feedback record
    await _client.from(RequestConstants.feedbackTable).insert({
      'message': message,
      'type': type,
      'email': email,
      'user_id': userId,
      'attachments': attachmentUrls,
    });
  }
}
