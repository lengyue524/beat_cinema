import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Services/services/atomic_file_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ConfigEditPanel extends StatefulWidget {
  const ConfigEditPanel({super.key, required this.metadata});
  final LevelMetadata metadata;

  @override
  State<ConfigEditPanel> createState() => _ConfigEditPanelState();
}

class _ConfigEditPanelState extends State<ConfigEditPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _videoFileCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _offsetCtrl;
  late final TextEditingController _durationCtrl;
  bool _loop = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config = widget.metadata.cinemaConfig;
    _videoFileCtrl = TextEditingController(text: config?.videoFile ?? '');
    _titleCtrl = TextEditingController(text: config?.title ?? '');
    _authorCtrl = TextEditingController(text: config?.author ?? '');
    _videoUrlCtrl = TextEditingController(text: config?.videoUrl ?? '');
    _offsetCtrl = TextEditingController(text: '${config?.offset ?? 0}');
    _durationCtrl = TextEditingController(text: '${config?.duration ?? 0}');
    _loop = config?.loop ?? false;
  }

  @override
  void dispose() {
    _videoFileCtrl.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _videoUrlCtrl.dispose();
    _offsetCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final configPath =
          p.join(widget.metadata.levelPath, Constants.cinemaConfigFileName);
      final file = File(configPath);
      Map<String, dynamic> existing = {};
      if (await file.exists()) {
        try {
          existing =
              json.decode(await file.readAsString()) as Map<String, dynamic>;
        } catch (_) {}
      }

      existing['videoFile'] = _videoFileCtrl.text;
      existing['title'] = _titleCtrl.text;
      existing['author'] = _authorCtrl.text;
      existing['videoUrl'] = _videoUrlCtrl.text;
      existing['offset'] = int.tryParse(_offsetCtrl.text) ?? 0;
      existing['duration'] = int.tryParse(_durationCtrl.text) ?? 0;
      existing['loop'] = _loop;

      await AtomicFileService().writeString(configPath, json.encode(existing));

      if (mounted) {
        setState(() {
          _dirty = false;
          _saving = false;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.config_saved ?? 'Config saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _field(l10n?.config_video_file ?? 'Video File', _videoFileCtrl,
              validator: (v) => (v == null || v.isEmpty)
                  ? (l10n?.config_required ?? 'Required')
                  : null),
          _field(l10n?.config_title ?? 'Title', _titleCtrl),
          _field(l10n?.config_author ?? 'Author', _authorCtrl),
          _field(l10n?.config_video_url ?? 'Video URL', _videoUrlCtrl),
          _field(l10n?.config_offset ?? 'Offset (ms)', _offsetCtrl,
              number: true),
          _field(l10n?.config_duration ?? 'Duration (ms)', _durationCtrl,
              number: true),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(l10n?.config_loop ?? 'Loop',
                  style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Switch(
                value: _loop,
                activeTrackColor: AppColors.brandPurple,
                onChanged: (v) {
                  setState(() => _loop = v);
                  _markDirty();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save, size: 18),
            label: Text(l10n?.config_save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool number = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        onChanged: (_) => _markDirty(),
      ),
    );
  }
}
