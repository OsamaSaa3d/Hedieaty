import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> pledgedGifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPledgedGifts();
  }

  Future<void> _fetchPledgedGifts() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('pledged_gifts')
            .get();

        setState(() {
          pledgedGifts = snapshot.docs
              .map((doc) => {
                    'name': doc['name'],
                    'friend': doc['friend'],
                    'dueDate': doc['dueDate'],
                    'id': doc.id
                  })
              .toList();
          _isLoading = false;
        });
      } catch (e) {
        print("Error fetching pledged gifts: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editPledgedGift(String giftId) async {
    // Implement functionality to edit the pledged gift (e.g., navigate to an edit page)
    // For simplicity, let's just show a Snackbar here for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing pledged gift with ID: $giftId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Pledged Gifts")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : pledgedGifts.isEmpty
              ? Center(child: Text('No pledged gifts yet.'))
              : ListView.builder(
                  itemCount: pledgedGifts.length,
                  itemBuilder: (context, index) {
                    var gift = pledgedGifts[index];
                    return ListTile(
                      title: Text(gift['name']),
                      subtitle: Text(
                          'Friend: ${gift['friend']}, Due: ${gift['dueDate']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editPledgedGift(gift['id']),
                      ),
                    );
                  },
                ),
    );
  }
}
