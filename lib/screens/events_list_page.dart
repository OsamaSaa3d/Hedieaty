import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'gifts_list_page.dart';
import 'create_event_list_page.dart';
import 'friend_tile.dart'; // Import the FriendTile class

class Event {
  final String name;
  final String status;
  final String category;
  final String id; // Event document ID
  final DateTime? date;
  final String? userId; // Make userId nullable

  Event({
    required this.name,
    required this.status,
    required this.category,
    required this.id,
    this.date,
    this.userId, // Make userId optional
  });

  // Factory method to create Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      name: data['name'],
      status: data['status'],
      category: data['category'],
      id: doc.id,
      date: data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date']))
          : null,
      userId: data['userId'], // userId can be null now
    );
  }
}

class EventListPage extends StatefulWidget {
  final Friend friend; // Accept friend object

  EventListPage({required this.friend}); // Constructor to accept friend object

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Event> events = [];
  List<Event> filteredEvents = [];
  String sortCriteria = "name";

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  // Fetch events from Firestore
  Future<void> _fetchEvents() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch events related to the friend's userId from the 'events' collection
        QuerySnapshot snapshot = await _firestore
            .collection('events')
            .where('userId', isEqualTo: widget.friend.id)
            .get();

        // Populate the events list with fetched data
        setState(() {
          events = snapshot.docs.map((doc) {
            return Event.fromFirestore(doc);
          }).toList();
          filteredEvents = List.from(events); // Initialize filteredEvents here
        });
      } catch (e) {
        print("Error fetching events: $e");
      }
    }
  }

  // Sort events based on criteria
  void sortEvents() {
    setState(() {
      events.sort((a, b) {
        if (sortCriteria == "name") return a.name.compareTo(b.name);
        if (sortCriteria == "category") return a.category.compareTo(b.category);
        if (sortCriteria == "status") return a.status.compareTo(b.status);
        return 0;
      });
      filteredEvents = List.from(events); // Update filteredEvents after sorting
    });
  }

  // Edit event
  void _editEvent(int index) {
    final event = events[index];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventListPage(
          initialEventName: event.name,
          initialEventDescription: event.status,
          initialEventLocation: event.category,
          initialEventDate: event.date,
          initialEventStatus: event.status, // Pass current status
          initialEventCategory: event.category, // Pass current category
          eventId: event.id,
        ),
      ),
    ).then((result) {
      if (result != null) {
        // Update the event in Firestore (no need to add a new one)
        _firestore
            .collection('events')
            .doc(event.id) // Use the existing event id to update
            .update(result) // Pass the updated event data
            .then((_) {
          // Update the local event list to reflect the changes
          setState(() {
            // Replace the old event with the updated one
            events[index] =
                Event.fromFirestore(result); // Update the local event list
            filteredEvents =
                List.from(events); // Ensure filtered events are updated
          });
        }).catchError((e) {
          print("Error updating event: $e");
        });
      }
    });
  }

  // Delete event
  void _deleteEvent(int index) {
    final event = events[index];

    setState(() {
      events.removeAt(index);
    });

    // Remove event from Firestore
    _firestore
        .collection('events') // Fix path here
        .doc(event.id)
        .delete();
  }

  // Modify the _filterEvents method to update filteredEvents properly
  void _filterEvents(String query) {
    setState(() {
      if (query.isEmpty) {
        // If the search bar is empty, show all events
        filteredEvents = List.from(events);
      } else {
        // Otherwise, filter events by name
        filteredEvents = events.where((event) {
          return event.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friend.name}'s Events"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0), // Height of the search bar
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) =>
                  _filterEvents(value), // Call filtering function
              decoration: InputDecoration(
                hintText: "Search events...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            // Sorting menu
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueAccent, Colors.purpleAccent],
          ),
        ),
        child: filteredEvents.isEmpty
            ? Center(child: Text('No events found.'))
            : ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return EventTile(
                    eventName: event.name,
                    eventStatus: event.status,
                    category: event.category,
                    userId: event.userId,
                    onEdit: () => _editEvent(index),
                    onDelete: () => _deleteEvent(index),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftListPage(event: event),
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

class EventTile extends StatelessWidget {
  final String eventName;
  final String eventStatus;
  final String category;
  final String? userId; // userId of the event creator (nullable)
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  EventTile({
    required this.eventName,
    required this.eventStatus,
    required this.category,
    required this.userId,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = eventStatus == "Upcoming"
        ? Colors.orange
        : (eventStatus == "Current" ? Colors.green : Colors.grey);

    // Get the current user's id
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(eventName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Category: $category, Status: $eventStatus",
            style: TextStyle(color: statusColor)),
        trailing: Wrap(
          spacing: 12,
          children: [
            // Only show edit and delete buttons if the current user is the event creator
            if (userId == currentUserId) ...[
              // Check userId safely
              IconButton(
                icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
