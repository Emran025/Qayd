import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/settings/get_base_currency_use_case.dart';
import 'package:qayd/application/settings/list_currencies_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/pos_activation_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

enum PosWorkspaceStatus { initial, loading, ready, disabled, failure }

final class PosWorkspaceState {
  const PosWorkspaceState({
    this.status = PosWorkspaceStatus.initial,
    this.currency,
    this.failure,
  });

  final PosWorkspaceStatus status;
  final CurrencyCode? currency;
  final Failure? failure;

  bool get isReady => status == PosWorkspaceStatus.ready && currency != null;

  PosWorkspaceState copyWith({
    PosWorkspaceStatus? status,
    CurrencyCode? currency,
    Failure? failure,
    bool clearFailure = false,
    bool clearCurrency = false,
  }) {
    return PosWorkspaceState(
      status: status ?? this.status,
      currency: clearCurrency ? null : currency ?? this.currency,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

/// Loads the activation gate and base currency needed by the POS workspace.
/// Direct navigation cannot bypass the activation check because it is repeated
/// through the repository before any POS child screen is opened.
final class PosWorkspaceCubit extends Cubit<PosWorkspaceState> {
  PosWorkspaceCubit({
    required PosActivationRepository activationRepository,
    required GetBaseCurrencyUseCase getBaseCurrencyUseCase,
    required ListCurrenciesUseCase listCurrenciesUseCase,
  })  : _activationRepository = activationRepository,
        _getBaseCurrencyUseCase = getBaseCurrencyUseCase,
        _listCurrenciesUseCase = listCurrenciesUseCase,
        super(const PosWorkspaceState());

  final PosActivationRepository _activationRepository;
  final GetBaseCurrencyUseCase _getBaseCurrencyUseCase;
  final ListCurrenciesUseCase _listCurrenciesUseCase;

  Future<void> load() async {
    if (isClosed || state.status == PosWorkspaceStatus.loading) return;
    emit(
      state.copyWith(
        status: PosWorkspaceStatus.loading,
        clearFailure: true,
        clearCurrency: true,
      ),
    );

    final enabledResult = await _activationRepository.isEnabled();
    if (isClosed) return;
    if (enabledResult.isFailure) {
      _failure(enabledResult.failureOrNull!);
      return;
    }
    if (enabledResult.valueOrNull != true) {
      emit(
        state.copyWith(
          status: PosWorkspaceStatus.disabled,
          clearFailure: true,
          clearCurrency: true,
        ),
      );
      return;
    }

    final baseCodeResult = await _getBaseCurrencyUseCase();
    if (isClosed) return;
    if (baseCodeResult.isFailure) {
      _failure(baseCodeResult.failureOrNull!);
      return;
    }

    final currenciesResult = await _listCurrenciesUseCase(onlyActive: true);
    if (isClosed) return;
    if (currenciesResult.isFailure) {
      _failure(currenciesResult.failureOrNull!);
      return;
    }

    final baseCode = baseCodeResult.valueOrNull;
    final currencies = currenciesResult.valueOrNull ?? const <CurrencyCode>[];
    CurrencyCode? currency;
    for (final candidate in currencies) {
      if (candidate.code == baseCode) {
        currency = candidate;
        break;
      }
    }
    if (currency == null) {
      _failure(
        ValidationFailure(
            messageAr: AppStrings.posWorkspaceCurrencyUnavailable),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PosWorkspaceStatus.ready,
        currency: currency,
        clearFailure: true,
      ),
    );
  }

  void _failure(Failure failure) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PosWorkspaceStatus.failure,
        failure: failure,
      ),
    );
  }
}
