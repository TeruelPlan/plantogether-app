import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _nameController;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    context.read<SettingsBloc>().add(const LoadSettings());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _showError => _isDirty && _nameController.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          state.whenOrNull(
            loaded: (displayName) {
              if (!_isDirty) {
                _nameController.text = displayName;
              }
            },
            saved: (displayName) {
              _nameController.text = displayName;
              setState(() => _isDirty = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Display name updated')),
              );
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
          );
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final isSaving = state is SettingsSaving;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('settings_display_name_field'),
                    controller: _nameController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      errorText: _showError ? 'Display name is required' : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _isDirty = true),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const ValueKey('settings_save_button'),
                      onPressed: (isSaving || _nameController.text.trim().isEmpty)
                          ? null
                          : () {
                              final trimmed = _nameController.text.trim();
                              if (trimmed.isNotEmpty) {
                                context
                                    .read<SettingsBloc>()
                                    .add(SaveDisplayName(trimmed));
                              } else {
                                setState(() => _isDirty = true);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
