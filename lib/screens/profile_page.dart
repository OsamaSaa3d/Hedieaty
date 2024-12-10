import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lab3/screens/my_pledged_gifts_page.dart';
import 'package:lab3/screens/gifts_list_page.dart'; // Import the GiftsListPage
import 'package:lab3/screens/events_list_page.dart'; // Import the EventListPage

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditable = false;
  bool notificationsEnabled = true;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = true;
  List<Event> _createdEvents =
      []; // Store Event objects instead of Map<String, dynamic>

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchCreatedEvents();
  }

  // Fetching the current user's details from Firebase
  Future<void> _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
        _emailController.text = user.email ?? '';
      });
      // Fetch additional user data (e.g., full name) from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _fullNameController.text = userDoc['name'] ?? '';
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Fetching the list of events the user has created
  Future<void> _fetchCreatedEvents() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Convert the documents into Event objects
      List<Event> events = eventSnapshot.docs.map((doc) {
        return Event.fromFirestore(
            doc); // Convert Firestore document to Event object
      }).toList();

      setState(() {
        _createdEvents = events; // Store the Event objects in the list
      });
    }
  }

  // Save the profile changes
  Future<void> _saveProfile() async {
    if (_user != null && _fullNameController.text.isNotEmpty) {
      try {
        // Update full name in Firestore
        await _firestore.collection('users').doc(_user!.uid).update({
          'fullName': _fullNameController.text,
        });
        // If password is provided, update it
        if (_passwordController.text.isNotEmpty) {
          await _user!.updatePassword(_passwordController.text);
        }
        // If email is different, update it
        if (_emailController.text != _user!.email) {
          await _user!.updateEmail(_emailController.text);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Profile Settings",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  TextField(
                    controller: _fullNameController,
                    enabled: isEditable,
                    decoration: InputDecoration(labelText: 'Full Name'),
                  ),
                  TextField(
                    controller: _emailController,
                    enabled: isEditable,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    enabled: isEditable,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Password'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEditable = !isEditable;
                      });
                      if (isEditable) {
                        _saveProfile();
                      }
                    },
                    child: Text(isEditable ? "Save Changes" : "Edit Profile"),
                  ),
                  SwitchListTile(
                    title: Text("Enable Notifications"),
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                      // Update notification settings in Firestore or Firebase Cloud Messaging (FCM)
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Your Created Events",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _createdEvents.isEmpty
                      ? Text("You haven't created any events yet.")
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _createdEvents.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // Navigate to the GiftsListPage with the selected event object
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GiftListPage(
                                        event: _createdEvents[
                                            index]), // Pass the entire event object
                                  ),
                                );
                              },
                              child: ListTile(
                                title: Text(_createdEvents[index].name),
                              ),
                            );
                          },
                        ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyPledgedGiftsPage()),
                      );
                    },
                    child: Text("Go to My Pledged Gifts"),
                  ),
                ],
              ),
            ),
    );
  }
}
