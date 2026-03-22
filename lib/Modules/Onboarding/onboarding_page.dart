import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Services/services/beat_saber_detector.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();

  static const _prefsKey = 'onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;
  List<String> _detectedPaths = [];

  @override
  void initState() {
    super.initState();
    BeatSaberDetector().detectPaths().then((paths) {
      if (mounted) setState(() => _detectedPaths = paths);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      OnboardingPage.markComplete();
      widget.onComplete();
    }
  }

  void _skip() {
    OnboardingPage.markComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _WelcomeStep(),
                _PathStep(detectedPaths: _detectedPaths),
                _OverviewStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _skip,
                  child: const Text('Skip',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                Row(
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentPage
                            ? AppColors.brandPurple
                            : AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(_currentPage < 2 ? 'Next' : 'Get Started'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_filter,
              size: 80, color: AppColors.brandPurple),
          const SizedBox(height: AppSpacing.lg),
          Text('Welcome to Beat Cinema',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Manage Cinema mod videos for Beat Saber',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({required this.detectedPaths});
  final List<String> detectedPaths;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open,
              size: 64, color: AppColors.brandPurple),
          const SizedBox(height: AppSpacing.lg),
          Text('Beat Saber Path',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          if (detectedPaths.isNotEmpty) ...[
            const Text('Auto-detected:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            ...detectedPaths.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(p,
                      style: const TextStyle(color: AppColors.textPrimary)),
                )),
          ] else
            const Text('No installation detected.\nSet path in Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OverviewStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard,
              size: 64, color: AppColors.brandPurple),
          const SizedBox(height: AppSpacing.lg),
          Text('Quick Overview',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          const _FeatureRow(Icons.library_music, 'Levels',
              'Browse and manage custom levels'),
          const _FeatureRow(Icons.download, 'Downloads',
              'Search and download videos'),
          const _FeatureRow(Icons.settings, 'Settings',
              'Configure paths and preferences'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandPurple, size: 32),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
