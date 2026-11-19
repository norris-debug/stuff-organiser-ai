part of 'scan_flow.dart';

extension _ScanResultCards on _ScanFlowScreenState {
  Widget _afterCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      // The theme pack is part of the key so a different pack rebuilds the card.
      key: ValueKey<Object>(widget.pack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _afterImage(scheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'After tidying',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_afterCaption(), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _afterCaption() {
    if (_afterLoading) {
      return 'Generating the after-tidying picture from your photo...';
    }
    return 'After tidying - AI concept sketch built from the setting.';
  }

  Widget _afterImage(ColorScheme scheme) {
    final Uint8List? bytes = _afterBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _conceptPlaceholder(scheme),
      );
    }
    final String? url = _afterUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) {
          if (progress == null) return child;
          return _loadingPlaceholder(scheme);
        },
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _conceptPlaceholder(scheme),
      );
    }
    return _loadingPlaceholder(scheme);
  }

  Widget _loadingPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(color: scheme.primary),
      ),
    );
  }

  Widget _conceptPlaceholder(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.secondaryContainer, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.auto_awesome,
              size: 32,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Concept preview',
              style: TextStyle(color: scheme.onSecondaryContainer),
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
            const SizedBox(height: 12),
            Text(
              'After-shot: AI concept sketch built from the setting text.',
              style: theme.textTheme.bodySmall,
            ),
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
