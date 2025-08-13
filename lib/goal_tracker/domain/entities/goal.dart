class Goal {
  final String id;
  String title;
  String description;
  List<Milestone> milestones;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    List<Milestone>? milestones,
  }) : milestones = milestones ?? [];
}

class Milestone {
  final String id;
  String title;
  List<Task> tasks;

  Milestone({
    required this.id,
    required this.title,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];
}

class Task {
  final String id;
  String name;
  bool completed;
  List<Checklist> checklists;

  Task({
    required this.id,
    required this.name,
    this.completed = false,
    List<Checklist>? checklists,
  }) : checklists = checklists ?? [];
}

class Checklist {
  final String id;
  String title;
  bool isCompleted;

  Checklist({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}
