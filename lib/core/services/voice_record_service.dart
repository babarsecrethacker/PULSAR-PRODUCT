import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:flutter/foundation.dart';

class VoiceRecordService {
  VoiceRecordService._();

  static final VoiceRecordService _instance =
      VoiceRecordService._();

  factory VoiceRecordService() => _instance;

  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> get isRecording =>
    _recorder.isRecording();

  Future<void> start() async {
  if (!await _recorder.hasPermission()) {
    throw Exception("Microphone permission denied");
  }

  final dir = await getTemporaryDirectory();

  final path =
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.wav";

  await _recorder.start(
    const RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 44100,
      numChannels: 1,
      bitRate: 128000,
    ),
    path: path,
  );

  print("Recording to:");
  print(path);
}

Future<String?> stop() async {
  final path = await _recorder.stop();

  if (path == null) {
    print("No recording path");
    return null;
  }

  final file = File(path);

  if (!await file.exists()) {
    print("File doesn't exist");
    return null;
  }

  final bytes = await file.readAsBytes();

  print("Recorded bytes: ${bytes.length}");

  return base64Encode(bytes);
}
}