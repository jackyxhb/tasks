import 'package:flutter/material.dart';

import '../../../app/app_shell_controller.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../application/search_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller});

  final AppShellController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _queryController;
  late final TextEditingController _projectController;
  late final TextEditingController _workerController;
  bool _includeArchived = true;
  bool _busy = false;
  String? _error;
  GroupedSearchResults? _results;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _projectController = TextEditingController();
    _workerController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _projectController.dispose();
    _workerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalResults = _results == null
        ? 0
        : _results!.projects.length +
            _results!.tasks.length +
            _results!.meetings.length +
            _results!.rawCaptures.length +
            _results!.people.length;

    return FeatureSectionScaffold(
      title: 'Global Search',
      summary:
          'Grouped discovery across projects, tasks, meetings, raw captures, and people with structured local filters.',
      accent: AppSection.search.accent,
      actions: const <ActionData>[
        ActionData(label: 'Projects', icon: Icons.apartment_rounded),
        ActionData(label: 'Meetings', icon: Icons.groups_rounded),
        ActionData(label: 'Raw Captures', icon: Icons.perm_media_rounded),
      ],
      metrics: <MetricData>[
        const MetricData(
          title: 'Indexed Types',
          value: '5',
          detail: 'Projects, tasks, meetings, people, raw captures.',
          color: Color(0xFF5A5E9A),
        ),
        MetricData(
          title: 'Current Results',
          value: '$totalResults',
          detail: 'Grouped hits returned from the local search service.',
          color: const Color(0xFF2F6B63),
        ),
      ],
      sections: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    hintText:
                        'Search projects, tasks, meetings, raw captures, and people',
                    labelText: 'Search Query',
                    prefixIcon: Icon(Icons.manage_search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ResponsiveGrid(
                  children: <Widget>[
                    TextField(
                      controller: _projectController,
                      decoration: const InputDecoration(
                        labelText: 'Project Filter',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: _workerController,
                      decoration: const InputDecoration(
                        labelText: 'Worker Filter',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include Archived'),
                      value: _includeArchived,
                      onChanged: (bool value) {
                        setState(() {
                          _includeArchived = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _busy ? null : _runSearch,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Run Search'),
                    ),
                    if (_results != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() {
                                  _results = null;
                                  _error = null;
                                });
                              },
                        child: const Text('Clear Results'),
                      ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_results == null)
          const DetailCard(
            title: 'Search Scope',
            subtitle: 'Grouped result sections',
            children: <Widget>[
              InfoRow(
                label: 'Projects',
                value: 'Preview recent activity and open tasks.',
              ),
              InfoRow(
                label: 'Tasks',
                value:
                    'Match on notes, location, task title, and worker fields.',
              ),
              InfoRow(
                label: 'Meetings',
                value: 'Show transcript and summary snippets for context.',
              ),
            ],
          )
        else
          ResponsiveGrid(
            children: <Widget>[
              _SearchResultsCard(title: 'Projects', hits: _results!.projects),
              _SearchResultsCard(title: 'Tasks', hits: _results!.tasks),
              _SearchResultsCard(title: 'Meetings', hits: _results!.meetings),
              _SearchResultsCard(
                title: 'Raw Captures',
                hits: _results!.rawCaptures,
              ),
              _SearchResultsCard(title: 'People', hits: _results!.people),
            ],
          ),
      ],
    );
  }

  Future<void> _runSearch() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await widget.controller.searchRecords(
        request: SearchRequest(
          query: _queryController.text,
          filters: SearchFilters(
            projectName: _projectController.text,
            workerName: _workerController.text,
            includeArchived: _includeArchived,
          ),
          limitPerGroup: 10,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}

class _SearchResultsCard extends StatelessWidget {
  const _SearchResultsCard({required this.title, required this.hits});

  final String title;
  final List<SearchHit> hits;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: title,
      subtitle: '${hits.length} result${hits.length == 1 ? '' : 's'}',
      children: hits.isEmpty
          ? const <Widget>[
              InfoRow(label: 'Results', value: 'No matches found.'),
            ]
          : hits
              .map(
                (hit) => QueueItem(
                  title: hit.title,
                  caption: _joinParts(<String?>[hit.subtitle, hit.snippet]),
                  status: hit.archived ? 'Archived' : hit.recordType,
                ),
              )
              .toList(growable: false),
    );
  }
}

String _joinParts(List<String?> parts) {
  return parts
      .where((part) => part != null && part.trim().isNotEmpty)
      .map((part) => part!.trim())
      .join(' • ');
}
