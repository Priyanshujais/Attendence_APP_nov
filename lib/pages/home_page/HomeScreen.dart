import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zarvis_app/pages/home_page/CalenderScreen.dart';
import 'package:zarvis_app/pages/home_page/DashbordScreen.dart';
import 'package:zarvis_app/pages/home_page/TodayScreen.dart';

import '../Login_pages/LoginScreen.dart';

class Homescreen extends StatefulWidget {
  String deviceId;
  String empCode;
  String userId;
  String clientId;
  String projectCode;
  String locationId;
  String companyId;
  String token;

  Homescreen({
    super.key,
    required this.token,
    required this.locationId,
    required this.userId,
    required this.projectCode,
    required this.deviceId,
    required this.clientId,
    required this.companyId,
    required this.empCode,
  });

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  int currentIndex = 1; // Set initial index to 1 for Todayscreen

  List<IconData> navigatioIcon = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.dashcube,
  ];

  @override
  void initState() {
    super.initState();
    log('this is emp code---- ${widget.empCode}');
    log('this is token ----${widget.token}');
    log('this is location id---- ${widget.locationId}');
    log('this is project id-----${widget.projectCode}');
    log("this is comp is -----${widget.companyId}");
    log("this is device id -----${widget.deviceId}");
    log("this is client id ---${widget.clientId}");
    log("this is user id ----${widget.userId}");
    getDetails(); // Call getDetails to store values in SharedPreferences
  }

  Future<void> getDetails() async {
    // Get SharedPreferences instance
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("token", widget.token);
    await prefs.setString("userId", widget.userId);
    await prefs.setString("projectCode", widget.projectCode);
    await prefs.setString("companyId", widget.companyId);
    await prefs.setString("empCode", widget.empCode);
    await prefs.setString("locationId", widget.locationId);
    await prefs.setString("deviceId", widget.deviceId);
    await prefs.setString("clientId", widget.clientId);


    log("Stored token: ${prefs.getString('token')}");
    log("Stored userId: ${prefs.getString('userId')}");
    log("Stored projectCode: ${prefs.getString('projectCode')}");
    log("Stored companyId: ${prefs.getString('companyId')}");
    log("Stored empCode: ${prefs.getString('empCode')}");
    log("Stored locationId: ${prefs.getString('locationId')}");
    log("Stored deviceId: ${prefs.getString('deviceId')}");
    log("Stored clientId: ${prefs.getString('clientId')}");


    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible =
    KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          Calenderscreen(),
          Todayscreen(
            token: widget.token,
            clientId: widget.clientId,
            companyId: widget.companyId,
            userId: widget.userId,
            deviceId: widget.deviceId,
            empCode: widget.empCode,
            locationId: widget.locationId,
            projectCode: widget.projectCode,
          ),
          Dashbordscreen(
            token: widget.token,
            empCode: widget.empCode,
            companyId: widget.companyId,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black, blurRadius: 10, offset: Offset(2, 2))
            ]),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigatioIcon.length; i++) ...<Expanded>{
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white10,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigatioIcon[i],
                              color:
                              i == currentIndex ? Colors.red : Colors.grey,
                              size: i == currentIndex ? 40 : 25,
                            ),
                            i == currentIndex
                                ? Container(
                              margin: const EdgeInsets.only(top: 6),
                              height: 3,
                              width: 22,
                              decoration: const BoxDecoration(
                                borderRadius:
                                BorderRadius.all(Radius.circular(40)),
                                color: Colors.white10,
                              ),
                            )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              }
            ],
          ),
        ),
      ),
    );
  }
}