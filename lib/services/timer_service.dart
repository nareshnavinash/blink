import 'dart:async';

enum TimerState { working, onBreak, paused, idle }

enum BreakType { short, long }

class TimerStatus {
  final TimerState state;
  final int remainingSeconds;
  final int totalSeconds;
  final BreakType nextBreakType;
  final int breaksTakenInCycle;

  const TimerStatus({
    required this.state,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextBreakType,
    required this.breaksTakenInCycle,
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
      case TimerState.working:
        return 'Next break in';
      case TimerState.onBreak:
        return nextBreakType == BreakType.long
            ? 'Long break'
            : 'Short break';
      case TimerState.paused:
        return 'Paused';
      case TimerState.idle:
        return 'Idle';
    }
  }

  TimerStatus copyWith({
    TimerState? state,
    int? remainingSeconds,
    int? totalSeconds,
    BreakType? nextBreakType,
    int? breaksTakenInCycle,
  }) {
    return TimerStatus(
      state: state ?? this.state,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      nextBreakType: nextBreakType ?? this.nextBreakType,
      breaksTakenInCycle: breaksTakenInCycle ?? this.breaksTakenInCycle,
    );
  }
}

class TimerService {
  Timer? _timer;
  final StreamController<TimerStatus> _statusController =
      StreamController<TimerStatus>.broadcast();

  late int _workDurationSeconds;
  late int _shortBreakDurationSeconds;
  late int _longBreakDurationSeconds;
  late int _longBreakInterval;

  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _breaksTakenInCycle = 0;
  TimerState _state = TimerState.idle;
  BreakType _currentBreakType = BreakType.short;

  // Saved state for pause/resume
  TimerState? _stateBeforePause;

  Stream<TimerStatus> get statusStream => _statusController.stream;

  TimerStatus get currentStatus => TimerStatus(
    state: _state,
    remainingSeconds: _remainingSeconds,
    totalSeconds: _totalSeconds,
    nextBreakType: _currentBreakType,
    breaksTakenInCycle: _breaksTakenInCycle,
  );

  void configure({
    required int workMinutes,
    required int breakSeconds,
    required int longBreakMinutes,
    required int longBreakInterval,
  }) {
    _workDurationSeconds = workMinutes * 60;
    _shortBreakDurationSeconds = breakSeconds;
    _longBreakDurationSeconds = longBreakMinutes * 60;
    _longBreakInterval = longBreakInterval;
  }

  void startWorkSession() {
    _timer?.cancel();
    _totalSeconds = _workDurationSeconds;
    _remainingSeconds = _workDurationSeconds;
    _state = TimerState.working;
    _updateNextBreakType();
    _emitStatus();
    _startTicking();
  }

  void startBreak() {
    _timer?.cancel();
    _state = TimerState.onBreak;

    if (_currentBreakType == BreakType.long) {
      _totalSeconds = _longBreakDurationSeconds;
      _remainingSeconds = _longBreakDurationSeconds;
    } else {
      _totalSeconds = _shortBreakDurationSeconds;
      _remainingSeconds = _shortBreakDurationSeconds;
    }

    _emitStatus();
    _startTicking();
  }

  void pause() {
    if (_state == TimerState.paused) return;
    _stateBeforePause = _state;
    _timer?.cancel();
    _state = TimerState.paused;
    _emitStatus();
  }

  void resume() {
    if (_state != TimerState.paused) return;
    _state = _stateBeforePause ?? TimerState.working;
    _stateBeforePause = null;
    _emitStatus();
    _startTicking();
  }

  void skipBreak() {
    if (_state != TimerState.onBreak) return;
    _onBreakComplete();
  }

  void startBreakNow() {
    _timer?.cancel();
    startBreak();
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
    if (_state == TimerState.working) {
      startBreak();
    } else if (_state == TimerState.onBreak) {
      _onBreakComplete();
    }
  }

  void _onBreakComplete() {
    _breaksTakenInCycle++;
    if (_breaksTakenInCycle >= _longBreakInterval) {
      _breaksTakenInCycle = 0;
    }
    startWorkSession();
  }

  void _updateNextBreakType() {
    _currentBreakType =
        (_breaksTakenInCycle + 1) >= _longBreakInterval
            ? BreakType.long
            : BreakType.short;
  }

  void _emitStatus() {
    _statusController.add(currentStatus);
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}
