import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

enum PairingRole { desktop, mobile }

enum PairingSyncEvent {
  breakStart,
  breakEnd,
  pause,
  resume,
  ping,
}

class PairingMessage {
  final PairingSyncEvent event;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  PairingMessage({
    required this.event,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'event': event.name,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PairingMessage.fromJson(Map<String, dynamic> json) => PairingMessage(
    event: PairingSyncEvent.values.byName(json['event'] as String),
    data: json['data'] as Map<String, dynamic>?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class PairingService {
  HttpServer? _server;
  HttpClient? _client;
  final PairingRole role;

  String? _pairingCode;
  String? _pairedDeviceAddress;
  int _port = 0;
  bool _isPaired = false;

  final StreamController<PairingMessage> _messageController =
      StreamController<PairingMessage>.broadcast();

  Stream<PairingMessage> get messages => _messageController.stream;
  bool get isPaired => _isPaired;
  String? get pairingCode => _pairingCode;
  int get port => _port;

  PairingService({required this.role});

  /// Desktop: Start server and generate pairing code
  Future<String> startServer() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _port = _server!.port;
    _pairingCode = _generateCode();

    _server!.listen(_handleRequest);

    return _pairingCode!;
  }

  /// Mobile: Connect to desktop using IP:port and pairing code
  Future<bool> connectToDesktop({
    required String address,
    required int port,
    required String code,
  }) async {
    _client = HttpClient();
    try {
      final request = await _client!.post(address, port, '/pair');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'code': code}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body) as Map<String, dynamic>;

      if (result['success'] == true) {
        _isPaired = true;
        _pairedDeviceAddress = address;
        _port = port;
        _startPolling();
        return true;
      }
    } catch (_) {
      // Connection failed
    }
    return false;
  }

  /// Send a sync event to the paired device
  Future<void> sendEvent(PairingSyncEvent event, {Map<String, dynamic>? data}) async {
    final message = PairingMessage(event: event, data: data);

    if (role == PairingRole.desktop && _server != null) {
      // Desktop stores the event for mobile to poll
      _pendingEvents.add(message);
    } else if (role == PairingRole.mobile && _pairedDeviceAddress != null) {
      // Mobile sends directly to desktop
      try {
        _client ??= HttpClient();
        final request = await _client!.post(
          _pairedDeviceAddress!,
          _port,
          '/event',
        );
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(message.toJson()));
        await request.close();
      } catch (_) {
        // Send failed
      }
    }
  }

  final List<PairingMessage> _pendingEvents = [];
  Timer? _pollTimer;

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _pollEvents();
    });
  }

  Future<void> _pollEvents() async {
    if (_pairedDeviceAddress == null) return;
    try {
      _client ??= HttpClient();
      final request = await _client!.get(
        _pairedDeviceAddress!,
        _port,
        '/events',
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final events = (jsonDecode(body) as List<dynamic>)
          .map((e) => PairingMessage.fromJson(e as Map<String, dynamic>));

      for (final event in events) {
        _messageController.add(event);
      }
    } catch (_) {
      // Poll failed
    }
  }

  void _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    if (path == '/pair' && request.method == 'POST') {
      final body = await utf8.decodeStream(request);
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['code'] == _pairingCode) {
        _isPaired = true;
        _pairedDeviceAddress = request.connectionInfo?.remoteAddress.address;
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'success': true}))
          ..close();
      } else {
        request.response
          ..statusCode = 401
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'success': false, 'error': 'Invalid code'}))
          ..close();
      }
    } else if (path == '/events' && request.method == 'GET') {
      final events = List<PairingMessage>.from(_pendingEvents);
      _pendingEvents.clear();
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(events.map((e) => e.toJson()).toList()))
        ..close();
    } else if (path == '/event' && request.method == 'POST') {
      final body = await utf8.decodeStream(request);
      final message =
          PairingMessage.fromJson(jsonDecode(body) as Map<String, dynamic>);
      _messageController.add(message);
      request.response
        ..statusCode = 200
        ..close();
    } else if (path == '/status' && request.method == 'GET') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'app': 'Blink',
          'role': role.name,
          'paired': _isPaired,
        }))
        ..close();
    } else {
      request.response
        ..statusCode = 404
        ..close();
    }
  }

  String _generateCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  Future<void> unpair() async {
    _isPaired = false;
    _pairedDeviceAddress = null;
    _pendingEvents.clear();
    _pollTimer?.cancel();
  }

  Future<void> dispose() async {
    _pollTimer?.cancel();
    await _server?.close();
    _client?.close();
    _messageController.close();
  }
}
