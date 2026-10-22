import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../monetization.dart';
import 'quiz.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.title,
    required this.right,
    required this.answered,
    required this.wrong,
    required this.isMock,
    required this.passed,
    required this.retry,
    required this.mode,
  });

  final String title;
  final int right;
  final int answered;
  final List<Question> wrong;
  final bool isMock;
  final bool passed;
  final List<Question> retry;
  final QuizMode mode;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final theme = Theme.of(context);
    final headline = isMock ? (passed ? 'You passed!' : 'Not yet. Keep practising.') : 'Done!';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: BannerSlot(ads: scope.ads),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Icon(isMock && !passed ? Icons.school_outlined : Icons.emoji_events_outlined,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(headline, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('$right of $answered correct',
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Home'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isMock
                      ? () => startMock(context, replace: true)
                      : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        title: title,
                        questions: List.of(retry)..shuffle(),
                        mode: mode,
                      ),
                    ),
                  ),
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
          if (wrong.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Questions to review', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final q in wrong)
              Card(
                child: ListTile(
                  title: Text(q.text),
                  subtitle: Text('Answer: ${q.correct}'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
