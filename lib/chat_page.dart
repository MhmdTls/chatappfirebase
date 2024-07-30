import 'dart:async';
import 'package:chatappfirbase/chat_bubble.dart';
import 'package:chatappfirbase/chat_service.dart';
import 'package:chatappfirbase/login_page.dart';
import 'package:chatappfirbase/text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:translator/translator.dart';


class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const ChatPage({
    Key? key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedMessages = {};
  final translator = GoogleTranslator();

  bool _isSelectionMode = false;
  bool _isUploading = false;
  double _uploadProgress = 0;



  void _scheduleMessage() {
    if (_messageController.text.isNotEmpty) {
      DatePickerBdaya.showDateTimePicker(
        context,
        showTitleActions: true,
        onConfirm: (dateTime) {

          DateTime scheduledTime = dateTime;


          Duration delay = scheduledTime.difference(DateTime.now());


          Timer(delay, () async {
            await _chatService.sendMessage(widget.receiverUserID, _messageController.text);
            _messageController.clear();
            _scrollToBottom();
          });


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message scheduled for ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}'),
            ),
          );
        },
        currentTime: DateTime.now(),
      );
    }
  }









  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverUserID, _messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }



  void sendImage() async {
    setState(() {
      _isUploading = true;
    });

    _chatService.uploadProgressStream.listen((progress) {
      setState(() {
        _uploadProgress = progress;
      });
    });

    await _chatService.sendImage(widget.receiverUserID);
     // Notify the receiver

    setState(() {
      _isUploading = false;
    });

    _scrollToBottom();
  }


  void sendVideo() async {
    setState(() {
      _isUploading = true;
    });

    _chatService.uploadProgressStream.listen((progress) {
      setState(() {
        _uploadProgress = progress;
      });
    });

    await _chatService.sendVideo(widget.receiverUserID);

    setState(() {
      _isUploading = false;
    });

    _scrollToBottom();
  }



  void deleteSelectedMessages() async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    for (var messageId in _selectedMessages) {
      await _chatService.deleteMessage(messageId, currentUserId, widget.receiverUserID);
    }
    setState(() {
      _selectedMessages.clear();
      _isSelectionMode = false;
    });
  }


  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }

      _isSelectionMode = _selectedMessages.isNotEmpty;
    });
  }

  void _showTranslateOptions(String message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: <Widget>[
            ListTile(
              title: Text('Translate to Arabic'),
              onTap: () => _translateMessage(message, 'ar'),
            ),
            ListTile(
              title: Text('Translate to English'),
              onTap: () => _translateMessage(message, 'en'),
            ),
            ListTile(
              title: Text('Translate to German'),
              onTap: () => _translateMessage(message, 'de'),
            ),
            ListTile(
              title: Text('Translate to Spanish'),
              onTap: () => _translateMessage(message, 'es'),
            ),
          ],
        );
      },
    );
  }

  void _translateMessage(String message, String targetLang) async {
    var translation = await translator.translate(message, to: targetLang);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Translated Message'),
          content: Text(translation.text),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF182E4C),
      appBar: AppBar(
        title: Text(widget.receiverUserEmail),
        backgroundColor: const Color(0xFF182E4C),
        actions: _isSelectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteSelectedMessages,
          ),
        ]
            : [],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
          _buildMessageInput(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverUserID, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ' + snapshot.error.toString()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        WidgetsBinding.instance!.addPostFrameCallback((_) => _scrollToBottom());

        List<DocumentSnapshot> docs = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        DateTime? lastDate;

        for (var document in docs) {
          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
          DateTime messageDate = (data['timestamp'] as Timestamp).toDate();
          if (lastDate == null || !isSameDate(lastDate, messageDate)) {
            messageWidgets.add(
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(messageDate),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, backgroundColor: Colors.white),
                    ),
                  ),
                ),
              ),
            );
            lastDate = messageDate;
          }
          messageWidgets.add(_buildMessageItem(document));
        }

        return ListView(
          controller: _scrollController,
          children: messageWidgets,
        );
      },
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid) ? Alignment.centerRight : Alignment.centerLeft;
    var bubbleColor = (data['senderId'] == _firebaseAuth.currentUser!.uid) ? const Color(0xFF1E88E5) : Colors.black38;
    var textColor = (data['senderId'] == _firebaseAuth.currentUser!.uid) ? Colors.white : Colors.black;
    DateTime messageTime = (data['timestamp'] as Timestamp).toDate();

    return GestureDetector(
      onLongPress: () {
        _toggleSelection(document.id);
      },

      child: Container(
        alignment: alignment,
        color: _selectedMessages.contains(document.id) ? Colors.grey[300] : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),


          child: Row(
            mainAxisAlignment: alignment == Alignment.centerRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (alignment == Alignment.centerRight && data['message'] != null)
                IconButton(
                  icon: const Icon(Icons.translate,size: 18,),
                  color: Colors.white,
                  onPressed: () => _showTranslateOptions(data['message']),
                ),
              ChatBubble(
                message: data['message'],
                imageUrl: data['imageUrl'],
                videoUrl: data['videoUrl'],
                color: bubbleColor,
                time: DateFormat('hh:mm a').format(messageTime),
              ),
              if (alignment == Alignment.centerLeft && data['message'] != null)
                IconButton(
                  icon: const Icon(Icons.translate,size: 18,),
                  color: btnColor,

                  onPressed: () => _showTranslateOptions(data['message']),
                ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, size: 33,),
            color: btnColor,
            onPressed: sendImage,
          ),
          IconButton(
            icon: const Icon(Icons.slow_motion_video, size: 33,),
            color: btnColor,
            onPressed: sendVideo,
          ),
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: 'Enter message',
              obscureText: false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 33,),
            color: btnColor,
            onPressed: sendMessage,
          ),
          IconButton(
            icon: const Icon(Icons.schedule, size: 33,),
            color: btnColor,
            onPressed: _scheduleMessage,
          ),
        ],
      ),
    );
  }
}
