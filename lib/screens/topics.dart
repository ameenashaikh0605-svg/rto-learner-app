import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'quiz.dart';
import 'unlock.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final exam = scope.exam;
    final progress = scope.progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice by topic')),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final cat in exam.categories)
              Builder(builder: (context) {
                final all = exam.inCategory(cat);
                final open = progress.unlocked ? all : all.where(exam.isFree).toList();
                final done = all.where((q) => progress.mastered.contains(q.id)).length;
                final locked = all.length - open.length;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: done / all.length),
                        const SizedBox(height: 4),
                        Text(locked > 0
                            ? '$done of ${all.length} mastered · $locked locked'
                            : '$done of ${all.length} mastered'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            title: cat,
                            questions: List.of(open)..shuffle(),
                            mode: QuizMode.practice,
                          ),
                        ),
                      );
                      if (locked > 0 && context.mounted) {
                        showUnlockSheet(context,
                            reason: 'You finished the free questions in this topic. '
                                'Unlock to practise all $locked more.');
                      }
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
