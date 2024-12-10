import 'package:flutter/material.dart';
import 'package:lab3/screens/events_list_page.dart';
import 'gift_details_page.dart'; // Ensure this is imported
import 'firestore_service.dart'; // Import the FirestoreService
import 'package:firebase_auth/firebase_auth.dart';

class GiftListPage extends StatefulWidget {
  final Event event;

  GiftListPage({required this.event});

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  late FirestoreService _firestoreService;
  List<Map<String, dynamic>> gifts = [];
  List<Map<String, dynamic>> filteredGifts = [];
  String sortCriteria = "name";
  bool isUserCreator = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _checkIfUserIsCreator();
  }

  void _filterGifts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredGifts = List.from(gifts); // Show all gifts if query is empty
      } else {
        filteredGifts = gifts.where((gift) {
          return gift['name']
              .toLowerCase()
              .contains(query.toLowerCase()); // Filter only by name
        }).toList();
      }
    });
  }

  // Function to check if the current user is the creator of the event
  void _checkIfUserIsCreator() async {
    try {
      // Check if the current user is the creator of the event
      final eventCreatorId = widget.event.userId;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        isUserCreator = eventCreatorId == currentUserId;
      });
    } catch (e) {
      print("Error fetching event: $e");
      setState(() {
        isUserCreator = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.event.name} Gifts"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0), // Height of the search bar
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) => _filterGifts(value),
              decoration: InputDecoration(
                hintText: "Search gifts...",
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getGifts(widget.event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No gifts available"));
          }

          gifts = snapshot.data!;
          sortGifts();
          filteredGifts = List.from(gifts);

          return ListView.builder(
            itemCount: filteredGifts.length,
            itemBuilder: (context, index) {
              final gift = filteredGifts[index];
              return GiftTile(
                giftName: gift["name"]!,
                category: gift["category"]!,
                status: gift["status"]!,
                onEdit:
                    isUserCreator ? () => _editGift(gifts.indexOf(gift)) : null,
                onDelete: isUserCreator
                    ? () => _deleteGift(gifts.indexOf(gift))
                    : null,
                onPledgeChange: isUserCreator
                    ? null
                    : (bool isPledged) {
                        _togglePledgeGift(index, isPledged);
                      },
              );
            },
          );
        },
      ),
      floatingActionButton: isUserCreator
          ? FloatingActionButton(
              onPressed: () async {
                final newGift = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GiftDetailsPage(eventId: widget.event.id),
                  ),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void sortGifts() {
    gifts.sort((a, b) {
      if (sortCriteria == "name") {
        return a["name"]!.toLowerCase().compareTo(b["name"]!.toLowerCase());
      }
      if (sortCriteria == "category") {
        return a["category"]!
            .toLowerCase()
            .compareTo(b["category"]!.toLowerCase());
      }
      if (sortCriteria == "status") {
        return a["status"]!.toLowerCase().compareTo(b["status"]!.toLowerCase());
      }
      return 0;
    });

    // After sorting, update filteredGifts without calling setState()
    filteredGifts = List.from(gifts);
  }

  void _editGift(int index) async {
    if (index >= 0 && index < filteredGifts.length) {
      // Open the GiftDetailsPage for editing
      final updatedGift = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GiftDetailsPage(
            eventId: widget.event.id,
            giftDetails: filteredGifts[index], // Pass current gift details
          ),
        ),
      );

      if (updatedGift != null) {
        try {
          // Get the ID of the gift being updated
          String giftId = filteredGifts[index]['id'];

          // Update the gift in Firestore
          await _firestoreService.updateGift(
              widget.event.id, giftId, updatedGift);

          setState(() {
            // Include the 'id' in the updated gift so it remains consistent
            updatedGift['id'] = giftId;

            // Update the gift in the main list (gifts)
            int originalIndex =
                gifts.indexWhere((gift) => gift['id'] == giftId);
            if (originalIndex != -1) {
              gifts[originalIndex] = updatedGift;
            }

            // Update the gift in the filtered list
            filteredGifts[index] = updatedGift;
          });
        } catch (e) {
          print("Error updating gift: $e");
        }
      }
    }
  }

  void _deleteGift(int index) async {
    if (index >= 0 && index < filteredGifts.length) {
      final giftId = filteredGifts[index]['id'];

      if (giftId == null) {
        print("Gift ID is null for index $index");
        return;
      }

      try {
        // Delete the gift from Firestore
        await _firestoreService.deleteGift(widget.event.id, giftId);

        setState(() {
          // Remove from main list
          gifts.removeWhere((gift) => gift['id'] == giftId);
          // Remove from filtered list
          filteredGifts.removeAt(index);
        });
      } catch (e) {
        print("Error deleting gift: $e");
      }
    }
  }

  // Function to toggle pledge status
  void _togglePledgeGift(int index, bool isPledged) async {
    final newStatus = isPledged ? 'Pledged' : 'Available';
    await _firestoreService.updateGiftStatus(
        widget.event.id, gifts[index]['id'], newStatus);

    setState(() {
      gifts[index]['status'] = newStatus; // Update the UI
    });
  }
}

class GiftTile extends StatelessWidget {
  final String giftName;
  final String category;
  final String status;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>?
      onPledgeChange; // Callback for toggling pledge state

  GiftTile({
    required this.giftName,
    required this.category,
    required this.status,
    this.onEdit,
    this.onDelete,
    this.onPledgeChange,
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
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            if (onPledgeChange != null)
              Switch(
                value: status ==
                    "Pledged", // If status is "Pledged", the switch will be on
                onChanged: (bool value) {
                  onPledgeChange!(
                      value); // Trigger the callback to change the pledge status
                },
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey[300],
              ),
          ],
        ),
      ),
    );
  }
}
