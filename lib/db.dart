import 'dart:async';
import 'model/contacts.dart';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

class DatabaseHandler {
  Future<Database> initializeDB() async {
    final db = openDatabase(
      join(await getDatabasesPath(), 'contact_db.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, user TEXT, phone TEXT, checkin TEXT)',
        );
        await db.execute(
            'CREATE TABLE setting(id INTEGER PRIMARY KEY DEFAULT 1 NOT NULL, timeAgo INTEGER DEFAULT 0 NOT NULL )');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 4) {
          await db.execute(
              'CREATE TABLE setting(id INTEGER PRIMARY KEY DEFAULT 1 NOT NULL, timeAgo INTEGER DEFAULT 0 NOT NULL )');
        }
      },
      version: 5,
    );
    return db;
  }

  Future<void> insertContact(Contact contact) async {
    final db = await initializeDB();

    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Contact>> loadFirstNContacts(int n) async {
    final db = await initializeDB();
    final List<Map<String, dynamic>> maps =
        await db.query('contacts', orderBy: 'checkin DESC', limit: n);
    return List.generate(maps.length, (i) {
      return Contact(
        id: maps[i]['id'],
        user: maps[i]['user'],
        phone: maps[i]['phone'],
        checkin: maps[i]['checkin'],
      );
    });
  }

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

  Future<int> getCount() async {
    final db = await initializeDB();

    int count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT (*) FROM contacts'))!;

    return count;
  }

  Future<void> deleteContact() async {
    final db = await initializeDB();

    await db.delete('contacts');
  }

  // Future updateTimeAgo() async {
  //   final db = await initializeDB();

  //   int updateCount = await db.update(
  //     'setting',
  //     {'timeAgo': 1},
  //   );
  //   print(updateCount);
  // }

  // Future getTimeAgo() async {
  //   final db = await initializeDB();
  //   final List<Map<String, dynamic>> maps = await db.query('setting');
  //   return List.generate(maps.length, (i) {
  //     return maps[i]['timeAgo'];
  //   });
  // }
}
