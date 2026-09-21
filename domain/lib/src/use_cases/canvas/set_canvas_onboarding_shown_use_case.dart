import '../../../domain.dart';
import '../use_case.dart';

/// Use case to mark the canvas onboarding slider as shown.
class SetCanvasOnboardingShownUseCase
    implements FutureUseCase<NoParams, void> {
  /// Repository for settings.
  final SettingsRepository repository;

  /// Creates a [SetCanvasOnboardingShownUseCase].
  const SetCanvasOnboardingShownUseCase({required this.repository});

  @override
  Future<void> execute([NoParams? params]) {
    return repository.setCanvasOnboardingShown();
  }
}
