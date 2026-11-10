import 'dart:async';
import 'dart:ui' show Locale;

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
  final GetActiveSubscriptionUseCase _getActiveSubscriptionUseCase;
  final IsNoAdsPurchasedUseCase _isNoAdsPurchasedUseCase;
  final GetSubscriptionPlanTypeUseCase _getSubscriptionPlanTypeUseCase;

  /// Creates a [SettingsBloc] with the required use cases.
  SettingsBloc({
    required this._getSettingsUseCase,
    required this._updateSettingsUseCase,
    required this._getCurrentUserUseCase,
    required this._deleteAccountUseCase,
    required this._getActiveSubscriptionUseCase,
    required this._isNoAdsPurchasedUseCase,
    required this._getSubscriptionPlanTypeUseCase,
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

      SubscriptionEntity? subscription;
      bool noAdsPurchased = false;
      if (user != null) {
        subscription = await _getActiveSubscriptionUseCase.execute(user.id);
        noAdsPurchased = await _isNoAdsPurchasedUseCase.execute(user.id);
      }
      final planType = _getSubscriptionPlanTypeUseCase.execute(subscription);

      emit(state.copyWith(
        status: SettingsStatus.success,
        locale: code ?? state.locale,
        user: user,
        activeSubscription: subscription,
        planType: planType,
        noAdsPurchased: noAdsPurchased,
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
    final List<String> parts = code.replaceAll('_', '-').split('-');
    final String languageCode = parts.first;
    final String? countryCode = parts.length > 1 ? parts[1] : null;

    for (final Locale locale in AppLocalization.supportedLocales) {
      if (locale.languageCode != languageCode) continue;
      if (countryCode != null && locale.countryCode != countryCode) continue;
      return '${locale.languageCode}-${locale.countryCode}';
    }

    final Locale fallback = AppLocalization.fallbackLocale;
    return '${fallback.languageCode}-${fallback.countryCode}';
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
