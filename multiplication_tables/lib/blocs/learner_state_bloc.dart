import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:fsrs/fsrs.dart' show FSRS, Card, Rating, SchedulingInfo;

enum CellState { notAttempted, correct, incorrect, fastCorrect }

class LearnerState {
  final Map<String, CellState> grid;
  final Map<String, Card> fsrsItems;
  final int maxFactor;
  final bool autoIncrease;
  final bool shouldSuggestIncrease;

  LearnerState({
    required this.grid,
    required this.fsrsItems,
    this.maxFactor = 12,
    this.autoIncrease = true,
    this.shouldSuggestIncrease = false,
  });

  LearnerState copyWith({
    Map<String, CellState>? grid,
    Map<String, Card>? fsrsItems,
    int? maxFactor,
    bool? autoIncrease,
    bool? shouldSuggestIncrease,
  }) {
    return LearnerState(
      grid: grid ?? this.grid,
      fsrsItems: fsrsItems ?? this.fsrsItems,
      maxFactor: maxFactor ?? this.maxFactor,
      autoIncrease: autoIncrease ?? this.autoIncrease,
      shouldSuggestIncrease:
          shouldSuggestIncrease ?? this.shouldSuggestIncrease,
    );
  }
}

abstract class LearnerStateEvent {}

class UpdateCell extends LearnerStateEvent {
  final int factor1;
  final int factor2;
  final CellState newState;
  final int fsrsGrade;

  UpdateCell(this.factor1, this.factor2, this.newState, this.fsrsGrade);
}

class UpdateMaxFactor extends LearnerStateEvent {
  final int maxFactor;
  UpdateMaxFactor(this.maxFactor);
}

class ResetProgress extends LearnerStateEvent {}

class ToggleAutoIncrease extends LearnerStateEvent {
  final bool autoIncrease;
  ToggleAutoIncrease(this.autoIncrease);
}

class LearnerStateBloc extends HydratedBloc<LearnerStateEvent, LearnerState> {
  final FSRS fsrs = FSRS();

  LearnerStateBloc()
      : super(LearnerState(grid: {}, fsrsItems: {}, maxFactor: 5)) {
    on<UpdateCell>(_onUpdateCell);
    on<UpdateMaxFactor>(_onUpdateMaxFactor);
    on<ResetProgress>(_onResetProgress);
    on<ToggleAutoIncrease>(_onToggleAutoIncrease);
  }

  void _onUpdateCell(UpdateCell event, Emitter<LearnerState> emit) {
    final newGrid = Map<String, CellState>.from(state.grid);
    final newFsrsItems = Map<String, Card>.from(state.fsrsItems);
    final key = '${event.factor1}x${event.factor2}';

    newGrid[key] = event.newState;

    final now = DateTime.now().toUtc();
    final fsrsItem = newFsrsItems[key] ?? Card.def(now, now);
    final rating = _convertGradeToRating(event.fsrsGrade);
    final schedulingInfo = fsrs.repeat(fsrsItem, now)[rating]!;
    newFsrsItems[key] = schedulingInfo.card;

    emit(state.copyWith(
      grid: newGrid,
      fsrsItems: newFsrsItems,
      shouldSuggestIncrease: _calculateShouldSuggestIncrease(),
    ));
  }

  Rating _convertGradeToRating(int grade) {
    switch (grade) {
      case 1:
        return Rating.again;
      case 2:
        return Rating.hard;
      case 3:
      case 4:
        return Rating.good;
      case 5:
        return Rating.easy;
      default:
        throw ArgumentError('Invalid grade: $grade');
    }
  }

  void _onUpdateMaxFactor(UpdateMaxFactor event, Emitter<LearnerState> emit) {
    if (event.maxFactor != state.maxFactor) {
      emit(state.copyWith(
        maxFactor: event.maxFactor,
        shouldSuggestIncrease: _calculateShouldSuggestIncrease(),
      ));

      // Schedule grid update
      Future.microtask(() => _updateGridForNewMaxFactor(event.maxFactor));
    }
  }

  void _updateGridForNewMaxFactor(int newMaxFactor) {
    final newGrid = Map<String, CellState>.from(state.grid);
    final newFsrsItems = Map<String, Card>.from(state.fsrsItems);

    for (int i = 1; i <= newMaxFactor; i++) {
      for (int j = 1; j <= newMaxFactor; j++) {
        final key = '${i}x$j';
        if (!newGrid.containsKey(key)) {
          newGrid[key] = CellState.notAttempted;
        }
        if (!newFsrsItems.containsKey(key)) {
          final now = DateTime.now().toUtc();
          newFsrsItems[key] = Card.def(now, now);
        }
      }
    }

    emit(state.copyWith(
      grid: newGrid,
      fsrsItems: newFsrsItems,
      maxFactor: newMaxFactor,
      shouldSuggestIncrease: _calculateShouldSuggestIncrease(),
    ));
  }

  void _onResetProgress(ResetProgress event, Emitter<LearnerState> emit) {
    emit(LearnerState(
        grid: {},
        fsrsItems: {},
        maxFactor: state.maxFactor,
        autoIncrease: state.autoIncrease,
        shouldSuggestIncrease: false));
  }

  void _onToggleAutoIncrease(
      ToggleAutoIncrease event, Emitter<LearnerState> emit) {
    emit(LearnerState(
      grid: state.grid,
      fsrsItems: state.fsrsItems,
      maxFactor: state.maxFactor,
      autoIncrease: event.autoIncrease,
      shouldSuggestIncrease: state.shouldSuggestIncrease,
    ));
  }

  bool _calculateShouldSuggestIncrease() {
    final totalCells = state.maxFactor * state.maxFactor;
    final masteredCells = state.grid.entries.where((entry) {
      final factors = entry.key.split('x').map(int.parse).toList();
      return factors[0] <= state.maxFactor &&
          factors[1] <= state.maxFactor &&
          (entry.value == CellState.correct ||
              entry.value == CellState.fastCorrect);
    }).length;

    return masteredCells / totalCells >= 0.9;
  }

  @override
  LearnerState? fromJson(Map<String, dynamic> json) {
    try {
      final grid = (json['grid'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, CellState.values[value as int]),
      );
      final fsrsItems = (json['fsrsItems'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, Card.fromJson(value as Map<String, dynamic>)),
      );
      return LearnerState(
        grid: grid,
        fsrsItems: fsrsItems,
        maxFactor: json['maxFactor'] as int,
        autoIncrease: json['autoIncrease'] as bool? ?? true,
        shouldSuggestIncrease: json['shouldSuggestIncrease'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(LearnerState state) {
    return {
      'grid': state.grid.map((key, value) => MapEntry(key, value.index)),
      'fsrsItems':
          state.fsrsItems.map((key, value) => MapEntry(key, value.toJson())),
      'maxFactor': state.maxFactor,
      'autoIncrease': state.autoIncrease,
      'shouldSuggestIncrease': state.shouldSuggestIncrease,
    };
  }
}
