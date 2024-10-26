import 'package:flutter/material.dart';

void main() {
  runApp(HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty - Gift List Manager',
      theme: ThemeData(
        primaryColor: Color(0xFF6200EE),
        accentColor: Color(0xFF03DAC6),
        scaffoldBackgroundColor: Color(0xFFF2F2F2),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF6200EE),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6200EE),
        ),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';

  void login() {
    if (_usernameController.text == 'osama' &&
        _passwordController.text == '123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      setState(() {
        errorMessage = 'Invalid username or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Login",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: login,
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchController = TextEditingController();
  List<Friend> friends = [
    Friend(name: "Alice Johnson", photo: 'assets/1.jpeg', upcomingEvents: 2),
    Friend(name: "Bob Brown", photo: 'assets/2.jpeg', upcomingEvents: 1),
    Friend(name: "Catherine Fox", photo: 'assets/3.jpeg', upcomingEvents: 0),
    Friend(name: "Daniel Green", photo: 'assets/4.jpeg', upcomingEvents: 3),
  ];
  List<Friend> filteredFriends = [];

  @override
  void initState() {
    super.initState();
    filteredFriends = friends;
  }

  void searchFriends(String query) {
    setState(() {
      filteredFriends = friends
          .where((friend) =>
              friend.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friends List"),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(friends: friends),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Create Your Own Event/List"),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15.0),
                textStyle: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final newEventList = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateEventListPage()),
                );

                // Handle the new event/list data if it is not null
                if (newEventList != null) {
                  print(
                      "New Event/List Created: ${newEventList['name']}, Date: ${newEventList['date']}");
                  // You may want to refresh your events list or display the new event
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                return FriendTile(
                  friend: filteredFriends[index],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add friend functionality
        },
        child: Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditable = false;
  final TextEditingController _usernameController =
      TextEditingController(text: "osama");
  final TextEditingController _emailController =
      TextEditingController(text: "osama@example.com");
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Profile Settings",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              enabled: isEditable,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              enabled: isEditable,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              enabled: isEditable,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isEditable = !isEditable;
                });
              },
              child: Text(isEditable ? "Save Changes" : "Edit Profile"),
            ),
            SwitchListTile(
              title: Text("Enable Notifications"),
              value: true,
              onChanged: (value) {
                // Update notification settings
              },
            ),
            SizedBox(height: 20),
            Text("My Created Events",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text("Birthday Party"),
                    subtitle: Text("2 Gifts"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EventListPage(
                                friendName: "osama", eventCount: 2)),
                      );
                    },
                  ),
                  ListTile(
                    title: Text("Wedding"),
                    subtitle: Text("5 Gifts"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EventListPage(
                                friendName: "osama", eventCount: 5)),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text("My Pledged Gifts"),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPledgedGiftsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MyPledgedGiftsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Pledged Gifts")),
      body: ListView(
        children: [
          ListTile(
            title: Text("Bluetooth Speaker"),
            subtitle: Text("Friend: Alice Johnson, Due: 2024-11-30"),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Edit pledge functionality
              },
            ),
          ),
          ListTile(
            title: Text("Handmade Card"),
            subtitle: Text("Friend: Bob Brown, Due: 2024-12-15"),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Edit pledge functionality
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Friend {
  final String name;
  final String photo;
  final int upcomingEvents;

  Friend(
      {required this.name, required this.photo, required this.upcomingEvents});
}

class FriendTile extends StatelessWidget {
  final Friend friend;

  FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(friend.photo),
          radius: 25,
        ),
        title: Text(friend.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          friend.upcomingEvents > 0
              ? "Upcoming Events: ${friend.upcomingEvents}"
              : "No Upcoming Events",
          style: TextStyle(color: Colors.grey),
        ),
        trailing:
            Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventListPage(
                friendName: friend.name,
                eventCount: friend.upcomingEvents,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final List<Friend> friends;

  FriendSearchDelegate({required this.friends});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = friends
        .where(
            (friend) => friend.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView(
      children: results.map((friend) => FriendTile(friend: friend)).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = friends
        .where(
            (friend) => friend.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView(
      children:
          suggestions.map((friend) => FriendTile(friend: friend)).toList(),
    );
  }
}

class EventListPage extends StatefulWidget {
  final String friendName;
  final int eventCount;

  EventListPage({required this.friendName, required this.eventCount});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, String>> events = [
    {"name": "Birthday Party", "status": "Upcoming", "category": "Personal"},
    {"name": "Wedding", "status": "Past", "category": "Family"},
    {"name": "Graduation", "status": "Upcoming", "category": "Friends"},
    {"name": "Office Party", "status": "Current", "category": "Work"},
  ];

  String sortCriteria = "name";

  void sortEvents() {
    setState(() {
      events.sort((a, b) {
        if (sortCriteria == "name") return a["name"]!.compareTo(b["name"]!);
        if (sortCriteria == "category")
          return a["category"]!.compareTo(b["category"]!);
        if (sortCriteria == "status")
          return a["status"]!.compareTo(b["status"]!);
        return 0;
      });
    });
  }

  void _editEvent(int index) {
    final event = events[index];

    // Convert the date string to DateTime only if it is not null
    DateTime? eventDateTime;
    if (event["date"] != null) {
      eventDateTime = DateTime.tryParse(
          event["date"]!); // Use the non-null assertion operator
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventListPage(
          initialEventName: event["name"],
          initialEventDescription: event["description"],
          initialEventLocation: event["location"],
          initialEventDate: eventDateTime, // Pass DateTime instead of String
        ),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          // Update the event in your list with the new details
          events[index] = {
            "name": result['name'],
            "description": result['description'],
            "location": result['location'],
            "date": result['date'] != null
                ? result['date']
                : null, // Ensure it's a String
          };
        });
      }
    });
  }

  void _deleteEvent(int index) {
    setState(() {
      events.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friendName}'s Events"),
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
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventTile(
            eventName: event["name"]!,
            eventStatus: event["status"]!,
            category: event["category"]!,
            onEdit: () => _editEvent(index),
            onDelete: () => _deleteEvent(index),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftListPage(eventName: event["name"]!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateEventListPage()),
          );
          if (result != null) {
            setState(() {
              events.add(result);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  final String eventName;
  final String eventStatus;
  final String category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  EventTile({
    required this.eventName,
    required this.eventStatus,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = eventStatus == "Upcoming"
        ? Colors.orange
        : (eventStatus == "Current" ? Colors.green : Colors.grey);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(eventName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Category: $category, Status: $eventStatus",
            style: TextStyle(color: statusColor)),
        trailing: Wrap(
          spacing: 12,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class GiftListPage extends StatefulWidget {
  final String eventName;

  GiftListPage({required this.eventName});

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Map<String, dynamic>> gifts = [
    {"name": "Handmade Card", "category": "Craft", "status": "Pledged"},
    {
      "name": "Bluetooth Speaker",
      "category": "Electronics",
      "status": "Available"
    },
    {"name": "Gift Card", "category": "Gift Cards", "status": "Pledged"},
    {"name": "Personalized Mug", "category": "Home", "status": "Available"},
  ];

  String sortCriteria = "name";

  void sortGifts() {
    setState(() {
      gifts.sort((a, b) {
        if (sortCriteria == "name") return a["name"]!.compareTo(b["name"]!);
        if (sortCriteria == "category")
          return a["category"]!.compareTo(b["category"]!);
        if (sortCriteria == "status")
          return a["status"]!.compareTo(b["status"]!);
        return 0;
      });
    });
  }

  void _editGift(int index) async {
    // Navigate to GiftDetailsPage with the selected gift's details
    final updatedGift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiftDetailsPage(giftDetails: gifts[index]),
      ),
    );

    // If an updated gift is returned, update the gifts list
    if (updatedGift != null) {
      setState(() {
        gifts[index] =
            updatedGift; // Update the selected gift with the new details
      });
    }
  }

  void _deleteGift(int index) {
    setState(() {
      gifts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.eventName} Gifts"),
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
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return GiftTile(
            giftName: gift["name"]!,
            category: gift["category"]!,
            status: gift["status"]!,
            onEdit: () => _editGift(index),
            onDelete: () => _deleteGift(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to GiftDetailsPage and wait for the result
          final newGift = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GiftDetailsPage()),
          );

          // If a new gift is returned, update the gifts list
          if (newGift != null) {
            setState(() {
              gifts.add(newGift); // Assuming newGift is a Map<String, dynamic>
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class GiftTile extends StatelessWidget {
  final String giftName;
  final String category;
  final String status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  GiftTile({
    required this.giftName,
    required this.category,
    required this.status,
    required this.onEdit,
    required this.onDelete,
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
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class GiftDetailsPage extends StatefulWidget {
  final Map<String, dynamic>?
      giftDetails; // Optional parameter for existing gift details

  GiftDetailsPage({Key? key, this.giftDetails}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    // If giftDetails is provided, pre-fill the fields
    if (widget.giftDetails != null) {
      giftName = widget.giftDetails!["name"];
      description = widget.giftDetails!["description"] ?? '';
      category = widget.giftDetails!["category"] ?? '';
      price = widget.giftDetails!["price"]?.toDouble() ?? 0.0;
      isPledged = (widget.giftDetails!["status"] == "Pledged");
    } else {
      // Default values for new gift
      giftName = '';
      description = '';
      category = '';
      price = 0.0;
      isPledged = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.giftDetails == null ? "Add Gift" : "Edit Gift"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: giftName,
                decoration: InputDecoration(labelText: 'Gift Name'),
                onSaved: (value) => giftName = value ?? '',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a gift name';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => description = value ?? '',
              ),
              TextFormField(
                initialValue: category,
                decoration: InputDecoration(labelText: 'Category'),
                onSaved: (value) => category = value ?? '',
              ),
              TextFormField(
                initialValue: price.toString(),
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    price = double.tryParse(value ?? '0') ?? 0.0,
              ),
              SwitchListTile(
                title: Text('Pledged'),
                value: isPledged,
                onChanged: (value) {
                  setState(() {
                    isPledged = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Return the updated gift details to GiftsListPage
                    Navigator.pop(context, {
                      "name": giftName,
                      "description": description,
                      "category": category,
                      "price": price,
                      "status":
                          isPledged ? "Pledged" : "Available", // Example status
                    });
                  }
                },
                child: Text(
                    widget.giftDetails == null ? "Add Gift" : "Update Gift"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateEventListPage extends StatefulWidget {
  final String? initialEventName;
  final String? initialEventDescription;
  final String? initialEventLocation;
  final DateTime? initialEventDate;

  CreateEventListPage({
    this.initialEventName,
    this.initialEventDescription,
    this.initialEventLocation,
    this.initialEventDate,
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

  @override
  void initState() {
    super.initState();
    // Populate the fields with initial values
    eventName = widget.initialEventName;
    eventDescription = widget.initialEventDescription;
    eventLocation = widget.initialEventLocation;
    eventDate = widget.initialEventDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Event/List"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Event/List Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an event name";
                  }
                  return null;
                },
                onSaved: (value) => eventName = value,
                initialValue: eventName, // Set initial value
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: "Event Description"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an event description";
                  }
                  return null;
                },
                onSaved: (value) => eventDescription = value,
                initialValue: eventDescription, // Set initial value
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: "Event Location"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an event location";
                  }
                  return null;
                },
                onSaved: (value) => eventLocation = value,
                initialValue: eventLocation, // Set initial value
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration:
                    InputDecoration(labelText: "Event Date (YYYY-MM-DD)"),
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
                readOnly: true,
                validator: (value) {
                  if (eventDate == null) {
                    return "Please select an event date";
                  }
                  return null;
                },
                controller: TextEditingController(
                  text: eventDate != null
                      ? "${eventDate!.toLocal()}".split(' ')[0]
                      : "",
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Handle the creation or update of the event/list
                    Navigator.pop(context, {
                      'name': eventName,
                      'description': eventDescription,
                      'location': eventLocation,
                      'date': eventDate,
                    });
                  }
                },
                child: Text("Save Event/List"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
