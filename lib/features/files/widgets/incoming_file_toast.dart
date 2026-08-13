import 'package:flutter/material.dart';

class IncomingFileToast extends StatelessWidget {
  final String sender;
  final String fileName;
  final int fileSize;

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingFileToast({
    super.key,
    required this.sender,
    required this.fileName,
    required this.fileSize,
    required this.onAccept,
    required this.onDecline,
  });

  String readableSize() {
    if (fileSize > 1024 * 1024) {
      return "${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB";
    }

    if (fileSize > 1024) {
      return "${(fileSize / 1024).toStringAsFixed(1)} KB";
    }

    return "$fileSize B";
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 25,
      left: 25,

      child: Material(
        color: Colors.transparent,

        child: TweenAnimationBuilder(

          duration: const Duration(milliseconds: 450),

          tween: Tween(
            begin: const Offset(-350, 0),
            end: Offset.zero,
          ),

          builder: (context, Offset value, child) {

            return Transform.translate(
              offset: value,
              child: child,
            );

          },

          child: Container(

            width: 340,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(

              color: const Color(0xff151B2D),

              borderRadius: BorderRadius.circular(24),

              border: Border.all(
                color: const Color(0xff6C63FF),
              ),

              boxShadow: const [

                BoxShadow(

                  color: Colors.black54,

                  blurRadius: 25,

                  offset: Offset(0, 10),

                ),

              ],

            ),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    const Icon(
                      Icons.folder_zip,
                      color: Color(0xff7E74FF),
                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      child: Text(

                        fileName,

                        style: const TextStyle(

                          color: Colors.white,

                          fontWeight: FontWeight.bold,

                          fontSize: 16,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 14),

                Text(

                  "$sender wants to send you a file.",

                  style: const TextStyle(
                    color: Colors.white70,
                  ),

                ),

                const SizedBox(height: 8),

                Text(

                  readableSize(),

                  style: const TextStyle(

                    color: Colors.white54,

                  ),

                ),

                const SizedBox(height: 18),

                Row(

                  children: [

                    Expanded(

                      child: ElevatedButton(

                        onPressed: onAccept,

                        style: ElevatedButton.styleFrom(

                          backgroundColor:
                              const Color(0xff6C63FF),

                        ),

                        child: const Text("Accept"),

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child: ElevatedButton(

                        onPressed: onDecline,

                        style: ElevatedButton.styleFrom(

                          backgroundColor:
                              Colors.redAccent,

                        ),

                        child: const Text("Decline"),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ),

      ),

    );
  }
}