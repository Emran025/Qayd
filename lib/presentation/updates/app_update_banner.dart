import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/domain/entities/app_update_snapshot.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/updates/app_update_cubit.dart';

class AppUpdateBanner extends StatelessWidget {
  const AppUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      bloc: context.read<AppUpdateCubit>(),
      builder: (context, state) {
        if (!state.shouldShowBanner && state.errorMessage == null) {
          return const SizedBox.shrink();
        }

        final restartRequired = state.status == AppUpdateStatus.restartRequired;
        final errorMessage = state.errorMessage;
        return Material(
          color: restartRequired
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(
                  restartRequired
                      ? Icons.restart_alt_rounded
                      : Icons.system_update_rounded,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restartRequired
                            ? AppStrings.appUpdateRestartBody
                            : AppStrings.appUpdateAvailableTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (!restartRequired && errorMessage == null)
                        Text(AppStrings.appUpdateAvailableBody),
                      if (errorMessage != null)
                        Text(
                          errorMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (!restartRequired && errorMessage == null)
                  TextButton(
                    onPressed: state.isInstalling
                        ? null
                        : context.read<AppUpdateCubit>().install,
                    child: Text(
                      state.isInstalling
                          ? AppStrings.appUpdateInstalling
                          : AppStrings.appUpdateInstallAction,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
