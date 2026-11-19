import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../services/plan_engine.dart';
import '../state/app_state.dart';
import '../widgets/mascot_widget.dart';

/// Screen 5: step-by-step tidy checklist produced by the plan engine.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ThemeData theme = Theme.of(context);
    final TidyPlan plan = state.currentPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('Tidy plan')),
      body: plan.isEmpty
          ? _EmptyPlan(state: state)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        MascotWidget(
                          variant: state.mascot,
                          pack: state.themePack,
                          size: 72,
                          mood: MascotMood.cheer,
                          celebrationTick: state.celebrationTick,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${plan.totalItems} loose thing${plan.totalItems == 1 ? '' : 's'}',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${plan.sprints.length} sprint${plan.sprints.length == 1 ? '' : 's'} · '
                                'about ${plan.totalMinutes} min · '
                                '${state.organizedCount} of ${state.items.length} organised',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final PlanSprint sprint in plan.sprints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SprintCard(sprint: sprint, state: state),
                  ),
              ],
            ),
    );
  }
}

class _SprintCard extends StatelessWidget {
  const _SprintCard({required this.sprint, required this.state});

  final PlanSprint sprint;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(sprint.spaceEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(sprint.spaceName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${sprint.minutes}-minute sprint · ${sprint.estimateLabel}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final PlanStep step in sprint.steps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  step.itemId.isEmpty ? Icons.circle_outlined : Icons.radio_button_unchecked,
                  color: theme.colorScheme.primary,
                ),
                title: Text(step.title),
                subtitle: step.detail.isEmpty ? null : Text(step.detail),
                trailing: Text('${step.seconds}s', style: theme.textTheme.labelSmall),
                onTap: () {
                  final Item? item = state.itemById(step.itemId);
                  if (item != null) state.toggleItemStatus(item);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MascotWidget(
              variant: state.mascot,
              pack: state.themePack,
              size: 140,
              mood: MascotMood.cheer,
              celebrationTick: state.celebrationTick,
            ),
            const SizedBox(height: 12),
            Text('Nothing to do right now', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Everything is put away. Use Quick add when something turns up.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
