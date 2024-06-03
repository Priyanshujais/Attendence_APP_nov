import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Login_pages/LoginScreen.dart';
import 'drawer_pages/ApplyLeave.dart';
import 'drawer_pages/ChangePassword.dart';
import 'drawer_pages/Leave Status.dart';
import 'drawer_pages/Report.dart';
import 'drawer_pages/calendar_screen.dart';
import 'drawer_pages/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isIn = true;

  // Define data
  Map<String, dynamic> data = {
  "name": [
  'Profile',
  "Attendance Calendar",
  "Apply Leave",
  "Leave Status",
  "Change Password",
  "Report"
  ], // Example list of names
    'goto': [
      ProfileScreen(), CalendarScreen(),
      LeaveScreen(),LeaveStatus(), Changepassword(),
      ReportScreen(),
    ],
  };
  // Define isTapped list
  List<bool> isTapped = List.generate(
    6,
        (index) => false,
  );

  // Define _selectItem method
  void _selectItem(int index) {
    setState(() {
      // Reset all tiles to unselected state
      isTapped = List.generate(6, (index) => false);
      // Set the tapped tile to selected state
      isTapped[index] = true;
    });
  }

  void toggleState() {
    setState(() {
      isIn = !isIn;
      print(isIn ? "IN" : "OUT"); // Log the state to console
    });
  }

  Future<void> _showReportDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("To mark attendence",
            ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Date:'),
                // Display calendar here
                SizedBox(height: 10),
                Text('Status:'),
                // Dropdown for selecting status here
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Remarks',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add functionality to save the report here
                Navigator.of(context).pop();
              },
              child: Text("Add report"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ZARVIS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.pink.shade800,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              size: 40,
              color: Colors.white,
            ),
            onPressed: () {
              // Add functionality for bell icon here
            },
          ),
        ],
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 35,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Image.asset("assets/images/zarvis.png"),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: 6,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    data['name'][index],
                    style: TextStyle(
                      color: isTapped[index] ? Colors.red : Colors.black,
                    ),
                  ),
                  onTap: () {
                    _selectItem(index); // Set the tapped item to selected state
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => data['goto'][index],
                      ),
                    );
                  },
                );
              },
            ),

            Divider(),
            ListTile(
              title: Text('App Rating'),
              onTap: () {
                // Add functionality for drawer item 2
              },
            ),
            ListTile(
              title: Text('Log Out'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background image here
          Center(
            child: Container(
              height: 200.h,
              width: 200.w,
              decoration: BoxDecoration(
                color: isIn ? Colors.pink.shade800 : Colors.red.shade800,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: () {
                  toggleState();
                  _showReportDialog(context);
                },
                child: Center(
                  child: Text(
                    isIn ? "IN" : "OUT",
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}