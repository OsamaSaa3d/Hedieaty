import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a gift to the event's sub-collection
  Future<void> addGift(String eventId, Map<String, dynamic> giftData) async {
    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('gifts')
          .add(giftData);
    } catch (e) {
      print("Error adding gift: $e");
    }
  }

  // Fetch gifts for a specific event by event ID
  Stream<List<Map<String, dynamic>>> getGifts(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  // Update gift details
  Future<void> updateGift(
      String eventId, String giftId, Map<String, dynamic> updatedData) async {
    await _db
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .update(updatedData);
  }

  // Delete gift
  Future<void> deleteGift(String eventId, String giftId) async {
    await _db
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .delete();
  }

  // Update gift status (Pledged/Available)
  Future<void> updateGiftStatus(
      String eventId, String giftId, String status, String? pledgerId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .update({
      'status': status,
      'pledgerId': pledgerId,
    });
  }

  Future<Map<String, dynamic>?> getEventByName(String eventName) async {
    try {
      var eventDoc = await _db
          .collection('events')
          .where('name', isEqualTo: eventName)
          .limit(1)
          .get();

      if (eventDoc.docs.isNotEmpty) {
        return eventDoc.docs.first.data();
      }
      return null; // If no event found
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }
}
