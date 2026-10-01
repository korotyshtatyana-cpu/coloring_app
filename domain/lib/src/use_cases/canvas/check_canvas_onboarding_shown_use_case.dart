import '../../../domain.dart';

/// Use case to check if the canvas onboarding slider has been shown.
class CheckCanvasOnboardingShownUseCase
    implements FutureUseCase<NoParams, bool> {
  /// Repository for settings.
  final SettingsRepository repository;

  /// Creates a [CheckCanvasOnboardingShownUseCase].
  const CheckCanvasOnboardingShownUseCase({required this.repository});

  @override
  Future<bool> execute([NoParams? params]) {
    return repository.isCanvasOnboardingShown();
  }
}
