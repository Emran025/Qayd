import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/pos_accounting_posting.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_invoice_payment.dart';
import 'package:qayd/domain/entities/pos_sale_posting.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/pos_product_repository.dart';
import 'package:qayd/domain/repositories/pos_stock_movement_repository.dart';
import 'package:qayd/domain/repositories/pos_template_installation_repository.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/services/pos_money_math.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

final class BuildPosSalePostingInput {
  const BuildPosSalePostingInput({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.warehouseId,
    required this.currency,
    required this.lines,
    required this.idempotencyKey,
    required this.invoiceDate,
    required this.createdAt,
    this.customerAccountId,
    this.cashSale = true,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String warehouseId;
  final CurrencyCode currency;
  final List<BuildPosSaleLineInput> lines;
  final String idempotencyKey;
  final DateTime invoiceDate;
  final DateTime createdAt;
  final AccountId? customerAccountId;
  final bool cashSale;
}

final class BuildPosSaleLineInput {
  const BuildPosSaleLineInput(
      {required this.productId, required this.quantity});

  final String productId;
  final PosQuantity quantity;
}

/// Builds a sale payload without writing anything to SQLite.
final class BuildPosSalePostingUseCase {
  BuildPosSalePostingUseCase({
    required PosProductRepository productRepository,
    required PosStockMovementRepository stockRepository,
    required PosTemplateInstallationRepository installationRepository,
    required AccountRepository accountRepository,
    required IdGenerator idGenerator,
    EntryGenerator entryGenerator = const EntryGenerator(),
  })  : _productRepository = productRepository,
        _stockRepository = stockRepository,
        _installationRepository = installationRepository,
        _accountRepository = accountRepository,
        _idGenerator = idGenerator,
        _entryGenerator = entryGenerator;

  final PosProductRepository _productRepository;
  final PosStockMovementRepository _stockRepository;
  final PosTemplateInstallationRepository _installationRepository;
  final AccountRepository _accountRepository;
  final IdGenerator _idGenerator;
  final EntryGenerator _entryGenerator;

  Future<Result<PosSalePosting>> call(BuildPosSalePostingInput input) async {
    try {
      if (input.lines.isEmpty || input.invoiceId.trim().isEmpty) {
        return _invalid('pos_sale_input_invalid');
      }
      final installation = await _installationRepository.getEnabledInstallation(
        template: PosTemplateDefinition.current(),
      );
      if (installation.isFailure) {
        return FailureResult(installation.failureOrNull!);
      }
      final context = installation.valueOrNull;
      if (context == null || context.warehouseId != input.warehouseId) {
        return _invalid('pos_sale_not_enabled');
      }
      final accountIds = await _resolveAccounts(context.accountIdsByKey, input);
      if (accountIds.isFailure) return FailureResult(accountIds.failureOrNull!);
      final accounts = accountIds.valueOrNull!;

      final invoiceLines = <PosInvoiceLine>[];
      final movements = <PosStockMovement>[];
      var cogsMinor = 0;
      for (final request in input.lines) {
        final productResult =
            await _productRepository.getById(request.productId);
        if (productResult.isFailure) {
          return FailureResult(productResult.failureOrNull!);
        }
        final product = productResult.valueOrNull!;
        if (!product.isActive ||
            product.currency != input.currency ||
            request.quantity.scale != product.quantityScale ||
            request.quantity.isZero) {
          return _invalid('pos_sale_product_invalid');
        }
        final balanceResult = await _stockRepository.getBalance(
          productId: product.id,
          warehouseId: input.warehouseId,
        );
        if (balanceResult.isFailure) {
          return FailureResult(balanceResult.failureOrNull!);
        }
        final balance = balanceResult.valueOrNull!;
        if (balance.quantity.scale != product.quantityScale ||
            balance.quantity.scaledUnits < request.quantity.scaledUnits) {
          return _invalid('pos_sale_insufficient_stock');
        }
        final lineId = _idGenerator.next();
        final unitCost = balance.averageUnitCost;
        final line = PosInvoiceLine.create(
          id: lineId,
          invoiceId: input.invoiceId,
          productId: product.id,
          productNameSnapshot: product.name,
          barcodeSnapshot: product.primaryBarcode?.value,
          quantity: request.quantity,
          unitPrice: product.salePrice,
          unitCost: unitCost,
          discount: Money.zero(input.currency),
          tax: Money.zero(input.currency),
          createdAt: input.createdAt,
        );
        invoiceLines.add(line);
        cogsMinor +=
            PosMoneyMath.multiply(request.quantity, unitCost).minorUnits;
        movements.add(
          PosStockMovement.create(
            id: _idGenerator.next(),
            productId: product.id,
            warehouseId: input.warehouseId,
            type: PosStockMovementType.sale,
            direction: PosStockMovementDirection.outbound,
            quantity: request.quantity,
            unitCost: unitCost,
            sourceType: 'pos_invoice',
            sourceId: input.invoiceId,
            sourceLineId: lineId,
            occurredAt: input.invoiceDate,
            idempotencyKey: '${input.idempotencyKey}:stock:$lineId',
            createdAt: input.createdAt,
          ),
        );
      }

      var invoice = PosInvoice.draft(
        id: input.invoiceId,
        invoiceNumber: input.invoiceNumber,
        type: PosInvoiceType.sale,
        warehouseId: input.warehouseId,
        currency: input.currency,
        lines: invoiceLines,
        idempotencyKey: input.idempotencyKey,
        invoiceDate: input.invoiceDate,
        now: input.createdAt,
        counterpartyAccountId: input.customerAccountId,
      ).post(input.createdAt);
      final payments = <PosInvoicePayment>[];
      if (input.cashSale) {
        invoice = invoice.applyPayment(invoice.total, input.createdAt);
        payments.add(
          PosInvoicePayment.create(
            id: _idGenerator.next(),
            invoiceId: invoice.id,
            accountId: accounts.cash,
            method: PosPaymentMethod.cash,
            amount: invoice.total,
            currency: invoice.currency,
            occurredAt: input.createdAt,
            idempotencyKey: '${input.idempotencyKey}:payment:cash',
          ),
        );
      }

      final commercialVoucher = Voucher.draft(
        id: VoucherId(_idGenerator.next()),
        type: VoucherType.receipt,
        date: input.invoiceDate,
        amount: invoice.total,
        currency: invoice.currency,
        counterpartyId: accounts.revenue,
        affectedAccountId: input.cashSale ? accounts.cash : accounts.receivable,
        referenceNumber: invoice.id,
        description: 'POS sale ${invoice.invoiceNumber}',
        createdAt: input.createdAt,
      ).confirm(input.createdAt);
      final commercialEntries = _entryGenerator.generateForConfirmedVoucher(
        voucher: commercialVoucher,
        transactionId: TransactionId(_idGenerator.next()),
        debitEntryId: EntryId(_idGenerator.next()),
        creditEntryId: EntryId(_idGenerator.next()),
        ledgerCreatedAt: input.createdAt,
      );
      final cogsVoucher = Voucher.draft(
        id: VoucherId(_idGenerator.next()),
        type: VoucherType.payment,
        date: input.invoiceDate,
        amount: Money.fromMinorUnits(cogsMinor, input.currency),
        currency: input.currency,
        counterpartyId: accounts.cogs,
        affectedAccountId: accounts.inventory,
        referenceNumber: invoice.id,
        description: 'POS COGS ${invoice.invoiceNumber}',
        createdAt: input.createdAt,
      ).confirm(input.createdAt);
      final cogsEntries = _entryGenerator.generateForConfirmedVoucher(
        voucher: cogsVoucher,
        transactionId: TransactionId(_idGenerator.next()),
        debitEntryId: EntryId(_idGenerator.next()),
        creditEntryId: EntryId(_idGenerator.next()),
        ledgerCreatedAt: input.createdAt,
      );
      return Success(
        PosSalePosting(
          invoice: invoice,
          movements: movements,
          postings: [
            PosAccountingPosting(
              sourceId: invoice.id,
              voucher: commercialVoucher,
              entries: commercialEntries,
            ),
            PosAccountingPosting(
              sourceId: invoice.id,
              voucher: cogsVoucher,
              entries: cogsEntries,
            ),
          ],
          payments: payments,
        ),
      );
    } catch (error) {
      return FailureResult(failureFromDomainException(error));
    }
  }

  Future<Result<_SaleAccounts>> _resolveAccounts(
    Map<String, String> ids,
    BuildPosSalePostingInput input,
  ) async {
    final required = <PosTemplateAccountKey>[
      PosTemplateAccountKey.inventoryAsset,
      PosTemplateAccountKey.salesRevenue,
      PosTemplateAccountKey.costOfGoodsSold,
      if (input.cashSale)
        PosTemplateAccountKey.posCash
      else
        PosTemplateAccountKey.customerReceivables,
    ];
    final resolved = <PosTemplateAccountKey, AccountId>{};
    for (final key in required) {
      final raw = ids[key.value]?.trim();
      if (raw == null || raw.isEmpty) {
        return _invalid('pos_sale_accounts_missing');
      }
      final accountResult = await _accountRepository.getById(AccountId(raw));
      if (accountResult.isFailure) {
        return FailureResult(accountResult.failureOrNull!);
      }
      final account = accountResult.valueOrNull;
      if (account == null || !account.isActive || account.isArchived) {
        return _invalid('pos_sale_accounts_invalid');
      }
      resolved[key] = account.id;
    }
    if (!input.cashSale && input.customerAccountId == null) {
      return _invalid('pos_sale_customer_required');
    }
    return Success(
      _SaleAccounts(
        inventory: resolved[PosTemplateAccountKey.inventoryAsset]!,
        revenue: resolved[PosTemplateAccountKey.salesRevenue]!,
        cogs: resolved[PosTemplateAccountKey.costOfGoodsSold]!,
        cash:
            resolved[PosTemplateAccountKey.posCash] ?? AccountId('unused-cash'),
        receivable: resolved[PosTemplateAccountKey.customerReceivables] ??
            AccountId('unused-receivable'),
      ),
    );
  }

  FailureResult<T> _invalid<T>(String code) => FailureResult(
        ValidationFailure(messageAr: AppStrings.posInvoiceInvalid, code: code),
      );
}

final class _SaleAccounts {
  const _SaleAccounts({
    required this.inventory,
    required this.revenue,
    required this.cogs,
    required this.cash,
    required this.receivable,
  });

  final AccountId inventory;
  final AccountId revenue;
  final AccountId cogs;
  final AccountId cash;
  final AccountId receivable;
}
