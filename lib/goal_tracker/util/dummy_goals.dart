import 'package:uuid/uuid.dart';
import '../domain/entities/checklist.dart';
import '../domain/entities/goal.dart';
import '../domain/entities/milestone.dart';
import '../domain/entities/task.dart';

// Generates both goals and milestones lists for demo/testing
Map<String, dynamic> generateDummyGoalsAndMilestones() {
  const uuid = Uuid();

  // Create individual milestones first
  final milestone1 = Milestone(
    id: uuid.v4(),
    title: 'Finish beginner tutorials',
    tasks: [
      Task(
        id: uuid.v4(),
        name: 'Complete Flutter Getting Started',
        completed: false,
        checklists: [
          Checklist(
            id: uuid.v4(),
            title: 'Install Flutter SDK',
            isCompleted: true,
          ),
          Checklist(
            id: uuid.v4(),
            title: 'Run first Hello World app',
            isCompleted: false,
          ),
        ],
      ),
    ],
  );

  final goals = [
    Goal(
      id: uuid.v4(),
      title: 'Learn Flutter',
      description: 'Complete Flutter & Dart crash course and build a sample project.',
      milestoneIds: [milestone1.id], // Only the list of IDs
    ),
    Goal(
      id: uuid.v4(),
      title: 'Fitness Routine',
      description: 'Build a consistent workout and diet tracking habit.',
      milestoneIds: [],
    ),
  ];

  final milestones = [milestone1];

  // Optionally, you can return a milestones map as well for easier lookup:
  final milestonesMap = { for (var m in milestones) m.id: m };

  return {
    'goals': goals,
    'milestones': milestones,
    'milestonesMap': milestonesMap,
  };
}
