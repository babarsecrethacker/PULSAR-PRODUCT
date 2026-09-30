import 'dart:io';

class LanServerService {
  Process? _process;

  bool get isRunning => _process != null;

  Future<void> start() async {
    if (!Platform.isWindows) return;

    if (_process != null) {
      return;
    }

    final executable = File(
      '${Directory.current.path}\\server\\pulsar_server.exe',
    );

    if (!await executable.exists()) {
      throw Exception(
        'PULSAR server executable not found: ${executable.path}',
      );
    }

    _process = await Process.start(
      executable.path,
      [],
      runInShell: true,
    );

    _process!.stdout
        .transform(const SystemEncoding().decoder)
        .listen((data) {
      print('[PULSAR SERVER] $data');
    });

    _process!.stderr
        .transform(const SystemEncoding().decoder)
        .listen((data) {
      print('[PULSAR SERVER ERROR] $data');
    });

    _process!.exitCode.then((code) {
      print('[PULSAR SERVER] exited with code $code');
      _process = null;
    });
  }

  Future<void> stop() async {
    if (_process == null) return;

    _process!.kill();
    _process = null;
  }
}