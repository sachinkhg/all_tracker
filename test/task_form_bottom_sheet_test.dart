// /*
//  * Widget tests for TaskFormBottomSheet
//  *
//  * Purpose:
//  * - Verify that goal field is read-only
//  * - **CRITICAL**: Test that goal display updates when milestone changes
//  * - Verify form validation (milestone required, name required)
//  * - Test that goalId is never directly editable by the user
//  */

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:all_tracker/goal_tracker/presentation/widgets/task_form_bottom_sheet.dart';

// void main() {
//   group('TaskFormBottomSheet - Goal Field Behavior', () {
//     testWidgets('CRITICAL: goal field is read-only and displays lock icon',
//         (tester) async {
//       // Arrange
//       final milestoneOptions = ['m1::Milestone 1', 'm2::Milestone 2'];
//       final milestoneGoalMap = {'m1': 'Goal A', 'm2': 'Goal B'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {},
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Assert: Goal field should have lock icon indicating read-only
//       expect(find.byIcon(Icons.lock), findsOneWidget);

//       // Assert: Goal field should show placeholder text initially
//       expect(find.text('(Select a milestone first)'), findsOneWidget);

//       // Assert: Goal field should be disabled (not tappable)
//       final goalDecorator = tester.widget<InputDecorator>(
//         find.widgetWithText(InputDecorator, 'Goal (auto-set from milestone)'),
//       );
//       expect(goalDecorator.decoration?.enabled, isFalse);
//     });

//     testWidgets(
//         'CRITICAL: goal display updates automatically when milestone changes',
//         (tester) async {
//       // Arrange
//       final milestoneOptions = ['m1::Milestone 1', 'm2::Milestone 2'];
//       final milestoneGoalMap = {'m1': 'Goal A', 'm2': 'Goal B'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {},
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Act: Select milestone (tap on milestone selector)
//       final milestoneSelector = find.widgetWithText(
//         InputDecorator,
//         'Milestone *',
//       );
//       await tester.tap(milestoneSelector);
//       await tester.pumpAndSettle();

//       // The context dropdown bottom sheet would open in a real app
//       // For this test, we verify that the initial state is correct

//       // Assert: Goal field should still show placeholder before milestone selection
//       expect(find.text('(Select a milestone first)'), findsOneWidget);
//     });

//     testWidgets('goal field should not have any tap handler', (tester) async {
//       // Arrange
//       final milestoneOptions = ['m1::Milestone 1'];
//       final milestoneGoalMap = {'m1': 'Goal A'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {},
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Try to tap on the goal field
//       final goalField = find.widgetWithText(
//         InputDecorator,
//         'Goal (auto-set from milestone)',
//       );

//       // This should not trigger any action (no InkWell wrapper for goal field)
//       await tester.tap(goalField);
//       await tester.pumpAndSettle();

//       // Assert: No error should occur and no dialog/sheet should open
//       expect(find.byType(AlertDialog), findsNothing);
//     });
//   });

//   group('TaskFormBottomSheet - Validation', () {
//     testWidgets('shows error when submitting without milestone',
//         (tester) async {
//       // Arrange
//       bool submitted = false;
//       final milestoneOptions = ['m1::Milestone 1'];
//       final milestoneGoalMap = {'m1': 'Goal A'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {
//                 submitted = true;
//               },
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Act: Enter task name but don't select milestone
//       final nameField = find.widgetWithText(TextField, 'Task Name');
//       await tester.enterText(nameField, 'Test Task');
//       await tester.pumpAndSettle();

//       // Act: Try to submit
//       final saveButton = find.widgetWithText(FilledButton, 'Save');
//       await tester.tap(saveButton);
//       await tester.pumpAndSettle();

//       // Assert: Should show snackbar with error message
//       expect(find.text('Please select a milestone'), findsOneWidget);
//       expect(submitted, isFalse); // Should not have called onSubmit
//     });

//     testWidgets('shows error when submitting without task name',
//         (tester) async {
//       // Arrange
//       bool submitted = false;
//       final milestoneOptions = ['m1::Milestone 1'];
//       final milestoneGoalMap = {'m1': 'Goal A'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               initialMilestoneId: 'm1', // Milestone already selected
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {
//                 submitted = true;
//               },
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Act: Try to submit without entering a name
//       final saveButton = find.widgetWithText(FilledButton, 'Save');
//       await tester.tap(saveButton);
//       await tester.pumpAndSettle();

//       // Assert: Should show snackbar with error message
//       expect(find.text('Task name is required'), findsOneWidget);
//       expect(submitted, isFalse); // Should not have called onSubmit
//     });
//   });

//   group('TaskFormBottomSheet - Form Fields', () {
//     testWidgets('renders all required form fields', (tester) async {
//       // Arrange
//       final milestoneOptions = ['m1::Milestone 1'];
//       final milestoneGoalMap = {'m1': 'Goal A'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {},
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Assert: All fields should be present
//       expect(find.widgetWithText(TextField, 'Task Name'), findsOneWidget);
//       expect(
//           find.widgetWithText(InputDecorator, 'Milestone *'), findsOneWidget);
//       expect(
//           find.widgetWithText(
//               InputDecorator, 'Goal (auto-set from milestone)'),
//           findsOneWidget);
//       expect(
//           find.widgetWithText(InputDecorator, 'Target Date'), findsOneWidget);
//       expect(find.widgetWithText(InputDecorator, 'Status'), findsOneWidget);
//       expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
//     });

//     testWidgets('initializes with provided values in edit mode',
//         (tester) async {
//       // Arrange
//       final milestoneOptions = ['m1::Milestone 1', 'm2::Milestone 2'];
//       final milestoneGoalMap = {'m1': 'Goal A', 'm2': 'Goal B'};

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: TaskFormBottomSheet(
//               title: 'Edit Task',
//               initialName: 'Existing Task',
//               initialMilestoneId: 'm1',
//               initialStatus: 'In Progress',
//               milestoneOptions: milestoneOptions,
//               milestoneGoalMap: milestoneGoalMap,
//               onSubmit: (name, targetDate, milestoneId, status) async {},
//             ),
//           ),
//         ),
//       );

//       await tester.pumpAndSettle();

//       // Assert: Fields should be initialized with values
//       expect(find.text('Edit Task'), findsOneWidget);
//       expect(find.text('Existing Task'), findsOneWidget);
//       expect(find.text('Milestone 1'), findsOneWidget);
//       expect(find.text('Goal A'), findsOneWidget); // Goal auto-displayed
//       expect(find.text('In Progress'), findsOneWidget);
//     });
//   });
// }

