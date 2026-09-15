import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Android uses an exclusively local native recognizer; iOS enforces onDevice.
/// No branch retries a failed recognition with a remote/default recognizer.
class OfflineVoice {
  OfflineVoice({
    TargetPlatform? platform,
    SpeechToText? speech,
    MethodChannel channel = const MethodChannel('cercaposta/offline_speech'),
  }) : _platform = platform ?? defaultTargetPlatform,
       _speech = speech ?? SpeechToText(),
       _channel = channel;

  final TargetPlatform _platform;
  final SpeechToText _speech;
  final MethodChannel _channel;
  static int _counter = 0;
  String? _session;
  bool _ready = false;
  void Function(String, bool)? _onResult;
  void Function(String)? _onStatus;
  void Function(String)? _onError;

  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;
    if (_platform == TargetPlatform.android) {
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'event' || call.arguments is! Map) return;
        final event = call.arguments as Map;
        if (_session == null || event['sessionId'] != _session) return;
        final value = event['value'];
        if (value is! String) return;
        switch (event['kind']) {
          case 'result':
            _onResult?.call(value, event['final'] == true);
          case 'status':
            _onStatus?.call(value);
          case 'error':
            _onError?.call(value);
        }
      });
      _ready = await _channel.invokeMethod<bool>('initialize') ?? false;
    } else if (_platform == TargetPlatform.iOS) {
      _ready = await _speech.initialize(
        onStatus: onStatus,
        onError: (e) => onError(e.errorMsg),
      );
    } else {
      _ready = false;
    }
    return _ready;
  }

  Future<void> listen({
    required String localeId,
    required void Function(String, bool) onResult,
  }) async {
    if (!_ready) throw StateError('local speech unavailable');
    final id = '${++_counter}';
    _session = id;
    _onResult = onResult;
    if (_platform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('listen', {
        'sessionId': id,
        'localeId': localeId,
      });
    } else {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          onDevice: true,
          cancelOnError: true,
        ),
        onResult: (result) {
          if (_session == id) {
            onResult(result.recognizedWords, result.finalResult);
          }
        },
      );
    }
  }

  Future<void> stop() async {
    final id = _session;
    _session = null;
    _onResult = null;
    try {
      if (_platform == TargetPlatform.android) {
        if (id != null) {
          await _channel.invokeMethod<void>('stop', {'sessionId': id});
        }
      } else if (_platform == TargetPlatform.iOS) {
        await _speech.cancel();
      }
    } on PlatformException {
      // Activity/recognizer teardown may already have released the native session.
    } on MissingPluginException {
      // The Flutter engine can be detached before a disposed widget finishes stop.
    }
  }
}
