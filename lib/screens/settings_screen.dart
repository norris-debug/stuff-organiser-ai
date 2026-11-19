import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';
import 'dashboard_screen.dart';

/// Screen 6: theme packs, mascot customisation and account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: <Widget>[
          _Section(
            title: 'Theme pack',
            subtitle: 'Colours for the whole app.',
            child: Column(
              children: themePacks.map((ThemePack pack) {
                final bool selected = pack.id == state.themePack.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => state.setThemePack(pack),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: pack.seed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(pack.emoji, style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(pack.label, style: theme.textTheme.titleSmall),
                          ),
                          if (selected)
                            Icon(Icons.check_circle, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: 'Mascot',
            subtitle: 'Pick the buddy for the ${state.themePack.label} pack.',
            child: Column(
              children: state.themePack.mascots
                  .toList()
                  .asMap()
                  .entries
                  .map((MapEntry<int, MascotVariant> entry) {
                final MascotVariant variant = entry.value;
                final bool selected = variant == state.mascot;
                // v0.8.3: expression variety - each row shows a different
                // mood instead of one shared smile.
                final MascotMood mood =
                    MascotMood.values[entry.key % MascotMood.values.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => state.setMascot(variant),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          MascotWidget(
                            variant: variant,
                            pack: state.themePack,
                            size: 56,
                            mood: mood,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(variant.label, style: theme.textTheme.titleSmall),
                          ),
                          if (selected)
                            Icon(Icons.check_circle, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: 'Account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.person_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.user?.displayLabel ?? 'Not signed in',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (state.demoMode) const Chip(label: Text('Demo mode')),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => _showAuthDialog(context, state),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in / Sign up'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.demoMode
                          ? null
                          : () async {
                              await state.signOut();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Signed out')),
                              );
                            },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Spaces',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${state.spaces.length} space${state.spaces.length == 1 ? '' : 's'} · '
                  '${state.items.length} item${state.items.length == 1 ? '' : 's'} · '
                  '${state.looseCount} still loose',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => showAddSpaceDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add space'),
                    ),
                    if (state.demoMode)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await state.resetDemoData();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demo data reset')),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset demo data'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => state.replayOnboarding(),
                      icon: const Icon(Icons.replay),
                      label: const Text('Replay onboarding'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _Section(
            title: 'About',
            child: Text(
              'Stuff Organiser AI - MVP v1.\n'
              'Photo-based item detection and real mascot art are coming in v2.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAuthDialog(BuildContext context, AppState state) async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Sign in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('signup'),
            child: const Text('Sign up'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('signin'),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );

    if (action == null) {
      emailController.dispose();
      passwordController.dispose();
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text;
    emailController.dispose();
    passwordController.dispose();

    if (action == 'signup') {
      await state.signUp(email, password);
    } else {
      await state.signIn(email, password);
    }
    if (!context.mounted) return;
    final String message = state.errorMessage ?? 'Signed in as ${state.user?.displayLabel ?? 'guest'}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
