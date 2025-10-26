import 'package:all_tracker/goal_tracker/domain/repositories/goal_repository.dart';
import 'package:all_tracker/goal_tracker/domain/repositories/milestone_repository.dart';
import 'package:all_tracker/goal_tracker/domain/repositories/task_repository.dart';
import 'package:all_tracker/goal_tracker/domain/repositories/habit_repository.dart';
import 'package:all_tracker/goal_tracker/domain/repositories/habit_completion_repository.dart';

// Lightweight abstract stubs to satisfy analyzer without external mocking libs.
// In tests, prefer real implementations/fakes over these, or replace with mocktail
// based mocks once dev dependencies are fetched.
abstract class MockGoalRepository implements GoalRepository {}
abstract class MockMilestoneRepository implements MilestoneRepository {}
abstract class MockTaskRepository implements TaskRepository {}
abstract class MockHabitRepository implements HabitRepository {}
abstract class MockHabitCompletionRepository implements HabitCompletionRepository {}


