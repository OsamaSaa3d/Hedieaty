import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFriendsPage extends StatefulWidget {
  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  Set<String> outgoingRequests = {};
  Set<String> incomingRequests = {};
  Set<String> friends = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchOutgoingRequests();
    _fetchIncomingRequests();
    _fetchFriends();
  }

  // Fetch all users excluding friends
  Future<void> _fetchUsers() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final userSnapshot = await _firestore.collection('users').get();

      // Fetch the list of friends by checking both userId1 and userId2 fields
      final friendsSnapshot = await _firestore
          .collection('friends')
          .where('userId1', isEqualTo: currentUserId)
          .get();

      final friendsIds =
          friendsSnapshot.docs.map((doc) => doc['userId2'] as String).toSet();

      // Also check the second field (userId2) for friendships
      final friendsSnapshot2 = await _firestore
          .collection('friends')
          .where('userId2', isEqualTo: currentUserId)
          .get();

      friendsIds.addAll(
          friendsSnapshot2.docs.map((doc) => doc['userId1'] as String).toSet());

      setState(() {
        // Load all users excluding self and the users who are friends
        users = userSnapshot.docs
            .map((doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((user) =>
                user.id != currentUserId && // Exclude self
                !friendsIds.contains(user.id)) // Exclude friends
            .toList();
        filteredUsers = List.from(users);
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  // Fetch outgoing requests
  Future<void> _fetchOutgoingRequests() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final requestSnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        outgoingRequests = requestSnapshot.docs
            .map((doc) => doc['receiverId'] as String)
            .toSet();
      });
    } catch (e) {
      print("Error fetching outgoing requests: $e");
    }
  }

  // Fetch incoming requests
  Future<void> _fetchIncomingRequests() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final requestSnapshot = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        incomingRequests = requestSnapshot.docs
            .map((doc) => doc['senderId'] as String)
            .toSet();
      });
    } catch (e) {
      print("Error fetching incoming requests: $e");
    }
  }

  // Fetch friends
  Future<void> _fetchFriends() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final friendsSnapshot = await _firestore
          .collection('friends')
          .where('userId1', isEqualTo: currentUserId)
          .get();

      setState(() {
        friends =
            friendsSnapshot.docs.map((doc) => doc['userId2'] as String).toSet();
      });
    } catch (e) {
      print("Error fetching friends: $e");
    }
  }

  // Search users
  void _searchUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Send friend request
  Future<void> _sendFriendRequest(
      String receiverId, String receiverName, String receiverEmail) async {
    final senderId = _auth.currentUser?.uid;
    final senderEmail = _auth.currentUser?.email ?? "Unknown";
    String senderName = "Unknown";

    try {
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: senderEmail)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        senderName = userDoc.docs.first['name'];
      }

      await _firestore.collection('friendRequests').add({
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverEmail': receiverEmail,
        'status': 'pending',
      });

      setState(() {
        outgoingRequests.add(receiverId); // Add to outgoing requests
        // Instead of removing, mark the user card as "pending"
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request sent to $receiverName.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error sending request: $e")));
    }
  }

  // Cancel friend request
  Future<void> _cancelFriendRequest(String receiverId) async {
    final currentUserId = _auth.currentUser?.uid;

    try {
      final requestSnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestSnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        outgoingRequests.remove(receiverId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Friend request canceled.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error canceling request: $e")));
    }
  }

  // Accept friend request
  Future<void> _acceptFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;

    try {
      final requestSnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestSnapshot.docs) {
        await doc.reference.update({'status': 'accepted'});
      }

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUserName = currentUserDoc['name'];
      final currentUserEmail = currentUserDoc['email'];

      // Fetch sender user details
      final senderUserDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderUserName = senderUserDoc['name'];
      final senderUserEmail = senderUserDoc['email'];
      await _firestore.collection('friends').add({
        'userId1': senderId,
        'userId2': currentUserId,
        'userEmail1': senderUserEmail, // Add user email here
        'userEmail2': currentUserEmail, // Add user email here
        'userName1': senderUserName, // Add user name here
        'userName2': currentUserName, // Add user name here
      });

      setState(() {
        incomingRequests.remove(senderId);
        friends.add(senderId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Friend request accepted.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error accepting request: $e")));
    }
  }

  // Decline friend request
  Future<void> _declineFriendRequest(String senderId) async {
    try {
      final requestSnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestSnapshot.docs) {
        await doc.reference.update({'status': 'declined'});
      }

      setState(() {
        incomingRequests.remove(senderId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Friend request declined.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error declining request: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Friends")),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: _searchUsers,
                decoration:
                    InputDecoration(labelText: "Search by name or email"),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isOutgoingRequest =
                        outgoingRequests.contains(user.id);
                    final isIncomingRequest =
                        incomingRequests.contains(user.id);
                    final isFriend = friends.contains(user.id);

                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: isFriend
                            ? Text("Friend")
                            : isOutgoingRequest
                                ? ElevatedButton(
                                    onPressed: () =>
                                        _cancelFriendRequest(user.id),
                                    child: Text("Cancel Request"),
                                  )
                                : isIncomingRequest
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () =>
                                                _acceptFriendRequest(user.id),
                                            child: Text("Accept"),
                                          ),
                                          SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _declineFriendRequest(user.id),
                                            child: Text("Decline"),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _sendFriendRequest(
                                            user.id, user.name, user.email),
                                        child: Text("Send Request"),
                                      ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
