import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything the app remembers between launches. Stored on the phone only.
class Progress extends ChangeNotifier {
  Progress._(this._prefs);

  static Future<Progress> load() async => Progress._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kCorrect = 'correct_ids';
  static const _kMissed = 'missed_ids';
  static const _kUnlocked = 'unlocked';
  static const _kBestMock = 'best_mock';
  static const _kMocksTaken = 'mocks_taken';
  static const _kLastMockDay = 'last_mock_day';

  Set<int> _ids(String key) => (_prefs.getStringList(key) ?? const []).map(int.parse).toSet();

  Future<void> _save(String key, Set<int> ids) =>
      _prefs.setStringList(key, ids.map((e) => '$e').toList());

  /// Questions answered right at least once, and not missed since.
  Set<int> get mastered => _ids(_kCorrect);

  /// Questions answered wrong most recently. These feed "Review mistakes".
  Set<int> get missed => _ids(_kMissed);

  bool get unlocked => _prefs.getBool(_kUnlocked) ?? false;
  int get bestMock => _prefs.getInt(_kBestMock) ?? 0;
  int get mocksTaken => _prefs.getInt(_kMocksTaken) ?? 0;

  Future<void> record(int questionId, bool right) async {
    final mastered = this.mastered;
    final missed = this.missed;
    if (right) {
      mastered.add(questionId);
      missed.remove(questionId);
    } else {
      mastered.remove(questionId);
      missed.add(questionId);
    }
    await _save(_kCorrect, mastered);
    await _save(_kMissed, missed);
    notifyListeners();
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Free users get one mock exam a day.
  bool get canTakeMockToday => unlocked || _prefs.getString(_kLastMockDay) != _today();

  Future<void> recordMock(int score) async {
    await _prefs.setInt(_kMocksTaken, mocksTaken + 1);
    await _prefs.setString(_kLastMockDay, _today());
    if (score > bestMock) await _prefs.setInt(_kBestMock, score);
    notifyListeners();
  }

  Future<void> setUnlocked(bool value) async {
    await _prefs.setBool(_kUnlocked, value);
    notifyListeners();
  }

  Future<void> reset() async {
    for (final k in [_kCorrect, _kMissed, _kBestMock, _kMocksTaken, _kLastMockDay]) {
      await _prefs.remove(k);
    }
    notifyListeners();
  }
}
