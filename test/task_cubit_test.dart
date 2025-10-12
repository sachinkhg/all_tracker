// /*
//  * Unit tests for TaskCubit
//  *
//  * Purpose:
//  * - Verify TaskCubit state management
//  * - **CRITICAL**: Test goalId auto-assignment logic from milestone
//  * - Test exception handling for missing or invalid milestones
//  * - Verify CRUD operations trigger correct state transitions
//  */

// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:bloc_test/bloc_test.dart';

// import 'package:all_tracker/goal_tracker/domain/entities/task.dart';
// import 'package:all_tracker/goal_tracker/domain/entities/milestone.dart';
// import 'package:all_tracker/goal_tracker/domain/repositories/milestone_repository.dart';
// import 'package:all_tracker/goal_tracker/domain/usecases/task/create_task.dart';
// import 'package:all_tracker/goal_tracker/domain/usecases/task/get_all_tasks.dart';
// import 'package:all_tracker/goal_tracker/domain/usecases/task/get_task_by_id.dart';
// import 'package:all_tracker/goal_tracker/domain/usecases/task/get_tasks_by_milestone_id.dart';
// import 'package:all_tracker/goal_tracker/domain/usecases/task/update_task.dart';
// import 'package:all_tracker/goal_tracker/domain/usecases/task/delete_task.dart';
// import 'package:all_tracker/goal_tracker/presentation/bloc/task_cubit.dart';
// import 'package:all_tracker/goal_tracker/presentation/bloc/task_state.dart';

// import 'task_cubit_test.mocks.dart';

// @GenerateMocks([
//   GetAllTasks,
//   GetTaskById,
//   GetTasksByMilestoneId,
//   CreateTask,
//   UpdateTask,
//   DeleteTask,
//   MilestoneRepository,
// ])
// void main() {
//   late TaskCubit cubit;
//   late MockGetAllTasks mockGetAll;
//   late MockGetTaskById mockGetById;
//   late MockGetTasksByMilestoneId mockGetByMilestoneId;
//   late MockCreateTask mockCreate;
//   late MockUpdateTask mockUpdate;
//   late MockDeleteTask mockDelete;
//   late MockMilestoneRepository mockMilestoneRepo;

//   setUp(() {
//     mockGetAll = MockGetAllTasks();
//     mockGetById = MockGetTaskById();
//     mockGetByMilestoneId = MockGetTasksByMilestoneId();
//     mockCreate = MockCreateTask();
//     mockUpdate = MockUpdateTask();
//     mockDelete = MockDeleteTask();
//     mockMilestoneRepo = MockMilestoneRepository();

//     cubit = TaskCubit(
//       getAll: mockGetAll,
//       getById: mockGetById,
//       getByMilestoneId: mockGetByMilestoneId,
//       create: mockCreate,
//       update: mockUpdate,
//       delete: mockDelete,
//       milestoneRepository: mockMilestoneRepo,
//     );
//   });

//   tearDown(() {
//     cubit.close();
//   });

//   group('TaskCubit - loadTasks', () {
//     blocTest<TaskCubit, TaskState>(
//       'emits [TasksLoading, TasksLoaded] when loadTasks succeeds',
//       build: () {
//         when(mockGetAll()).thenAnswer((_) async => [
//               Task(
//                 id: '1',
//                 name: 'Test Task',
//                 milestoneId: 'm1',
//                 goalId: 'g1',
//                 status: 'To Do',
//               ),
//             ]);
//         return cubit;
//       },
//       act: (cubit) => cubit.loadTasks(),
//       expect: () => [
//         isA<TasksLoading>(),
//         isA<TasksLoaded>(),
//       ],
//     );

//     blocTest<TaskCubit, TaskState>(
//       'emits [TasksLoading, TasksError] when loadTasks fails',
//       build: () {
//         when(mockGetAll()).thenThrow(Exception('Load failed'));
//         return cubit;
//       },
//       act: (cubit) => cubit.loadTasks(),
//       expect: () => [
//         isA<TasksLoading>(),
//         isA<TasksError>(),
//       ],
//     );
//   });

//   group('TaskCubit - addTask (goalId auto-assignment)', () {
//     blocTest<TaskCubit, TaskState>(
//       'CRITICAL: auto-assigns goalId from milestone during create',
//       build: () {
//         // Mock milestone with goalId
//         final milestone = Milestone(
//           id: 'm1',
//           name: 'Test Milestone',
//           goalId: 'g1', // This should be auto-assigned to the task
//         );

//         when(mockMilestoneRepo.getMilestoneById('m1'))
//             .thenAnswer((_) async => milestone);
//         when(mockCreate(any)).thenAnswer((_) async {});
//         when(mockGetAll()).thenAnswer((_) async => []);

//         return cubit;
//       },
//       act: (cubit) => cubit.addTask(
//         name: 'New Task',
//         targetDate: null,
//         milestoneId: 'm1',
//         status: 'To Do',
//       ),
//       verify: (_) {
//         // Verify that milestone was fetched
//         verify(mockMilestoneRepo.getMilestoneById('m1')).called(1);
        
//         // Verify that create was called with a task having the correct goalId
//         final captured = verify(mockCreate(captureAny)).captured;
//         expect(captured.length, 1);
//         final task = captured[0] as Task;
//         expect(task.goalId, 'g1'); // goalId should be auto-assigned from milestone
//         expect(task.milestoneId, 'm1');
//         expect(task.name, 'New Task');
//       },
//     );

//     blocTest<TaskCubit, TaskState>(
//       'throws MilestoneNotFoundException when milestone does not exist',
//       build: () {
//         when(mockMilestoneRepo.getMilestoneById('m999'))
//             .thenAnswer((_) async => null);
//         return cubit;
//       },
//       act: (cubit) => cubit.addTask(
//         name: 'New Task',
//         targetDate: null,
//         milestoneId: 'm999',
//         status: 'To Do',
//       ),
//       errors: () => [
//         isA<MilestoneNotFoundException>(),
//       ],
//     );

//     blocTest<TaskCubit, TaskState>(
//       'throws InvalidMilestoneException when milestone has empty goalId',
//       build: () {
//         final invalidMilestone = Milestone(
//           id: 'm1',
//           name: 'Invalid Milestone',
//           goalId: '', // Empty goalId
//         );

//         when(mockMilestoneRepo.getMilestoneById('m1'))
//             .thenAnswer((_) async => invalidMilestone);
//         return cubit;
//       },
//       act: (cubit) => cubit.addTask(
//         name: 'New Task',
//         targetDate: null,
//         milestoneId: 'm1',
//         status: 'To Do',
//       ),
//       errors: () => [
//         isA<InvalidMilestoneException>(),
//       ],
//     );
//   });

//   group('TaskCubit - editTask (goalId auto-assignment)', () {
//     blocTest<TaskCubit, TaskState>(
//       'CRITICAL: auto-assigns goalId from milestone during update',
//       build: () {
//         // Mock milestone with goalId
//         final milestone = Milestone(
//           id: 'm2',
//           name: 'Updated Milestone',
//           goalId: 'g2', // Task should get this goalId
//         );

//         when(mockMilestoneRepo.getMilestoneById('m2'))
//             .thenAnswer((_) async => milestone);
//         when(mockUpdate(any)).thenAnswer((_) async {});
//         when(mockGetAll()).thenAnswer((_) async => []);

//         return cubit;
//       },
//       act: (cubit) => cubit.editTask(
//         id: 't1',
//         name: 'Updated Task',
//         targetDate: null,
//         milestoneId: 'm2',
//         status: 'In Progress',
//       ),
//       verify: (_) {
//         // Verify that milestone was fetched
//         verify(mockMilestoneRepo.getMilestoneById('m2')).called(1);
        
//         // Verify that update was called with a task having the correct goalId
//         final captured = verify(mockUpdate(captureAny)).captured;
//         expect(captured.length, 1);
//         final task = captured[0] as Task;
//         expect(task.goalId, 'g2'); // goalId should be auto-assigned from milestone
//         expect(task.milestoneId, 'm2');
//         expect(task.name, 'Updated Task');
//         expect(task.status, 'In Progress');
//       },
//     );

//     blocTest<TaskCubit, TaskState>(
//       'throws MilestoneNotFoundException when milestone does not exist during update',
//       build: () {
//         when(mockMilestoneRepo.getMilestoneById('m999'))
//             .thenAnswer((_) async => null);
//         return cubit;
//       },
//       act: (cubit) => cubit.editTask(
//         id: 't1',
//         name: 'Updated Task',
//         targetDate: null,
//         milestoneId: 'm999',
//         status: 'To Do',
//       ),
//       errors: () => [
//         isA<MilestoneNotFoundException>(),
//       ],
//     );
//   });

//   group('TaskCubit - removeTask', () {
//     blocTest<TaskCubit, TaskState>(
//       'deletes task and reloads list',
//       build: () {
//         when(mockDelete('t1')).thenAnswer((_) async {});
//         when(mockGetAll()).thenAnswer((_) async => []);
//         return cubit;
//       },
//       act: (cubit) => cubit.removeTask('t1'),
//       verify: (_) {
//         verify(mockDelete('t1')).called(1);
//         verify(mockGetAll()).called(1);
//       },
//     );
//   });

//   group('TaskCubit - filters', () {
//     test('hasActiveFilters returns true when filters are applied', () {
//       cubit.applyFilter(status: 'Complete');
//       expect(cubit.hasActiveFilters, isTrue);
//     });

//     test('hasActiveFilters returns false when no filters are applied', () {
//       expect(cubit.hasActiveFilters, isFalse);
//     });

//     blocTest<TaskCubit, TaskState>(
//       'clearFilters removes all active filters',
//       build: () {
//         when(mockGetAll()).thenAnswer((_) async => []);
//         return cubit;
//       },
//       seed: () => TasksLoaded([]),
//       act: (cubit) {
//         cubit.applyFilter(status: 'Complete');
//         cubit.clearFilters();
//       },
//       verify: (cubit) {
//         expect(cubit.hasActiveFilters, isFalse);
//       },
//     );
//   });
// }

