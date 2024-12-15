import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lab3/screens/my_pledged_gifts_page.dart';
import 'package:lab3/screens/gifts_list_page.dart'; // Import the GiftsListPage
import 'package:lab3/screens/events_list_page.dart'; // Import the EventListPage
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

      // Call the upload function after selecting the image
      _uploadProfilePicture();
    } else {
      print("No image selected");
    }
  }

  // Method to upload the selected image to Firebase Storage
  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) return;

    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Define the file name and reference in Firebase Storage
      String fileName =
          'profile_pics/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print("Uploading profile picture to $fileName");
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      print("Storage reference: $storageRef");

      // Create an upload task
      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      print("Upload task: $uploadTask");

      // Monitor the upload progress or completion
      await uploadTask.whenComplete(() async {
        try {
          // Once upload completes, get the download URL
          String downloadURL = await storageRef.getDownloadURL();
          print("Download URL: $downloadURL");

          // Save the image URL in Firestore
          print("Updating profile picture URL in Firestore");
          await _firestore.collection('users').doc(user.uid).update({
            'profilePicUrl': downloadURL,
          });
          print("Profile picture URL updated successfully");

          // Update the state with the new image URL
          setState(() {
            _profileImageUrl = downloadURL;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture uploaded successfully!')),
          );
        } catch (e) {
          // Handle any errors during the URL retrieval or Firestore update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error during post-upload processing: $e')),
          );
        }
      });
    } catch (e) {
      // Handle any errors during the initial upload
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
                                ? NetworkImage(_profileImageUrl)
                                : _profileImage != null
                                    ? FileImage(_profileImage!) as ImageProvider
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
