import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IndividualChatScreen extends StatefulWidget {
  final String otherUserId; // The ID of the user you're chatting with

  IndividualChatScreen(this.otherUserId);

  @override
  _IndividualChatScreenState createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final otherUser = FirebaseFirestore.instance.collection('users').;

    return Scaffold(
      appBar: AppBar(
        title: Text('${}'), // Replace with the user's name
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: _firestore
                  .collection('messages')
                  .doc(_getChatId())
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                List<DocumentSnapshot> messages = snapshot.data!.docs;
                List<Widget> messageWidgets = [];
                for (var message in messages) {
                  final messageText = message['text'];
                  final messageSender = message['senderId'];

                  final messageWidget = MessageWidget(
                    text: messageText,
                    isMe: _auth.currentUser!.uid == messageSender,
                  );

                  messageWidgets.add(messageWidget);
                }
                return ListView(
                  children: messageWidgets,
                );
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Colors.blue),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: 'Send a message'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      _firestore.collection('messages').doc(_getChatId()).collection('messages').add({
        'text': text,
        'senderId': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _textController.clear();
    }
  }

  String _getChatId() {
    // Create a chat room ID based on user IDs to ensure uniqueness
    List<String> userIds = [widget.otherUserId, _auth.currentUser!.uid];
    userIds.sort();
    return userIds.join('_');
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isMe;

  MessageWidget({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey,
              borderRadius: isMe
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    )
                  : const BorderRadius.only(
                      topRight: Radius.circular(20.0),
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
            ),
            child: Text(
              text,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
