import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';
import 'package:fsrs/fsrs.dart';

enum QuestionType { priority, due, random }

class TrainingState {
  final int factor1;
  final int factor2;
  final int? userAnswer;
  final bool isCorrect;
  final DateTime questionStartTime;
  final bool isTransitioning;

  TrainingState({
    required this.factor1,
    required this.factor2,
    this.userAnswer,
    this.isCorrect = false,
    required this.questionStartTime,
    this.isTransitioning = false,
  });

  TrainingState copyWith({
    int? factor1,
    int? factor2,
    int? userAnswer,
    bool? isCorrect,
    DateTime? questionStartTime,
    bool? isTransitioning,
  }) {
    return TrainingState(
      factor1: factor1 ?? this.factor1,
      factor2: factor2 ?? this.factor2,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }
}

abstract class TrainingEvent {}

class GenerateQuestion extends TrainingEvent {}

class SubmitAnswer extends TrainingEvent {
  final int answer;
  SubmitAnswer(this.answer);
}

class TransitionToNextQuestion extends TrainingEvent {}

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final LearnerStateBloc learnerStateBloc;
  final Random _random = Random();

  TrainingBloc(this.learnerStateBloc)
      : super(TrainingState(
          factor1: 1,
          factor2: 1,
          questionStartTime: DateTime.now(),
        )) {
    on<GenerateQuestion>(_onGenerateQuestion);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<TransitionToNextQuestion>(_onTransitionToNextQuestion);
  }

  void _onGenerateQuestion(
      GenerateQuestion event, Emitter<TrainingState> emit) {
    final questionType = _getNextQuestionType();
    final newState = _generateQuestion(questionType);
    emit(newState);
  }

  void _onSubmitAnswer(SubmitAnswer event, Emitter<TrainingState> emit) {
    final isCorrect = event.answer == state.factor1 * state.factor2;
    final answerDuration = DateTime.now().difference(state.questionStartTime);

    CellState cellState;
    int fsrsGrade;
    if (isCorrect) {
      if (answerDuration.inSeconds < 3) {
        cellState = CellState.fastCorrect;
        fsrsGrade = 5; // Perfect response
      } else {
        cellState = CellState.correct;
        fsrsGrade = 4; // Correct response
      }
    } else {
      cellState = CellState.incorrect;
      fsrsGrade = 1; // Incorrect response
    }

    // Update the learner state
    learnerStateBloc
        .add(UpdateCell(state.factor1, state.factor2, cellState, fsrsGrade));

    // Emit the current state with the user's answer and set isTransitioning to true
    emit(state.copyWith(
      userAnswer: event.answer,
      isCorrect: isCorrect,
      isTransitioning: true,
    ));
  }

  void _onTransitionToNextQuestion(
      TransitionToNextQuestion event, Emitter<TrainingState> emit) {
    add(GenerateQuestion());
  }

  QuestionType _getNextQuestionType() {
    final priorityItems = learnerStateBloc.state.grid.entries
        .where((entry) =>
            entry.value == CellState.notAttempted ||
            entry.value == CellState.incorrect)
        .toList();

    if (priorityItems.isNotEmpty) {
      return QuestionType.priority;
    } else {
      final now = DateTime.now();
      final dueItems = learnerStateBloc.state.fsrsItems.entries
          .where((entry) =>
              entry.value.due.isBefore(now) &&
              learnerStateBloc.state.grid[entry.key] != CellState.fastCorrect)
          .toList();

      return dueItems.isNotEmpty ? QuestionType.due : QuestionType.random;
    }
  }

  TrainingState _generateQuestion(QuestionType questionType) {
    switch (questionType) {
      case QuestionType.priority:
        return _generatePriorityQuestion();
      case QuestionType.due:
        return _generateDueQuestion();
      case QuestionType.random:
        return _generateRandomQuestion();
    }
  }

  TrainingState _generatePriorityQuestion() {
    final maxFactor = learnerStateBloc.state.maxFactor;
    final priorityItems = learnerStateBloc.state.grid.entries
        .where((entry) =>
            entry.value == CellState.notAttempted ||
            entry.value == CellState.incorrect)
        .where((entry) {
      final factors = entry.key.split('x').map(int.parse).toList();
      return factors[0] <= maxFactor && factors[1] <= maxFactor;
    }).toList();

    if (priorityItems.isEmpty) {
      return _generateRandomQuestion();
    }

    final selectedItem = priorityItems[_random.nextInt(priorityItems.length)];
    final factors = selectedItem.key.split('x').map(int.parse).toList();
    return TrainingState(
      factor1: factors[0],
      factor2: factors[1],
      questionStartTime: DateTime.now(),
    );
  }

  TrainingState _generateDueQuestion() {
    final maxFactor = learnerStateBloc.state.maxFactor;
    final now = DateTime.now();
    final dueItems = learnerStateBloc.state.fsrsItems.entries
        .where((entry) =>
            entry.value.due.isBefore(now) &&
            learnerStateBloc.state.grid[entry.key] != CellState.fastCorrect)
        .where((entry) {
      final factors = entry.key.split('x').map(int.parse).toList();
      return factors[0] <= maxFactor && factors[1] <= maxFactor;
    }).toList();

    if (dueItems.isEmpty) {
      return _generateRandomQuestion();
    }

    final selectedItem = dueItems[_random.nextInt(dueItems.length)];
    final factors = selectedItem.key.split('x').map(int.parse).toList();
    return TrainingState(
      factor1: factors[0],
      factor2: factors[1],
      questionStartTime: now,
    );
  }

  TrainingState _generateRandomQuestion() {
    final maxFactor = learnerStateBloc.state.maxFactor;
    final factor1 = 1 + _random.nextInt(maxFactor);
    final factor2 = 1 + _random.nextInt(maxFactor);
    return TrainingState(
      factor1: factor1,
      factor2: factor2,
      questionStartTime: DateTime.now(),
    );
  }
}
