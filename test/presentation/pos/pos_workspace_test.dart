import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/application/settings/get_base_currency_use_case.dart';
import 'package:qayd/application/settings/list_currencies_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_activation_result.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/pos_activation_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/pos/pos_workspace_page.dart';
import 'package:qayd/presentation/pos/pos_workspace_cubit.dart';
import 'package:qayd/presentation/theme/app_theme.dart';

final class _WorkspaceCurrencyRepository implements CurrencyRepository {
  _WorkspaceCurrencyRepository(this.currency);

  final CurrencyCode currency;

  @override
  Future<Result<CurrencyCode?>> getByCode(String code) async =>
      Success(code == currency.code ? currency : null);

  @override
  Future<Result<List<CurrencyCode>>> getAll({bool onlyActive = false}) async =>
      Success([currency]);

  @override
  Future<Result<void>> save(CurrencyCode currency,
          {bool isPredefined = false}) async =>
      const Success(null);

  @override
  Future<Result<void>> toggleActiveStatus(String code, bool isActive) async =>
      const Success(null);

  @override
  Future<Result<String>> getBaseCurrencyCode() async => Success(currency.code);

  @override
  Future<Result<void>> setBaseCurrencyCode(String code) async =>
      const Success(null);
}

final class _WorkspaceActivationRepository implements PosActivationRepository {
  _WorkspaceActivationRepository(this.enabled);

  final bool enabled;

  @override
  Future<Result<bool>> isEnabled() async => Success(enabled);

  @override
  Future<Result<void>> disable() async => const Success(null);

  @override
  Future<Result<PosActivationResult>> installTemplate({
    required PosTemplateDefinition template,
    required DateTime now,
    required String deviceId,
  }) async =>
      throw UnimplementedError();
}

CurrencyCode _currency() => CurrencyCode(
      code: 'SAR',
      nameAr: 'ريال',
      symbol: 'ر.س',
    );

PosWorkspaceCubit _cubit({required bool enabled}) {
  final currency = _currency();
  final currencyRepository = _WorkspaceCurrencyRepository(currency);
  return PosWorkspaceCubit(
    activationRepository: _WorkspaceActivationRepository(enabled),
    getBaseCurrencyUseCase: GetBaseCurrencyUseCase(currencyRepository),
    listCurrenciesUseCase: ListCurrenciesUseCase(currencyRepository),
  );
}

void main() {
  group('PosWorkspaceCubit', () {
    test('blocks workspace when POS is disabled', () async {
      final cubit = _cubit(enabled: false);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, PosWorkspaceStatus.disabled);
      expect(cubit.state.currency, isNull);
    });

    test('loads base currency only after POS activation is confirmed',
        () async {
      final cubit = _cubit(enabled: true);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, PosWorkspaceStatus.ready);
      expect(cubit.state.currency?.code, 'SAR');
    });
  });

  testWidgets('shows a locked workspace when activation is disabled',
      (tester) async {
    final cubit = _cubit(enabled: false);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PosWorkspacePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.posWorkspaceDisabled), findsOneWidget);
    expect(find.text(AppStrings.posCatalogTitle), findsNothing);
  });

  testWidgets('shows the catalog entry only after activation is enabled',
      (tester) async {
    final cubit = _cubit(enabled: true);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PosWorkspacePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.posWorkspaceWelcome), findsOneWidget);
    expect(find.text(AppStrings.posCatalogTitle), findsOneWidget);
  });
}
