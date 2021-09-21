import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'model/contacts.dart';

// Input from contacts example dataset
final input = '''
{
"user": "Chan Saw Lin"
"phone": "0152131113"
"check-in": 2020-06-30 16:10:05
},
{
"user": "Lee Saw Loy"
"phone": "0161231346"
"check-in": 2020-07-11 15:39:59
},
{
"user": "Khaw Tong Lin"
"phone": "0158398109"
"check-in": 2020-08-19 11:10:18
},
{
"user": "Lim Kok Lin"
"phone": "0168279101"
"check-in": 2020-08-19 11:11:35
},
{
"user": "Low Jun Wei"
"phone": "0112731912"
"check-in": 2020-08-15 13:00:05
},
{
"user": "Yong Weng Kai"
"phone": "0172332743"
"check-in": 2020-07-31 18:10:11
},
{
"user": "Jayden Lee"
"phone": "0191236439"
"check-in": 2020-08-22 08:10:38
},
{
"user": "Kong Kah Yan"
"phone": "0111931233"
"check-in": 2020-07-11 12:00:00
},
{
"user": "Jasmine Lau"
"phone": "0162879190"
"check-in": 2020-08-01 12:10:05
},
{
"user": "Chan Saw Lin"
"phone": "016783239"
"check-in": 2020-08-23 11:59:05
}
''';

// Function to convert from
// {
//   "user": "Example 1"
//   "phone": "0123456789"
//   "check-in": 2021-09-19 19:15:05
// }
// ...
// to
// ...
// {
//   "user": "Example 1",
//   "phone": "0123456789",
//   "checkin": "2021-09-19 19:15:05"
// }
//
// and returns List of Contacts
convertJsonReadable(var input) {
  input = input.replaceAll('check-in', 'checkin');
  input = input.split(',');

  List inputs = [];
  for (int i = 0; i < input.length; i++) {
    String output = '';
    if (i != 0) {
      input[i] = input[i].substring(1, input[i].length);
    }
    var temp = input[i].split('\n');
    temp[1] = temp[1] + ',';
    temp[2] = temp[2] + ',';
    for (int j = 0; j < temp.length; j++) {
      var newString = temp[3];
      newString = temp[3].substring(0, 11) +
          '\"' +
          temp[3].substring(11, temp[3].length) +
          '\"';
      if (j != 3) {
        output += temp[j];
      } else {
        output += newString;
      }
    }
    inputs.add(output);
  }

  List<Contact> result = [];
  for (var i in inputs) {
    Map<String, dynamic> jsonFormat = jsonDecode(i);
    var newContact = Contact(
        user: jsonFormat['user'],
        phone: jsonFormat['phone'],
        checkin: jsonFormat['checkin']);
    result.add(newContact);
  }
  return result;
}

// DatabaseHandler Class for API calls
class DatabaseHandler {
  // Initializing Database
  Future<Database> initializeDB() async {
    final db = openDatabase(
      join(await getDatabasesPath(), 'contacts_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, user TEXT, phone TEXT, checkin TEXT)',
        );
        await db.execute(
          'CREATE TABLE settings(timeAgo INTEGER)',
        );
      },
      version: 1,
    );
    return db;
  }

  // Insert new Contact into database
  Future<void> insertContact(Contact contact) async {
    final db = await initializeDB();

    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert default setting of timeAgo format
  Future<void> insertSetting(int i) async {
    final db = await initializeDB();

    await db.insert('settings', {'timeAgo': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Load n number of contacts to display initially
  Future<List<Contact>> loadFirstNContacts(int n) async {
    final db = await initializeDB();
    List<Map<String, dynamic>> maps =
        await db.query('contacts', orderBy: 'checkin DESC', limit: n);
    if (maps.length == 0) {
      for (var i in convertJsonReadable(input)) {
        await insertContact(i);
      }
      await insertSetting(0);
      maps = await db.query('contacts', orderBy: 'checkin DESC', limit: n);
    }
    return List.generate(maps.length, (i) {
      return Contact(
        id: maps[i]['id'],
        user: maps[i]['user'],
        phone: maps[i]['phone'],
        checkin: maps[i]['checkin'],
      );
    });
  }

  // Load the rest of the contacts if user scrolls down
  Future<List<Contact>> loadRemainingContacts(int n) async {
    final db = await initializeDB();

    final List<Map<String, dynamic>> maps = await db.query('contacts',
        orderBy: 'checkin DESC', limit: -1, offset: n);
    return List.generate(maps.length, (i) {
      return Contact(
        id: maps[i]['id'],
        user: maps[i]['user'],
        phone: maps[i]['phone'],
        checkin: maps[i]['checkin'],
      );
    });
  }

  // Pull-to-refresh generate random contacts
  Future insertRandomContacts(int n) async {
    var result = convertJsonReadable(input);
    var contacts = [];
    for (int i = 0; i < n; i++) {
      var random = new Random();
      contacts.add(result[random.nextInt(result.length - 1)]);
    }

    return contacts;
  }

  // Get the total number of contacts in the database
  Future<int> getCount() async {
    final db = await initializeDB();

    int count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT (*) FROM contacts'))!;

    return count;
  }

  // Delete all contacts (not used)
  Future<void> deleteContact() async {
    final db = await initializeDB();

    await db.delete('contacts');
  }

  // Update user settings of timeAgo formatting
  Future updateTimeAgo(int value) async {
    final db = await initializeDB();

    await db.update(
      'settings',
      {'timeAgo': value},
    );
  }

  // Retrieve user settings of timeAgo formatting
  Future getTimeAgo() async {
    final db = await initializeDB();
    final List<Map<String, dynamic>> maps = await db.query('settings');
    return List.generate(maps.length, (i) {
      return maps[i]['timeAgo'];
    });
  }
}
