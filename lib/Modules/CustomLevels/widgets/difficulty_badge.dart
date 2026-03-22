import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulties});

  final List<String> difficulties;

  static const _order = ['Easy', 'Normal', 'Hard', 'Expert', 'ExpertPlus'];

  static Color colorFor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return BeatSaberColors.easy;
      case 'Normal':
        return BeatSaberColors.normal;
      case 'Hard':
        return BeatSaberColors.hard;
      case 'Expert':
        return BeatSaberColors.expert;
      case 'ExpertPlus':
        return BeatSaberColors.expertPlus;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<String>.from(difficulties)
      ..sort((a, b) =>
          _order.indexOf(a).compareTo(_order.indexOf(b)));

    return Semantics(
      label: sorted.join(', '),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: sorted.map((d) {
          final isExpertPlus = d == 'ExpertPlus';
          final size = isExpertPlus ? 10.0 : 8.0;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Tooltip(
              message: d,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorFor(d),
                  border: isExpertPlus
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
