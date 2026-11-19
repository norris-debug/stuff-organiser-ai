part of 'scan_flow.dart';

extension _ScanResultCards on _ScanFlowScreenState {
  /// v0.7: the thinking state lives here on the result page. The old AI
  /// concept sketch placeholder is gone - the organized render comes back
  /// from the Cellulose lane instead.
  Widget _afterCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _ThinkingLine(mascot: widget.mascot, pack: widget.pack),
            const SizedBox(height: 10),
            Text(
              'The organized render and the checked plan come back from the '
              'Cellulose lane and land in the Tidy Plan tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notesCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _ScanPlan plan = _plan;

    final List<Widget> observationWidgets = plan.observations.isEmpty
        ? <Widget>[
            Text('No observations recorded.', style: theme.textTheme.bodySmall),
          ]
        : plan.observations
            .map(
              (String observation) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        observation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();

    final List<Widget> habitWidgets = plan.habits
        .map(
          (String habit) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.repeat, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(habit, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What the coach saw',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...observationWidgets,
            const Divider(height: 24),
            Text(
              'Step-by-step plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < plan.suggestions.length; i++)
              _suggestionBlock(context, i + 1, plan.suggestions[i]),
            const Divider(height: 24),
            Text(
              'Keep it tidy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...habitWidgets,
          ],
        ),
      ),
    );
  }

  Widget _suggestionBlock(
    BuildContext context,
    int number,
    _Suggestion suggestion,
  ) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$number. ${suggestion.title}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (suggestion.detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(suggestion.detail, style: theme.textTheme.bodyMedium),
          ],
          if (suggestion.steps.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            for (final String step in suggestion.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('- '),
                    Expanded(
                      child: Text(step, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
