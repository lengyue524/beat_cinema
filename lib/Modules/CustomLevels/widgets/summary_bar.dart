import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';

class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CustomLevelsBloc, CustomLevelsState>(
      buildWhen: (prev, curr) => curr is CustomLevelsLoaded,
      builder: (context, state) {
        if (state is! CustomLevelsLoaded) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              _stat(l10n?.summary_total ?? '总数',
                  '${state.filteredLevels.length}', AppColors.textPrimary),
              const SizedBox(width: AppSpacing.md),
              _stat(l10n?.summary_configured ?? '已配置',
                  '${state.configuredCount}', AppColors.brandPurple),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
                color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
