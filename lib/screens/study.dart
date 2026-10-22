import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../models.dart';
import 'unlock.dart';

/// Every question with its accepted answers, grouped by topic.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final exam = scope.exam;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Study all questions')),
      body: ListenableBuilder(
        listenable: scope.progress,
        builder: (context, _) {
          final unlocked = scope.progress.unlocked;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final cat in exam.categories) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(cat, style: theme.textTheme.titleMedium),
                ),
                for (final q in exam.questions.where((q) => q.category == cat))
                  _StudyCard(q: q, locked: !unlocked && !q.studyOnly && !exam.isFree(q)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.q, required this.locked});

  final Question q;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: CircleAvatar(radius: 16, child: Text('${q.id}', style: const TextStyle(fontSize: 12))),
      title: q.image == null
          ? Text(q.text)
          : Row(children: [
              SvgPicture.asset(q.image!, height: 44),
              const SizedBox(width: 12),
              Expanded(child: Text(q.text)),
            ]),
      trailing: locked ? const Icon(Icons.lock_outline) : null,
      onExpansionChanged: locked ? (_) => showUnlockSheet(context) : null,
      childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: locked
          ? [const Text('Unlock to see this answer.')]
          : [
              if (q.studyOnly)
                Text(q.note ?? '', style: theme.textTheme.bodyMedium)
              else ...[
                Text(q.correct!, style: const TextStyle(fontWeight: FontWeight.w600)),
                for (final a in q.alsoAccepted) Text(a),
                if (q.explanation != null) ...[
                  const SizedBox(height: 4),
                  Text(q.explanation!, style: theme.textTheme.bodySmall),
                ],
              ],
            ],
    );
  }
}
