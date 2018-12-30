// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

void main() {
//  debugPaintSizeEnabled = true;
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MainWidget()));
}

class MainWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 5, title: Text("Graphql Flutter"),),
      body: UserList(),
    );
  }
}

class UserList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserListState();
  }
}

class User {
  final String firstName;
  final String lastName;
  final String avatar;
  final String email;

  User({
    this.firstName,
    this.lastName,
    this.avatar,
    this.email,
  });
}

Future<List<dynamic>> getUsers() async {
  final query = """
  {
  allUsers {
    firstName
    lastName
    avatar
    email
  }
}
""";

  final bodyJson = json.encode({"query": query});
  final response = await http.post("https://fakerql.com/graphql",
      headers: {
        "Content-Type": "application/json",
      },
      body: bodyJson);

  print("graphql replied: " + response.statusCode.toString());
  if (response.statusCode != 200) {
    throw Exception('Failed to load users');
  }

  final decodedJson = json.decode(response.body);

  return decodedJson["data"]["allUsers"].map((user) {
    return User(
      firstName: user["firstName"],
      lastName: user["lastName"],
      avatar: user["avatar"],
      email: user["email"],
    );
  }).toList();
}

class UserListState extends State<UserList> {
  Future<List<dynamic>> itemsFuture;
  ScrollController _controller;

  _scrollListener() {}

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    itemsFuture = getUsers();
  }

  Widget _buildUser(User user) {
    return Row(children: <Widget>[
      Container(
          padding: EdgeInsets.all(16),
          child: CircleAvatar(
            backgroundImage: NetworkImage(user.avatar),
          )),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "${user.firstName} ${user.lastName}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            user.email,
            style: TextStyle(fontSize: 14),
          )
        ],
      )
    ]);
  }

  Widget _buildList(List list) {
    return NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            _onStartScroll(scrollNotification.metrics);
          } else if (scrollNotification is ScrollUpdateNotification) {
            _onUpdateScroll(scrollNotification.metrics);
          } else if (scrollNotification is ScrollEndNotification) {
            _onEndScroll(scrollNotification.metrics);
          }
        },
        child: ListView.builder(
            shrinkWrap: true,
            controller: _controller,
            itemCount: list.length,
            itemBuilder: (context, i) {
              var child = _buildUser(list[i]);

              var color = Colors.white;
              if (i % 2 != 0) {
                color = Color.fromARGB(255, 0xf6, 0xf6, 0xf6);
              }

              return Container(
                  decoration: BoxDecoration(color: color), child: child);
            }));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
        future: itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildList(snapshot.data);
          } else if (snapshot.hasError) {
            print(snapshot.error.toString());
            return Center(child: Text("Oooops, something went wrong"));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  void _onStartScroll(ScrollMetrics metrics) {}

  void _onUpdateScroll(ScrollMetrics metrics) {}

  void _onEndScroll(ScrollMetrics metrics) {
    setState(() {});
  }
}
