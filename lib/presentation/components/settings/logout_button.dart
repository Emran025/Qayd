import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = ColorTokens.errorSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.logout_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppStringsAr.logoutAction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    QaydDialog.show(
      context: context,
      title: AppStringsAr.logoutConfirmTitle,
      content: AppStringsAr.logoutConfirmBody,
      icon: Icons.logout_rounded,
      iconColor: ColorTokens.errorSoft,
      primaryActionLabel: AppStringsAr.logoutAction,
      onPrimaryAction: () {
        Navigator.pop(context);
        context.read<SecurityCubit>().logout();
      },
      secondaryActionLabel: AppStringsAr.actionCancel,
      onSecondaryAction: () => Navigator.pop(context),
    );
  }
}
