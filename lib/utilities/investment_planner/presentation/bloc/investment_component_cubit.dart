import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/investment_component.dart';
import '../../domain/usecases/component/create_component.dart';
import '../../domain/usecases/component/get_all_components.dart';
import '../../domain/usecases/component/get_component_by_id.dart';
import '../../domain/usecases/component/update_component.dart';
import '../../domain/usecases/component/delete_component.dart';
import 'investment_component_state.dart';

/// Cubit to manage InvestmentComponent state
class InvestmentComponentCubit extends Cubit<InvestmentComponentState> {
  final GetAllComponents getAll;
  final GetComponentById getById;
  final CreateComponent create;
  final UpdateComponent update;
  final DeleteComponent delete;

  InvestmentComponentCubit({
    required this.getAll,
    required this.getById,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(ComponentsLoading()) {
    loadComponents();
  }

  Future<void> loadComponents() async {
    try {
      emit(ComponentsLoading());
      final components = await getAll();
      emit(ComponentsLoaded(components));
    } catch (e) {
      emit(ComponentsError(e.toString()));
    }
  }

  Future<void> addComponent(
    String name,
    double percentage,
    int priority, {
    double? minLimit,
    double? maxLimit,
    double? multipleOf,
  }) async {
    try {
      final component = InvestmentComponent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        percentage: percentage,
        minLimit: minLimit,
        maxLimit: maxLimit,
        multipleOf: multipleOf,
        priority: priority,
      );
      await create(component);
      await loadComponents();
    } catch (e) {
      emit(ComponentsError(e.toString()));
    }
  }

  Future<void> updateComponent(InvestmentComponent component) async {
    try {
      await update(component);
      await loadComponents();
    } catch (e) {
      emit(ComponentsError(e.toString()));
    }
  }

  Future<void> deleteComponent(String id) async {
    try {
      await delete(id);
      await loadComponents();
    } catch (e) {
      emit(ComponentsError(e.toString()));
    }
  }

  Future<void> reorderComponents(int oldIndex, int newIndex) async {
    try {
      final currentState = state;
      if (currentState is ComponentsLoaded) {
        final components = List<InvestmentComponent>.from(currentState.components);
        
        // Remove the item from old position
        final movedComponent = components.removeAt(oldIndex);
        
        // Insert at new position
        components.insert(newIndex, movedComponent);
        
        // Update priorities based on new positions (1-based priority)
        final updatedComponents = <InvestmentComponent>[];
        for (int i = 0; i < components.length; i++) {
          final component = components[i];
          final updatedComponent = component.copyWith(priority: i + 1);
          updatedComponents.add(updatedComponent);
          await update(updatedComponent);
        }
        
        // Reload to reflect changes
        await loadComponents();
      }
    } catch (e) {
      emit(ComponentsError(e.toString()));
    }
  }
}

