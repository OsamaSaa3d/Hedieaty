import 'dart:convert'; // Required for base64Decode
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Friend class to model a friend object
class Friend {
  final String id;
  final String name;
  final String? profilePicUrl; // Updated field for image URL or base64
  final int upcomingEvents;

  Friend({
    required this.id,
    required this.name,
    this.profilePicUrl,
    required this.upcomingEvents,
  });

  factory Friend.fromMap(
      Map<String, dynamic> map, String id, String currentUserId) {
    String name = (currentUserId == map['userId2'])
        ? (map['userName1'] ?? 'Unknown')
        : (map['userName2'] ?? 'Unknown');

    return Friend(
      id: id,
      name: name,
      profilePicUrl:
          map['profilePicUrl'], // Expect profilePicUrl from Firestore
      upcomingEvents: map['upcomingEvents'] ?? 0,
    );
  }
}

class FriendTile extends StatelessWidget {
  final Friend friend;

  const FriendTile({required this.friend, Key? key}) : super(key: key);

  // Function to return appropriate profile image widget
  Widget _getProfileImage() {
    print(friend.profilePicUrl);
    print("yeah");
    if (friend.profilePicUrl != null && friend.profilePicUrl!.isNotEmpty) {
      try {
        // Attempt to decode base64 image
        final decodedImage = base64Decode(friend.profilePicUrl!);
        return CircleAvatar(
          backgroundImage:
              Image.memory(decodedImage).image, // Display decoded image
        );
      } catch (e) {
        // If decoding fails, assume it's a URL
        return CircleAvatar(
          backgroundImage: NetworkImage(friend.profilePicUrl!),
        );
      }
    } else {
      // Fallback to default avatar if no image
      return CircleAvatar(
        backgroundColor: Colors.grey[300], // Light grey background
        child: Icon(Icons.person, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getProfileImage(),
      title: Text(friend.name),
      subtitle: Text(
        friend.upcomingEvents == 0
            ? 'No Upcoming Events'
            : '${friend.upcomingEvents} Upcoming Events',
      ),
    );
  }
}
