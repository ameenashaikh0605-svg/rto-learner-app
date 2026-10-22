import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../config.dart';

Future<void> showUnlockSheet(BuildContext context, {String? reason}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _UnlockSheet(reason: reason),
  );
}

class _UnlockSheet extends StatelessWidget {
  const _UnlockSheet({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([store, scope.progress]),
      builder: (context, _) {
        final product = store.product;
        final Widget action;
        if (scope.progress.unlocked) {
          action = FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Unlocked. Thank you!'),
          );
        } else if (!AppConfig.supportsStore) {
          action = const Text('Purchases work in the Android and iPhone app.',
              textAlign: TextAlign.center);
        } else if (product == null) {
          action = const Text('The store is not available right now. Please try again later.',
              textAlign: TextAlign.center);
        } else {
          action = FilledButton(
            onPressed: store.busy ? null : store.buy,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(store.busy ? 'Please wait…' : 'Unlock for ${product.price}'),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.workspace_premium_outlined, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('Unlock everything', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                if (reason != null) ...[
                  const SizedBox(height: 8),
                  Text(reason!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                for (final line in [
                  'All ${scope.exam.questions.length} questions and signs',
                  'Unlimited practice tests',
                  'No ads',
                  'Pay once. No subscription.',
                ])
                  ListTile(dense: true, leading: const Icon(Icons.check_circle_outline), title: Text(line)),
                const SizedBox(height: 12),
                action,
                if (store.error != null) ...[
                  const SizedBox(height: 8),
                  Text(store.error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                ],
                if (AppConfig.supportsStore && !scope.progress.unlocked)
                  TextButton(onPressed: store.restore, child: const Text('Restore purchase')),
              ],
            ),
          ),
        );
      },
    );
  }
}
