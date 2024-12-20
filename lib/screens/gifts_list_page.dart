import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lab3/screens/events_list_page.dart';
import 'gift_details_page.dart'; // Ensure this is imported
import 'firestore_service.dart'; // Import the FirestoreService
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

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
  String query = '';
  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _checkIfUserIsCreator();
  }

  void _filterGifts(String query) {
    if (query.isEmpty) {
      // If the query is empty, show all gifts
      filteredGifts = List.from(gifts);
    } else {
      // Otherwise, filter gifts by name
      filteredGifts = gifts.where((gift) {
        return gift['name']!.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
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
              onChanged: (value) {
                setState(() {
                  query = value; // Store the input value in the query variable
                });
              },
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
            key: Key("gifts_popup_menu"),
            onSelected: (value) {
              setState(() {
                sortCriteria = value;
                sortGifts();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  key: Key("sort_gifts_name"),
                  value: "name",
                  child: Text("Sort by Name")),
              PopupMenuItem(
                  key: Key("sort_gifts_category"),
                  value: "category",
                  child: Text("Sort by Category")),
              PopupMenuItem(
                  key: Key("sort_gifts_status"),
                  value: "status",
                  child: Text("Sort by Status")),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.greenAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
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
            _filterGifts(query);

            return ListView.builder(
              itemCount: filteredGifts.length,
              itemBuilder: (context, index) {
                final gift = filteredGifts[index];
                final isPledged = gift['status'] == 'Pledged';
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final pledgerId =
                    gift['pledgerId']; // ID of the user who pledged this gift

                return GiftTile(
                  giftName: gift["name"]!,
                  category: gift["category"]!,
                  status: gift["status"]!,
                  imageBase64: gift.containsKey("image") ? gift["image"] : "",

                  // Allow editing or deleting only if the user is the creator and the gift is not pledged
                  onEdit: (isUserCreator && !isPledged)
                      ? () => _editGift(gifts.indexOf(gift))
                      : null,
                  onDelete: (isUserCreator && !isPledged)
                      ? () => _deleteGift(gifts.indexOf(gift))
                      : null,

                  // Pledging logic: Only allow pledging if the gift is "Available" or unpledging if the current user is the pledger
                  onPledgeChange: (isUserCreator ||
                          (isPledged && pledgerId != currentUserId))
                      ? null // Disable the toggle for non-pledgers
                      : (bool newValue) {
                          _togglePledgeGift(index, newValue);
                        },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isUserCreator
          ? FloatingActionButton(
              key: Key("add_gift_button"),
              onPressed: () async {
                final newGift =
                    await Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return GiftDetailsPage(eventId: widget.event.id);
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    // Define the transition effect (slide-up from the bottom)
                    const begin = Offset(0.0, 1.0); // Start from the bottom
                    const end = Offset.zero; // End at the top
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                ));
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final gift = gifts[index];
    final isAlreadyPledged = gift['status'] == 'Pledged';
    final pledgerId = gift['pledgerId'];

    // Check if another user is trying to unpledge or pledge a gift already pledged
    if (isAlreadyPledged && pledgerId != currentUserId) {
      print(
          "You cannot change the pledge status of a gift pledged by someone else.");
      return; // Exit early
    }

    // Determine new status and pledger ID
    final newStatus = isPledged ? 'Pledged' : 'Available';
    final newPledgerId = isPledged ? currentUserId : null;

    try {
      final eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .get();
      if (!eventSnapshot.exists) {
        print("Event not found");
        return;
      }
      final eventData = eventSnapshot.data();
      final userId = eventData?['userId'];

      if (userId == null) {
        print("User ID not found in event data.");
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!userSnapshot.exists) {
        print("user not found");
        return;
      }
      final userData = userSnapshot.data();
      final pledgerName = userData?['name'];

      // Update Firestore
      await _firestoreService.updateGiftStatus(
        widget.event.id,
        gift['id'],
        newStatus,
        newPledgerId,
      );

      // Add the gift status history for the user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('gifts status history')
          .add({
        'giftId': gift['id'],
        'giftName': gift['name'],
        'status': newStatus,
        'pledgerId': newPledgerId,
        'pledgerName': pledgerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Update local state
      setState(() {
        gifts[index]['status'] = newStatus;
        gifts[index]['pledgerId'] = newPledgerId; // Update pledger ID
      });
    } catch (e) {
      print("Error updating pledge status: $e");
    }
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
  final String? imageBase64;

  GiftTile({
    required this.giftName,
    required this.category,
    required this.status,
    this.onEdit,
    this.onDelete,
    this.onPledgeChange,
    this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    // Check if there's an image in base64, otherwise use a default image

    // Widget giftImage = imageBase64 != null && imageBase64!.isNotEmpty
    //     ? Image.memory(
    //         base64Decode(imageBase64!),
    //         fit: BoxFit.cover,
    //         width: 50,
    //         height: 50,
    //         errorBuilder: (context, error, stackTrace) {
    //           return Image.asset(
    //             'assets/default_gift_image.png',
    //             fit: BoxFit.cover,
    //             width: 50,
    //             height: 50,
    //           );
    //         },
    //       )
    //     : Image.asset(
    //         'assets/default_gift_image.png',
    //         fit: BoxFit.cover,
    //         width: 50,
    //         height: 50,
    //       );

    Widget giftImage = imageBase64 != null && imageBase64!.isNotEmpty
        ? (() {
            try {
              // Attempt to decode the base64 string
              return Image.memory(
                base64Decode(imageBase64!),
                fit: BoxFit.cover,
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  // If any error occurs in Image.memory, show the default image
                  return Image.asset(
                    'assets/default_gift_image.png',
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  );
                },
              );
            } catch (e) {
              // If any exception occurs during decoding, fallback to the default image
              return Image.asset(
                'assets/default_gift_image.png',
                fit: BoxFit.cover,
                width: 50,
                height: 50,
              );
            }
          })()
        : Image.asset(
            'assets/default_gift_image.png',
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          );

    Color statusColor = status == "Pledged"
        ? Colors.orange
        : (status == "Available" ? Colors.green : Colors.grey);
    void _showGiftDetails(BuildContext context, String giftName,
        String category, String status, String? imageBase64) {
      // Add image parameter
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.blueAccent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display the gift image
                  imageBase64 != null && imageBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(imageBase64),
                          fit: BoxFit.cover,
                          height: 150,
                          width: 150,
                        )
                      : Image.asset(
                          'assets/default_gift_image.png', // Default image
                          fit: BoxFit.cover,
                          height: 150,
                          width: 150,
                        ),
                  SizedBox(height: 16),
                  // Display gift details
                  Text(
                    giftName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Category: $category",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Status: $status",
                    style: TextStyle(
                      fontSize: 18,
                      color: status == "Pledged"
                          ? Colors.orange
                          : const Color.fromARGB(255, 168, 36, 139),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Close button
                  TextButton(
                    key: Key("close_button"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "Close",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        key: Key("gift_tile"),
        leading: giftImage,
        title: Text(giftName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Category: $category, Status: $status",
            style: TextStyle(color: statusColor)),
        onTap: () {
          _showGiftDetails(context, giftName, category, status, imageBase64);
        },
        trailing: Wrap(
          spacing: 12,
          children: [
            if (onEdit != null)
              IconButton(
                key: Key("edit_gift_button"),
                icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                key: Key("delete_gift_button"),
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            if (onPledgeChange != null)
              Switch(
                key: Key("gift_pledge_switch"),
                value: status == "Pledged",
                onChanged: (bool value) {
                  if (onPledgeChange != null) {
                    onPledgeChange!(value);
                  }
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
