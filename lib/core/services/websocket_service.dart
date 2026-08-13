import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message.dart';
import '../../features/call/services/rtc_service.dart';


class WebSocketService {

  WebSocketService._();

  static final WebSocketService _instance =
      WebSocketService._();

  factory WebSocketService() => _instance;


  WebSocketChannel? _channel;


  bool _connected = false;
  List<String> _cachedUsers = [];

List<String> get cachedUsers =>
    List.unmodifiable(_cachedUsers);


  String? _myUsername;



  //-----------------------------------------
  // MESSAGE STORAGE
  //-----------------------------------------

  final List<ChatMessage> _messages = [];


  List<ChatMessage> get messages =>
      List.unmodifiable(
        _messages,
      );



  //-----------------------------------------
  // CONVERSATION STORAGE
  //-----------------------------------------

  final Map<String, List<ChatMessage>>
      _conversationStorage = {};



  final StreamController<
      Map<String, List<ChatMessage>>>
      _conversationsController =
      StreamController.broadcast();



  Stream<Map<String, List<ChatMessage>>>
      get conversations =>
          _conversationsController.stream;



  List<ChatMessage> conversationWith(
      String username,
  ) {

    return _conversationStorage[username] ?? [];

  }




  //-----------------------------------------
  // STREAM CONTROLLERS
  //-----------------------------------------

  final _usersController =
      StreamController<List<String>>.broadcast();


  Stream<List<String>> get users =>
      _usersController.stream;



  final _messageController =
      StreamController<ChatMessage>.broadcast();


  Stream<ChatMessage> get messageStream =>
      _messageController.stream;




  //-----------------------------------------
  // CALL STREAMS
  //-----------------------------------------

  final _incomingFiles =
    StreamController<Map<String, dynamic>>.broadcast();

Stream<Map<String, dynamic>> get incomingFiles =>
    _incomingFiles.stream;

  final _incomingCalls =
      StreamController<String>.broadcast();


  Stream<String> get incomingCalls =>
      _incomingCalls.stream;



  final _callAccepted =
      StreamController<String>.broadcast();


  Stream<String> get callAccepted =>
      _callAccepted.stream;



  final _callRejected =
      StreamController<String>.broadcast();


  Stream<String> get callRejected =>
      _callRejected.stream;



  final _callEnded =
      StreamController<String>.broadcast();


  Stream<String> get callEnded =>
      _callEnded.stream;

        //-----------------------------------------
  // CONNECT
  //-----------------------------------------

  void connect({
    required String username,
  }) {

    if (_connected) {
      return;
    }


    _myUsername = username;


    print("==============================");
    print("NOVA WebSocket");
    print("Username: $username");
    print("==============================");


    _channel = WebSocketChannel.connect(

      Uri.parse(
        "ws://127.0.0.1:8080/ws",
      ),

    );


    _connected = true;


    print(
      "Connected to NOVA Server",
    );



    _channel!.sink.add(

      jsonEncode({

        "type":
            "register",

        "username":
            username,

      }),

    );


    print(
      "Register sent",
    );



    _listen();

  }

  // Send File offer

  void sendFileOffer({
  required String to,
  required String name,
  required int size,
}) {
  sendRaw({
    "type": "file_offer",
    "from": _myUsername,
    "to": to,
    "name": name,
    "size": size,
  });
}





  //-----------------------------------------
  // LISTEN
  //-----------------------------------------

  void _listen() {


    _channel!.stream.listen(

      (data) async {


        print(
          "⬇ Received: $data",
        );


        try {


          final packet =
              jsonDecode(
                data.toString(),
              );



          switch(packet["type"]) {



            //--------------------------------
            // USERS
            //--------------------------------

            case "users":


              final list =
    List<String>.from(
      packet["users"] ?? [],
    );

_cachedUsers = list;

_usersController.add(_cachedUsers);

  break;





            //--------------------------------
            // MESSAGE
            //--------------------------------

            case "message":


              final msg =
                  ChatMessage.fromJson(
                    packet,
                  );


              _storeMessage(
                msg,
              );


              print(
                "💬 ${msg.from} -> ${msg.to}: ${msg.message}",
              );


              break;

              //--------------------------------
// VOICE
//--------------------------------

case "voice":

  final msg = ChatMessage.fromJson(
    packet,
  );

  _storeMessage(
    msg,
  );

  print(
    "🎤 Voice message from ${msg.from}",
  );

  break;





            //--------------------------------
            // CALL REQUEST
            //--------------------------------

            case "call_request":


              final from =
                  packet["from"];


              if(from != null){

                _incomingCalls.add(
                  from,
                );

              }


              break;





            //--------------------------------
            // CALL ACCEPT
            //--------------------------------

            case "call_accept":


              final from =
                  packet["from"];


              if(from != null){

                _callAccepted.add(
                  from,
                );

              }


              break;

                          //--------------------------------
            // CALL REJECT
            //--------------------------------

            case "call_reject":


              final from =
                  packet["from"];


              if(from != null){

                _callRejected.add(
                  from,
                );

              }


              break;





            //--------------------------------
            // CALL END
            //--------------------------------

            case "call_end":


              final from =
                  packet["from"];


              if(from != null){

                _callEnded.add(
                  from,
                );

              }


              break;

              case "file_offer":

  _incomingFiles.add(packet);

  break;





            //--------------------------------
            // RTC SIGNALS
            //--------------------------------

            case "offer":

  await RTCService().initialize();

  RTCService().setRemoteUser(
    packet["from"],
  );

  await RTCService().setRemoteDescription(
    packet["sdp"],
  );

  final answer =
      await RTCService().createAnswer();

  sendAnswer(
    packet["from"],
    answer,
  );

  break;





            case "answer":


              await RTCService()
    .setRemoteDescription(
      packet["sdp"],
    );


              break;





            case "candidate":


              await RTCService()
                  .addCandidate(

                    packet["candidate"],

                  );


              break;

          }


        } catch(e){

          print(
            "WebSocket parse error: $e",
          );

        }


      },



      onDone: () {


        _connected = false;


        print(
          "Disconnected from NOVA Server",
        );


      },



      onError: (error){


        print(
          "WebSocket error: $error",
        );


      },


    );


  }

  //-----------------------------------------
  // STORE MESSAGE
  //-----------------------------------------

  void _storeMessage(
      ChatMessage message,
  ){


    _messages.add(
      message,
    );



    final otherUser =
        message.from == _myUsername
            ? message.to
            : message.from;



    _conversationStorage.putIfAbsent(

      otherUser,

      () => [],

    );



    _conversationStorage[otherUser]!
        .add(

          message,

        );



    _conversationsController.add(

      _conversationStorage,

    );



    _messageController.add(

      message,

    );


  }

    //-----------------------------------------
  // SEND RAW DATA
  //-----------------------------------------

  void sendRaw(
      Map<String, dynamic> data,
  ){

    if(!_connected){
      return;
    }


    _channel?.sink.add(

      jsonEncode(
        data,
      ),

    );

  }





 //------------------------------
// SEND MESSAGE
//------------------------------

void sendMessage(
  ChatMessage message,
) {
  sendRaw(
    message.toJson(),
  );
}

void send({
  required String to,
  required String message,
}) {
  final chat = ChatMessage(
    from: _myUsername!,
    to: to,
    message: message,
    time: DateTime.now(),
  );

  sendMessage(chat);
}

  //-----------------------------------------
  // CALL FUNCTIONS
  //-----------------------------------------

  void callUser(
      String username,
  ){

    sendRaw({

      "type":
          "call_request",

      "from":
          _myUsername,

      "to":
          username,

    });

  }





  void acceptCall(
      String username,
  ){

    sendRaw({

      "type":
          "call_accept",

      "from":
          _myUsername,

      "to":
          username,

    });

  }





  void rejectCall(
      String username,
  ){

    sendRaw({

      "type":
          "call_reject",

      "from":
          _myUsername,

      "to":
          username,

    });

  }





  void endCall(
      String username,
  ){

    sendRaw({

      "type":
          "call_end",

      "from":
          _myUsername,

      "to":
          username,

    });

  }





  //-----------------------------------------
  // RTC SIGNALS
  //-----------------------------------------

  void sendOffer(
      String username,
      dynamic sdp,
  ){

    sendRaw({

      "type":
          "offer",

      "from":
          _myUsername,

      "to":
          username,

      "sdp":
          sdp,

    });

  }

  void sendVoice({
  required String to,
  required String audio,
}) {

  sendRaw({

    "type": "voice",

    "from": _myUsername,

    "to": to,

    "audio": audio,

    "time": DateTime.now().toIso8601String(),

  });

}





  void sendAnswer(
      String username,
      dynamic sdp,
  ){

    sendRaw({

      "type":
          "answer",

      "from":
          _myUsername,

      "to":
          username,

      "sdp":
          sdp,

    });

  }





  void sendCandidate(
      String username,
      dynamic candidate,
  ){

    sendRaw({

      "type":
          "candidate",

      "from":
          _myUsername,

      "to":
          username,

      "candidate":
          candidate,

    });

  }





  //-----------------------------------------
  // DISCONNECT
  //-----------------------------------------

  void disconnect(){

    _connected = false;


    _channel?.sink.close();


    _channel = null;


    print(
      "NOVA disconnected",
    );

  }



}