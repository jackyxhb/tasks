import 'package:flutter/material.dart';

enum AppSection {
  home,
  inbox,
  projects,
  tasks,
  meetings,
  search,
  reports,
  importSection,
  exportSection,
  settings,
  archive,
}

extension AppSectionDetails on AppSection {
  String get title {
    switch (this) {
      case AppSection.home:
        return 'Home';
      case AppSection.inbox:
        return 'Inbox';
      case AppSection.projects:
        return 'Projects';
      case AppSection.tasks:
        return 'Tasks';
      case AppSection.meetings:
        return 'Meetings';
      case AppSection.search:
        return 'Search';
      case AppSection.reports:
        return 'Reports';
      case AppSection.importSection:
        return 'Import';
      case AppSection.exportSection:
        return 'Export';
      case AppSection.settings:
        return 'Settings';
      case AppSection.archive:
        return 'Archive';
    }
  }

  IconData get icon {
    switch (this) {
      case AppSection.home:
        return Icons.home_rounded;
      case AppSection.inbox:
        return Icons.inbox_rounded;
      case AppSection.projects:
        return Icons.apartment_rounded;
      case AppSection.tasks:
        return Icons.task_alt_rounded;
      case AppSection.meetings:
        return Icons.groups_rounded;
      case AppSection.search:
        return Icons.manage_search_rounded;
      case AppSection.reports:
        return Icons.assessment_rounded;
      case AppSection.importSection:
        return Icons.download_rounded;
      case AppSection.exportSection:
        return Icons.upload_rounded;
      case AppSection.settings:
        return Icons.settings_rounded;
      case AppSection.archive:
        return Icons.inventory_2_rounded;
    }
  }

  Color get accent {
    switch (this) {
      case AppSection.home:
        return const Color(0xFF1F6B5C);
      case AppSection.inbox:
        return const Color(0xFFC06B37);
      case AppSection.projects:
        return const Color(0xFF4D5F8C);
      case AppSection.tasks:
        return const Color(0xFF2F6B63);
      case AppSection.meetings:
        return const Color(0xFF7A5D42);
      case AppSection.search:
        return const Color(0xFF5A5E9A);
      case AppSection.reports:
        return const Color(0xFF6D4B73);
      case AppSection.importSection:
        return const Color(0xFF3E7B7D);
      case AppSection.exportSection:
        return const Color(0xFF9C6B3C);
      case AppSection.settings:
        return const Color(0xFF556270);
      case AppSection.archive:
        return const Color(0xFF7A6B5A);
    }
  }
}