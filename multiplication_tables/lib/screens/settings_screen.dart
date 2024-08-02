import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentMaxFactor = 12;

  @override
  void initState() {
    super.initState();
    _currentMaxFactor = context.read<LearnerStateBloc>().state.maxFactor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48), // Add space for back button
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maximum Factor',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Adjust the maximum factor for multiplication tables',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<LearnerStateBloc, LearnerState>(
                                  buildWhen: (previous, current) =>
                                      previous.maxFactor != current.maxFactor,
                                  builder: (context, state) {
                                    return Column(
                                      children: [
                                        Slider(
                                          value: _currentMaxFactor.toDouble(),
                                          min: 3,
                                          max: 50,
                                          divisions: 47,
                                          label: _currentMaxFactor.toString(),
                                          onChanged: (value) {
                                            setState(() {
                                              _currentMaxFactor = value.toInt();
                                            });
                                          },
                                          onChangeEnd: (value) {
                                            context
                                                .read<LearnerStateBloc>()
                                                .add(UpdateMaxFactor(
                                                    value.toInt()));
                                          },
                                        ),
                                        Text(
                                          'Current maximum factor: $_currentMaxFactor',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto Increase',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Automatically suggest increasing the maximum factor',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<LearnerStateBloc, LearnerState>(
                                  builder: (context, state) {
                                    return SwitchListTile(
                                      title: const Text('Auto Increase'),
                                      value: state.autoIncrease,
                                      onChanged: (value) {
                                        context
                                            .read<LearnerStateBloc>()
                                            .add(ToggleAutoIncrease(value));
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('About',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text('Multiplication Tables App v1.0',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text('Developed by Your Name',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShadButton.destructive(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Reset Progress'),
                                  content: const Text(
                                      'Are you sure you want to reset all progress? This action cannot be undone.'),
                                  actions: <Widget>[
                                    ShadButton.outline(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ShadButton.destructive(
                                      onPressed: () {
                                        context
                                            .read<LearnerStateBloc>()
                                            .add(ResetProgress());
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Progress has been reset')),
                                        );
                                      },
                                      child: const Text('Reset'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Reset Progress'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: ShadButton.outline(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
