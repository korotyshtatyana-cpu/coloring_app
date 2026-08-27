part of 'settings_bloc.dart';

/// Base class for settings events.
abstract class SettingsEvent extends Equatable {
  /// Creates a [SettingsEvent].
  const SettingsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests loading saved settings.
class LoadSettings extends SettingsEvent {
  /// Creates a [LoadSettings] event.
  const LoadSettings();
}

/// Changes the application language.
class ChangeLanguage extends SettingsEvent {
  /// New language code.
  final String languageCode;

  /// Creates a [ChangeLanguage] event.
  const ChangeLanguage(this.languageCode);

  @override
  List<Object?> get props => <Object?>[languageCode];
}
