import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiplication_tables/blocs/training_bloc.dart';
import 'package:multiplication_tables/widgets/increase_max_factor_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Add this listener
    context.read<TrainingBloc>().stream.listen((state) {
      if (state.isTransitioning) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitAnswer(BuildContext context) {
    if (_controller.text.isNotEmpty) {
      context
          .read<TrainingBloc>()
          .add(SubmitAnswer(int.parse(_controller.text)));
      _controller.clear();
      _animationController.forward(from: 0.0).then((_) {
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          context.read<TrainingBloc>().add(TransitionToNextQuestion());
        });
      });
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      _controller.text += number;
    });
  }

  void _onBackspace() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text =
            _controller.text.substring(0, _controller.text.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _QuestionDisplay(
                                  isTransitioning: state.isTransitioning,
                                ),
                                const SizedBox(height: 22),
                                _AnswerInput(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  onSubmitted: (_) => _submitAnswer(context),
                                  enabled: !state.isTransitioning,
                                ),
                                const SizedBox(height: 11),
                                const SizedBox(
                                  height: 61,
                                  child: _FeedbackDisplay(),
                                ),
                                const SizedBox(height: 11),
                                if (state.isTransitioning)
                                  LinearProgressIndicator(
                                    value: _animationController.value,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor),
                                  ),
                              ],
                            ),
                          ),
                          NumberPad(
                            onNumberPressed: _onNumberPressed,
                            onBackspace: _onBackspace,
                            onSubmit: () => _submitAnswer(context),
                            enabled: !state.isTransitioning,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (MediaQuery.sizeOf(context).width < 1200)
                  const _BackButton(),
                BlocBuilder<LearnerStateBloc, LearnerState>(
                  builder: (context, learnerState) {
                    final showNextLevel = learnerState.autoIncrease &&
                        learnerState.shouldSuggestIncrease;
                    if (!showNextLevel) return const SizedBox.shrink();
                    return const IncreaseMaxFactorButton();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestionDisplay extends StatelessWidget {
  final bool isTransitioning;

  const _QuestionDisplay({
    required this.isTransitioning,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TrainingBloc, TrainingState, String>(
      selector: (state) => '${state.factor1} × ${state.factor2} = ?',
      builder: (context, question) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            key: ValueKey(question), // Add this key
            opacity: isTransitioning ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Text(
              question,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

class _AnswerInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final bool enabled;

  const _AnswerInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: onSubmitted,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall,
      enabled: enabled,
    );
  }
}

class _FeedbackDisplay extends StatelessWidget {
  const _FeedbackDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TrainingBloc, TrainingState, TrainingState?>(
      selector: (state) => state.userAnswer != null ? state : null,
      builder: (context, state) {
        return AnimatedOpacity(
          opacity: state != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: state != null
              ? _buildFeedbackContent(context, state)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildFeedbackContent(BuildContext context, TrainingState state) {
    final isCorrect = state.isCorrect;
    final color = isCorrect ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.error,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.factor1} × ${state.factor2} = ${state.factor1 * state.factor2}',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: ShadButton.outline(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class NumberPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool enabled;

  const NumberPad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onSubmit,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 60.0;
    const double fontSize = 20.0;

    return IgnorePointer(
      ignoring: !enabled,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(['1', '2', '3'], buttonSize, fontSize),
            _buildRow(['4', '5', '6'], buttonSize, fontSize),
            _buildRow(['7', '8', '9'], buttonSize, fontSize),
            _buildRow(['C', '0', '✓'], buttonSize, fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> buttons, double buttonSize, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons.map((button) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: ShadButton(
                onPressed: () {
                  if (button == 'C') {
                    onBackspace();
                  } else if (button == '✓') {
                    onSubmit();
                  } else {
                    onNumberPressed(button);
                  }
                },
                child: Text(
                  button,
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
