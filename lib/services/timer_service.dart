import 'dart:async';

enum TimerState { working, preBreak, onBreak, paused, idle }

enum BreakType { short, long }

class TimerStatus {
  final TimerState state;
  final int remainingSeconds;
  final int totalSeconds;
  final BreakType nextBreakType;
  final int breaksTakenInCycle;
  final int postponesUsedToday;
  final int maxPostponesPerDay;

  const TimerStatus({
    required this.state,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextBreakType,
    required this.breaksTakenInCycle,
    this.postponesUsedToday = 0,
    this.maxPostponesPerDay = 5,
  });

  bool get canPostpone => postponesUsedToday < maxPostponesPerDay;
  int get postponesRemaining => maxPostponesPerDay - postponesUsedToday;

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
      case TimerState.preBreak:
        return 'Break starting in';
      case TimerState.onBreak:
        return nextBreakType == BreakType.long ? 'Long break' : 'Short break';
      case TimerState.paused:
        return 'Paused';
      case TimerState.idle:
        return 'Idle';
    }
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
  int _preBreakSeconds = 30;
  int _maxPostponesPerDay = 5;

  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _breaksTakenInCycle = 0;
  int _postponesUsedToday = 0;
  TimerState _state = TimerState.idle;
  BreakType _currentBreakType = BreakType.short;

  TimerState? _stateBeforePause;

  // Callbacks for notifications
  void Function()? onPreBreakStart;
  void Function(BreakType type)? onBreakStart;
  void Function()? onBreakEnd;

  Stream<TimerStatus> get statusStream => _statusController.stream;

  TimerStatus get currentStatus => TimerStatus(
    state: _state,
    remainingSeconds: _remainingSeconds,
    totalSeconds: _totalSeconds,
    nextBreakType: _currentBreakType,
    breaksTakenInCycle: _breaksTakenInCycle,
    postponesUsedToday: _postponesUsedToday,
    maxPostponesPerDay: _maxPostponesPerDay,
  );

  void configure({
    required int workMinutes,
    required int breakSeconds,
    required int longBreakMinutes,
    required int longBreakInterval,
    int preBreakSeconds = 30,
    int maxPostponesPerDay = 5,
  }) {
    _workDurationSeconds = workMinutes * 60;
    _shortBreakDurationSeconds = breakSeconds;
    _longBreakDurationSeconds = longBreakMinutes * 60;
    _longBreakInterval = longBreakInterval;
    _preBreakSeconds = preBreakSeconds;
    _maxPostponesPerDay = maxPostponesPerDay;
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

  void _startPreBreak() {
    _timer?.cancel();
    _state = TimerState.preBreak;
    _totalSeconds = _preBreakSeconds;
    _remainingSeconds = _preBreakSeconds;
    onPreBreakStart?.call();
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

    onBreakStart?.call(_currentBreakType);
    _emitStatus();
    _startTicking();
  }

  void postpone(int minutes) {
    if (!currentStatus.canPostpone) return;
    _postponesUsedToday++;
    _timer?.cancel();
    _state = TimerState.working;
    _totalSeconds = minutes * 60;
    _remainingSeconds = minutes * 60;
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

  void resetDailyPostpones() {
    _postponesUsedToday = 0;
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
    switch (_state) {
      case TimerState.working:
        _startPreBreak();
      case TimerState.preBreak:
        startBreak();
      case TimerState.onBreak:
        _onBreakComplete();
      case TimerState.paused:
      case TimerState.idle:
        break;
    }
  }

  void _onBreakComplete() {
    _breaksTakenInCycle++;
    if (_breaksTakenInCycle >= _longBreakInterval) {
      _breaksTakenInCycle = 0;
    }
    onBreakEnd?.call();
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
