import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/space.dart';
import '../scan/scan_flow.dart';
import '../services/plan_engine.dart';
import '../state/app_state.dart';
import '../widgets/mascot_widget.dart';
import 'dashboard_parts.dart';
import 'plan_screen.dart';
import 'quick_add_screen.dart';
import 'settings_screen.dart';
import 'space_detail_screen.dart';

export 'dashboard_parts.dart' show showAddSpaceDialog;

/// Bottom-navigation shell shared by the three main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // v0.7: tabs mount their screens fresh (the old IndexedStack kept every
      // tab alive, so a scan auto-save into the Tidy Plan would not show up
      // in the Plan tab until a full app restart).
      body: <Widget>[
        DashboardScreen(onOpenPlan: () => setState(() => _index = 1)),
        const PlanScreen(),
        const SettingsScreen(),
      ][_index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const QuickAddScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Quick add'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}

/// Screen 2: spaces overview, mascot greeting and today's plan card.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenPlan});

  final VoidCallback? onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ThemeData theme = Theme.of(context);
    final TidyPlan plan = state.currentPlan;

    return Scaffold(
      appBar: AppBar(
        // v0.8.13: taller app bar so the title block can sit lower without
        // clipping the version line.
        toolbarHeight: 76,
        // v0.8.13: title top gap matched to the Demo mode chip.
        title: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Stuff Organiser AI'),
            Text(
              state.user?.displayLabel ?? 'Guest',
              style: theme.textTheme.bodySmall,
            ),
            // v0.8.16: the badge is derived from the package metadata
            // (Meiosis task-3), so it can never drift from the real build
            // version again - pubspec is the single source of truth.
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                final PackageInfo? info = snapshot.data;
                // v0.8.24 (R4-F1): CI stamps version.json as the single-key
                // probe format, so web's PackageInfo carries the whole
                // '0.8.23+43' string as version with an empty buildNumber -
                // plain concatenation rendered a dangling trailing plus. A
                // version already carrying its build is used as-is; the
                // build number is appended only when present.
                final String versionLabel = info == null
                    ? ''
                    : info.version.contains('+')
                        ? 'v${info.version}'
                        : 'v${info.version}+${info.buildNumber}';
                return Text(
                  versionLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                );
              },
            ),
          ],
          ),
        ),
        actions: <Widget>[
          if (state.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(label: Text('Demo mode')),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: <Widget>[
            _GreetingCard(state: state),
            const SizedBox(height: 16),
            const _ScanCard(),
            const SizedBox(height: 16),
            _PlanCard(plan: plan, onStart: onOpenPlan),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text('Your spaces', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => showAddSpaceDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add space'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.spaces.isEmpty)
              const _EmptySpaces()
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: state.spaces
                    .map((Space space) => _SpaceCard(space: space, state: state))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int loose = state.looseCount;
    final String greeting = loose == 0
        ? 'All clear! Add something whenever it shows up.'
        : '$loose thing${loose == 1 ? '' : 's'} still loose. One sprint and you are done.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            MascotWidget(
              variant: state.mascot,
              pack: state.themePack,
              size: 96,
              mood: loose == 0 ? MascotMood.cheer : MascotMood.happy,
              celebrationTick: state.celebrationTick,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_greetingWord(), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(greeting, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingWord() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 18) return 'Good afternoon!';
    return 'Good evening!';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.onStart});

  final TidyPlan plan;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (plan.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.celebration_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nothing loose right now. Enjoy the calm, or log something new.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text("Today's plan", style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${plan.totalItems} items · about ${plan.totalMinutes} min',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final PlanSprint sprint in plan.sprints)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Text(sprint.spaceEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${sprint.spaceName} · ${sprint.steps.length} item${sprint.steps.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(sprint.estimateLabel, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start 10-minute sprint'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.space, required this.state});

  final Space space;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int loose = state.looseInSpace(space.id);
    final int total = state.countInSpace(space.id);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SpaceDetailScreen(spaceId: space.id)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(space.emoji, style: const TextStyle(fontSize: 30)),
            const Spacer(),
            Text(space.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              loose == 0 ? '$total item${total == 1 ? '' : 's'} · tidy' : '$loose loose of $total',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySpaces extends StatelessWidget {
  const _EmptySpaces();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('No spaces yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            // v0.8.16: first runs start empty - a venue appears here the
            // moment it is scanned.
            Text('Scan a room and it shows up here automatically.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => showAddSpaceDialog(context),
              child: const Text('Add space'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent Scan entry on the home dashboard.
class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    final AppState state = context.read<AppState>();
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.photo_camera_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Room scan', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Snap a photo and the coach chats you through tidying it.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ScanFlowScreen(
                    prefs: state.prefs,
                    mascot: state.mascot,
                    pack: state.themePack,
                    appState: state,
                  ),
                ),
              ),
              child: const Text('Tidy Up'),
            ),
          ],
        ),
      ),
    );
  }
}