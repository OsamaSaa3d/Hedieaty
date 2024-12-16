import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for base64 decoding
import 'create_event_list_page.dart';
import 'events_list_page.dart';
import 'friend_tile.dart';
import 'gifts_list_page.dart';
import 'login_page.dart';
import 'add_friends_page.dart';
import 'profile_page.dart'; // Add the import for ProfilePage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Friend> friends = [];
  List<Friend> filteredFriends = [];
  String? currentUserId;
  bool isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid; // Get the current user UID
    if (currentUserId != null) {
      _fetchFriends();
    }
    // Listen for changes in the search text and filter friends accordingly
    searchController.addListener(() {
      _filterFriends();
    });
  }

  void _filterFriends() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredFriends = friends
          .where((friend) => friend.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<int> _fetchUpcomingEvents(String friendId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: friendId)
          .where('status', isEqualTo: 'Upcoming')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print("Error fetching events for friend $friendId: $e");
      return 0;
    }
  }

  Future<void> _fetchFriends() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Fetch friends where currentUserId is userId1 or userId2
      final querySnapshot = await _firestore
          .collection('friends')
          .where('userId1', isEqualTo: currentUserId)
          .get();
      final querySnapshot2 = await _firestore
          .collection('friends')
          .where('userId2', isEqualTo: currentUserId)
          .get();

      final List<Friend> loadedFriends = [];

      for (final doc in [...querySnapshot.docs, ...querySnapshot2.docs]) {
        final data = doc.data() as Map<String, dynamic>;
        final friendId = data['userId1'] == currentUserId
            ? data['userId2']
            : data['userId1'];

        // Fetch profile data from the 'users' collection
        final userDoc =
            await _firestore.collection('users').doc(friendId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        // Get upcoming events count
        final upcomingEventsCount = await _fetchUpcomingEvents(friendId);

        // Add friend to the list
        loadedFriends.add(Friend.fromMap(
          {
            ...data,
            'profilePicUrl':
                userData?['profilePicUrl'] ?? '', // Safely fetch profilePicUrl
            'upcomingEvents': upcomingEventsCount,
          },
          friendId,
          currentUserId,
        ));
      }

      for (final friend in loadedFriends) {
        print('Friend: ${friend.name}, ProfilePicUrl: ${friend.profilePicUrl}');
      }

      setState(() {
        friends = loadedFriends;
        filteredFriends = loadedFriends;
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print("Error fetching friends: $e");
      setState(() {
        isLoading = false; // Set loading to false if there's an error
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<List<Friend>> _combineFriendsData(
      List<QueryDocumentSnapshot> friendsDocs) async {
    final List<Friend> loadedFriends = [];

    for (final doc in friendsDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // Check if the current user is part of the friendship (either userId1 or userId2)
      if (data['userId1'] == currentUserId ||
          data['userId2'] == currentUserId) {
        // Get the friend ID (the one that is not the current user)
        final friendId = data['userId1'] == currentUserId
            ? data['userId2']
            : data['userId1'];

        // Fetch the user profile data for the friend
        final userDoc =
            await _firestore.collection('users').doc(friendId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        // Get the upcoming events count for the friend
        final upcomingEventsCount = await _fetchUpcomingEvents(friendId);

        // Create a Friend instance and add it to the list
        loadedFriends.add(Friend.fromMap(
          {
            ...data,
            'profilePicUrl': userData?['profilePicUrl'] ?? '',
            'upcomingEvents': upcomingEventsCount,
          },
          friendId,
          currentUserId!,
        ));
      }
    }

    return loadedFriends;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // To allow gradient behind the AppBar
      appBar: AppBar(
        title: Text("Friends List"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purpleAccent],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 100), // Space below the AppBar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add, color: Colors.white),
                label: Text("Create Your Own Event/List"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateEventListPage()),
                  );
                  _fetchFriends();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search Friends",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('friends').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading friends!",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  // Combine friends where userId1 or userId2 matches current user
                  final friendsDocs = snapshot.data?.docs ?? [];

                  return FutureBuilder(
                    future: _combineFriendsData(friendsDocs),
                    builder: (context,
                        AsyncSnapshot<List<Friend>> combinedSnapshot) {
                      if (combinedSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final loadedFriends = combinedSnapshot.data ?? [];

                      if (loadedFriends.isEmpty) {
                        return Center(
                          child: Text(
                            "You don't have any friends yet. Start sending some friend requests!",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: loadedFriends.length,
                        itemBuilder: (context, index) {
                          final friend = loadedFriends[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 16),
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: friend.profilePicUrl != null &&
                                        friend.profilePicUrl!.isNotEmpty
                                    ? Image.memory(
                                            base64Decode(friend.profilePicUrl!))
                                        .image
                                    : const AssetImage(
                                        "assets/default_profile_pic.png"),
                              ),
                              title: Text(friend.name,
                                  style: TextStyle(fontSize: 18)),
                              subtitle: Text(
                                friend.upcomingEvents == 0
                                    ? 'No Upcoming Events'
                                    : '${friend.upcomingEvents} Upcoming Events',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EventListPage(friend: friend),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[300],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Friends"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
        ],
        onTap: (index) {
          if (index == 0) {
            print("Navigate to Home");
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddFriendsPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventListPage(
                  friend: Friend(
                    name: 'My Events',
                    id: currentUserId ?? '',
                    upcomingEvents: 0,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Helper function to load a base64-encoded image from a string
  Widget _loadBase64Image(String base64Image) {
    try {
      Uint8List bytes = base64Decode(base64Image);
      return Image.memory(
        bytes,
        fit: BoxFit.cover, // Optional: set the fit if needed
      );
    } catch (e) {
      print("Error decoding base64 image: $e");
      return Image.asset(
          'assets/default_profile_pic.png'); // Fallback to default image
    }
  }
}
