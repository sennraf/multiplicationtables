import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class IncreaseMaxFactorButton extends StatelessWidget {
  const IncreaseMaxFactorButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: ShadButton.outline(
        onPressed: () {
          final maxFactor = context.read<LearnerStateBloc>().state.maxFactor;
          context.read<LearnerStateBloc>().add(
                UpdateMaxFactor(maxFactor + 1),
              );
        },
        child: const Text('Increase Level'),
      ),
    );
  }
}
