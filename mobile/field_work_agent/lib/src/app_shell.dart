import 'package:flutter/material.dart';

import 'app_runtime.dart';
import 'app_sections.dart';
import 'section_screens.dart';

class FieldWorkAgentApp extends StatelessWidget {
  const FieldWorkAgentApp({
    super.key,
    this.controller = const LocalAppShellController(),
  });

  final AppShellController controller;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6B5C);

    return MaterialApp(
      title: 'Field Work Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
      ),
      home: AppShell(controller: controller),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppShellController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _selected = AppSection.home;
  late Future<AppShellData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 960;
    final section = _selected;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(section.title),
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SectionNavigation(
                selected: section,
                onSelected: _selectSection,
              ),
            ),
      body: Row(
        children: <Widget>[
          if (isWide)
            Container(
              width: 280,
              margin: const EdgeInsets.fromLTRB(20, 12, 12, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF163B34),
                borderRadius: BorderRadius.circular(32),
              ),
              child: SectionNavigation(
                selected: section,
                onSelected: _selectSection,
              ),
            ),
          Expanded(
            child: FutureBuilder<AppShellData>(
              future: _dataFuture,
              builder:
                  (BuildContext context, AsyncSnapshot<AppShellData> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _LoadingBody();
                }

                if (snapshot.hasError) {
                  return _ErrorBody(
                    error: snapshot.error,
                    onRetry: _reload,
                  );
                }

                final data = snapshot.data ?? const AppShellData.empty();

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey<AppSection>(section),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(isWide ? 8 : 20, 12, 20, 20),
                      child: SectionBody(
                        section: section,
                        data: data,
                        controller: widget.controller,
                        onDataChanged: _replaceData,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectSection(AppSection section) {
    setState(() {
      _selected = section;
    });

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _reload() {
    setState(() {
      _dataFuture = widget.controller.load();
    });
  }

  void _replaceData(AppShellData data) {
    setState(() {
      _dataFuture = Future<AppShellData>.value(data);
    });
  }
}

class SectionNavigation extends StatelessWidget {
  const SectionNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    const entries = AppSection.values;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Field Work Agent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Local-first operations shell for capture, review, search, reports, and exchange.',
                    style: TextStyle(
                      color: Color(0xFFC7D6D0),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (BuildContext context, int index) {
                  final section = entries[index];
                  final active = section == selected;

                  return Material(
                    color:
                        active ? const Color(0xFF2B6659) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onSelected(section),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: <Widget>[
                            Icon(section.icon,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFFB3C9C2)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                section.title,
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFFE4EEEA),
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Local app runtime failed to initialize',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  error?.toString() ?? 'Unknown runtime error.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
