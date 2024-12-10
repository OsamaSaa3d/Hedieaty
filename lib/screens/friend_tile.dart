import 'package:flutter/material.dart';

// Friend class to model a friend object
class Friend {
  final String id;
  final String name;
  final String? photo;
  final int upcomingEvents;

  Friend({
    required this.id,
    required this.name,
    this.photo,
    required this.upcomingEvents,
  });

  factory Friend.fromMap(
      Map<String, dynamic> map, String id, String currentUserId) {
    // Determine the correct name field based on the currentUserId
    String name = (currentUserId == map['userId2'])
        ? (map['userName1'] ?? 'Unknown')
        : (map['userName2'] ?? 'Unknown');

    return Friend(
      id: id,
      name: name,
      photo: map['photo'], // Optional field for user photo
      upcomingEvents: map['upcomingEvents'] ?? 0, // Default to 0 if null
    );
  }
}

class FriendTile extends StatelessWidget {
  final Friend friend;

  // Constructor to accept a Friend object
  FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend.photo != null && friend.photo!.isNotEmpty
            ? NetworkImage(friend.photo!)
            : null,
        child: friend.photo == null || friend.photo!.isEmpty
            ? Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(friend.name),
      subtitle: Text(
        friend.upcomingEvents == 0
            ? 'No Upcoming Events'
            : '${friend.upcomingEvents} Upcoming Events',
      ),
    );
  }
}
