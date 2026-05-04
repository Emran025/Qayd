import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// DTO returned by [CollateralEntrySheet] when the user confirms input.
class CollateralInput {
  const CollateralInput({
    required this.description,
    required this.estimatedValueMinor,
    this.expiryDate,
    this.imagePaths = const [],
  });

  final String description;
  final int estimatedValueMinor;
  final DateTime? expiryDate;
  final List<String> imagePaths;
}

/// Bottom sheet for entering collateral (رهن / ضمان) details during
/// voucher creation.
///
/// Displays fields for item description, estimated value, expiry date,
/// and collateral photos. Returns a [CollateralInput] DTO on save.
class CollateralEntrySheet extends StatefulWidget {
  const CollateralEntrySheet({super.key, this.currencyCode = 'SAR'});

  final String currencyCode;

  static Future<CollateralInput?> show(
    BuildContext context, {
    String currencyCode = 'SAR',
  }) {
    return showModalBottomSheet<CollateralInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CollateralEntrySheet(currencyCode: currencyCode),
    );
  }

  @override
  State<CollateralEntrySheet> createState() => _CollateralEntrySheetState();
}

class _CollateralEntrySheetState extends State<CollateralEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  DateTime? _expiryDate;
  final List<XFile> _images = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _addImages() async {
    final picker = ImagePicker();
    final photos = await picker.pickMultiImage(imageQuality: 85);
    if (photos.isNotEmpty) {
      setState(() => _images.addAll(photos));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final valueText = _valueController.text.replaceAll(',', '');
    final valueMinor = (double.tryParse(valueText) ?? 0) * 100;

    if (valueMinor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseEnterAValid)),
      );
      return;
    }

    Navigator.of(context).pop(CollateralInput(
      description: _descriptionController.text.trim(),
      estimatedValueMinor: valueMinor.toInt(),
      expiryDate: _expiryDate,
      imagePaths: _images.map((f) => f.path).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = ColorTokens.goldAccent;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    Icon(Icons.shield_rounded, color: gold, size: 24),
                    SizedBox(width: SpacingTokens.sm),
                    Text(
                      AppStrings.addAMortgagesecurity,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.xl),

                // Description
                QaydTextField(
                  controller: _descriptionController,
                  label: AppStrings.descriptionOfTheMortgagesecurity,
                  maxLines: 3,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? AppStrings.required : null,
                ),
                SizedBox(height: SpacingTokens.md),

                // Estimated value
                QaydAmountField(
                  controller: _valueController,
                  label: 'القيمة التقديرية (${widget.currencyCode})',
                ),
                SizedBox(height: SpacingTokens.md),

                // Expiry date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppStrings.dueDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  subtitle: Text(
                    _expiryDate != null
                        ? DateFormat.yMMMd('ar').format(_expiryDate!)
                        : AppStrings.chooseADateOptional,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _expiryDate != null
                              ? scheme.onSurface
                              : scheme.outline,
                        ),
                  ),
                  trailing: Icon(Icons.event_rounded, color: gold),
                  onTap: _pickExpiryDate,
                ),
                Divider(color: scheme.outlineVariant),

                // Collateral images
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.mortgagePictures,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: _addImages,
                      icon: Icon(Icons.add_photo_alternate, color: gold),
                      label: Text(
                        AppStrings.addition,
                        style: TextStyle(color: gold),
                      ),
                    ),
                  ],
                ),

                // Image thumbnails
                if (_images.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: SpacingTokens.sm),
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_images[i].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                SizedBox(height: SpacingTokens.xl),

                // Save button
                FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: scheme.surface,
                  ),
                  icon: Icon(Icons.check_rounded),
                  label: Text(AppStrings.saveTheMortgage),
                ),
                SizedBox(height: SpacingTokens.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
