import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../monetization.dart';
import 'quiz.dart';
import 'study.dart';
import 'topics.dart';
import 'unlock.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final exam = scope.exam;
    final progress = scope.progress;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final total = exam.quizzable.length;
        final mastered = progress.mastered.length;
        final missed = progress.missed.length;
        return Scaffold(
          appBar: AppBar(
            title: Text(exam.title),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          bottomNavigationBar: BannerSlot(ads: scope.ads),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your progress', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: total == 0 ? 0 : mastered / total,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Text('$mastered of $total questions mastered'),
                      if (progress.mocksTaken > 0)
                        Text('Best test score: ${progress.bestMock} correct'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.timer_outlined,
                title: 'Take a practice test',
                subtitle: '${exam.mock.size} questions, like the real test. '
                    'Pass with ${exam.mock.passMark} correct.',
                onTap: () => startMock(context),
              ),
              _ActionTile(
                icon: Icons.menu_book_outlined,
                title: 'Practice by topic',
                subtitle: '${exam.categories.length} topics, with explanations',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const TopicsScreen())),
              ),
              _ActionTile(
                icon: Icons.replay,
                title: 'Review mistakes',
                subtitle: missed == 0 ? 'No mistakes yet' : '$missed questions to review',
                onTap: missed == 0
                    ? null
                    : () {
                        final qs = progress.missed.map(exam.byId).toList()..shuffle();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                                title: 'Review mistakes', questions: qs, mode: QuizMode.practice),
                          ),
                        );
                      },
              ),
              _ActionTile(
                icon: Icons.style_outlined,
                title: 'Study all questions',
                subtitle: 'Every question and sign with its answer',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const StudyScreen())),
              ),
              if (!progress.unlocked) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: const Text('Unlock all questions'),
                    subtitle: const Text('All topics, unlimited tests, no ads. Pay once.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showUnlockSheet(context),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(exam.disclaimer, style: theme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    final scope = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore purchase'),
              onTap: () {
                Navigator.pop(sheetContext);
                scope.store.restore();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Reset my progress'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Reset progress?'),
                    content: const Text('This clears your scores and mistakes. '
                        'Your purchase is kept.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
                    ],
                  ),
                );
                if (ok == true) await scope.progress.reset();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, size: 32),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          enabled: onTap != null,
          onTap: onTap,
        ),
      );
}
