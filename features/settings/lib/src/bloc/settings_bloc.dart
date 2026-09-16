import 'dart:async';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// BLoC responsible for application settings.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final UpdateSettingsUseCase _updateSettingsUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  /// Creates a [SettingsBloc] with the required use cases.
  SettingsBloc({
    required this._getSettingsUseCase,
    required this._updateSettingsUseCase,
    required this._getCurrentUserUseCase,
    required this._deleteAccountUseCase,
  }) : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeLanguage>(_onChangeLanguage);
    on<DeleteAccount>(_onDeleteAccount);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SettingsStatus.loading, error: null));

      final user = await _getCurrentUserUseCase.execute();
      String? code = await _getSettingsUseCase.execute();

      // Normalize existing codes
      code = _normalizeLocaleCode(code ?? event.currentLocale);

      emit(state.copyWith(
        status: SettingsStatus.success,
        locale: code ?? state.locale,
        user: user,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: SettingsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  String? _normalizeLocaleCode(String? code) {
    if (code == null) return null;
    if (code == 'en') return 'en-US';
    if (code == 'ru') return 'ru-RU';
    if (code == 'en_US') return 'en-US';
    if (code == 'ru_RU') return 'ru-RU';
    return code;
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _updateSettingsUseCase.execute(event.languageCode);
      emit(state.copyWith(locale: event.languageCode));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SettingsStatus.loading, error: null));
      await _deleteAccountUseCase.execute();
      emit(state.copyWith(status: SettingsStatus.success, isDeleted: true));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: SettingsStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
