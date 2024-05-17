import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../components/bottom_navigation_bar.dart';
import '../components/main_app_background.dart';
import '../models/user_details.dart';
import '../utilities/constants.dart';
import 'home_page.dart';
import 'my_stats.dart';
import 'settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend.dart';
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
  String _sortByValue = "Ascending";
  TextEditingController _searchController = TextEditingController();

  Future<void> fetchFriends() async {
    await dotenv.load(fileName: ".env");
    String? baseURL = dotenv.env['API_URL_BASE'];

    if (baseURL != null) {
      String apiUrl = '$baseURL/api/data';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> friendsData = data['friends'];

          setState(() {
            friends = friendsData.map((friendData) => Friend.fromJson(friendData)).toList();
          });
        } else {
          throw Exception('Failed to load friends: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
      }
    } else {
      print('BASE_URL is not defined in .env file');
    }
  }

  void filterFriends(String query) {
    setState(() {
      friends = friends.where((friend) => friend.name.toLowerCase().contains(query.toLowerCase())).toList();
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  title: 'Home Page',
                ),
              ),
            );
          },
        ),
        title: Text('My Friends', style: kSubSubTitleOfPage),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Row(
                children: [
                  Text("Total Friends: ${friends.length}", style: kSubSubTitleOfPage),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: _sortByValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            _sortByValue = newValue!;
                          });
                        },
                        items: ['Ascending', 'Recently Met'].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: kSimpleTextWhite),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return TransparentProfileButton(
                    name: friend.name,
                    mutualFriends: friend.mutualFriends,
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

class TransparentProfileButton extends StatelessWidget {
  final String name;
  final String mutualFriends;
  final VoidCallback onTap;

  TransparentProfileButton({
    required this.name,
    required this.mutualFriends,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.94,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile_image.jpg'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  mutualFriends,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            child: Text("Unfriend"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
