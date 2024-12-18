import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lab3/screens/firestore_service.dart';
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
  String query = "";
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    filteredEvents = List.from(events); // Initialize filteredEvents
  }

  // Sort events based on criteria
  void sortEvents() {
    events.sort((a, b) {
      if (sortCriteria == "name") {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (sortCriteria == "category") {
        return a.category.toLowerCase().compareTo(b.category.toLowerCase());
      }
      if (sortCriteria == "status") {
        return a.status.toLowerCase().compareTo(b.status.toLowerCase());
      }
      return 0; // Default case
    });

    // Update filteredEvents to reflect the sorted list
    filteredEvents = List.from(events);
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

    // Remove event from Firestore
    _firestore.collection('events').doc(event.id).delete().then((_) {
      // Since the StreamBuilder is already listening to Firestore, no need for local setState() here
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Event deleted successfully!'),
      ));
    }).catchError((e) {
      print("Error deleting event: $e");
    });
  }

  void _filterEvents(String query) {
    if (query.isEmpty) {
      // If the search bar is empty, show all events
      filteredEvents = List.from(events);
    } else {
      // Otherwise, filter events by name
      filteredEvents = events.where((event) {
        return event.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friend.name} Events"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) {
                // This will trigger a rebuild with the filtered data
                setState(() {
                  query = value;
                });
              },
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
            colors: [Colors.blue, Colors.green], // Define your colors here
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Event>>(
          stream: _firestoreService.getEventsForUser(widget.friend.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching events'));
            }

            if (snapshot.hasData) {
              events = snapshot.data!;

              // Update filteredEvents here directly after fetching
              filteredEvents = query.isEmpty
                  ? List.from(events)
                  : events.where((event) {
                      return event.name
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList();

              sortEvents();
              _filterEvents(query);

              return filteredEvents.isEmpty
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
                                builder: (context) =>
                                    GiftListPage(event: event),
                              ),
                            );
                          },
                        );
                      },
                    );
            }

            return Center(child: Text('No events found.'));
          },
        ),
      ),
      floatingActionButton: widget.friend.name == 'My'
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateEventListPage()),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
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
        leading: CircleAvatar(
          backgroundImage:
              AssetImage('assets/default_event_image.png'), // Default image
          radius: 30,
        ),
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
