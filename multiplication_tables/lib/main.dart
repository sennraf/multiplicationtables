import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:multiplication_tables/blocs/learner_state_bloc.dart';
import 'package:multiplication_tables/blocs/training_bloc.dart';
import 'package:multiplication_tables/screens/learner_state_screen.dart';
import 'package:multiplication_tables/screens/settings_screen.dart';
import 'package:multiplication_tables/screens/training_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shadcn_ui/shadcn_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );
  final learnerStateBloc = LearnerStateBloc();
  runApp(MyApp(learnerStateBloc: learnerStateBloc));
}

class MyApp extends StatelessWidget {
  final AppRouter _appRouter = AppRouter();
  final LearnerStateBloc learnerStateBloc;

  MyApp({super.key, required this.learnerStateBloc});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LearnerStateBloc>(
          create: (context) => learnerStateBloc,
        ),
        BlocProvider<TrainingBloc>(
          create: (context) => TrainingBloc(context.read<LearnerStateBloc>()),
        ),
      ],
      child: ShadApp(
        title: 'Multiplication Tables Trainer',
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: const ShadSlateColorScheme.light(),
        ),
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadSlateColorScheme.dark(),
        ),
        themeMode: ThemeMode.system,
        onGenerateRoute: _appRouter.onGenerateRoute,
      ),
    );
  }
}

class AppRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LearnerStateScreen());
      case '/training':
        return MaterialPageRoute(builder: (_) => const TrainingScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LearnerStateScreen());
    }
  }
}
