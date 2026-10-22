import 'dart:convert';
import 'dart:io';

import 'package:exam_prep/main.dart';
import 'package:exam_prep/models.dart';
import 'package:exam_prep/monetization.dart';
import 'package:exam_prep/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Exam _exam() => Exam.fromJson(jsonDecode(File('assets/questions.json').readAsStringSync()));

void main() {
  test('question bank is complete and well formed', () {
    final exam = _exam();
    expect(exam.questions.map((q) => q.id), List.generate(exam.questions.length, (i) => i + 1));
    expect(exam.questions.length, greaterThanOrEqualTo(100));
    for (final q in exam.quizzable) {
      expect(q.wrong.length, 3, reason: 'Q${q.id}');
      expect({q.correct, ...q.wrong}.length, 4, reason: 'Q${q.id} has duplicate options');
      expect(exam.categories, contains(q.category));
    }
    for (final q in exam.questions.where((q) => q.image != null)) {
      expect(File(q.image!).existsSync(), isTrue, reason: q.image);
    }
    expect(exam.questions.where((q) => q.image != null).length, greaterThanOrEqualTo(30));
  });

  test('free tier gives the first questions of each topic', () {
    final exam = _exam();
    for (final cat in exam.categories) {
      final list = exam.inCategory(cat);
      final free = list.where(exam.isFree).length;
      expect(free, list.length < exam.freePerCategory ? list.length : exam.freePerCategory);
    }
  });

  test('progress records right and wrong answers and the daily test limit', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await Progress.load();
    await p.record(5, false);
    expect(p.missed, {5});
    await p.record(5, true);
    expect(p.missed, isEmpty);
    expect(p.mastered, {5});
    expect(p.canTakeMockToday, isTrue);
    await p.recordMock(14);
    expect(p.canTakeMockToday, isFalse);
    expect(p.bestMock, 14);
    await p.setUnlocked(true);
    expect(p.canTakeMockToday, isTrue);
  });

  testWidgets('practice test has a per-question timer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final exam = _exam();
    final progress = await Progress.load();
    await tester.pumpWidget(ExamApp(exam: exam, progress: progress, ads: Ads(progress), store: Store(progress)));
    await tester.tap(find.text('Take a practice test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Question 1 of ${exam.mock.size}'), findsOneWidget);
    expect(find.text('${exam.mock.secondsPerQuestion} s'), findsOneWidget);
    await tester.pump(Duration(seconds: exam.mock.secondsPerQuestion!));
    await tester.pump();
    expect(find.text('Next question'), findsOneWidget);
    expect(progress.missed.length, 1);
  });

  testWidgets('practice a topic and answer a question', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final exam = _exam();
    final progress = await Progress.load();
    await tester.pumpWidget(ExamApp(exam: exam, progress: progress, ads: Ads(progress), store: Store(progress)));
    expect(find.text('Take a practice test'), findsOneWidget);

    await tester.tap(find.text('Practice by topic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(exam.categories[3]));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of ${exam.freePerCategory}'), findsOneWidget);

    final shown = exam.inCategory(exam.categories[3]).firstWhere((q) => find.text(q.text).evaluate().isNotEmpty);
    await tester.tap(find.text(shown.correct!));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(progress.mastered, {shown.id});
    expect(find.text('Next question'), findsOneWidget);
  });
}
