import 'package:flutter/material.dart';
import 'package:myapp/sql_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
        debugShowCheckedModeBanner: false,
        // title: 'To-Do',
        theme: ThemeData(
          primarySwatch: Colors.orange,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All journals
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
 
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _refreshJournals(); // Loading the diary when the app starts
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel name
      channelDescription: 'your_channel_description', // Channel description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
      _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                // onPressed: () async {
                //   // Save new journal
                //   if (id == null) {
                //     await _addItem();
                //   }

                //   if (id != null) {
                //     await _updateItem(id);
                //   }
                onPressed: () async {
                if (id == null) {
                  await _addItem();
                  _showNotification('Task Created', 'Your task has been created successfully.');
                } else {
                  await _updateItem(id);
                  _showNotification('Task Updated', 'Your task has been updated successfully.');
                }

                  // Clear the text fields
                  _titleController.text = '';
                  _descriptionController.text = '';

                  // Close the bottom sheet
                  Navigator.of(context).pop();
                },
                child: Text(id == null ? 'Create New' : 'Update'),
              )
            ],
          ),
        ));
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    final existingJournal = _journals.firstWhere((element) => element['id'] == id);
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text, existingJournal['isDone']);
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    _showNotification('Task Deleted', 'Your task has been deleted successfully.');
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //   content: Text('Successfully deleted a journal!'),
    // ));
    _refreshJournals();
  }

   Future<void> _toggleDone(int id, bool isDone) async {
    final existingJournal = _journals.firstWhere((element) => element['id'] == id);
    await SQLHelper.updateItem(id, existingJournal['title'], existingJournal['description'], isDone ? 1 : 0);
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _journals.length,
        itemBuilder: (context, index) => Card(
          color: Colors.orange[200],
          margin: const EdgeInsets.all(15),
          child: ListTile(
             leading: Checkbox(
                    value: _journals[index]['isDone'] == 1,
                    onChanged: (bool? value) {
                      _toggleDone(_journals[index]['id'], value!);
                    },
                  ),
              // title: Text(_journals[index]['title']),
              title: Text(
                    _journals[index]['title'],
                    style: TextStyle(
                      decoration: _journals[index]['isDone'] == 1
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
              // subtitle: Text(_journals[index]['description']),
              subtitle: Text(
                    _journals[index]['description'],
                    style: TextStyle(
                      decoration: _journals[index]['isDone'] == 1
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.edit),
                    //   onPressed: () => _showForm(_journals[index]['id']),
                    // ),
                    IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _journals[index]['isDone'] == 1
                              ? null
                              : () => _showForm(_journals[index]['id']),
                        ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete),
                    //   onPressed: () =>
                    //       _deleteItem(_journals[index]['id']),
                    // ),
                    IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _journals[index]['isDone'] == 1
                              ? null
                              : () => _deleteItem(_journals[index]['id']),
                        ),
                  ],
                ),
              )),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}