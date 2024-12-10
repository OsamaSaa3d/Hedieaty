import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OutgoingRequestsPage extends StatefulWidget {
  @override
  _OutgoingRequestsPageState createState() => _OutgoingRequestsPageState();
}

class _OutgoingRequestsPageState extends State<OutgoingRequestsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> outgoingRequests = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid; // Get the current user UID
    if (currentUserId != null) {
      _fetchOutgoingRequests();
    }
  }

  Future<void> _fetchOutgoingRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId) // Filter by UID
          .where('status', isEqualTo: 'pending') // Only pending requests
          .get();

      setState(() {
        outgoingRequests = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      // Handle errors (e.g., display a Snackbar)
      print("Error fetching outgoing requests: $e");
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).delete();
      setState(() {
        outgoingRequests.removeWhere((request) => request['id'] == requestId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request canceled successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error canceling request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Outgoing Requests"),
      ),
      body: outgoingRequests.isEmpty
          ? Center(
              child: Text(
                "No outgoing requests.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: outgoingRequests.length,
              itemBuilder: (context, index) {
                final request = outgoingRequests[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(request['receiverName'] ?? 'Unknown'),
                  subtitle: Text("Request sent to ${request['receiverEmail']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelRequest(request['id']),
                  ),
                );
              },
            ),
    );
  }
}
