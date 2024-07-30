import 'package:chatappfirbase/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_page.dart';
import 'chat_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  void signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

  void startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  void stopSearch() {
    setState(() {
      isSearching = false;
      searchQuery = '';
      searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
          onChanged: updateSearchQuery,
        )
            : Text('QuickChat'),
        backgroundColor: const Color(0xFF182E4C),
        actions: [
          isSearching
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: stopSearch,
          )
              : IconButton(
            icon: const Icon(Icons.search),
            onPressed: startSearch,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF182E4C), // Dark blue color
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading..');
        }

        var users = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
          return data['email']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No users found', style: TextStyle(color: Colors.white)));
        }

        return ListView(
          children: users.map<Widget>((doc) => _buildUserListItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    if (_auth.currentUser!.email != data['email']) {
      return FutureBuilder<int>(
        future: _getUnreadMessageCount(data['uid']),
        builder: (context, snapshot) {
          int unreadCount = snapshot.data ?? 0;
          return ListTile(
            title: Text(
              data['email'],
              style: TextStyle(color: Colors.white),
            ),
            trailing: unreadCount > 0
                ? CircleAvatar(
              radius: 10,
              backgroundColor: Colors.blue,
              child: Text(
                unreadCount.toString(),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
                : null,
            onTap: () async {
              // Reset unread messages count
              await _chatService.resetUnreadMessages(data['uid'], _auth.currentUser!.uid);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverUserEmail: data['email'],
                    receiverUserID: data['uid'],
                  ),
                ),
              );
              setState(() {});
              },
          );
        },
      );
    } else {
      return Container();
    }
  }


  Future<int> _getUnreadMessageCount(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    final unreadMessages = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    return unreadMessages.size;
  }
}
