import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qayd/core/constants/countries_names.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/phone_zone.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class ProfileDetailsSection extends StatefulWidget {
  const ProfileDetailsSection({super.key});

  @override
  State<ProfileDetailsSection> createState() => _ProfileDetailsSectionState();
}

class _ProfileDetailsSectionState extends State<ProfileDetailsSection> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // Stores full number
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController(); // Stores full number

  final _phoneZoneController = TextEditingController();
  final _phoneNumController = TextEditingController();
  final _whatsappZoneController = TextEditingController();
  final _whatsappNumController = TextEditingController();

  String? _avatarPath;
  String? _logoPath;
  String? _avatarUrl;
  String? _logoUrl;
  bool _loading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await InjectionContainer.licenseVault.readLicenseData();
    if (data == null) return;

    if (mounted) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        final p = data['phone'] ?? '';
        _phoneController.text = p;
        _splitFullNumber(p, _phoneZoneController, _phoneNumController);

        _emailController.text = data['email'] ?? '';

        final w = data['whatsapp_number'] ?? '';
        _whatsappController.text = w;
        _splitFullNumber(w, _whatsappZoneController, _whatsappNumController);

        _avatarUrl = data['avatar_url'];
        _logoUrl = data['logo_url'];
      });
    }
  }

  void _splitFullNumber(
    String full,
    TextEditingController zone,
    TextEditingController num,
  ) {
    if (full.isEmpty) return;
    final digits = full.replaceAll(RegExp(r'[^\d]'), '');
    // Try matching longest country codes first
    final sortedCountries = List.from(countries)
      ..sort((a, b) =>
          b.countryCallingCode.length.compareTo(a.countryCallingCode.length));

    for (var c in sortedCountries) {
      final code = c.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.startsWith(code)) {
        zone.text = code;
        num.text = digits.substring(code.length);
        return;
      }
    }
    num.text = digits;
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isAvatar ? 512 : 1024,
      maxHeight: isAvatar ? 512 : 1024,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() {
      if (isAvatar) {
        _avatarPath = image.path;
      } else {
        _logoPath = image.path;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    final phoneFull =
        (_phoneZoneController.text + _phoneNumController.text).trim();
    final whatsappFull =
        (_whatsappZoneController.text + _whatsappNumController.text).trim();

    final result = await InjectionContainer.updateProfileUseCase.call(
      name: _nameController.text.trim(),
      phone: phoneFull,
      email: _emailController.text.trim(),
      whatsappNumber: whatsappFull,
      avatarPath: _avatarPath,
      logoPath: _logoPath,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (result.isSuccess) {
          _isEditing = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStringsAr.profileUpdateSuccess)),
          );
          _avatarPath = null;
          _logoPath = null;
          _load(); // Reload URL from vault
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result.failureOrNull?.messageAr ?? 'خطأ في التحديث')),
          );
        }
      });
    }
  }

  void _cancel() {
    setState(() {
      _isEditing = false;
      _avatarPath = null;
      _logoPath = null;
      _load(); // Revert to saved data
    });
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Card(
      margin: const EdgeInsets.all(SpacingTokens.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isEditing ? _buildEditMode(gold) : _buildViewMode(gold),
        ),
      ),
    );
  }

  Widget _buildViewMode(Color gold) {
    return Column(
      key: const ValueKey('view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QaydText(
              AppStringsAr.profileDetailsSection,
              slot: QaydTextStyleSlot.titleMedium,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: Icon(Icons.edit_note_rounded, color: gold),
              tooltip: AppStringsAr.voucherEditAction,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        // ── Avatar & Logo Row ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ImagePickerSlot(
              label: AppStringsAr.profileImageUpload,
              localPath: _avatarPath,
              remoteUrl: _avatarUrl,
              onPick: () {},
              isCircle: true,
              isEditing: false,
            ),
            _ImagePickerSlot(
              label: AppStringsAr.profileLogoUpload,
              localPath: _logoPath,
              remoteUrl: _logoUrl,
              onPick: () {},
              isCircle: false,
              isEditing: false,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xl),

        _DetailItem(
          icon: Icons.person_outline_rounded,
          label: AppStringsAr.profileNameLabel,
          value: _nameController.text,
          gold: gold,
        ),
        _DetailItem(
          icon: Icons.phone_outlined,
          label: AppStringsAr.profilePhoneLabel,
          value: _phoneController.text,
          gold: gold,
        ),
        _DetailItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: AppStringsAr.profileWhatsAppLabel,
          value: _whatsappController.text,
          gold: gold,
        ),
        _DetailItem(
          icon: Icons.email_outlined,
          label: AppStringsAr.profileEmailLabel,
          value: _emailController.text,
          gold: gold,
        ),
      ],
    );
  }

  Widget _buildEditMode(Color gold) {
    return Column(
      key: const ValueKey('edit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QaydText(
          AppStringsAr.profileDetailsSection,
          slot: QaydTextStyleSlot.titleMedium,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: SpacingTokens.md),

        // ── Avatar & Logo Row ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ImagePickerSlot(
              label: AppStringsAr.profileImageUpload,
              localPath: _avatarPath,
              remoteUrl: _avatarUrl,
              onPick: () => _pickImage(true),
              isCircle: true,
              isEditing: true,
            ),
            _ImagePickerSlot(
              label: AppStringsAr.profileLogoUpload,
              localPath: _logoPath,
              remoteUrl: _logoUrl,
              onPick: () => _pickImage(false),
              isCircle: false,
              isEditing: true,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        QaydTextField(
          controller: _nameController,
          label: AppStringsAr.profileNameLabel,
          prefixIcon: Icon(Icons.person_outline, color: gold),
        ),
        const SizedBox(height: SpacingTokens.md),
        PhoneZoneForm(
          zoneController: _phoneZoneController,
          phoneController: _phoneNumController,
          label: AppStringsAr.profilePhoneLabel,
        ),
        const SizedBox(height: SpacingTokens.md),
        PhoneZoneForm(
          zoneController: _whatsappZoneController,
          phoneController: _whatsappNumController,
          label: AppStringsAr.profileWhatsAppLabel,
        ),
        const SizedBox(height: SpacingTokens.md),
        QaydTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          label: AppStringsAr.profileEmailLabel,
          prefixIcon: Icon(Icons.email_outlined, color: gold),
        ),
        const SizedBox(height: SpacingTokens.xl),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : _cancel,
                child: Text(AppStringsAr.actionCancel),
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(AppStringsAr.profileUpdateAction),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.gold,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: gold, size: 20),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QaydText(
                  label,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                QaydText(
                  value.isEmpty ? '—' : value,
                  slot: QaydTextStyleSlot.bodyLarge,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerSlot extends StatelessWidget {
  const _ImagePickerSlot({
    required this.label,
    required this.onPick,
    this.localPath,
    this.remoteUrl,
    required this.isCircle,
    required this.isEditing,
  });

  final String label;
  final VoidCallback onPick;
  final String? localPath;
  final String? remoteUrl;
  final bool isCircle;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (localPath != null) {
      image = FileImage(File(localPath!));
    } else if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      image = NetworkImage(remoteUrl!);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: isEditing ? onPick : null,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircle ? null : BorderRadius.circular(12),
                  border: isEditing
                      ? Border.all(
                          color: Theme.of(context)
                              .extension<QaydCustomColors>()!
                              .goldAccent
                              .withValues(alpha: 0.5),
                          width: 2)
                      : null,
                  image: image != null
                      ? DecorationImage(
                          image: image,
                          fit: BoxShape.circle ==
                                  (isCircle ? BoxShape.circle : null)
                              ? BoxFit.cover
                              : BoxFit.contain)
                      : null,
                ),
                child: image == null
                    ? Icon(
                        isCircle ? Icons.person : Icons.business,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              if (isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<QaydCustomColors>()!
                          .goldAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        QaydText(
          label,
          slot: QaydTextStyleSlot.labelSmall,
        ),
      ],
    );
  }
}
