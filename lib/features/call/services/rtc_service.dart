import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/services/websocket_service.dart';

class RTCService {
  RTCService._();

  static final RTCService _instance = RTCService._();

  factory RTCService() => _instance;

  String? _remoteUsername;

  RTCPeerConnection? peerConnection;

  MediaStream? localStream;
  MediaStream? remoteStream;

  final RTCVideoRenderer localRenderer =
      RTCVideoRenderer();

  final RTCVideoRenderer remoteRenderer =
      RTCVideoRenderer();

  final _remoteConnected =
      StreamController<bool>.broadcast();

  Stream<bool> get remoteConnected =>
      _remoteConnected.stream;

  bool _closing = false;

  void setRemoteUser(String username) {
    _remoteUsername = username;
  }

  // ---------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------

  Future<void> initialize() async {
    if (peerConnection != null) {
      print("⚠️ RTC already initialized");
      return;
    }

    _closing = false;

    await localRenderer.initialize();
    await remoteRenderer.initialize();

    localStream =
        await navigator.mediaDevices.getUserMedia({
      "audio": {
        "echoCancellation": true,
        "noiseSuppression": false,
        "autoGainControl": false,
      },
      "video": false,
    });

    for (final track
        in localStream!.getAudioTracks()) {
      track.enabled = true;

      print("========== LOCAL MIC ==========");
      print("Track ID: ${track.id}");
      print("Kind: ${track.kind}");
      print("Enabled: ${track.enabled}");
    }

    peerConnection =
        await createPeerConnection({
      "iceServers": [
        {
          "urls": [
            "stun:stun.l.google.com:19302",
          ],
        },
      ],
      "sdpSemantics": "unified-plan",
      "bundlePolicy": "max-bundle",
      "rtcpMuxPolicy": "require",
    });

    for (final track
        in localStream!.getTracks()) {
      await peerConnection!.addTrack(
        track,
        localStream!,
      );
    }

    peerConnection!.onTrack = (event) {
      if (_closing) return;

      if (event.streams.isNotEmpty) {
        remoteStream =
            event.streams.first;

        remoteRenderer.srcObject =
            remoteStream;

        print(
          "🔊 Remote audio tracks: "
          "${remoteStream!.getAudioTracks().length}",
        );

        _remoteConnected.add(true);
      }
    };

    peerConnection!.onIceCandidate =
        (candidate) {
      if (_closing) return;

      if (candidate == null) {
        return;
      }

      final username =
          _remoteUsername;

      if (username == null ||
          username.isEmpty) {
        return;
      }

      WebSocketService().sendCandidate(
        username,
        candidate.toMap(),
      );
    };

    print("✅ RTC Initialized");
  }

  // ---------------------------------------------------------
  // OFFER
  // ---------------------------------------------------------

  Future<Map<String, dynamic>>
      createOffer() async {
    if (peerConnection == null) {
      throw StateError(
        "RTC is not initialized",
      );
    }

    final offer =
        await peerConnection!.createOffer();

    await peerConnection!
        .setLocalDescription(offer);

    return {
      "type": offer.type,
      "sdp": offer.sdp,
    };
  }

  // ---------------------------------------------------------
  // ANSWER
  // ---------------------------------------------------------

  Future<Map<String, dynamic>>
      createAnswer() async {
    if (peerConnection == null) {
      throw StateError(
        "RTC is not initialized",
      );
    }

    final answer =
        await peerConnection!.createAnswer();

    await peerConnection!
        .setLocalDescription(answer);

    return {
      "type": answer.type,
      "sdp": answer.sdp,
    };
  }

  // ---------------------------------------------------------
  // REMOTE DESCRIPTION
  // ---------------------------------------------------------

  Future<void> setRemoteDescription(
    Map<String, dynamic> data,
  ) async {
    if (_closing) return;

    final pc = peerConnection;

    if (pc == null) {
      print(
        "❌ PeerConnection is null",
      );
      return;
    }

    if (data["sdp"] == null ||
        data["type"] == null) {
      print("❌ Invalid SDP");
      return;
    }

    try {
      await pc.setRemoteDescription(
        RTCSessionDescription(
          data["sdp"],
          data["type"],
        ),
      );

      print(
        "✅ Remote Description Set",
      );
    } catch (e) {
      print(
        "❌ Remote Description Error: $e",
      );
    }
  }

  // ---------------------------------------------------------
  // ICE
  // ---------------------------------------------------------

  Future<void> addCandidate(
    Map<String, dynamic> data,
  ) async {
    if (_closing) return;

    final pc = peerConnection;

    if (pc == null) {
      print(
        "⚠️ Ignoring candidate: "
        "RTC is not active",
      );
      return;
    }

    if (data["candidate"] == null) {
      return;
    }

    try {
      final candidate =
          RTCIceCandidate(
        data["candidate"],
        data["sdpMid"],
        data["sdpMLineIndex"],
      );

      await pc.addCandidate(
        candidate,
      );

      print(
        "✅ ICE Candidate Added",
      );
    } catch (e) {
      print(
        "❌ Candidate Error: $e",
      );
    }
  }

  // ---------------------------------------------------------
  // HARD CLOSE
  // ---------------------------------------------------------

  Future<void> close() async {
    if (_closing) {
      return;
    }

    _closing = true;

    print(
      "🛑 HARD RTC SHUTDOWN",
    );

    // Stop microphone FIRST.
    final local =
        localStream;

    if (local != null) {
      for (final track
          in local.getTracks()) {
        try {
          track.enabled = false;
          await track.stop();
        } catch (e) {
          print(
            "⚠️ Local track stop: $e",
          );
        }
      }
    }

    // Stop remote tracks.
    final remote =
        remoteStream;

    if (remote != null) {
      for (final track
          in remote.getTracks()) {
        try {
          track.enabled = false;
          await track.stop();
        } catch (e) {
          print(
            "⚠️ Remote track stop: $e",
          );
        }
      }
    }

    try {
      localRenderer.srcObject =
          null;
    } catch (_) {}

    try {
      remoteRenderer.srcObject =
          null;
    } catch (_) {}

    final pc =
        peerConnection;

    peerConnection = null;

    localStream = null;
    remoteStream = null;
    _remoteUsername = null;

    if (pc != null) {
      try {
        await pc.close();
      } catch (e) {
        print(
          "⚠️ Peer close: $e",
        );
      }

      try {
        await pc.dispose();
      } catch (e) {
        print(
          "⚠️ Peer dispose: $e",
        );
      }
    }

    _remoteConnected.add(false);

    print(
      "✅ RTC COMPLETELY CLOSED",
    );
  }
}