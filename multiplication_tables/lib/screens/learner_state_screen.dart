import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';
import 'package:multiplication_tables/screens/training_screen.dart';
import 'package:multiplication_tables/widgets/multiplication_grid.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LearnerStateScreen extends StatelessWidget {
  const LearnerStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Practice Multiplication Tables',
          style: ShadTheme.of(context).textTheme.h3,
        ),
        actions: [
          ShadButton.outline(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1200) {
            return const CombinedView();
          } else {
            return MobileView(constraints: constraints);
          }
        },
      ),
    );
  }
}

class MobileView extends StatelessWidget {
  final BoxConstraints constraints;

  const MobileView({required this.constraints, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: BlocBuilder<LearnerStateBloc, LearnerState>(
        builder: (context, state) {
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          final gridSize = availableWidth > 600 && availableHeight > 600
              ? 600.0
              : min(availableWidth, availableHeight);

          final showNextLevel =
              state.autoIncrease && state.shouldSuggestIncrease;

          return Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: gridSize,
                  height: gridSize,
                  child: const MultiplicationGrid(),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShadButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/training'),
                        child: const Text('Start Training'),
                      ),
                      const SizedBox(width: 16),
                      if (showNextLevel)
                        ShadButton.outline(
                          onPressed: () {
                            context.read<LearnerStateBloc>().add(
                                  UpdateMaxFactor(state.maxFactor + 1),
                                );
                          },
                          child: const Text('Increase Level'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CombinedView extends StatelessWidget {
  const CombinedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(68.0),
            child: MultiplicationGrid(),
          ),
        ),
        Expanded(
          flex: 1,
          child: TrainingScreen(),
        ),
      ],
    );
  }
}
