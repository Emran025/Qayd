import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/backup/restore_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class RestoreDiscoveryPage extends StatelessWidget {
  const RestoreDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: BlocConsumer<RestoreCubit, RestoreState>(
        listener: (context, state) {
          if (state is RestoreSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت استعادة البيانات بنجاح.')),
            );
            Navigator.of(context).pop(true);
          } else if (state is RestoreFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorAr)));
          } else if (state is RestoreNeedsPrimaryKey) {
            _showPrimaryKeyDialog(context, state.backupPath);
          } else if (state is RestoreNoBackupFound) {
            Navigator.of(context).pop(false); // Go to fresh app
          }
        },
        builder: (context, state) {
          if (state is RestoreFound) {
            return _buildFoundUI(context, state);
          }
          return const Center(
            child: CircularProgressIndicator(color: ColorTokens.emerald500),
          );
        },
      ),
    );
  }

  Widget _buildFoundUI(BuildContext context, RestoreFound state) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final localMod = state.localFile.existsSync()
        ? state.localFile.lastModifiedSync()
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.xl,
        ),
        child: Column(
          children: [
            const AuthAnimatedIcon(
              iconData: Icons.cloud_download_rounded,
              iconColor: ColorTokens.emerald500,
            ),
            const SizedBox(height: SpacingTokens.lg),
            const AuthTitleBlock(
              title: 'وجدنا نسخة احتياطية',
              subtitle:
                  'هناك نسخة احتياطية سابقة لبياناتك. هل تود استعادتها الآن؟',
            ),
            const SizedBox(height: SpacingTokens.xl),

            if (state.localFile.existsSync()) ...[
              _buildBackupCard(
                context,
                title: 'نسخة محلية على الجهاز',
                subtitle:
                    'بتاريخ: ${localMod != null ? dateFormat.format(localMod) : 'غير معروف'}',
                onTap: () => context.read<RestoreCubit>().performRestore(
                  localFile: state.localFile,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
            ],

            if (state.driveInfo != null) ...[
              _buildBackupCard(
                context,
                title: 'نسخة من Google Drive',
                subtitle:
                    'بتاريخ: ${state.driveInfo!.lastModified != null ? dateFormat.format(state.driveInfo!.lastModified!) : 'غير معروف'}',
                onTap: () => context.read<RestoreCubit>().performRestore(
                  fromDrive: true,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
            ],

            const Spacer(),
            AuthSubmitButton(
              label: 'استعادة النسخة المحددة',
              loading: state is RestoreInProgess,
              onPressed: () {
                // If there's only one, we can define a default or just use the card clicks
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'تخطي والبدء بجهاز جديد',
                style: TextStyle(color: ColorTokens.slate400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(SpacingTokens.md),
        border: Border.all(color: ColorTokens.emerald500.withOpacity(0.3)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: ColorTokens.slate400),
        ),
        trailing: const Icon(
          Icons.restore_rounded,
          color: ColorTokens.emerald500,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPrimaryKeyDialog(BuildContext context, String path) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        title: const Text(
          'مفتاح التشفير مطلوب',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الرجاء إدخال المفتاح الأساسي (كلمات الاسترداد الـ 24) لفك تشفير النسخة الاحتياطية.',
              style: TextStyle(color: ColorTokens.slate400),
            ),
            const SizedBox(height: SpacingTokens.md),
            TextField(
              controller: controller,
              maxLines: 4,
              cursorColor: ColorTokens.emerald500,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B), // Slate 800
                hintText: 'ادخل عبارة الاسترداد هنا...',
                hintStyle: const TextStyle(color: ColorTokens.slate400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: ColorTokens.slate400),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.emerald600,
            ),
            onPressed: () {
              final phrase = controller.text.trim();
              if (phrase.isNotEmpty) {
                Navigator.pop(dCtx);
                context.read<RestoreCubit>().restoreWithPrimaryKey(
                  path,
                  phrase,
                );
              }
            },
            child: const Text('تأكيد وفك التشفير'),
          ),
        ],
      ),
    );
  }
}
