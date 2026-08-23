import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';

void main() {
  group('PosTemplateDefinition', () {
    test('current template has stable identity and one warehouse scope', () {
      final template = PosTemplateDefinition.current();

      expect(template.templateKey, PosTemplateDefinition.coreTemplateKey);
      expect(template.version, PosTemplateDefinition.currentVersion);
      expect(template.warehouseCode, 'POS-MAIN');
      expect(
        template.costMethod,
        PosTemplateDefinition.weightedAverageCostMethod,
      );
    });

    test('account keys are unique and stable', () {
      final template = PosTemplateDefinition.current();
      final keys = template.accounts.map((account) => account.key).toSet();
      final values =
          template.accounts.map((account) => account.key.value).toSet();

      expect(keys.length, template.accounts.length);
      expect(values.length, template.accounts.length);
      expect(
        values,
        containsAll(<String>[
          'pos.inventory_asset',
          'pos.opening_balance_clearing',
          'pos.sales_revenue',
          'pos.cogs',
          'pos.cash',
          'pos.customer_receivables',
          'pos.supplier_payables',
          'pos.sales_returns',
          'pos.purchase_returns',
          'pos.discounts',
          'pos.tax_payable',
        ]),
      );
    });

    test('core accounts expose correct debit and credit natures', () {
      final template = PosTemplateDefinition.current();

      expect(
        template.account(PosTemplateAccountKey.inventoryAsset).nature,
        AccountNature.debit,
      );
      expect(
        template.account(PosTemplateAccountKey.salesRevenue).nature,
        AccountNature.credit,
      );
      expect(
        template.account(PosTemplateAccountKey.costOfGoodsSold).nature,
        AccountNature.debit,
      );
      expect(
        template.account(PosTemplateAccountKey.supplierPayables).nature,
        AccountNature.credit,
      );
      expect(
        template.account(PosTemplateAccountKey.openingBalanceClearing).nature,
        AccountNature.credit,
      );
    });

    test('only tax payable is optional in the core template', () {
      final template = PosTemplateDefinition.current();
      final optional = template.accounts
          .where((account) => account.isOptional)
          .map((account) => account.key)
          .toList();

      expect(
          optional, <PosTemplateAccountKey>[PosTemplateAccountKey.taxPayable]);
    });

    test('account lookup returns the exact stable specification', () {
      final template = PosTemplateDefinition.current();
      final spec = template.account(PosTemplateAccountKey.discounts);

      expect(spec.name, 'POS Discounts');
      expect(spec.key.value, 'pos.discounts');
      expect(spec.classification.isStandard, isFalse);
      expect(spec.nature, AccountNature.debit);
    });
  });
}
