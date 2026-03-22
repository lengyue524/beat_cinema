import 'dart:io';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:sprintf/sprintf.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  late final TextEditingController _proxyController;

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController();
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        if (state is! AppLaunchComplated) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        if (_proxyController.text != state.proxyServer) {
          _proxyController.text = state.proxyServer;
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildPageHeader(context),
            const SizedBox(height: AppSpacing.md),
            _buildSectionCard(
              context: context,
              title: l10n?.nav_settings ?? 'Settings',
              subtitle: l10n?.config_section_basic_subtitle ??
                  'Core environment and preferences',
              icon: Icons.tune_rounded,
              children: [
                _buildPathSetting(context, state, l10n),
                _buildLabeledField(
                  context: context,
                  label: l10n?.languages ?? 'Languages',
                  field: DropdownButtonFormField<AppLocal>(
                    initialValue: state.local,
                    decoration: const InputDecoration(isDense: true),
                    items: AppLocal.values
                        .map((e) => DropdownMenuItem<AppLocal>(
                              value: e,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<AppBloc>().add(AppLocalUpdateEvent(value));
                    },
                  ),
                ),
                _buildLabeledField(
                  context: context,
                  label: l10n?.video_res ?? 'Video Resolution',
                  field: DropdownButtonFormField<CinemaVideoQuality>(
                    initialValue: state.cinemaVideoQuality,
                    decoration: const InputDecoration(isDense: true),
                    items: CinemaVideoQuality.values
                        .map((e) => DropdownMenuItem<CinemaVideoQuality>(
                              value: e,
                              child: Text(e.toName()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      context
                          .read<AppBloc>()
                          .add(AppCinemaVideoQualityUpdateEvent(value));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSectionCard(
              context: context,
              title: l10n?.config_section_proxy_title ?? 'Proxy',
              subtitle: l10n?.config_section_proxy_subtitle ??
                  'Network access strategy for download pipeline',
              icon: Icons.shield_moon_outlined,
              children: [
                Row(
                  children: [
                    _buildProxyModeChip(state.proxyMode, l10n),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _proxyModeDescription(state.proxyMode, l10n),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                _buildLabeledField(
                  context: context,
                  label: l10n?.config_label_proxy_mode ?? 'Proxy Mode',
                  field: DropdownButtonFormField<ProxyMode>(
                    initialValue: state.proxyMode,
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      DropdownMenuItem(
                        value: ProxyMode.system,
                        child: Text(l10n?.config_proxy_mode_system ??
                            'System Proxy (Default)'),
                      ),
                      DropdownMenuItem(
                        value: ProxyMode.custom,
                        child: Text(
                            l10n?.config_proxy_mode_custom ?? 'Custom Proxy'),
                      ),
                      DropdownMenuItem(
                        value: ProxyMode.none,
                        child: Text(l10n?.config_proxy_mode_none ?? 'No Proxy'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      context
                          .read<AppBloc>()
                          .add(AppProxyModeUpdateEvent(value));
                      _showSaved(
                        context,
                        l10n?.config_proxy_saved_mode ?? 'Proxy mode updated',
                      );
                    },
                  ),
                ),
                if (state.proxyMode == ProxyMode.custom)
                  _buildLabeledField(
                    context: context,
                    label: l10n?.config_label_proxy_address ?? 'Proxy Address',
                    field: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proxyController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: l10n?.config_proxy_address_hint ??
                                  '127.0.0.1:7890 or http://127.0.0.1:7890',
                            ),
                            onSubmitted: (value) => context
                                .read<AppBloc>()
                                .add(AppProxyServerUpdateEvent(value)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.tonal(
                          onPressed: () {
                            context.read<AppBloc>().add(
                                  AppProxyServerUpdateEvent(
                                    _proxyController.text,
                                  ),
                                );
                            _showSaved(
                              context,
                              l10n?.config_proxy_saved_address ??
                                  'Proxy address saved',
                            );
                          },
                          child: Text(l10n?.config_save ?? 'Save'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final themedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      themedChildren.add(children[i]);
      if (i < children.length - 1) {
        themedChildren.add(const Divider(height: AppSpacing.lg));
      }
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandPurple),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ...themedChildren,
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.surface3,
            AppColors.surface2,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_suggest_rounded,
              color: AppColors.brandPurple,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.config_page_title ?? 'App Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  l10n?.config_page_subtitle ??
                      'Path, download strategy and proxy configuration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProxyModeChip(ProxyMode mode, AppLocalizations? l10n) {
    final (label, color) = switch (mode) {
      ProxyMode.system => (
          l10n?.config_proxy_mode_system ?? 'System Proxy (Default)',
          AppColors.brandPurple
        ),
      ProxyMode.custom => (
          l10n?.config_proxy_mode_custom ?? 'Custom Proxy',
          AppColors.info
        ),
      ProxyMode.none => (
          l10n?.config_proxy_mode_none ?? 'No Proxy',
          AppColors.warning
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _proxyModeDescription(ProxyMode mode, AppLocalizations? l10n) {
    return switch (mode) {
      ProxyMode.system => l10n?.config_proxy_mode_desc_system ??
          'Auto-detect system proxy, recommended for daily use',
      ProxyMode.custom => l10n?.config_proxy_mode_desc_custom ??
          'Specify proxy server manually for restricted networks',
      ProxyMode.none => l10n?.config_proxy_mode_desc_none ??
          'Direct network access without proxy',
    };
  }

  Widget _buildPathSetting(
    BuildContext context,
    AppLaunchComplated state,
    AppLocalizations? l10n,
  ) {
    return _buildLabeledField(
      context: context,
      label: l10n?.beat_saber_dir ?? 'BeatSaber dir:',
      field: Row(
        children: [
          Expanded(
            child: Text(
              (state.beatSaberPath ?? '').isEmpty ? '-' : state.beatSaberPath!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: () => _pickBeatSaberDir(context),
            icon: const Icon(Icons.folder_open, size: 18),
            label: Text(l10n?.choose_dir ?? 'Choose Dir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required BuildContext context,
    required String label,
    required Widget field,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: field),
      ],
    );
  }

  Future<void> _pickBeatSaberDir(BuildContext context) async {
    final beatSaberDir = await FilePicker.platform.getDirectoryPath();
    if (beatSaberDir == null) return;
    final exePath = p.join(beatSaberDir, Constants.beatSaberExe);
    final customLevelsPath =
        p.join(beatSaberDir, Constants.dataDir, Constants.customLevelsDir);
    final exeExists = await File(exePath).exists();
    final levelsExist = await Directory(customLevelsPath).exists();
    if (exeExists && levelsExist) {
      if (context.mounted) {
        context.read<AppBloc>().add(AppBeatSaverPathUpdateEvent(beatSaberDir));
        _showSaved(
          context,
          AppLocalizations.of(context)?.config_game_dir_saved ??
              'Game directory updated',
        );
      }
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sprintf(
            AppLocalizations.of(context)!.exe_not_found,
            [Constants.beatSaberExe],
          ),
        ),
      ),
    );
  }

  void _showSaved(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
