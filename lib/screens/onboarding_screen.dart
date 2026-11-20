import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';

/// Screen 1: pick a theme pack, pick a mascot, name the first space.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _spaceController = TextEditingController(text: 'Kitchen');
  int _page = 0;
  String _emoji = '🍳';

  /// v0.8.16 (Meiosis TC-02): a rapid double-tap on "Start organising"
  /// ran completion twice. The flag blocks the second press while the
  /// first is still in flight.
  bool _finishing = false;

  static const List<String> _emojis = <String>['🍳', '🗂️', '👕', '🛏️', '🛁', '🎸', '📚', '📦'];

  @override
  void dispose() {
    _controller.dispose();
    _spaceController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _back() {
    if (_page > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _finish(AppState state) async {
    if (_finishing) return;
    _finishing = true;
    try {
      await state.completeOnboarding(_spaceController.text, emoji: _emoji);
    } finally {
      _finishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (int index) => setState(() => _page = index),
                children: <Widget>[
                  _ThemeStep(state: state),
                  _MascotStep(state: state),
                  _SpaceStep(
                    controller: _spaceController,
                    emoji: _emoji,
                    emojis: _emojis,
                    onEmoji: (String value) => setState(() => _emoji = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: <Widget>[
                  if (_page > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  if (_page < 2)
                    FilledButton(
                      onPressed: _next,
                      child: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _finishing ? null : () => _finish(state),
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text('Start organising'),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (int index) {
                final bool active = index == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeStep extends StatelessWidget {
  const _ThemeStep({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: <Widget>[
        Text('Hey! I am your tidy buddy.', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Pick a look. You can change it any time in Settings.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final ThemePack pack in themePacks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ThemePackTile(
              pack: pack,
              selected: pack.id == state.themePack.id,
              onTap: () => state.setThemePack(pack),
            ),
          ),
      ],
    );
  }
}

class _ThemePackTile extends StatelessWidget {
  const _ThemePackTile({required this.pack, required this.selected, required this.onTap});

  final ThemePack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pack.seed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(pack.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(pack.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${pack.mascots.length} mascots',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _MascotStep extends StatelessWidget {
  const _MascotStep({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: <Widget>[
        Text('Who helps you tidy?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('He cheers you on when things get organised.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Center(
          child: MascotWidget(
            variant: state.mascot,
            pack: state.themePack,
            size: 190,
            mood: MascotMood.cheer,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: state.themePack.mascots
              .map((MascotVariant variant) => ChoiceChip(
                    label: Text(variant.label),
                    selected: variant == state.mascot,
                    onSelected: (_) => state.setMascot(variant),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SpaceStep extends StatelessWidget {
  const _SpaceStep({
    required this.controller,
    required this.emoji,
    required this.emojis,
    required this.onEmoji,
  });

  final TextEditingController controller;
  final String emoji;
  final List<String> emojis;
  final ValueChanged<String> onEmoji;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: <Widget>[
        Text('Name your first space', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('A zone of the house - kitchen, desk, wardrobe...', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Space name',
            hintText: 'Kitchen',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 20),
        Text('Icon', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emojis.map((String value) {
            final bool selected = value == emoji;
            return InkWell(
              onTap: () => onEmoji(value),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? theme.colorScheme.primaryContainer : null,
                ),
                child: Text(value, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}