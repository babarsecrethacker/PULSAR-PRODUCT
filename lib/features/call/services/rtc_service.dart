import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/services/websocket_service.dart';


class RTCService {

  RTCService._();

  static final RTCService _instance =
      RTCService._();

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

      void setRemoteUser(String username) {
  _remoteUsername = username;
}



  //-----------------------------------------
  // INITIALIZE RTC
  //-----------------------------------------

  Future<void> initialize() async {


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

for (final track in localStream!.getAudioTracks()) {
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
        "stun:stun.l.google.com:19302"
      ]
    }
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
  print("========== REMOTE TRACK ==========");
  print("Kind: ${event.track.kind}");
  print("Enabled: ${event.track.enabled}");
  print("Streams: ${event.streams.length}");

  if (event.streams.isNotEmpty) {
    remoteStream = event.streams.first;

    remoteRenderer.srcObject = remoteStream;

    print(
      "Remote audio tracks: ${remoteStream!.getAudioTracks().length}",
    );

    for (final t in remoteStream!.getAudioTracks()) {
      print("Track enabled: ${t.enabled}");
    }

    _remoteConnected.add(true);
  }
};



    peerConnection!.onIceCandidate = (candidate) {
  if (candidate == null) return;

  if (_remoteUsername != null) {
    WebSocketService().sendCandidate(
      _remoteUsername!,
      candidate.toMap(),
    );
  }
};



    print(
      "✅ RTC Initialized",
    );

  }




  //-----------------------------------------
  // CREATE OFFER
  //-----------------------------------------

  Future<Map<String,dynamic>>
      createOffer() async {


    final offer =
        await peerConnection!
            .createOffer();


    await peerConnection!
        .setLocalDescription(
          offer,
        );


    return {

      "type": offer.type,

      "sdp": offer.sdp,

    };

  }





  //-----------------------------------------
  // CREATE ANSWER
  //-----------------------------------------

  Future<Map<String,dynamic>>
      createAnswer() async {


    final answer =
        await peerConnection!
            .createAnswer();


    await peerConnection!
        .setLocalDescription(
          answer,
        );


    return {

      "type": answer.type,

      "sdp": answer.sdp,

    };

  }





  //-----------------------------------------
  // SET REMOTE DESCRIPTION
  //-----------------------------------------

  Future<void> setRemoteDescription(
  Map<String, dynamic> data,
) async {

  if (peerConnection == null) {
    print("❌ PeerConnection is null");
    return;
  }

  if (data["sdp"] == null || data["type"] == null) {
    print("❌ Invalid SDP");
    return;
  }

  final description = RTCSessionDescription(
    data["sdp"],
    data["type"],
  );

  try {

    await peerConnection!.setRemoteDescription(
      description,
    );

    print("✅ Remote Description Set");

  } catch (e) {

    print("❌ Remote Description Error: $e");

  }
}





  //-----------------------------------------
  // ADD ICE CANDIDATE
  //-----------------------------------------

  Future<void> addCandidate(
  Map<String, dynamic> data,
) async {

  if (peerConnection == null) {
    print("❌ PeerConnection is null");
    return;
  }

  if (data["candidate"] == null) {
    print("❌ Candidate is null");
    return;
  }

  final candidate = RTCIceCandidate(
    data["candidate"],
    data["sdpMid"],
    data["sdpMLineIndex"],
  );

  try {

    await peerConnection!.addCandidate(candidate);

    print("✅ ICE Candidate Added");

  } catch (e) {

    print("❌ Candidate Error: $e");

  }
}





  //-----------------------------------------
  // CLOSE CALL
  //-----------------------------------------

  Future<void> close() async {


    await localStream?.dispose();

    await remoteStream?.dispose();


    await peerConnection?.close();


    peerConnection = null;


    print(
      "📴 RTC Closed",
    );

  }

}