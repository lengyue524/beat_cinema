import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          itemCount: widget.itemCount,
          itemExtent: 48,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _SkeletonTile(
              shimmerValue: (_controller.value + index * 0.05) % 1.0,
            );
          },
        );
      },
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({required this.shimmerValue});

  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.surface2;
    const highlightColor = AppColors.surface4;
    final color =
        Color.lerp(baseColor, highlightColor, _shimmerCurve(shimmerValue))!;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            height: 12,
            width: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  double _shimmerCurve(double value) {
    if (value < 0.5) return value * 2;
    return (1.0 - value) * 2;
  }
}
