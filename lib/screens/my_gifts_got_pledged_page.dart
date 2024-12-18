import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting dates

class MyGiftsGotPledgedPage extends StatefulWidget {
  @override
  _MyGiftsGotPledgedPageState createState() => _MyGiftsGotPledgedPageState();
}

class _MyGiftsGotPledgedPageState extends State<MyGiftsGotPledgedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  // Fetch all gifts with status 'Pledged' for the current user
  Stream<List<Map<String, dynamic>>> _getPledgedGiftsStream() {
    if (_user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('events')
        .where('userId',
            isEqualTo:
                _user!.uid) // Get events where userId matches current user
        .snapshots()
        .asyncMap((eventSnapshot) async {
      List<Map<String, dynamic>> pledgedGifts = [];

      for (var eventDoc in eventSnapshot.docs) {
        // Get the gifts collection for each event
        var giftSnapshot = await eventDoc.reference
            .collection('gifts')
            .where('status',
                isEqualTo: 'Pledged') // Filter gifts with 'Pledged' status
            .get();

        for (var giftDoc in giftSnapshot.docs) {
          var giftData = giftDoc.data() as Map<String, dynamic>;

          // Get the pledgerId and fetch their name from the users collection
          var pledgerId = giftData['pledgerId'];
          var userSnapshot =
              await _firestore.collection('users').doc(pledgerId).get();

          var pledgerName = userSnapshot.exists
              ? userSnapshot['name'] ?? 'Unknown'
              : 'Unknown';

          // Get the event date (just the day part)
          var eventDate = (eventDoc['date'] as Timestamp).toDate();
          var eventDay = DateFormat('dd MMM yyyy').format(eventDate);

          pledgedGifts.add({
            'giftName': giftData['name'],
            'eventName': eventDoc['name'],
            'eventDate': eventDay,
            'pledger': pledgerName,
            'eventDateTime': eventDate,
          });
        }
      }
      return pledgedGifts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Gifts Got Pledged")),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getPledgedGiftsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(), // Show loading indicator
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No pledged gifts found.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            }

            final pledgedGifts = snapshot.data!;

            return ListView.builder(
              itemCount: pledgedGifts.length,
              itemBuilder: (context, index) {
                final gift = pledgedGifts[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      gift['giftName'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        Text(
                          "Event: ${gift['eventName']}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          "Date: ${gift['eventDate']}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          "Pledger: ${gift['pledger']}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
