enum ProjectStatus {
  active,
  inactive,
  completed,
  onHold,
  cancelled, archived;

  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Actif';
      case ProjectStatus.inactive:
        return 'Inactif';
      case ProjectStatus.completed:
        return 'Terminé';
      case ProjectStatus.onHold:
        return 'En attente';
      case ProjectStatus.cancelled:
        return 'Annulé';
      case ProjectStatus.archived:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ProjectStatus.active;
      case 'inactive':
        return ProjectStatus.inactive;
      case 'completed':
        return ProjectStatus.completed;
      case 'onhold':
      case 'on_hold':
        return ProjectStatus.onHold;
      case 'cancelled':
        return ProjectStatus.cancelled;
      default:
        return ProjectStatus.active;
    }
  }
}
