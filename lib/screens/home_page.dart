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
          .where('status', isEqualTo: 'Upcoming') // Filter for upcoming status
          .get();

      return querySnapshot.docs.length; // Return count of upcoming events
    } catch (e) {
      print("Error fetching events for friend $friendId: $e");
      return 0; // Return 0 if any error occurs
    }
  }

  Future<void> _fetchFriends() async {
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) return;

    try {
      // Fetch friends where the current user is userId1 or userId2
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

        // Fetch the upcoming events count for the friend
        final upcomingEventsCount = await _fetchUpcomingEvents(friendId);

        // Create Friend object with additional event count
        loadedFriends.add(Friend.fromMap(
          {...data, 'upcomingEvents': upcomingEventsCount},
          friendId,
          currentUserId,
        ));
      }

      setState(() {
        friends = loadedFriends;
        filteredFriends = loadedFriends;
      });
    } catch (e) {
      print("Error fetching friends: $e");
    }
  }

  void _searchFriends(String query) {
    setState(() {
      filteredFriends = friends
          .where((friend) =>
              friend.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
      appBar: AppBar(
        title: Text("Friends List"),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(friends: friends),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Create Your Own Event/List"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15.0),
                textStyle: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final newEventList = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEventListPage(),
                  ),
                );
                if (newEventList != null) {
                  _fetchFriends();
                }
              },
            ),
          ),
          // Button to navigate to the Add Friend page
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFriendsPage(),
                  ),
                );
              },
              child: Text("Add Friends"),
            ),
          ),
          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Text(
                      "You don't have any friends yet. Start adding people so that you can see their events.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to the EventListPage when the friend tile is tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventListPage(
                                friend:
                                    friend, // Pass the selected friend to EventListPage
                              ),
                            ),
                          );
                        },
                        child: FriendTile(
                            friend: friend), // Your FriendTile widget
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentUserId = _auth.currentUser?.uid;

          if (currentUserId == null) {
            // Handle case where the user is not logged in
            return;
          }

          try {
            // Fetch the upcoming events count for the current user
            final upcomingEventsCount =
                await _fetchUpcomingEvents(currentUserId);

            // Navigate to the EventListPage and pass the data (current user and events count)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventListPage(
                  friend: Friend(
                    name:
                        'My Events list', // You can pass the actual current user's name
                    id: currentUserId,
                    upcomingEvents:
                        upcomingEventsCount, // Pass the actual event count
                  ),
                ),
              ),
            );
          } catch (e) {
            print("Error fetching events: $e");
          }
        },
        child: Icon(Icons.event, color: Colors.white),
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final List<Friend> friends;

  FriendSearchDelegate({required this.friends});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = friends
        .where(
            (friend) => friend.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final friend = results[index];
        return FriendTile(friend: friend);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = friends
        .where(
            (friend) => friend.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final friend = suggestions[index];
        return FriendTile(friend: friend);
      },
    );
  }
}
