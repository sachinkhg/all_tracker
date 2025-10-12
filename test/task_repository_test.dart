// /*
//  * Unit tests for TaskRepositoryImpl
//  *
//  * Purpose:
//  * - Verify that TaskRepositoryImpl correctly delegates to TaskLocalDataSource
//  * - Ensure proper conversion between domain entities and data models
//  * - Test CRUD operations
//  */

// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';

// import 'package:all_tracker/goal_tracker/domain/entities/task.dart';
// import 'package:all_tracker/goal_tracker/data/models/task_model.dart';
// import 'package:all_tracker/goal_tracker/data/datasources/task_local_data_source.dart';
// import 'package:all_tracker/goal_tracker/data/repositories/task_repository_impl.dart';

// import 'task_repository_test.mocks.dart';

// @GenerateMocks([TaskLocalDataSource])
// void main() {
//   late TaskRepositoryImpl repository;
//   late MockTaskLocalDataSource mockDataSource;

//   setUp(() {
//     mockDataSource = MockTaskLocalDataSource();
//     repository = TaskRepositoryImpl(mockDataSource);
//   });

//   group('TaskRepository - getAllTasks', () {
//     test('should return list of Task entities from data source', () async {
//       // Arrange
//       final taskModels = [
//         TaskModel(
//           id: '1',
//           name: 'Test Task',
//           targetDate: DateTime(2025, 12, 31),
//           milestoneId: 'm1',
//           goalId: 'g1',
//           status: 'To Do',
//         ),
//       ];

//       when(mockDataSource.getAllTasks()).thenAnswer((_) async => taskModels);

//       // Act
//       final result = await repository.getAllTasks();

//       // Assert
//       expect(result, isA<List<Task>>());
//       expect(result.length, 1);
//       expect(result[0].name, 'Test Task');
//       expect(result[0].milestoneId, 'm1');
//       expect(result[0].goalId, 'g1');
//       verify(mockDataSource.getAllTasks()).called(1);
//     });
//   });

//   group('TaskRepository - getTaskById', () {
//     test('should return Task entity when found', () async {
//       // Arrange
//       final taskModel = TaskModel(
//         id: '1',
//         name: 'Test Task',
//         targetDate: DateTime(2025, 12, 31),
//         milestoneId: 'm1',
//         goalId: 'g1',
//         status: 'In Progress',
//       );

//       when(mockDataSource.getTaskById('1')).thenAnswer((_) async => taskModel);

//       // Act
//       final result = await repository.getTaskById('1');

//       // Assert
//       expect(result, isNotNull);
//       expect(result!.name, 'Test Task');
//       expect(result.status, 'In Progress');
//       verify(mockDataSource.getTaskById('1')).called(1);
//     });

//     test('should return null when task not found', () async {
//       // Arrange
//       when(mockDataSource.getTaskById('999')).thenAnswer((_) async => null);

//       // Act
//       final result = await repository.getTaskById('999');

//       // Assert
//       expect(result, isNull);
//       verify(mockDataSource.getTaskById('999')).called(1);
//     });
//   });

//   group('TaskRepository - createTask', () {
//     test('should convert entity to model and call data source', () async {
//       // Arrange
//       final task = Task(
//         id: '1',
//         name: 'New Task',
//         targetDate: DateTime(2025, 12, 31),
//         milestoneId: 'm1',
//         goalId: 'g1',
//         status: 'To Do',
//       );

//       when(mockDataSource.createTask(any)).thenAnswer((_) async {});

//       // Act
//       await repository.createTask(task);

//       // Assert
//       verify(mockDataSource.createTask(any)).called(1);
//     });
//   });

//   group('TaskRepository - updateTask', () {
//     test('should convert entity to model and call data source', () async {
//       // Arrange
//       final task = Task(
//         id: '1',
//         name: 'Updated Task',
//         targetDate: DateTime(2025, 12, 31),
//         milestoneId: 'm1',
//         goalId: 'g1',
//         status: 'Complete',
//       );

//       when(mockDataSource.updateTask(any)).thenAnswer((_) async {});

//       // Act
//       await repository.updateTask(task);

//       // Assert
//       verify(mockDataSource.updateTask(any)).called(1);
//     });
//   });

//   group('TaskRepository - deleteTask', () {
//     test('should call data source with correct id', () async {
//       // Arrange
//       when(mockDataSource.deleteTask('1')).thenAnswer((_) async {});

//       // Act
//       await repository.deleteTask('1');

//       // Assert
//       verify(mockDataSource.deleteTask('1')).called(1);
//     });
//   });

//   group('TaskRepository - getTasksByMilestoneId', () {
//     test('should return tasks filtered by milestone', () async {
//       // Arrange
//       final taskModels = [
//         TaskModel(
//           id: '1',
//           name: 'Task 1',
//           targetDate: null,
//           milestoneId: 'm1',
//           goalId: 'g1',
//           status: 'To Do',
//         ),
//         TaskModel(
//           id: '2',
//           name: 'Task 2',
//           targetDate: null,
//           milestoneId: 'm1',
//           goalId: 'g1',
//           status: 'In Progress',
//         ),
//       ];

//       when(mockDataSource.getTasksByMilestoneId('m1'))
//           .thenAnswer((_) async => taskModels);

//       // Act
//       final result = await repository.getTasksByMilestoneId('m1');

//       // Assert
//       expect(result.length, 2);
//       expect(result.every((t) => t.milestoneId == 'm1'), isTrue);
//       verify(mockDataSource.getTasksByMilestoneId('m1')).called(1);
//     });
//   });
// }

