import 'dart:async';

enum PomodoroState { work, shortBreak, longBreak, paused, idle }

class PomodoroStatus {
  final PomodoroState state;
  final int remainingSeconds;
  final int totalSeconds;
  final int currentPomodoro; // 1-based
  final int totalPomodoros; // typically 4
  final int pomodorosCompletedToday;

  const PomodoroStatus({
    required this.state,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.currentPomodoro,
    required this.totalPomodoros,
    required this.pomodorosCompletedToday,
  });

  double get progress =>
      totalSeconds > 0 ? 1.0 - (remainingSeconds / totalSeconds) : 0.0;

  String get remainingFormatted {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get stateLabel {
    switch (state) {
      case PomodoroState.work:
        return 'Focus';
      case PomodoroState.shortBreak:
        return 'Short Break';
      case PomodoroState.longBreak:
        return 'Long Break';
      case PomodoroState.paused:
        return 'Paused';
      case PomodoroState.idle:
        return 'Ready';
    }
  }
}

class PomodoroService {
  Timer? _timer;
  final StreamController<PomodoroStatus> _statusController =
      StreamController<PomodoroStatus>.broadcast();

  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _pomodorosPerCycle = 4;

  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _currentPomodoro = 1;
  int _pomodorosCompletedToday = 0;
  PomodoroState _state = PomodoroState.idle;
  PomodoroState? _stateBeforePause;

  void Function()? onPomodoroComplete;
  void Function()? onBreakStart;
  void Function()? onBreakEnd;

  Stream<PomodoroStatus> get statusStream => _statusController.stream;

  PomodoroStatus get currentStatus => PomodoroStatus(
    state: _state,
    remainingSeconds: _remainingSeconds,
    totalSeconds: _totalSeconds,
    currentPomodoro: _currentPomodoro,
    totalPomodoros: _pomodorosPerCycle,
    pomodorosCompletedToday: _pomodorosCompletedToday,
  );

  void configure({
    int workMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int pomodorosPerCycle = 4,
  }) {
    _workMinutes = workMinutes;
    _shortBreakMinutes = shortBreakMinutes;
    _longBreakMinutes = longBreakMinutes;
    _pomodorosPerCycle = pomodorosPerCycle;
  }

  void startWork() {
    _timer?.cancel();
    _state = PomodoroState.work;
    _totalSeconds = _workMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _emitStatus();
    _startTicking();
  }

  void startBreak() {
    _timer?.cancel();
    final isLong = _currentPomodoro >= _pomodorosPerCycle;
    _state = isLong ? PomodoroState.longBreak : PomodoroState.shortBreak;
    _totalSeconds = isLong ? _longBreakMinutes * 60 : _shortBreakMinutes * 60;
    _remainingSeconds = _totalSeconds;
    onBreakStart?.call();
    _emitStatus();
    _startTicking();
  }

  void pause() {
    if (_state == PomodoroState.paused || _state == PomodoroState.idle) return;
    _stateBeforePause = _state;
    _timer?.cancel();
    _state = PomodoroState.paused;
    _emitStatus();
  }

  void resume() {
    if (_state != PomodoroState.paused) return;
    _state = _stateBeforePause ?? PomodoroState.work;
    _stateBeforePause = null;
    _emitStatus();
    _startTicking();
  }

  void skipBreak() {
    if (_state != PomodoroState.shortBreak &&
        _state != PomodoroState.longBreak) {
      return;
    }
    _onBreakComplete();
  }

  void reset() {
    _timer?.cancel();
    _currentPomodoro = 1;
    _state = PomodoroState.idle;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _emitStatus();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _timer?.cancel();
        _onTimerComplete();
      }
      _emitStatus();
    });
  }

  void _onTimerComplete() {
    if (_state == PomodoroState.work) {
      _pomodorosCompletedToday++;
      onPomodoroComplete?.call();
      startBreak();
    } else {
      _onBreakComplete();
    }
  }

  void _onBreakComplete() {
    onBreakEnd?.call();
    if (_currentPomodoro >= _pomodorosPerCycle) {
      _currentPomodoro = 1;
    } else {
      _currentPomodoro++;
    }
    startWork();
  }

  void _emitStatus() {
    _statusController.add(currentStatus);
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}
