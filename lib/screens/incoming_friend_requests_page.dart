import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncomingFriendRequestsPage extends StatefulWidget {
  @override
  _IncomingFriendRequestsPageState createState() =>
      _IncomingFriendRequestsPageState();
}

class _IncomingFriendRequestsPageState
    extends State<IncomingFriendRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> incomingRequests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchIncomingRequests();
  }

  Future<void> _fetchIncomingRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final requestsSnapshot = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final details = await Future.wait(
        requestsSnapshot.docs
            .map((doc) async {
              final data = doc.data();
              final senderId = data['senderId'] as String;
              final senderDoc =
                  await _firestore.collection('users').doc(senderId).get();
              if (senderDoc.exists) {
                return {
                  'requestId': doc.id,
                  'senderId': senderId,
                  'senderName': senderDoc['name'] ?? 'Unknown',
                  'senderEmail': senderDoc['email'] ?? 'Unknown',
                };
              }
              return null;
            })
            .where((data) => data != null)
            .toList(),
      );

      setState(() {
        incomingRequests = details.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching requests: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _acceptFriendRequest(String requestId, String senderId,
      String senderName, String senderEmail) async {
    final currentUserId = _auth.currentUser?.uid;
    final currentUserEmail = _auth.currentUser?.email ?? "Unknown";

    String currentUserName = "Unknown";

    try {
      // Query the 'users' collection to get the name based on the current user's email
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUserEmail)
          .limit(1) // Limit to 1 document
          .get();

      if (userDoc.docs.isNotEmpty) {
        currentUserName =
            userDoc.docs.first['name']; // Assuming 'name' field exists
      }

      // Update the friend request to 'accepted'
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
      });

      // Add both users to each other's friends list
      await _firestore.collection('friends').add({
        'userId1': currentUserId,
        'userId2': senderId,
        'userName1': currentUserName,
        'userName2': senderName,
        'userEmail1': currentUserEmail,
        'userEmail2': senderEmail,
      });

      // Remove the accepted request from the list
      setState(() {
        incomingRequests = incomingRequests
            .where((req) => req['requestId'] != requestId)
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request accepted.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Incoming Requests")),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : incomingRequests.isEmpty
                ? Center(child: Text("No incoming requests"))
                : ListView.builder(
                    itemCount: incomingRequests.length,
                    itemBuilder: (ctx, index) {
                      final req = incomingRequests[index];
                      return ListTile(
                        title: Text(req['senderName']),
                        subtitle: Text(req['senderEmail']),
                        trailing: ElevatedButton(
                          onPressed: () => _acceptFriendRequest(
                            req['requestId'],
                            req['senderId'],
                            req['senderName'],
                            req['senderEmail'],
                          ),
                          child: Text("Accept"),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
