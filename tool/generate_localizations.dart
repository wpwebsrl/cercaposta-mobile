import 'dart:io';

/// Keep generated catalogs reproducible under the same formatter used by CI.
Future<void> main() async {
  final generated = await Process.run(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    ['gen-l10n'],
    runInShell: Platform.isWindows,
  );
  stdout.write(generated.stdout);
  stderr.write(generated.stderr);
  if (generated.exitCode != 0) exit(generated.exitCode);
  final formatted = await Process.run(Platform.resolvedExecutable, [
    'format',
    'lib/core/i18n',
  ]);
  stdout.write(formatted.stdout);
  stderr.write(formatted.stderr);
  exitCode = formatted.exitCode;
}
