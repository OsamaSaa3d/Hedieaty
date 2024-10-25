import 'package:flutter/material.dart';

void main() {
  runApp(HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty - Gift List Manager',
      theme: ThemeData(
        primaryColor: Color(0xFF6200EE),
        accentColor: Color(0xFF03DAC6),
        scaffoldBackgroundColor: Color(0xFFF2F2F2),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF6200EE),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6200EE),
        ),
      ),
      home: HomePage(),
    );
  }
}

class Friend {
  final String name;
  final String photo;
  final int upcomingEvents;

  Friend(
      {required this.name, required this.photo, required this.upcomingEvents});
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchController = TextEditingController();
  List<Friend> friends = [
    Friend(name: "Alice Johnson", photo: 'assets/1.jpeg', upcomingEvents: 2),
    Friend(name: "Bob Brown", photo: 'assets/2.jpeg', upcomingEvents: 1),
    Friend(name: "Catherine Fox", photo: 'assets/3.jpeg', upcomingEvents: 0),
    Friend(name: "Daniel Green", photo: 'assets/4.jpeg', upcomingEvents: 3),
  ];
  List<Friend> filteredFriends = [];

  @override
  void initState() {
    super.initState();
    filteredFriends = friends;
  }

  void searchFriends(String query) {
    setState(() {
      filteredFriends = friends
          .where((friend) =>
              friend.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
                primary: Theme.of(context).accentColor,
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15.0),
                textStyle: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                // 'Create Your Own Event/List' functionality
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                return FriendTile(
                  friend: filteredFriends[index],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add friend functionality
        },
        child: Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

class FriendTile extends StatelessWidget {
  final Friend friend;

  FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(friend.photo),
          radius: 25,
        ),
        title: Text(friend.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          friend.upcomingEvents > 0
              ? "Upcoming Events: ${friend.upcomingEvents}"
              : "No Upcoming Events",
          style: TextStyle(color: Colors.grey),
        ),
        trailing:
            Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventListPage(
                friendName: friend.name,
                eventCount: friend.upcomingEvents,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final List<Friend> friends;

  FriendSearchDelegate({required this.friends});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
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

    return ListView(
      children: results.map((friend) => FriendTile(friend: friend)).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = friends
        .where(
            (friend) => friend.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView(
      children:
          suggestions.map((friend) => FriendTile(friend: friend)).toList(),
    );
  }
}

class EventListPage extends StatefulWidget {
  final String friendName;
  final int eventCount;

  EventListPage({required this.friendName, required this.eventCount});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, String>> events = [
    {"name": "Birthday Party", "status": "Upcoming", "category": "Personal"},
    {"name": "Wedding", "status": "Past", "category": "Family"},
    {"name": "Graduation", "status": "Upcoming", "category": "Friends"},
    {"name": "Office Party", "status": "Current", "category": "Work"},
  ];

  String sortCriteria = "name";

  void sortEvents() {
    setState(() {
      events.sort((a, b) {
        if (sortCriteria == "name") return a["name"]!.compareTo(b["name"]!);
        if (sortCriteria == "category")
          return a["category"]!.compareTo(b["category"]!);
        if (sortCriteria == "status")
          return a["status"]!.compareTo(b["status"]!);
        return 0;
      });
    });
  }

  void _editEvent(int index) {
    // Implement edit functionality here
    print("Editing event: ${events[index]['name']}");
  }

  void _deleteEvent(int index) {
    setState(() {
      events.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friendName}'s Events"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortCriteria = value;
                sortEvents();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: "name", child: Text("Sort by Name")),
              PopupMenuItem(value: "category", child: Text("Sort by Category")),
              PopupMenuItem(value: "status", child: Text("Sort by Status")),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventTile(
            eventName: event["name"]!,
            eventStatus: event["status"]!,
            category: event["category"]!,
            onEdit: () => _editEvent(index),
            onDelete: () => _deleteEvent(index),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftListPage(eventName: event["name"]!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add Event functionality
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  final String eventName;
  final String eventStatus;
  final String category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  EventTile({
    required this.eventName,
    required this.eventStatus,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = eventStatus == "Upcoming"
        ? Colors.orange
        : (eventStatus == "Current" ? Colors.green : Colors.grey);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(eventName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Category: $category, Status: $eventStatus",
            style: TextStyle(color: statusColor)),
        trailing: Wrap(
          spacing: 12,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class GiftListPage extends StatefulWidget {
  final String eventName;

  GiftListPage({required this.eventName});

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Map<String, dynamic>> gifts = [
    {"name": "Handmade Card", "category": "Craft", "status": "Pledged"},
    {
      "name": "Bluetooth Speaker",
      "category": "Electronics",
      "status": "Available"
    },
    {"name": "Gift Card", "category": "Gift Cards", "status": "Pledged"},
    {"name": "Personalized Mug", "category": "Home", "status": "Available"},
  ];

  String sortCriteria = "name";

  void sortGifts() {
    setState(() {
      gifts.sort((a, b) {
        if (sortCriteria == "name") return a["name"]!.compareTo(b["name"]!);
        if (sortCriteria == "category")
          return a["category"]!.compareTo(b["category"]!);
        if (sortCriteria == "status")
          return a["status"]!.compareTo(b["status"]!);
        return 0;
      });
    });
  }

  void _editGift(int index) {
    // Implement gift edit functionality
    print("Editing gift: ${gifts[index]['name']}");
  }

  void _deleteGift(int index) {
    setState(() {
      gifts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.eventName} Gifts"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortCriteria = value;
                sortGifts();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: "name", child: Text("Sort by Name")),
              PopupMenuItem(value: "category", child: Text("Sort by Category")),
              PopupMenuItem(value: "status", child: Text("Sort by Status")),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return GiftTile(
            giftName: gift["name"]!,
            category: gift["category"]!,
            status: gift["status"]!,
            onEdit: () => _editGift(index),
            onDelete: () => _deleteGift(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add Gift functionality
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class GiftTile extends StatelessWidget {
  final String giftName;
  final String category;
  final String status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  GiftTile({
    required this.giftName,
    required this.category,
    required this.status,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == "Pledged"
        ? Colors.orange
        : (status == "Available" ? Colors.green : Colors.grey);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(giftName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Category: $category, Status: $status",
            style: TextStyle(color: statusColor)),
        trailing: Wrap(
          spacing: 12,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
