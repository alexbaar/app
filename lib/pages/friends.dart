import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/friend.dart';  // Assuming friend.dart is placed under models directory
import '../components/bottom_navigation_bar.dart';
import '../components/main_app_background.dart';
import '../utilities/constants.dart';
import 'friend_detail_page.dart';

class MyFriendScreen extends StatefulWidget {
  const MyFriendScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyFriendScreen> createState() => _MyFriendScreenState();
}

class _MyFriendScreenState extends State<MyFriendScreen> {
  int _currentIndex = 2;
  List<Friend> friends = [];
  TextEditingController _searchController = TextEditingController();

  Future<void> fetchFriends() async {
    await dotenv.load(fileName: ".env");
    String? baseURL = dotenv.env['API_URL_BASE'];
    if (baseURL != null) {
      String apiUrl = '$baseURL/users/';
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          friends = (json.decode(response.body) as List)
              .map((data) => Friend.fromJson(data, baseURL))
              .toList();
        });
      } else {
        throw Exception('Failed to load friends: ${response.statusCode}');
      }
    } else {
      print('BASE_URL is not defined in .env file');
    }
  }

  void filterFriends(String query) {
    setState(() {
      friends = friends.where((friend) => (friend.name + ' ' + friend.surname).toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kLoginRegisterBtnColour.withOpacity(0.9),
        title: Text('My Friends', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: CustomGradientContainerSoft(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Friends',
                  hintText: 'Type a name or surname',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                onChanged: filterFriends,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: friend.imagePath.isNotEmpty
                          ? NetworkImage(friend.imagePath)
                          : AssetImage('assets/profile_default.png') as ImageProvider,
                    ),
                    title: Text('${friend.name} ${friend.surname}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendDetailPage(friend: friend),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(initialIndex: _currentIndex),
    );
  }
}
