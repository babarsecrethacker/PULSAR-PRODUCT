import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioBase64;
  final bool isMine;

  const VoiceMessageBubble({
    super.key,
    required this.audioBase64,
    required this.isMine,
  });

  @override
  State<VoiceMessageBubble> createState() =>
      _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState
    extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _loaded = false;
  bool _playing = false;

  String? _tempPath;

  @override
  void initState() {
    super.initState();

    _prepare();

    _player.durationStream.listen((d) {
      if (!mounted) return;

      setState(() {
        _duration = d ?? Duration.zero;
      });
    });

    _player.positionStream.listen((p) {
      if (!mounted) return;

      setState(() {
        _position = p;
      });
    });

    _player.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _playing = state.playing;

        if (state.processingState ==
            ProcessingState.completed) {
          _player.seek(Duration.zero);
        }
      });
    });
  }

  Future<void> _prepare() async {
    try {
      final bytes =
          base64Decode(widget.audioBase64);

      final dir =
          await getTemporaryDirectory();

      final file = File(
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a",
      );

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      _tempPath = file.path;

      await _player.setFilePath(file.path);

      if (!mounted) return;

      setState(() {
        _loaded = true;
      });

    } catch (e) {
      debugPrint(
        "Voice prepare error: $e",
      );
    }
  }

  Future<void> _toggle() async {
    if (!_loaded) return;

    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _time(Duration d) {
    final m =
        d.inMinutes.toString().padLeft(2, '0');

    final s =
        (d.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return "$m:$s";
  }

    @override
  Widget build(BuildContext context) {
    final max =
        _duration.inMilliseconds == 0
            ? 1.0
            : _duration.inMilliseconds.toDouble();

    final value =
        _position.inMilliseconds
            .toDouble()
            .clamp(0.0, max);

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: widget.isMine
            ? const Color(0xFF6C63FF)
            : const Color(0xFF1A2335),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            children: [

              InkWell(
                borderRadius:
                    BorderRadius.circular(50),
                onTap: _toggle,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context)
                      .copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape:
                        SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: max,
                    activeColor: Colors.white,
                    inactiveColor:
                        Colors.white24,
                    onChanged: (v) async {
                      await _player.seek(
                        Duration(
                          milliseconds:
                              v.toInt(),
                        ),
                      );
                    },
                  ),
                ),
              ),

            ],
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              Text(
                _time(_position),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),

              Text(
                _time(_duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),

            ],
          ),

                  ],
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();

    if (_tempPath != null) {
      try {
        final file = File(_tempPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Ignore cleanup errors.
      }
    }

    super.dispose();
  }
}