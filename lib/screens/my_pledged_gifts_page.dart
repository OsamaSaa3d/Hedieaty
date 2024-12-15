import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting dates

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  List<Map<String, dynamic>> _pledgedGifts = []; // Store pledged gifts data

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchPledgedGifts();
    }
  }

  // Fetch all pledged gifts for the current user
  Future<void> _fetchPledgedGifts() async {
    List<Map<String, dynamic>> pledgedGifts = [];

    // Fetch all events where the current user is the pledger
    QuerySnapshot eventSnapshot = await _firestore.collection('events').get();
    for (var eventDoc in eventSnapshot.docs) {
      // Get the gifts collection for each event
      QuerySnapshot giftSnapshot =
          await eventDoc.reference.collection('gifts').get();

      for (var giftDoc in giftSnapshot.docs) {
        var giftData = giftDoc.data() as Map<String, dynamic>;

        // Check if the current user is the pledger
        if (giftData['pledgerId'] == _user!.uid) {
          // If the user has pledged this gift, fetch additional data
          var userSnapshot = await _firestore
              .collection('users')
              .doc(eventDoc['userId'])
              .get();
          var userName = userSnapshot['name'] ?? 'Unknown';

          // Get the event date (just the day part)
          var eventDate = (eventDoc['date'] as Timestamp).toDate();
          var eventDay = DateFormat('dd MMM yyyy').format(eventDate);

          // Check if the event date is in the future
          bool canUnpledge = eventDate.isAfter(DateTime.now());

          pledgedGifts.add({
            'giftName': giftData['name'],
            'eventName': eventDoc['name'],
            'eventDate': eventDay,
            'eventId': eventDoc.id,
            'eventCreator': userName,
            'giftId': giftData['id'],
            'eventDateTime': eventDate, // Store full event date for comparison
            'canUnpledge': canUnpledge, // Can the user unpledge this gift?
          });
        }
      }
    }

    setState(() {
      _pledgedGifts = pledgedGifts;
    });
  }

  void _unpledgeGift(String giftId, String eventId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Fetch the gift document from Firestore using the giftId and eventId
    final giftDoc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .get();

    if (!giftDoc.exists) {
      print("Gift not found.");
      return;
    }

    final giftData = giftDoc.data() as Map<String, dynamic>;
    final pledgerId = giftData['pledgerId'];

    // Check if the current user is the pledger of the gift
    if (pledgerId != currentUserId) {
      print("You cannot unpledge this gift as you are not the pledger.");
      return;
    }

    // Update Firestore to unpledge the gift
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('gifts')
          .doc(giftId)
          .update({
        'pledgerId': null,
        'status': 'Available', // Change the status back to 'Available'
      });

      // Update local state
      setState(() {
        _pledgedGifts = _pledgedGifts.map((gift) {
          if (gift['giftId'] == giftId) {
            gift['pledgerId'] = null;
            gift['status'] = 'Available'; // Update the status locally
          }
          return gift;
        }).toList();
      });

      print("Gift unpledged successfully.");
    } catch (e) {
      print("Error unpledging gift: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Pledged Gifts")),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _pledgedGifts.isEmpty
            ? Center(
                child: Text(
                  "You haven't pledged any gifts yet.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: _pledgedGifts.length,
                itemBuilder: (context, index) {
                  final gift = _pledgedGifts[index];
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
                            "Pledged for: ${gift['eventCreator']}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            "Date: ${gift['eventDate']}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      trailing: gift['canUnpledge']
                          ? ElevatedButton(
                              onPressed: () {
                                _unpledgeGift(gift['giftId'], gift['eventId']);
                              },
                              child: Text("Unpledge"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
