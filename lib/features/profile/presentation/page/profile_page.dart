import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _displayNameController;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileBloc>().add(const LoadProfile());
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          state.whenOrNull(
            loaded: (profile) {
              _displayNameController.text = profile.displayName;
              setState(() => _isDirty = false);
            },
            updateSuccess: (profile) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated')),
              );
              _displayNameController.text = profile.displayName;
              setState(() => _isDirty = false);
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $message')),
              );
            },
          );
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (profile) => _buildProfileForm(context, state),
              updating: () => _buildProfileForm(context, state),
              updateSuccess: (profile) => _buildProfileForm(context, state),
              error: (message) => Center(child: Text('Error: $message')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, ProfileState state) {
    final isUpdating = state is ProfileUpdating;
    final isEmpty = _displayNameController.text.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _displayNameController.text.isNotEmpty
                    ? _displayNameController.text[0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Display name field
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              hintText: 'Enter your display name',
              errorText: (_isDirty || isEmpty) && isEmpty
                  ? 'Display name is required'
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _isDirty = true);
            },
          ),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isEmpty || isUpdating)
                  ? null
                  : () {
                      context.read<ProfileBloc>().add(
                          UpdateDisplayName(_displayNameController.text.trim()));
                    },
              child: isUpdating
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
  }
}
