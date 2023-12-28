import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:concats_buddy/models/contact_model.dart';
import 'package:concats_buddy/utils/database_helper.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts Buddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 3, 74, 132)),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading contacts
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ContactListScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/splash.png'), // Replace with your splash image
      ),
    );
  }
}

class ContactListScreen extends StatefulWidget {
  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final dbHelper = DatabaseHelper();
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  _refreshContacts() async {
    List<Contact>? updatedContacts = await dbHelper.getContacts();
    setState(() {
      contacts = updatedContacts ?? [];
    });
  }

  _navigateToAddContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddContactScreen()),
    );

    _refreshContacts();
  }

  _navigateToUpdateContact(Contact contact) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateContactScreen(contact),
      ),
    );

    _refreshContacts();
  }

  _showDeleteDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Contact'),
          content: Text('Are you sure you want to delete ${contact?.name ?? ""}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteContact(contact);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  _deleteContact(Contact? contact) async {
    if (contact == null || contact.id == null) {
      print("Contact or contact ID is null");
      return;
    }

    int contactId = contact.id!;
    await dbHelper.deleteContact(contactId);
    _refreshContacts();
  }

  _searchContacts(String query) async {
    List<Contact>? filteredContacts =
        await dbHelper.searchContacts(query);
    setState(() {
      contacts = filteredContacts ?? [];
    });
  }

  Widget _buildContactItem(Contact contact) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      title: Text(
        contact.name ?? "",
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        contact.phoneNumber ?? "",
        style: TextStyle(fontSize: 14.0, color: Colors.grey),
      ),
      leading: CircleAvatar(
        radius: 30,
        child: Text(
          contact.name?[0] ?? "",
          style: TextStyle(fontSize: 20.0),
        ),
      ),
      onTap: () {
        _navigateToUpdateContact(contact);
      },
      onLongPress: () {
        _showDeleteDialog(contact);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contacts Buddy',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContactSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Add settings functionality
            },
          ),
        ],
      ),
      body: contacts.isEmpty
          ? Center(
              child: Text(
                'No contacts available',
                style: TextStyle(fontSize: 16.0),
              ),
            )
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return _buildContactItem(contacts[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddContact();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class ContactSearchDelegate extends SearchDelegate<void> {
  final dbHelper = DatabaseHelper();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
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
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder(
      future: dbHelper.searchContacts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<Contact>? searchResults = snapshot.data;

        return ListView.builder(
          itemCount: searchResults?.length ?? 0,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(searchResults?[index].name ?? ""),
              subtitle: Text(searchResults?[index].phoneNumber ?? ""),
              onTap: () {
                // Handle tapping on a search result
              },
            );
          },
        );
      },
    );
  }
}

class AddContactScreen extends StatefulWidget {
  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final dbHelper = DatabaseHelper();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _phoneNumberController,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                Contact newContact = Contact(
                  id: null,
                  name: _nameController.text,
                  phoneNumber: _phoneNumberController.text,
                );
                await dbHelper.saveContact(newContact);
                Navigator.pop(context); // Return to the previous screen
              },
              child: Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateContactScreen extends StatefulWidget {
  final Contact contact;

  UpdateContactScreen(this.contact);

  @override
  _UpdateContactScreenState createState() => _UpdateContactScreenState();
}

class _UpdateContactScreenState extends State<UpdateContactScreen> {
  final dbHelper = DatabaseHelper();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.contact.name ?? "";
    _phoneNumberController.text = widget.contact.phoneNumber ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (value) {
                widget.contact.name = value;
              },
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _phoneNumberController,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _phoneNumberController.text.isNotEmpty) {
                  widget.contact.name = _nameController.text;
                  widget.contact.phoneNumber = _phoneNumberController.text;

                  await dbHelper.updateContact(widget.contact);
                  Navigator.pop(context); // Return to the previous screen
                } else {
                  // Show error or handle accordingly
                }
              },
              child: Text('Update Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

