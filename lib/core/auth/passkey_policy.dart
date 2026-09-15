import '../api/api_exception.dart';

// Keep in sync with Runner.entitlements; tests compare the shipped domains.
const iosPasskeyDomains = <String>{'app.cercaposta.it'};

bool passkeyServerSupported(String client, String? server) {
  final uri = Uri.tryParse(server ?? '');
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return false;
  }
  return client != 'ios' || iosPasskeyDomains.contains(uri.host.toLowerCase());
}

void requirePasskeyServer(String client, String? server, {String? rpId}) {
  final host = Uri.tryParse(server ?? '')?.host.toLowerCase() ?? '';
  final rp = rpId?.toLowerCase();
  if (!passkeyServerSupported(client, server) ||
      (rp != null &&
          (rp.isEmpty ||
              !(host == rp || host.endsWith('.$rp')) ||
              (client == 'ios' && !iosPasskeyDomains.contains(rp))))) {
    throw ApiException('passkeys.domain_not_associated');
  }
}
