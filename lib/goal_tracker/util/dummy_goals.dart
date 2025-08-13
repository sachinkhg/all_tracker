import 'package:uuid/uuid.dart';
import '../domain/entities/goal.dart';

// Simple generator for dummy data
List<Goal> generateDummyGoals() {
  const uuid = Uuid();

  return [
    Goal(
      id: uuid.v4(),
      title: 'Learn Flutter',
      description: 'Complete Flutter & Dart crash course and build a sample project.',
      milestones: [
        Milestone(
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
        ),
      ],
    ),
    Goal(
      id: uuid.v4(),
      title: 'Fitness Routine',
      description: 'Build a consistent workout and diet tracking habit.',
      milestones: [],
    ),
  ];
}
