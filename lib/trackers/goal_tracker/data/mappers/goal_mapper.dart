/// Mapper for converting between Goal domain entities and GoalModel data models.
///
/// This mapper extracts the entity-to-model conversion logic from repositories,
/// making it easier to test mappings independently and reuse mapping logic.
///
/// Usage:
/// ```dart
/// final mapper = GoalMapper();
/// final model = mapper.toModel(goalEntity);
/// final entity = mapper.toEntity(goalModel);
/// ```
import '../../domain/entities/goal.dart';
import '../models/goal_model.dart';

class GoalMapper {
  /// Converts a domain [Goal] entity to a [GoalModel] data model.
  ///
  /// This method delegates to GoalModel.fromEntity() to maintain compatibility
  /// with existing code. Complex mapping logic can be added here if needed.
  GoalModel toModel(Goal entity) {
    return GoalModel.fromEntity(entity);
  }

  /// Converts a [GoalModel] data model to a domain [Goal] entity.
  ///
  /// This method delegates to GoalModel.toEntity() to maintain compatibility
  /// with existing code. Complex mapping logic can be added here if needed.
  Goal toEntity(GoalModel model) {
    return model.toEntity();
  }

  /// Converts a list of [GoalModel] data models to a list of domain [Goal] entities.
  List<Goal> toEntityList(List<GoalModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }

  /// Converts a list of domain [Goal] entities to a list of [GoalModel] data models.
  List<GoalModel> toModelList(List<Goal> entities) {
    return entities.map((entity) => GoalModel.fromEntity(entity)).toList();
  }
}

