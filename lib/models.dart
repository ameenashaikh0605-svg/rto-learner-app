import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class Question {
  Question({
    required this.id,
    required this.category,
    required this.text,
    required this.correct,
    required this.wrong,
    required this.alsoAccepted,
    required this.studyOnly,
    required this.note,
    required this.explanation,
    required this.image,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as int,
        category: j['category'] as String,
        text: j['question'] as String,
        correct: j['correct'] as String?,
        wrong: List<String>.from(j['wrong'] ?? const []),
        alsoAccepted: List<String>.from(j['alsoAccepted'] ?? const []),
        studyOnly: j['studyOnly'] == true,
        note: j['note'] as String?,
        explanation: j['explanation'] as String?,
        image: j['image'] as String?,
      );

  final int id;
  final String category;
  final String text;
  final String? correct;
  final List<String> wrong;
  final List<String> alsoAccepted;

  /// Questions whose answer depends on where the user lives. Shown on study
  /// cards only, never in a quiz.
  final bool studyOnly;
  final String? note;

  /// Why the answer is right, shown after answering.
  final String? explanation;

  /// Asset path of a picture (e.g. a road sign) shown with the question.
  final String? image;

  /// The answer options in a random order.
  List<String> shuffledOptions(Random rng) => [correct!, ...wrong]..shuffle(rng);
}

class MockRules {
  const MockRules({
    required this.size,
    required this.passMark,
    required this.maxWrong,
    this.secondsPerQuestion,
    this.stopEarly = true,
  });

  final int size;
  final int passMark;
  final int maxWrong;

  /// Time limit per question in a practice test, or null for no timer.
  final int? secondsPerQuestion;

  /// End the test as soon as the result is decided (pass mark reached or too
  /// many wrong), as the US civics interview does. Otherwise ask every question.
  final bool stopEarly;
}

class Exam {
  Exam({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mock,
    required this.freePerCategory,
    required this.disclaimer,
    required this.categories,
    required this.questions,
  });

  factory Exam.fromJson(Map<String, dynamic> j) {
    final mock = j['mock'] as Map<String, dynamic>;
    return Exam(
      id: j['examId'] as String,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String,
      mock: MockRules(
        size: mock['size'] as int,
        passMark: mock['passMark'] as int,
        maxWrong: mock['maxWrong'] as int,
        secondsPerQuestion: mock['secondsPerQuestion'] as int?,
        stopEarly: mock['stopEarly'] as bool? ?? true,
      ),
      freePerCategory: j['freeQuestionsPerCategory'] as int,
      disclaimer: j['disclaimer'] as String,
      categories: List<String>.from(j['categories']),
      questions: (j['questions'] as List).map((q) => Question.fromJson(q)).toList(),
    );
  }

  static Future<Exam> load() async =>
      Exam.fromJson(jsonDecode(await rootBundle.loadString('assets/questions.json')));

  final String id;
  final String title;
  final String subtitle;
  final MockRules mock;
  final int freePerCategory;
  final String disclaimer;
  final List<String> categories;
  final List<Question> questions;

  List<Question> get quizzable => questions.where((q) => !q.studyOnly).toList();

  List<Question> inCategory(String category) =>
      quizzable.where((q) => q.category == category).toList();

  /// Free users can practise the first [freePerCategory] questions of each category.
  bool isFree(Question q) {
    final list = inCategory(q.category);
    final index = list.indexWhere((x) => x.id == q.id);
    return index >= 0 && index < freePerCategory;
  }

  Question byId(int id) => questions.firstWhere((q) => q.id == id);
}
