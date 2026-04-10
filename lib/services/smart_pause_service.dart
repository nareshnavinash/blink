import 'dart:async';
import 'dart:io';

class SmartPauseConfig {
  final bool detectMeetings;
  final bool detectFullscreen;
  final bool detectVideoPlayers;
  final List<String> focusApps;
  final int postActivityDelayMinutes;

  const SmartPauseConfig({
    this.detectMeetings = true,
    this.detectFullscreen = true,
    this.detectVideoPlayers = true,
    this.focusApps = const [],
    this.postActivityDelayMinutes = 2,
  });
}

enum SmartPauseReason {
  meeting,
  fullscreen,
  videoPlayback,
  focusApp,
}

class SmartPauseService {
  Timer? _pollTimer;
  SmartPauseConfig _config = const SmartPauseConfig();
  bool _isPaused = false;
  SmartPauseReason? _currentReason;
  DateTime? _activityEndedAt;

  bool get isPaused => _isPaused;
  SmartPauseReason? get currentReason => _currentReason;

  void Function(bool shouldPause, SmartPauseReason? reason)? onPauseChanged;

  void configure(SmartPauseConfig config) {
    _config = config;
  }

  void start() {
    stop();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _check() async {
    SmartPauseReason? reason;

    if (_config.detectMeetings) {
      final inMeeting = await _detectMeeting();
      if (inMeeting) reason = SmartPauseReason.meeting;
    }

    if (reason == null && _config.detectFullscreen) {
      final fullscreen = await _detectFullscreen();
      if (fullscreen) reason = SmartPauseReason.fullscreen;
    }

    if (reason == null && _config.detectVideoPlayers) {
      final playing = await _detectVideoPlayback();
      if (playing) reason = SmartPauseReason.videoPlayback;
    }

    if (reason == null && _config.focusApps.isNotEmpty) {
      final focusApp = await _detectFocusApp();
      if (focusApp) reason = SmartPauseReason.focusApp;
    }

    final shouldPause = reason != null;

    // Handle post-activity delay
    if (!shouldPause && _isPaused) {
      if (_activityEndedAt == null) {
        _activityEndedAt = DateTime.now();
        return; // Don't unpause yet, wait for delay
      }
      final elapsed = DateTime.now().difference(_activityEndedAt!);
      if (elapsed.inMinutes < _config.postActivityDelayMinutes) {
        return; // Still within delay period
      }
    }

    if (shouldPause) {
      _activityEndedAt = null;
    }

    if (shouldPause != _isPaused) {
      _isPaused = shouldPause;
      _currentReason = reason;
      onPauseChanged?.call(shouldPause, reason);
    }
  }

  Future<bool> _detectMeeting() async {
    if (Platform.isMacOS) {
      return _detectMacOSMeeting();
    } else if (Platform.isLinux) {
      return _detectLinuxMeeting();
    }
    return false;
  }

  Future<bool> _detectMacOSMeeting() async {
    try {
      // Check if camera is in use
      final result = await Process.run('bash', ['-c',
        'log show --predicate \'subsystem == "com.apple.camera"\' --last 5s 2>/dev/null | grep -c "Asserting" || true'
      ]);
      final cameraActive = int.tryParse((result.stdout as String).trim()) ?? 0;
      if (cameraActive > 0) return true;

      // Check for known meeting apps with active audio
      final psResult = await Process.run('bash', ['-c',
        'ps aux | grep -iE "(zoom|teams|meet|webex|facetime|slack.*call)" | grep -v grep | wc -l'
      ]);
      final meetingApps = int.tryParse((psResult.stdout as String).trim()) ?? 0;
      return meetingApps > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _detectLinuxMeeting() async {
    try {
      // Check if mic/camera is in use via /proc
      final result = await Process.run('bash', ['-c',
        'fuser /dev/video* 2>/dev/null | wc -w || echo 0'
      ]);
      final devices = int.tryParse((result.stdout as String).trim()) ?? 0;
      return devices > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _detectFullscreen() async {
    if (Platform.isMacOS) {
      try {
        final result = await Process.run('bash', ['-c',
          '''osascript -e 'tell application "System Events" to get properties of first process whose frontmost is true' 2>/dev/null | grep -c "kAXFullScreenAttribute" || echo 0'''
        ]);
        final fs = int.tryParse((result.stdout as String).trim()) ?? 0;
        return fs > 0;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _detectVideoPlayback() async {
    try {
      final videoApps = ['vlc', 'mpv', 'iina', 'QuickTime Player'];
      final result = await Process.run('bash', ['-c',
        'ps aux | grep -iE "(${videoApps.join("|")})" | grep -v grep | wc -l'
      ]);
      final count = int.tryParse((result.stdout as String).trim()) ?? 0;
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _detectFocusApp() async {
    if (_config.focusApps.isEmpty) return false;
    try {
      final pattern = _config.focusApps.join('|');
      final result = await Process.run('bash', ['-c',
        'ps aux | grep -iE "($pattern)" | grep -v grep | wc -l'
      ]);
      final count = int.tryParse((result.stdout as String).trim()) ?? 0;
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    stop();
  }
}
