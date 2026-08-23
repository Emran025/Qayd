import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/domain/entities/pos_product.dart';
import 'package:qayd/domain/services/pos_money_math.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pos/pos_background_barcode_scanner.dart';
import 'package:qayd/presentation/pos/pos_checkout_cubit.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Fast POS checkout surface. Posting is deliberately not exposed until the
/// payment/document builder is connected to this cart.
class PosCheckoutPage extends StatelessWidget {
  const PosCheckoutPage({
    super.key,
    required this.cubit,
    this.scannerEnabled = true,
  });

  final PosCheckoutCubit cubit;
  final bool scannerEnabled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _PosCheckoutView(scannerEnabled: scannerEnabled),
    );
  }
}

class _PosCheckoutView extends StatefulWidget {
  const _PosCheckoutView({required this.scannerEnabled});

  final bool scannerEnabled;

  @override
  State<_PosCheckoutView> createState() => _PosCheckoutViewState();
}

class _PosCheckoutViewState extends State<_PosCheckoutView> {
  final _inputController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) context.read<PosCheckoutCubit>().search(value);
    });
  }

  Future<void> _submitInput() async {
    final value = _inputController.text.trim();
    if (value.isEmpty) return;
    await context.read<PosCheckoutCubit>().resolveAndAdd(value);
    if (mounted) {
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.posCheckoutTitle),
      body: Stack(
        children: [
          BlocBuilder<PosCheckoutCubit, PosCheckoutState>(
            builder: (context, state) => _CheckoutContent(
              state: state,
              inputController: _inputController,
              onChanged: _onChanged,
              onSubmitted: (_) => _submitInput(),
              onAddProduct: context.read<PosCheckoutCubit>().addProduct,
              onSetQuantity: context.read<PosCheckoutCubit>().setQuantity,
              onRemoveProduct: context.read<PosCheckoutCubit>().removeProduct,
              onClearCart: context.read<PosCheckoutCubit>().clearCart,
            ),
          ),
          PosBackgroundBarcodeScanner(
            onBarcode: (value) =>
                context.read<PosCheckoutCubit>().resolveAndAdd(value),
            enabled: widget.scannerEnabled,
          ),
        ],
      ),
    );
  }
}

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({
    required this.state,
    required this.inputController,
    required this.onChanged,
    required this.onSubmitted,
    required this.onAddProduct,
    required this.onSetQuantity,
    required this.onRemoveProduct,
    required this.onClearCart,
  });

  final PosCheckoutState state;
  final TextEditingController inputController;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<PosProduct> onAddProduct;
  final void Function(String, PosQuantity) onSetQuantity;
  final ValueChanged<String> onRemoveProduct;
  final VoidCallback onClearCart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      children: [
        TextField(
          controller: inputController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppStrings.posCheckoutInputHint,
            prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
            suffixIcon: IconButton(
              tooltip: AppStrings.posCheckoutClearCart,
              icon: const Icon(Icons.backspace_outlined),
              onPressed: inputController.clear,
            ),
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: SpacingTokens.sm),
        Row(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 18),
            const SizedBox(width: SpacingTokens.xs),
            Text(AppStrings.posCheckoutCameraActive),
            const Spacer(),
            TextButton.icon(
              onPressed: null,
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(AppStrings.posCheckoutPostingPending),
            ),
          ],
        ),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: Text(
              state.failure!.messageAr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (state.searchResults.isNotEmpty) ...[
          Text(
            AppStrings.posCheckoutSearchResults,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: SpacingTokens.xs),
          ...state.searchResults.map(
            (product) => Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(product.name),
                subtitle:
                    Text('${product.sku} · ${product.salePrice.minorUnits}'),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => onAddProduct(product),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
        ],
        Row(
          children: [
            Text(
              AppStrings.posCheckoutTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton(
              onPressed: state.lines.isEmpty ? null : onClearCart,
              child: Text(AppStrings.posCheckoutClearCart),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        if (state.lines.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Text(
                AppStrings.posCheckoutCartEmpty,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...state.lines.map(
            (line) => _CheckoutLineTile(
              line: line,
              onIncrement: () => onAddProduct(line.product),
              onDecrement: () {
                final step = PosMoneyMath.scaleFactor(line.quantity.scale);
                final next = line.quantity.scaledUnits - step;
                onSetQuantity(
                  line.product.id,
                  PosQuantity.fromScaled(
                    next < 0 ? 0 : next,
                    scale: line.quantity.scale,
                  ),
                );
              },
              onRemove: () => onRemoveProduct(line.product.id),
            ),
          ),
        const SizedBox(height: SpacingTokens.lg),
        Card(
          child: ListTile(
            title: Text(AppStrings.posCheckoutSubtotal),
            trailing: Text(
              '${state.subtotalMinorUnits}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutLineTile extends StatelessWidget {
  const _CheckoutLineTile({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final PosCheckoutLineState line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(line.product.name),
        subtitle: Text(
          '${line.quantity.toExactString()} × ${line.product.salePrice.minorUnits} = ${line.totalMinorUnits}',
        ),
        leading: IconButton(
          tooltip: AppStrings.posCheckoutClearCart,
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(line.quantity.toExactString()),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
