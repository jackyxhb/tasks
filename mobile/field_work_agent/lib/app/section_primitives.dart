import 'package:flutter/material.dart';

class FeatureSectionScaffold extends StatelessWidget {
  const FeatureSectionScaffold({
    super.key,
    required this.title,
    required this.summary,
    required this.accent,
    required this.actions,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String summary;
  final Color accent;
  final List<ActionData> actions;
  final List<MetricData> metrics;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        HeroPanel(title: title, summary: summary, accent: accent),
        if (actions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (action) => ActionChip(
                    avatar: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    onPressed: action.onPressed,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (metrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          ResponsiveGrid(
            children: metrics
                .map(
                  (metric) => MetricTile(
                    title: metric.title,
                    value: metric.value,
                    detail: metric.detail,
                    color: metric.color,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        for (final section in sections) ...<Widget>[
          const SizedBox(height: 20),
          section,
        ],
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.title,
    required this.summary,
    required this.accent,
  });

  final String title;
  final String summary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: <Color>[
            accent,
            Color.lerp(accent, const Color(0xFFD9A25C), 0.65)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFFF2ECE0),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  const DetailCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class QueueItem extends StatelessWidget {
  const QueueItem({
    super.key,
    required this.title,
    required this.caption,
    required this.status,
    this.actions = const <Widget>[],
  });

  final String title;
  final String caption;
  final String status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2DDD4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusPill(label: status),
              ],
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF214E45),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FilterStrip extends StatelessWidget {
  const FilterStrip({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: labels
          .map(
            (label) => Chip(
              label: Text(label),
              backgroundColor: Colors.white,
              side: BorderSide.none,
            ),
          )
          .toList(growable: false),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
        trailing: IgnorePointer(
          child: Switch(value: value, onChanged: (_) {}),
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth >= 1280
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(width: width, child: child),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class ActionData {
  const ActionData({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class MetricData {
  const MetricData({
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final Color color;
}
