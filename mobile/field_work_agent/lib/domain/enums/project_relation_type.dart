enum ProjectRelationType {
  worker,
  siteContact,
  coordinator,
  projectManager,
}

extension ProjectRelationTypeCodec on ProjectRelationType {
  String get storageValue {
    switch (this) {
      case ProjectRelationType.worker:
        return 'worker';
      case ProjectRelationType.siteContact:
        return 'site_contact';
      case ProjectRelationType.coordinator:
        return 'coordinator';
      case ProjectRelationType.projectManager:
        return 'project_manager';
    }
  }
}

ProjectRelationType projectRelationTypeFromStorage(String value) {
  switch (value) {
    case 'worker':
      return ProjectRelationType.worker;
    case 'site_contact':
      return ProjectRelationType.siteContact;
    case 'coordinator':
      return ProjectRelationType.coordinator;
    default:
      return ProjectRelationType.projectManager;
  }
}