import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppNotificationsPage extends StatefulWidget {
  @override
  _InAppNotificationsPageState createState() => _InAppNotificationsPageState();
}

class _InAppNotificationsPageState extends State<InAppNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gifts status history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In App Notifications'),
        backgroundColor: const Color.fromARGB(
            255, 87, 0, 150), // Custom color for the AppBar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications available.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final giftName = notification['giftName'];
              final status = notification['status'];
              final pledgerName = notification['pledgerName'];
              final timestamp = notification['timestamp'].toDate();

              return Card(
                margin: EdgeInsets.all(8.0),
                elevation: 5, // Add shadow to the cards
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                child: ListTile(
                  leading: Icon(
                    status == 'Pledged'
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: status == 'Pledged' ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    'Gift: $giftName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User: $pledgerName has ${status == 'Pledged' ? 'pledged' : 'unpledged'} the gift.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Timestamp: ${timestamp.toLocal()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  contentPadding: EdgeInsets.all(10.0),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
