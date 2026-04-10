import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum AutomationEvent {
  breakStart,
  breakEnd,
  pause,
  resume,
  blinkReminder,
  postureReminder,
}

enum AutomationType {
  shellCommand,
  webhook,
}

class Automation {
  final String id;
  final String name;
  final AutomationEvent event;
  final AutomationType type;
  final String command; // shell command or webhook URL
  final bool enabled;

  const Automation({
    required this.id,
    required this.name,
    required this.event,
    required this.type,
    required this.command,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'event': event.name,
    'type': type.name,
    'command': command,
    'enabled': enabled,
  };

  factory Automation.fromJson(Map<String, dynamic> json) => Automation(
    id: json['id'] as String,
    name: json['name'] as String,
    event: AutomationEvent.values.byName(json['event'] as String),
    type: AutomationType.values.byName(json['type'] as String),
    command: json['command'] as String,
    enabled: json['enabled'] as bool? ?? true,
  );
}

class AutomationService {
  late final SharedPreferences _prefs;
  List<Automation> _automations = [];

  List<Automation> get automations => List.unmodifiable(_automations);

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _load();
  }

  void _load() {
    final raw = _prefs.getStringList('automations') ?? [];
    _automations = raw
        .map((s) => Automation.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    await _prefs.setStringList(
      'automations',
      _automations.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  Future<void> add(Automation automation) async {
    _automations.add(automation);
    await _save();
  }

  Future<void> remove(String id) async {
    _automations.removeWhere((a) => a.id == id);
    await _save();
  }

  Future<void> trigger(AutomationEvent event) async {
    final matching = _automations.where(
      (a) => a.event == event && a.enabled,
    );

    for (final automation in matching) {
      switch (automation.type) {
        case AutomationType.shellCommand:
          await _runShellCommand(automation.command);
        case AutomationType.webhook:
          await _sendWebhook(automation.command, event);
      }
    }
  }

  Future<void> _runShellCommand(String command) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('bash', ['-c', command]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', command]);
      }
    } catch (_) {
      // Silently fail - user can check automation logs
    }
  }

  Future<void> _sendWebhook(String url, AutomationEvent event) async {
    try {
      final payload = jsonEncode({
        'event': event.name,
        'app': 'Blink',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('curl', [
          '-s', '-X', 'POST',
          '-H', 'Content-Type: application/json',
          '-d', payload,
          url,
        ]);
      }
    } catch (_) {
      // Silently fail
    }
  }

  void dispose() {}
}
