import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GiftDetailsPage extends StatefulWidget {
  final Map<String, dynamic>?
      giftDetails; // Optional parameter for existing gift details
  final String eventId; // The event ID to create the sub-collection

  GiftDetailsPage({Key? key, this.giftDetails, required this.eventId})
      : super(key: key);

  @override
  _GiftDetailsPageState createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late String giftName;
  late String description;
  late String category;
  late double price;
  bool isPledged = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _imageFile;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    // Pre-fill the fields with existing gift details if provided
    if (widget.giftDetails != null) {
      final gift = widget.giftDetails!;
      giftName = gift["name"] != null ? gift["name"] as String : '';
      description =
          gift["description"] != null ? gift["description"] as String : '';
      category = gift["category"] != null ? gift["category"] as String : '';
      price = gift["price"] != null ? (gift["price"] as num).toDouble() : 0.0;
      isPledged = (gift["status"] == "Pledged");
      _imageBase64 = gift["image"]; // If image exists in Firestore, get it
    } else {
      // Default values for a new gift
      giftName = '';
      description = '';
      category = '';
      price = 0.0;
      isPledged = false;
    }
  }

  // Method to pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _imageFile = imageFile;
        _imageBase64 = base64Encode(
            imageFile.readAsBytesSync()); // Encode the image as base64
      });
    }
  }

  // Save gift to Firestore
  void _saveGift() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final giftsCollection = _firestore
            .collection('events')
            .doc(widget.eventId)
            .collection('gifts');

        final giftData = {
          "name": giftName,
          "description": description,
          "category": category,
          "price": price,
          "status": isPledged ? "Pledged" : "Available",
          "image": _imageBase64, // Add the base64 image data here
          "PledgerId": null,
        };

        if (widget.giftDetails != null && widget.giftDetails!["id"] != null) {
          // Update existing gift
          await giftsCollection.doc(widget.giftDetails!["id"]).update(giftData);
          Navigator.pop(context, {
            "id": widget.giftDetails!['id'],
            "name": giftName,
            "description": description,
            "category": category,
            "price": price,
            "status": isPledged ? "Pledged" : "Available",
            "image": _imageBase64,
            "PledgerId": null,
          });
        } else {
          // Add new gift
          final newGiftRef = await giftsCollection.add(giftData);
          String generatedId = newGiftRef.id;
          await newGiftRef.update({"id": generatedId});

          Navigator.pop(context, {
            "id": generatedId,
            "name": giftName,
            "description": description,
            "category": category,
            "price": price,
            "status": isPledged ? "Pledged" : "Available",
            "image": _imageBase64,
            "PledgerId": null,
          });
        }
      } catch (e) {
        print("Error saving gift: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.giftDetails == null ? "Add Gift" : "Edit Gift"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent,
              Colors.greenAccent
            ], // You can change these colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  key: const Key('gift_name_field'),
                  label: 'Gift Name',
                  initialValue: giftName,
                  onSaved: (value) => giftName = value ?? '',
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter a gift name';
                    return null;
                  },
                ),
                _buildTextField(
                  key: const Key('gift_description_field'),
                  label: 'Description',
                  initialValue: description,
                  onSaved: (value) => description = value ?? '',
                ),
                _buildTextField(
                  key: const Key('gift_category_field'),
                  label: 'Category',
                  initialValue: category,
                  onSaved: (value) => category = value ?? '',
                ),
                _buildTextField(
                  key: const Key('gift_price_field'),
                  label: 'Price',
                  initialValue: price.toString(),
                  keyboardType: TextInputType.number,
                  onSaved: (value) =>
                      price = double.tryParse(value ?? '0') ?? 0.0,
                ),
                SwitchListTile(
                  title: Text('Pledged'),
                  value: isPledged,
                  onChanged: (value) => setState(() => isPledged = value),
                ),
                // Image picker button
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: _imageFile == null && _imageBase64 == null
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.white)
                        : _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                width:
                                    100, // Set the width to limit the image size
                                height:
                                    100, // Set the height to limit the image size
                                fit: BoxFit
                                    .cover, // This will ensure the image scales proportionally
                              )
                            : Image.memory(
                                base64Decode(_imageBase64!),
                                width:
                                    100, // Set the width to limit the image size
                                height:
                                    100, // Set the height to limit the image size
                                fit: BoxFit
                                    .cover, // This will ensure the image scales proportionally
                              ),
                  ),
                ),
                ElevatedButton(
                  key: const Key('gift_create_button'),
                  onPressed: _saveGift,
                  child: Text(
                      widget.giftDetails == null ? "Add Gift" : "Update Gift"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for creating text fields
  Widget _buildTextField({
    required Key key,
    required String label,
    required String initialValue,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      key: key,
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
