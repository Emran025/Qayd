import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Bottom sheet for picking attachment images from camera or gallery.
///
/// Returns a list of [XFile] paths selected by the user, or null if cancelled.
class AttachmentPickerSheet extends StatelessWidget {
  AttachmentPickerSheet({super.key});

  final ImagePicker _picker = ImagePicker();

  static Future<List<XFile>?> show(BuildContext context) {
    return showModalBottomSheet<List<XFile>>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AttachmentPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = ColorTokens.goldAccent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppStrings.attachPhotos,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: _PickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: AppStrings.camera,
                    color: gold,
                    onTap: () => _pickFromCamera(context),
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: _PickerOption(
                    icon: Icons.photo_library_rounded,
                    label: AppStrings.exhibition,
                    color: gold,
                    onTap: () => _pickFromGallery(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.md),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied || status.isDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, AppStrings.cameraOrPhotos);
      }
      return;
    }

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null && context.mounted) {
        Navigator.of(context).pop([photo]);
      }
    } catch (e) {
      debugPrint('Camera Error (Permission Denied or native error): $e');
      if (context.mounted) {
        _showSettingsDialog(context, AppStrings.camera);
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      // The Multi-image picker
      final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 85);
      if (photos.isNotEmpty && context.mounted) {
        Navigator.of(context).pop(photos);
      }
    } catch (e) {
      debugPrint('Gallery Picker Error: $e');
      if (context.mounted) {
        _showSettingsDialog(context, AppStrings.thePictures);
      }
    }
  }

  void _showSettingsDialog(BuildContext context, String serviceName) {
    QaydDialog.show(
      context: context,
      icon: Icons.shield_rounded,
      title: AppStrings.missingValidity,
      content: AppStrings.permissionDeniedMessage(serviceName),

      secondaryActionLabel: AppStrings.cancellation,
      onSecondaryAction: () => Navigator.pop(context),
      primaryActionLabel: AppStrings.openSettings,
      onPrimaryAction: () {
        Navigator.pop(context);
        openAppSettings(); // يفتح إعدادات التطبيق في الهاتف مباشرة
      },
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.xl,
            horizontal: SpacingTokens.md,
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              SizedBox(height: SpacingTokens.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
