import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../models.dart';
import 'results.dart';
import 'unlock.dart';

enum QuizMode { practice, mock }

/// Opens a practice test of random questions, or the unlock sheet when a free
/// user has already taken today's test.
void startMock(BuildContext context, {bool replace = false}) {
  final scope = AppScope.of(context);
  if (!scope.progress.canTakeMockToday) {
    showUnlockSheet(context,
        reason: 'Free users get one practice test a day. Unlock for unlimited tests.');
    return;
  }
  final pool = scope.exam.quizzable..shuffle(Random());
  final route = MaterialPageRoute<void>(
    builder: (_) => QuizScreen(
      title: 'Practice test',
      questions: pool.take(scope.exam.mock.size).toList(),
      mode: QuizMode.mock,
    ),
  );
  replace ? Navigator.pushReplacement(context, route) : Navigator.push(context, route);
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.title, required this.questions, required this.mode});

  final String title;
  final List<Question> questions;
  final QuizMode mode;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _rng = Random();
  int _index = 0;
  late List<String> _options;
  String? _picked;
  final List<Question> _wrong = [];
  int _right = 0;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _timedOut = false;

  Question get _q => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    _options = _q.shuffledOptions(_rng);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Practice tests have a time limit per question, like the real test.
  void _startTimer() {
    _timer?.cancel();
    final limit = AppScope.of(context).exam.mock.secondsPerQuestion;
    if (widget.mode != QuizMode.mock || limit == null || !mounted) return;
    setState(() => _secondsLeft = limit);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _timedOut = true;
        _pick('');
      }
    });
  }

  Future<void> _pick(String option) async {
    if (_picked != null) return;
    _timer?.cancel();
    final right = option == _q.correct;
    setState(() {
      _picked = option;
      if (right) {
        _right++;
      } else {
        _wrong.add(_q);
      }
    });
    await AppScope.of(context).progress.record(_q.id, right);
  }

  bool get _mockOver {
    final rules = AppScope.of(context).exam.mock;
    return widget.mode == QuizMode.mock &&
        rules.stopEarly &&
        (_right >= rules.passMark || _wrong.length >= rules.maxWrong);
  }

  void _next() {
    if (_mockOver || _index == widget.questions.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _timedOut = false;
      _options = _q.shuffledOptions(_rng);
    });
    _startTimer();
  }

  Future<void> _finish() async {
    final scope = AppScope.of(context);
    final passed = _right >= scope.exam.mock.passMark;
    if (widget.mode == QuizMode.mock) await scope.progress.recordMock(_right);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          title: widget.title,
          right: _right,
          answered: _right + _wrong.length,
          wrong: List.of(_wrong),
          isMock: widget.mode == QuizMode.mock,
          passed: passed,
          retry: widget.questions,
          mode: widget.mode,
        ),
      ),
    );
    scope.ads.maybeShowInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = widget.questions.length;
    final answered = _picked != null;
    final rules = AppScope.of(context).exam.mock;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + (answered ? 1 : 0)) / total),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Text('Question ${_index + 1} of $total', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      if (widget.mode == QuizMode.mock)
                        Text('$_right right · ${_wrong.length} wrong',
                            style: theme.textTheme.labelLarge),
                    ],
                  ),
                  if (rules.secondsPerQuestion != null && widget.mode == QuizMode.mock && !answered) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: _secondsLeft <= 10 ? scheme.error : null),
                        const SizedBox(width: 4),
                        Text('$_secondsLeft s',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: _secondsLeft <= 10 ? scheme.error : null)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _secondsLeft / rules.secondsPerQuestion!,
                            color: _secondsLeft <= 10 ? scheme.error : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.mode == QuizMode.mock)
                    Text('Pass with ${rules.passMark} of ${widget.questions.length} right.',
                        style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Text(_q.text, style: theme.textTheme.headlineSmall),
                  if (_q.image != null) ...[
                    const SizedBox(height: 16),
                    Center(child: SvgPicture.asset(_q.image!, height: 160, semanticsLabel: 'Road sign')),
                  ],
                  const SizedBox(height: 20),
                  for (final o in _options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OptionButton(
                        label: o,
                        state: !answered
                            ? _OptionState.idle
                            : o == _q.correct
                                ? _OptionState.right
                                : o == _picked
                                    ? _OptionState.wrong
                                    : _OptionState.dimmed,
                        onTap: () => _pick(o),
                      ),
                    ),
                  if (answered && _timedOut)
                    Text("Time's up! The right answer is highlighted.",
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
                  if (answered && _q.explanation != null) ...[
                    const SizedBox(height: 8),
                    Card(
                      color: scheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(_q.explanation!),
                      ),
                    ),
                  ],
                  if (answered && _q.alsoAccepted.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Card(
                      color: scheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Other accepted answers', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 6),
                            for (final a in _q.alsoAccepted) Text('• $a'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (answered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: Text(_mockOver || _index == total - 1 ? 'See results' : 'Next question'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, right, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.state, required this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? const Color(0xFF2E7D32) : const Color(0xFFC8E6C9);
    final red = dark ? const Color(0xFFB71C1C) : const Color(0xFFFFCDD2);
    final (Color bg, IconData? icon) = switch (state) {
      _OptionState.idle => (scheme.surfaceContainer, null),
      _OptionState.right => (green, Icons.check_circle),
      _OptionState.wrong => (red, Icons.cancel),
      _OptionState.dimmed => (scheme.surfaceContainer.withValues(alpha: 0.5), null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: state == _OptionState.idle ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
              if (icon != null) Icon(icon),
            ],
          ),
        ),
      ),
    );
  }
}
