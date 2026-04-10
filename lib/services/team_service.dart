import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/features/settings/settings_model.dart';

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'member'
  final String? devicePlatform;
  final DateTime? lastSeen;
  final int? healthScore;
  final int? breaksTakenToday;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'member',
    this.devicePlatform,
    this.lastSeen,
    this.healthScore,
    this.breaksTakenToday,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'member',
    devicePlatform: json['devicePlatform'] as String?,
    lastSeen: json['lastSeen'] != null
        ? DateTime.tryParse(json['lastSeen'] as String)
        : null,
    healthScore: json['healthScore'] as int?,
    breaksTakenToday: json['breaksTakenToday'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'devicePlatform': devicePlatform,
    'lastSeen': lastSeen?.toIso8601String(),
    'healthScore': healthScore,
    'breaksTakenToday': breaksTakenToday,
  };
}

class TeamStats {
  final int totalMembers;
  final int activeToday;
  final double avgHealthScore;
  final int totalBreaksToday;
  final double avgBreakCompliance; // 0.0 - 1.0

  const TeamStats({
    this.totalMembers = 0,
    this.activeToday = 0,
    this.avgHealthScore = 0,
    this.totalBreaksToday = 0,
    this.avgBreakCompliance = 0,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) => TeamStats(
    totalMembers: json['totalMembers'] as int? ?? 0,
    activeToday: json['activeToday'] as int? ?? 0,
    avgHealthScore: (json['avgHealthScore'] as num?)?.toDouble() ?? 0,
    totalBreaksToday: json['totalBreaksToday'] as int? ?? 0,
    avgBreakCompliance: (json['avgBreakCompliance'] as num?)?.toDouble() ?? 0,
  );
}

class TeamLicense {
  final String teamId;
  final String teamName;
  final int totalSeats;
  final int usedSeats;
  final DateTime? expiresAt;

  const TeamLicense({
    required this.teamId,
    required this.teamName,
    this.totalSeats = 5,
    this.usedSeats = 0,
    this.expiresAt,
  });

  bool get isValid => expiresAt == null || expiresAt!.isAfter(DateTime.now());
  int get availableSeats => totalSeats - usedSeats;

  factory TeamLicense.fromJson(Map<String, dynamic> json) => TeamLicense(
    teamId: json['teamId'] as String,
    teamName: json['teamName'] as String,
    totalSeats: json['totalSeats'] as int? ?? 5,
    usedSeats: json['usedSeats'] as int? ?? 0,
    expiresAt: json['expiresAt'] != null
        ? DateTime.tryParse(json['expiresAt'] as String)
        : null,
  );
}

class TeamService {
  late final SharedPreferences _prefs;
  String? _serverUrl;
  String? _authToken;
  String? _teamId;
  bool _isAdmin = false;

  bool get isInTeam => _teamId != null;
  bool get isAdmin => _isAdmin;
  String? get teamId => _teamId;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _serverUrl = _prefs.getString('team_server_url');
    _authToken = _prefs.getString('team_auth_token');
    _teamId = _prefs.getString('team_id');
    _isAdmin = _prefs.getBool('team_is_admin') ?? false;
  }

  Future<void> configure({
    required String serverUrl,
    required String authToken,
  }) async {
    _serverUrl = serverUrl;
    _authToken = authToken;
    await _prefs.setString('team_server_url', serverUrl);
    await _prefs.setString('team_auth_token', authToken);
  }

  Future<bool> joinTeam(String teamCode) async {
    try {
      final result = await _post('/api/teams/join', {'code': teamCode});
      if (result != null && result['teamId'] != null) {
        _teamId = result['teamId'] as String;
        _isAdmin = result['role'] == 'admin';
        await _prefs.setString('team_id', _teamId!);
        await _prefs.setBool('team_is_admin', _isAdmin);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> leaveTeam() async {
    if (_teamId == null) return;
    await _post('/api/teams/$_teamId/leave', {});
    _teamId = null;
    _isAdmin = false;
    await _prefs.remove('team_id');
    await _prefs.remove('team_is_admin');
  }

  Future<TeamLicense?> getLicense() async {
    if (_teamId == null) return null;
    final data = await _get('/api/teams/$_teamId/license');
    if (data != null) return TeamLicense.fromJson(data);
    return null;
  }

  Future<List<TeamMember>> getMembers() async {
    if (_teamId == null) return [];
    final data = await _get('/api/teams/$_teamId/members');
    if (data != null && data['members'] is List) {
      return (data['members'] as List<dynamic>)
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<TeamStats?> getTeamStats() async {
    if (_teamId == null) return null;
    final data = await _get('/api/teams/$_teamId/stats');
    if (data != null) return TeamStats.fromJson(data);
    return null;
  }

  /// Admin: push default settings to all team members
  Future<bool> pushTeamSettings(SettingsModel settings) async {
    if (!_isAdmin || _teamId == null) return false;
    final result = await _post(
      '/api/teams/$_teamId/settings',
      settings.toJson(),
    );
    return result != null;
  }

  /// Report this device's status to the team
  Future<void> reportStatus({
    required int healthScore,
    required int breaksTakenToday,
  }) async {
    if (_teamId == null) return;
    await _post('/api/teams/$_teamId/status', {
      'healthScore': healthScore,
      'breaksTakenToday': breaksTakenToday,
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    if (_serverUrl == null || _authToken == null) return null;
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$_serverUrl$path'));
      request.headers.set('Authorization', 'Bearer $_authToken');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (_serverUrl == null || _authToken == null) return null;
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_serverUrl$path'));
      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void dispose() {}
}
