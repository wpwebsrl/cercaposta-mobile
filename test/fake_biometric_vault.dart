import 'dart:async';

import 'package:cercaposta/core/auth/biometric_vault.dart';

class FakeBiometricVault implements BiometricVault {
  final values = <String, String>{};
  int reads = 0;
  int writes = 0;
  Completer<void>? readEntered;
  Completer<void>? readRelease;
  Completer<void>? writeEntered;
  Completer<void>? writeRelease;
  Object? readError;
  Object? writeError;
  @override
  Future<String?> read(
    String name, {
    required String reason,
    required String cancel,
  }) async {
    reads++;
    readEntered?.complete();
    await readRelease?.future;
    if (readError != null) throw readError!;
    return values[name];
  }

  @override
  Future<void> write(
    String name,
    String value, {
    required String reason,
    required String cancel,
  }) async {
    writes++;
    writeEntered?.complete();
    await writeRelease?.future;
    if (writeError != null) throw writeError!;
    values[name] = value;
  }

  @override
  Future<void> delete(String name) async {
    values.remove(name);
  }
}
