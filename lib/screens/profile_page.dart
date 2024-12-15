import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lab3/screens/my_pledged_gifts_page.dart';
import 'package:lab3/screens/gifts_list_page.dart'; // Import the GiftsListPage
import 'package:lab3/screens/events_list_page.dart'; // Import the EventListPage
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditable = false;
  bool notificationsEnabled = true;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = true;
  List<Event> _createdEvents = [];
  File? _profileImage; // Store the selected image file
  String _profileImageUrl = ''; // Store the URL of the uploaded image

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchCreatedEvents();
  }

  // Fetching the current user's details from Firebase
  Future<void> _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
        _emailController.text = user.email ?? '';
      });
      // Fetch additional user data (e.g., full name) from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _fullNameController.text = userData['name'] ?? '';

          // Check if the profilePicUrl field exists
          if (userData.containsKey('profilePicUrl')) {
            _profileImageUrl = userData['profilePicUrl'] ?? '';
          } else {
            _profileImageUrl = ''; // Set to an empty string or default value
          }
        });
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'profilePicUrl': '', // Add an empty field for profile picture URL
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Fetching the list of events the user has created
  Future<void> _fetchCreatedEvents() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Event> events = eventSnapshot.docs.map((doc) {
        return Event.fromFirestore(doc);
      }).toList();

      setState(() {
        _createdEvents = events;
      });
    }
  }

  // Method to allow the user to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path); // Store the selected file
      });

      // Convert the image to base64 and store it in Firestore
      _uploadProfilePicture();
    } else {
      print("No image selected");
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) return;

    try {
      // Convert the image file to a base64 string
      List<int> imageBytes = await _profileImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Get the current user
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save the base64 image string in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profilePicUrl': base64Image,
      });

      // Update the state with the new base64 string (optional)
      setState(() {
        _profileImageUrl = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  // Save the profile changes
  Future<void> _saveProfile() async {
    if (_user == null) return;

    String fullName = _fullNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // Step 1: Reauthenticate the user for sensitive operations
      String currentEmail = _user!.email!;
      String currentPassword =
          "your_placeholder_password"; // Use current password input
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: currentPassword,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Step 2: Update email if changed
      if (email.isNotEmpty && email != _user!.email) {
        await _user!.updateEmail(email);
      }

      // Step 3: Update password if provided
      if (password.isNotEmpty) {
        await _user!.updatePassword(password);
      }

      // Step 4: Update Firestore fields: 'name' and 'fullName'
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': fullName,
        'fullName': fullName,
        'email': email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        isEditable = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Image _getProfileImage() {
    if (_profileImageUrl.isNotEmpty) {
      // If the profile image URL is a base64 string
      try {
        Uint8List bytes = base64Decode(_profileImageUrl);
        return Image.memory(bytes); // Display the image from the decoded bytes
      } catch (e) {
        print("Error decoding base64 image: $e");
      }
    }
    return Image.asset(
        'assets/default_profile_image.png'); // Default image if not set
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Profile Settings",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 10),
                        // Profile picture section
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImageUrl.isNotEmpty
                                ? _getProfileImage()
                                    .image // Use the base64-decoded image
                                : null,
                            child: _profileImageUrl.isEmpty &&
                                    _profileImage == null
                                ? Icon(Icons.camera_alt,
                                    size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _fullNameController,
                          enabled: isEditable,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          enabled: isEditable,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          enabled: isEditable,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isEditable = !isEditable;
                            });
                            if (isEditable) {
                              _saveProfile();
                            }
                          },
                          child: Text(
                              isEditable ? "Save Changes" : "Edit Profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 10),
                        SwitchListTile(
                          title: Text("Enable Notifications",
                              style: TextStyle(color: Colors.white)),
                          value: notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              notificationsEnabled = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Your Created Events",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        _createdEvents.isEmpty
                            ? Text(
                                "You haven't created any events yet.",
                                style: TextStyle(color: Colors.white),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _createdEvents.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      // Handle event tap
                                    },
                                    child: ListTile(
                                      title: Text(
                                        _createdEvents[index].name,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
