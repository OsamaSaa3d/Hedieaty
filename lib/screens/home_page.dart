import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

        final upcomingEventsCount = await _fetchUpcomingEvents(friendId);
        loadedFriends.add(Friend.fromMap(
          {...data, 'upcomingEvents': upcomingEventsCount},
          friendId,
          currentUserId,
        ));
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
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(
                            "Loading...",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : friends.isEmpty
                      ? Center(
                          child: Text(
                            "You don't have any friends yet. Start sending some friend requests!",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = filteredFriends[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 16),
                              color: Colors.white,
                              child: ListTile(
                                title: Text(friend.name,
                                    style: TextStyle(fontSize: 18)),
                                subtitle: Text(
                                    "Upcoming Events: ${friend.upcomingEvents}"),
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
}
