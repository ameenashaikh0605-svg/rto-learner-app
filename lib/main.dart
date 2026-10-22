import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'models.dart';
import 'monetization.dart';
import 'progress.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final exam = await Exam.load();
  final progress = await Progress.load();
  final ads = Ads(progress);
  final store = Store(progress);
  runApp(ExamApp(exam: exam, progress: progress, ads: ads, store: store));
  // Started after the first frame so the app opens instantly.
  ads.init();
  store.init();
}

class ExamApp extends StatelessWidget {
  const ExamApp({
    super.key,
    required this.exam,
    required this.progress,
    required this.ads,
    required this.store,
  });

  final Exam exam;
  final Progress progress;
  final Ads ads;
  final Store store;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F4E9C);
    return AppScope(
      exam: exam,
      progress: progress,
      ads: ads,
      store: store,
      child: MaterialApp(
        title: exam.title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
