import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'model/contacts.dart';
import 'db.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: 'CONTACTS PAGE'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseHandler dbHandler = new DatabaseHandler();
  ScrollController _scrollController = ScrollController();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSwitched = false;
  bool _isCounted = false;
  int count = 0;

  int limit = 7;
  List<Contact> contactsList = [];

  @override
  void initState() {
    super.initState();
    dbHandler.deleteContact();
    _fetchInitialData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        if (_hasLoaded == false) {
          setState(() => _isLoading = true);
          _fetchMoreData();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    Fluttertoast.cancel();
    super.dispose();
  }

  // Called once during initState()
  Future _fetchInitialData() async {
    var result = await dbHandler.loadFirstNContacts(limit);
    var switched = await dbHandler.getTimeAgo();
    var countNumber = await dbHandler.getCount();
    setState(() {
      count = countNumber;
      contactsList = result;
      if (switched[0] == 0) {
        _isSwitched = false;
      } else {
        _isSwitched = true;
      }
    });
  }

  // When user scrolls down, loads the rest of contacts data
  Future _fetchMoreData() async {
    var result = await dbHandler.loadRemainingContacts(limit);
    setState(() {
      _isLoading = false;
      _hasLoaded = true;
      _isCounted = true;
      contactsList.addAll(result);
    });
  }

  // Convert from original time format to time ago format
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

  // Sharing function
  void shareContact(String user, String phone) {
    Share.share('Name: $user\nPhone: $phone');
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
          margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: <Widget>[
              _buildTopPortion(),
              Container(
                height: MediaQuery.of(context).size.height * 0.60,
                decoration: BoxDecoration(
                    color: Color(0xFFFBFDFF),
                    border: Border.all(color: Color(0xFF77848B), width: 3),
                    borderRadius: BorderRadius.circular(5)),
                child: contactsList.isEmpty
                    ? Center(child: Text('Loading...'))
                    : _buildListPortion(),
              ),
            ],
          ),
        )));
  }

  Widget _buildListView() {
    return ListView.builder(
        controller: _scrollController,
        itemCount:
            _isLoading ? contactsList.length + 1 : contactsList.length + 1,
        itemBuilder: (context, int index) {
          if (contactsList.length == index && _isLoading == true) {
            return Center(child: CircularProgressIndicator());
          } else if (contactsList.length == index && _hasLoaded == false) {
            return Container(
                alignment: Alignment.center, child: Text('Load more'));
          } else if (contactsList.length == index && _hasLoaded == true) {
            return Container(
                decoration: BoxDecoration(
                    color: Colors.grey[600],
                    border: Border(top: BorderSide(color: Colors.blueGrey))),
                height: 40,
                alignment: Alignment.center,
                child: Text('--- You have reached end of the list ---',
                    style:
                        GoogleFonts.abel(fontSize: 18, color: Colors.white)));
          }
          return Slidable(
            child: ListTile(
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
              trailing: _isSwitched
                  ? Text(
                      convertTimeAgo(contactsList[index].checkin),
                      style: GoogleFonts.ruluko(fontSize: 15),
                    )
                  : Text(contactsList[index].checkin,
                      style: GoogleFonts.ruluko(fontSize: 15)),
            ),
            actionPane: SlidableDrawerActionPane(),
            actionExtentRatio: 0.25,
            actions: [
              IconSlideAction(
                  caption: 'Share',
                  icon: Icons.share,
                  color: Color(0xFF77848B),
                  onTap: () => shareContact(
                      contactsList[index].user, contactsList[index].phone))
            ],
          );
        });
  }

  Widget _buildTopPortion() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('Contacts: ${_isCounted ? contactsList.length : count}',
              style: GoogleFonts.ruluko(
                  fontSize: 25, fontWeight: FontWeight.w500)),
          _buildSwitch(),
        ],
      ),
    );
  }

  Widget _buildListPortion() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: false,
      onRefresh: () async {
        var contacts = await dbHandler.insertRandomContacts(5);
        for (int i = 0; i < contacts.length; i++) {
          contactsList.add(contacts[i]);
        }
        Fluttertoast.showToast(
            msg: "Added 5 contacts",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.grey,
            textColor: Colors.white,
            fontSize: 16.0);
        setState(() => contactsList);
        _refreshController.refreshCompleted();
      },
      child: _buildListView(),
    );
  }

  Widget _buildSwitch() {
    return Switch(
        value: _isSwitched,
        onChanged: (value) {
          setState(() {
            if (value == false) {
              dbHandler.updateTimeAgo(0);
            } else {
              dbHandler.updateTimeAgo(1);
            }
            _isSwitched = value;
          });
        });
  }
}
