import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateEventListPage extends StatefulWidget {
  final String? initialEventName;
  final String? initialEventDescription;
  final String? initialEventLocation;
  final DateTime? initialEventDate;
  final String? initialEventCategory;
  final String? initialEventStatus;
  final String? eventId;

  CreateEventListPage({
    this.initialEventName,
    this.initialEventDescription,
    this.initialEventLocation,
    this.initialEventDate,
    this.initialEventCategory,
    this.initialEventStatus,
    this.eventId,
  });

  @override
  _CreateEventListPageState createState() => _CreateEventListPageState();
}

class _CreateEventListPageState extends State<CreateEventListPage> {
  final _formKey = GlobalKey<FormState>();
  String? eventName;
  String? eventDescription;
  String? eventLocation;
  DateTime? eventDate;
  String? eventCategory;
  String eventStatus = "Upcoming"; // Default status

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined categories for dropdown
  final List<String> categories = [
    'Conference',
    'Workshop',
    'Meetup',
    'Seminar',
    'Webinar',
    'Party',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    eventName = widget.initialEventName;
    eventDescription = widget.initialEventDescription;
    eventLocation = widget.initialEventLocation;
    eventDate = widget.initialEventDate;
    eventCategory =
        widget.initialEventCategory ?? categories[0]; // Default category
    eventStatus = widget.initialEventStatus ?? "Upcoming"; // Default status
  }

  // Save the event data to Firestore
  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create the event data map
      final eventData = {
        'name': eventName,
        'description': eventDescription,
        'location': eventLocation,
        'date': eventDate,
        'category': eventCategory,
        'status': eventStatus,
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      try {
        if (widget.eventId == null) {
          // If eventId is null, create a new event
          await _firestore.collection('events').add(eventData);
        } else {
          // If eventId is not null, update the existing event
          await _firestore
              .collection('events')
              .doc(widget.eventId)
              .update(eventData);
        }
        Navigator.pop(context, eventData); // Return the event data on success
      } catch (e) {
        print("Error saving event: $e");
        // Handle errors as needed (e.g., show a Snackbar with an error message)
      }
    }
  }

  // Helper method for building text fields (unchanged)
  Widget _buildTextField({
    required String label,
    String? initialValue,
    Function(String?)? onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Function()? onTap,
  }) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: initialValue,
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  // Dropdown menu for status
  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: eventStatus,
      onChanged: (newValue) {
        setState(() {
          eventStatus = newValue!;
        });
      },
      items: [
        DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
        DropdownMenuItem(value: 'Current', child: Text('Current')),
        DropdownMenuItem(value: 'Past', child: Text('Past')),
      ],
      decoration: InputDecoration(labelText: "Event Status"),
      validator: (value) {
        if (value == null) {
          return "Please select a status";
        }
        return null;
      },
    );
  }

  // Dropdown menu for category
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: eventCategory,
      onChanged: (newValue) {
        setState(() {
          eventCategory = newValue!;
        });
      },
      items: categories
          .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
          .toList(),
      decoration: InputDecoration(labelText: "Event Category"),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select a category";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Event/List"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.green
            ], // Change to your preferred colors
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
                  label: "Event/List Name",
                  initialValue: eventName,
                  onSaved: (value) => eventName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an event name";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Event Description",
                  initialValue: eventDescription,
                  onSaved: (value) => eventDescription = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an event description";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Event Location",
                  initialValue: eventLocation,
                  onSaved: (value) => eventLocation = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an event location";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Event Date (YYYY-MM-DD)",
                  readOnly: true,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: eventDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != eventDate) {
                      setState(() {
                        eventDate = pickedDate;
                      });
                    }
                  },
                  validator: (value) {
                    if (eventDate == null) {
                      return "Please select an event date";
                    }
                    return null;
                  },
                  initialValue: eventDate != null
                      ? "${eventDate!.toLocal()}".split(' ')[0]
                      : '',
                ),
                SizedBox(height: 16),
                _buildCategoryDropdown(),
                SizedBox(height: 16),
                _buildStatusDropdown(),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveEvent,
                  child: Text("Save Event/List"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
