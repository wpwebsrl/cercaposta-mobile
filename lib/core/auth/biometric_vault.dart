import 'dart:io';

import 'package:biometric_storage/biometric_storage.dart';

import '../api/api_exception.dart';

/// Every secret read is authorized by the native cryptographic operation.
/// The ordinary session store remains separate for background refreshes.
abstract interface class BiometricVault {
  Future<String?> read(
    String name, {
    required String reason,
    required String cancel,
  });
  Future<void> write(
    String name,
    String value, {
    required String reason,
    required String cancel,
  });
  Future<void> delete(String name);
}

class NativeBiometricVault implements BiometricVault {
  Future<BiometricStorageFile> _file(String name) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw ApiException('biometric.unavailable');
    }
    return BiometricStorage().getStorage(
      name,
      options: StorageFileInitOptions(
        authenticationRequired: true,
        authenticationValidityDurationSeconds: -1,
        androidBiometricOnly: true,
        darwinBiometricOnly: true,
      ),
    );
  }

  PromptInfo _prompt(String reason, String cancel) => PromptInfo(
    androidPromptInfo: AndroidPromptInfo(title: reason, negativeButton: cancel),
    iosPromptInfo: IosPromptInfo(saveTitle: reason, accessTitle: reason),
  );

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthException catch (error) {
      if (error.code == AuthExceptionCode.userCanceled ||
          error.code == AuthExceptionCode.canceled ||
          error.code == AuthExceptionCode.timeout) {
        throw ApiException('biometric.cancelled');
      }
      throw ApiException('biometric.unavailable');
    } on Object {
      // Never expose native diagnostics or fall back to unauthenticated storage.
      throw ApiException('biometric.unavailable');
    }
  }

  @override
  Future<String?> read(
    String name, {
    required String reason,
    required String cancel,
  }) => _run(
    () async => (await _file(name)).read(promptInfo: _prompt(reason, cancel)),
  );

  @override
  Future<void> write(
    String name,
    String value, {
    required String reason,
    required String cancel,
  }) => _run(() async {
    final file = await _file(name);
    final prompt = _prompt(reason, cancel);
    await file.write(value, promptInfo: prompt);
    // SecItemAdd can create an ACL-protected item without a prompt. Reading it
    // back proves the ACL is usable and requests presence before publishing enrollment.
    if (Platform.isIOS && await file.read(promptInfo: prompt) != value) {
      throw ApiException('biometric.unavailable');
    }
  });

  @override
  Future<void> delete(String name) =>
      _run(() async => (await _file(name)).delete());
}
