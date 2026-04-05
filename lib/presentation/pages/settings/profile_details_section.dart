import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class ProfileDetailsSection extends StatefulWidget {
  const ProfileDetailsSection({super.key});

  @override
  State<ProfileDetailsSection> createState() => _ProfileDetailsSectionState();
}

class _ProfileDetailsSectionState extends State<ProfileDetailsSection> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();

  String? _avatarPath;
  String? _logoPath;
  String? _avatarUrl;
  String? _logoUrl;
  bool _loading = false;

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
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _whatsappController.text = data['whatsapp_number'] ?? '';
        _avatarUrl = data['avatar_url'];
        _logoUrl = data['logo_url'];
      });
    }
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
    final result = await InjectionContainer.updateProfileUseCase.call(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      whatsappNumber: _whatsappController.text.trim(),
      avatarPath: _avatarPath,
      logoPath: _logoPath,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStringsAr.profileUpdateSuccess)),
        );
        _avatarPath = null;
        _logoPath = null;
        _load(); // Reload URL from vault
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.failureOrNull?.messageAr ?? 'خطأ في التحديث')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(SpacingTokens.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStringsAr.profileDetailsSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                ),
                _ImagePickerSlot(
                  label: AppStringsAr.profileLogoUpload,
                  localPath: _logoPath,
                  remoteUrl: _logoUrl,
                  onPick: () => _pickImage(false),
                  isCircle: false,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.lg),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStringsAr.profileNameLabel,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStringsAr.profilePhoneLabel,
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStringsAr.profileWhatsAppLabel,
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
             const SizedBox(height: SpacingTokens.sm),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: AppStringsAr.profileEmailLabel,
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(AppStringsAr.profileUpdateAction),
            ),
          ],
        ),
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
  });

  final String label;
  final VoidCallback onPick;
  final String? localPath;
  final String? remoteUrl;
  final bool isCircle;

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
          onTap: onPick,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircle ? null : BorderRadius.circular(12),
                  image: image != null
                      ? DecorationImage(image: image, fit: BoxShape.circle == (isCircle ? BoxShape.circle : null) ? BoxFit.cover : BoxFit.contain)
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
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
