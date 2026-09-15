import 'package:cercaposta/core/voice/offline_voice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechFake extends Fake implements SpeechToText {
  final calls = <Invocation>[];
  bool fail = false;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    if (invocation.memberName == #initialize) return Future<bool>.value(true);
    if (invocation.memberName == #listen) {
      if (fail) {
        return Future<void>.error(PlatformException(code: 'onDeviceError'));
      }
      return Future<void>.value();
    }
    if (invocation.memberName == #cancel) return Future<void>.value();
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cercaposta/offline_speech');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var available = true;
  var failed = false;

  setUp(() {
    calls.clear();
    available = true;
    failed = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return available;
      if (call.method == 'listen' && failed) {
        throw PlatformException(code: 'unavailable');
      }
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<void> event(String id, String words) async {
    final data = const StandardMethodCodec().encodeMethodCall(
      MethodCall('event', {
        'sessionId': id,
        'kind': 'result',
        'value': words,
        'final': true,
      }),
    );
    await messenger.handlePlatformMessage(channel.name, data, (_) {});
  }

  test('Android without an offline engine never starts recognition', () async {
    available = false;
    final speech = SpeechFake();
    final voice = OfflineVoice(
      platform: TargetPlatform.android,
      speech: speech,
    );
    expect(await voice.initialize(onStatus: (_) {}, onError: (_) {}), isFalse);
    await expectLater(
      voice.listen(localeId: 'it_IT', onResult: (_, _) {}),
      throwsStateError,
    );
    expect(calls.map((c) => c.method), ['initialize']);
    expect(speech.calls, isEmpty);
  });

  test(
    'local Android failure is returned without retrying a default recognizer',
    () async {
      final speech = SpeechFake();
      final voice = OfflineVoice(
        platform: TargetPlatform.android,
        speech: speech,
      );
      await voice.initialize(onStatus: (_) {}, onError: (_) {});
      failed = true;
      await expectLater(
        voice.listen(localeId: 'en_US', onResult: (_, _) {}),
        throwsA(isA<PlatformException>()),
      );
      expect(calls.map((c) => c.method), ['initialize', 'listen']);
      expect(speech.calls, isEmpty);
    },
  );

  test(
    'stopped or previous Android sessions cannot inject search text',
    () async {
      final voice = OfflineVoice(platform: TargetPlatform.android);
      final results = <String>[];
      await voice.initialize(onStatus: (_) {}, onError: (_) {});
      await voice.listen(
        localeId: 'it_IT',
        onResult: (text, _) => results.add(text),
      );
      final old = (calls.last.arguments as Map)['sessionId'] as String;
      await voice.stop();
      await event(old, 'stale');
      await voice.listen(
        localeId: 'it_IT',
        onResult: (text, _) => results.add(text),
      );
      final current = (calls.last.arguments as Map)['sessionId'] as String;
      await event(old, 'also stale');
      await event(current, 'current');
      expect(results, ['current']);
      await voice.stop();
    },
  );

  test(
    'iOS always requires on-device recognition and propagates unsupported languages',
    () async {
      final speech = SpeechFake();
      final voice = OfflineVoice(platform: TargetPlatform.iOS, speech: speech);
      await voice.initialize(onStatus: (_) {}, onError: (_) {});
      for (final locale in ['it_IT', 'en_US']) {
        await voice.listen(localeId: locale, onResult: (_, _) {});
        final options =
            speech.calls.last.namedArguments[#listenOptions]
                as SpeechListenOptions;
        expect(options.onDevice, isTrue);
        expect(options.cancelOnError, isTrue);
        expect(options.localeId, locale);
      }
      speech.fail = true;
      await expectLater(
        voice.listen(localeId: 'it_IT', onResult: (_, _) {}),
        throwsA(isA<PlatformException>()),
      );
      expect(speech.calls.where((c) => c.memberName == #listen).length, 3);
      expect(calls, isEmpty);
    },
  );
}
