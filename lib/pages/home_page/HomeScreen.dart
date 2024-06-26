import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zarvis_app/pages/home_page/CalenderScreen.dart';
import 'package:zarvis_app/pages/home_page/DashbordScreen.dart';
import 'package:zarvis_app/pages/home_page/TodayScreen.dart';

class Homescreen extends StatefulWidget {
  String deviceId;
  String empCode;
  String userId;
  String clientId;
  String projectCode;
  String locationId;
  String companyId;
  String token;
  Homescreen(
      {super.key,
        required this.token,
        required this.locationId,
        required this.userId,
        required this.projectCode,
        required this.deviceId,
        required this.clientId,
        required this.companyId,
        required this.empCode});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  int currentIndex = 1; // Set initial index to 1 for Todayscreen
  List<IconData> navigationIcon = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.dashcube,
  ];

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
          Dashbordscreen( token: widget.token,empCode: widget.empCode,companyId: widget.companyId,),
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
              for (int i = 0; i < navigationIcon.length; i++) ...<Expanded>{
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
                              navigationIcon[i],
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