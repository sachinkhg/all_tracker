import 'package:equatable/equatable.dart';


// Entity definition for Goal (domain layer)
class Goal extends Equatable {
final String id; // Unique identifier (GUID)
final String name; // Goal name/title
final String? description; // Goal description
final DateTime? targetDate; // Optional target date for the goal
final String? context; // Optional context/category for the goal
final bool isCompleted; // Status of the goal


const Goal({required this.id, required this.name, required this.description, this.targetDate, this.context, this.isCompleted = false});


@override
List<Object?> get props => [id, name, description, targetDate, context, isCompleted];
}