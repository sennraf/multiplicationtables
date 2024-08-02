import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';

class MultiplicationGrid extends StatelessWidget {
  const MultiplicationGrid({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearnerStateBloc, LearnerState>(
      builder: (context, state) {
        final showNextLevel = state.autoIncrease && state.shouldSuggestIncrease;
        final displayMaxFactor =
            showNextLevel ? state.maxFactor + 1 : state.maxFactor;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: displayMaxFactor + 1,
            childAspectRatio: 1,
          ),
          itemCount: (displayMaxFactor + 1) * (displayMaxFactor + 1),
          itemBuilder: (context, index) {
            final row = index ~/ (displayMaxFactor + 1);
            final col = index % (displayMaxFactor + 1);

            final isNextLevel = row > state.maxFactor || col > state.maxFactor;

            if (row == 0 && col == 0) {
              return const SizedBox.shrink();
            }
            if (row == 0 || col == 0) {
              return Opacity(
                opacity: isNextLevel ? 0.1 : 1.0,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '${row == 0 ? col : row}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              );
            }
            final cellState =
                state.grid['${row}x$col'] ?? CellState.notAttempted;

            return Opacity(
              opacity: isNextLevel ? 0.1 : 1.0,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _getCellColor(cellState),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getCellColor(CellState state) {
    switch (state) {
      case CellState.notAttempted:
        return Colors.grey;
      case CellState.correct:
        return Colors.orange;
      case CellState.incorrect:
        return Colors.red;
      case CellState.fastCorrect:
        return Colors.green;
    }
  }
}
