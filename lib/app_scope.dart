import 'package:flutter/widgets.dart';

import 'models.dart';
import 'monetization.dart';
import 'progress.dart';

/// Gives every screen access to the exam, saved progress, ads and the store.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.exam,
    required this.progress,
    required this.ads,
    required this.store,
    required super.child,
  });

  final Exam exam;
  final Progress progress;
  final Ads ads;
  final Store store;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
