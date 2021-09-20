import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import 'package:sqflite/sqflite.dart';

import 'model/contacts.dart';
import 'db.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: 'CONTACTS PAGE'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseHandler dbHandler = new DatabaseHandler();
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasLoaded = false;

  int limit = 7;
  List<Contact> contactsList = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        if (_hasLoaded == false) {
          setState(() => _isLoading = true);
          _fetchMoreData();
        } else {
          print('End of list');
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future _fetchInitialData() async {
    var result = await dbHandler.loadFirstNContacts(limit);
    setState(() => contactsList = result);
  }

  Future _fetchMoreData() async {
    var result = await dbHandler.loadRemainingContacts(limit);
    setState(() {
      _isLoading = false;
      _hasLoaded = true;
      contactsList.addAll(result);
    });
  }

  String convertTimeAgo(String input) {
    Duration diff = DateTime.now().difference(DateTime.parse(input));

    if (diff.inDays >= 1) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 1) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFD0D5D6),
        appBar: AppBar(
          title: Text(widget.title,
              style:
                  GoogleFonts.sen(fontWeight: FontWeight.w700, fontSize: 25)),
          backgroundColor: Color(0xFF282E34),
        ),
        body: Center(
            child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.60,
                margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
                decoration: BoxDecoration(
                    color: Color(0xFFFBFDFF),
                    border: Border.all(color: Color(0xFF77848B), width: 3),
                    borderRadius: BorderRadius.circular(15)),
                child: contactsList.isEmpty
                    ? Center(child: Text('Loading...'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _isLoading
                            ? contactsList.length + 1
                            : contactsList.length + 1,
                        itemBuilder: (context, int index) {
                          if (contactsList.length == index &&
                              _isLoading == true) {
                            return Center(child: CircularProgressIndicator());
                          } else if (contactsList.length == index &&
                              _hasLoaded == false) {
                            return Container(
                                alignment: Alignment.center,
                                child: Text('Load more'));
                          } else if (contactsList.length == index &&
                              _hasLoaded == true) {
                            return Container(
                                alignment: Alignment.center,
                                child: Text('End of list'));
                          }
                          return ListTile(
                            title: Wrap(spacing: 5, children: <Widget>[
                              Icon(Icons.person, size: 15),
                              Text(
                                contactsList[index].user,
                                style: GoogleFonts.ruluko(fontSize: 18),
                              )
                            ]),
                            subtitle: Wrap(spacing: 5, children: <Widget>[
                              Icon(Icons.phone, size: 15),
                              Text(
                                contactsList[index].phone,
                                style: GoogleFonts.ruluko(fontSize: 17),
                              ),
                            ]),
                            trailing: Text(
                              convertTimeAgo(contactsList[index].checkin),
                              style: GoogleFonts.ruluko(fontSize: 15),
                            ),
                          );
                        }))));
  }
}
