import 'dart:convert';
import 'dart:math';

/// Retrying the same user-confirmed message reuses its durable server identity.
class SendIdentity {
  String _payload = '';
  String _id = '';
  String forPayload(Map<String, Object?> payload) {
    final encoded = jsonEncode(payload);
    if (_payload != encoded) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 0x0f) | 0x40;
      bytes[8] = (bytes[8] & 0x3f) | 0x80;
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      _id =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      _payload = encoded;
    }
    return _id;
  }
}
