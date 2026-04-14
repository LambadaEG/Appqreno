import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createRoom(String roomCode, String hostName) async {
  await FirebaseFirestore.instance.collection('rooms').doc(roomCode).set({
    'status': 'waiting',

    'mode': 'Classic',

    'players': [
      {
        'name': hostName,
        'isReady': false,
        'score': 0,
        'isHost': true,
      }
    ],

    'createdAt': FieldValue.serverTimestamp(), // Good for cleaning up old rooms
  });
}
