import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../untils/untils.dart';
import '../Login_pages/LoginScreen.dart';
import 'Dashboard/ApplyLeave.dart';
import 'Dashboard/ChangePassword.dart';
import 'Dashboard/Leave Status.dart';
import 'Dashboard/Report.dart';
import 'Dashboard/app_rating.dart';
import 'Dashboard/manager/Event Calender.dart';
import 'Dashboard/manager/ManagerLeaveApporval.dart';
import 'Dashboard/manager/TeamAttendance.dart';
import 'Dashboard/manager/TeamReport.dart';
import 'Dashboard/profile_screen.dart';

class Dashbordscreen extends StatefulWidget {
  const Dashbordscreen({super.key});

  @override
  State<Dashbordscreen> createState() => _DashbordscreenState();
}

class _DashbordscreenState extends State<Dashbordscreen> {
  double screenHeight = 0.h;
  double screenWidth = 0.w;
  String emp_name = "";
  String greeting = "";

  void handleNavigation(String menuItem) async {
    // Implement navigation based on menu item
    switch (menuItem) {
      case "Profile":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
        break;
      case "Apply Leave":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyLeave()));
        break;
      case "Leave Status":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveStatus()));
        break;
      case "Change Password":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword()));
        break;
      case "Reports":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
        break;
      case "App rating":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AppRating()));
        break;

      case "Logout":
        // Perform logout logic
        await logoutUser();
        break;
    }
  }
 void handleNavigation2(String Managermenu) async {
    // Implement navigation based on menu item
    switch (Managermenu) {
      case "Profile":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
        break;
      case "Apply Leave":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyLeave()));
        break;
      case "Leave Status":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveStatus()));
        break;
      case "Change Password":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword()));
        break;
      case "Reports":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
        break;
      case "App rating":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AppRating()));
        break;
        case "Team attendance":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Teamattendance()));
        break;
        case "Manager Leave Apporval":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Managerleaveapporval()));
        break;case "Team Report ":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Teamreport()));
        break;case "Event Calender":
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EventCalendar()));
        break;
      case "Logout":
        // Perform logout logic
        await logoutUser();
        break;
    }
  }

  Future<void> logoutUser() async {
    const String apiUrl = 'http://35.154.148.75/zarvis/api/v2/logout';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      print('Token: $token');

      if (token == null) {
        print('Token is null');
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': '1',
          'message': 'User successfully logged out.',
        }),
      );

      if (response.statusCode == 200) {
        // Clear SharedPreferences on successful logout
        prefs.remove('token');
        prefs.remove('emp_name');

        // Navigate to LoginScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        print('Failed to logout: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Handle logout failure
      }
    } catch (e) {
      print('Error during logout: $e');
      // Handle logout error
    }
  }

  @override
  void initState() {
    super.initState();
    getUserName(); // Call getUserName() to fetch employee name when the widget initializes
  }

  void getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    emp_name = prefs.getString('emp_name') ??
        ""; // Get employee name from SharedPreferences
    setGreeting(); // Set the greeting based on the current time
    setState(() {
      // Set state to update UI with employee name and greeting
      print(emp_name);
    });
  }

  void setGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }
  }

  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height.h;
    screenWidth = MediaQuery.of(context).size.width.w;

    return SafeArea(
        top: true,
        child: isManager == true
            ?

            ///manager
            Scaffold(
                body: SizedBox(
                  width: screenWidth,
                  height: screenHeight,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            top: 15, left: 15, right: 15, bottom: 1),
                        width: screenWidth.w,
                        height: screenHeight / 1.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(70),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: const SizedBox(height: 40)),
                            Text(
                              "$greeting, \n$emp_name\nmanager", // Display greeting and employee name
                              style: const TextStyle(
                                fontSize: 35,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: screenHeight / 1.7.h,
                          width: screenWidth.w,
                          padding: const EdgeInsets.only(top: 0, bottom: 0),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(70),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20, left: 15, right: 15),
                            child: SingleChildScrollView(
                              child: GridView.builder(
                                itemCount: Managermenu.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.1,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                ),
                                itemBuilder: (context, index) {
                                  return AnimatedIconTile(
                                    icon: ManagermenuIcons[index],
                                    color: ManagermenuColors[index],
                                    label: Managermenu[index],
                                    onTap: () => handleNavigation2(Managermenu[index]),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            :

            ///emp
            Scaffold(
                body: SizedBox(
                  width: screenWidth,
                  height: screenHeight,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            top: 15, left: 15, right: 15, bottom: 1),
                        width: screenWidth.w,
                        height: screenHeight / 1.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(70),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: const SizedBox(height: 40)),
                            Text(
                              "$greeting ,\n$emp_name", // Display greeting and employee name
                              style: const TextStyle(
                                fontSize: 35,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // SizedBox(height: 4),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: screenHeight / 1.7.h,
                          width: screenWidth.w,
                          padding: const EdgeInsets.only(top: 0, bottom: 0),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(70),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20, left: 15, right: 15),
                            child: SingleChildScrollView(
                              child: GridView.builder(
                                itemCount: menu.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.1,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                ),
                                itemBuilder: (context, index) {
                                  return AnimatedIconTile(
                                    icon: menuIcons[index],
                                    color: menuColors[index],
                                    label: menu[index],
                                    onTap: () => handleNavigation(menu[index]),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
  }
}

class AnimatedIconTile extends StatefulWidget {
  final Icon icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const AnimatedIconTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedIconTileState createState() => _AnimatedIconTileState();
}

class _AnimatedIconTileState extends State<AnimatedIconTile>
    with SingleTickerProviderStateMixin {
  double scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() {
      scale = 0.9;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      scale = 1.0;
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () {
        setState(() {
          scale = 1.0;
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.identity()..scale(scale),
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: widget.icon,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
