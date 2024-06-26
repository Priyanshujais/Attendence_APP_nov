

import 'package:flutter/material.dart';

import '../pages/home_page/Dashboard/ApplyLeave.dart';
import '../pages/home_page/Dashboard/ChangePassword.dart';
import '../pages/home_page/Dashboard/Leave Status.dart';
import '../pages/home_page/Dashboard/Report.dart';
import '../pages/home_page/Dashboard/calendar_screen.dart';
import '../pages/home_page/Dashboard/manager/ManagerLeaveApporval.dart';
import '../pages/home_page/Dashboard/manager/TeamAttendance.dart';
import '../pages/home_page/Dashboard/profile_screen.dart';

Map<String, dynamic> data = {
  "name": [
    'Profile',
    "Attendance Calendar",
    "Apply Leave",
    "Leave Status",
    "Change Password",
    "Report",

  ],
  "goto": [const Profile_Screen(), const CalendarScreen(),const  ApplyLeave(),const LeaveStatus(), const ChangePassword(),const  ReportScreen(),const Teamattendance(),ManagerLeaveApproval(
     )]
};





List<String> menu = [
  "Profile",
  "Apply Leave",
  "Leave Status",
  "Change Password",
  "Reports",
  "App rating",

  "Logout",
];

List<Color> menuColors = [
  const Color(0xFFF44326),
  const Color(0xFFFF6E40),
  const Color(0xFF61BDFD),
  const Color(0xFFCB84FB),
  const Color(0xFF78E667),
  const Color(0xFFDA126D),
  const Color(0xFFDA126D),
  const Color(0xFFFF6B6B),
];

List<Icon> menuIcons = [
  const Icon(Icons.person, color: Colors.white, size: 38),
  const Icon(Icons.leave_bags_at_home_outlined, color: Colors.white, size: 35),
  const Icon(Icons.safety_check, color: Colors.white, size: 35),
  const Icon(Icons.lock, color: Colors.white, size: 35),
  const Icon(Icons.pending_actions, color: Colors.white, size: 35),
  const Icon(Icons.star_border, color: Colors.white, size: 35),
  const Icon(Icons.logout, color: Colors.white, size: 35),
];


////manager
List<String> Managermenu = [
  "Profile",
  "Apply Leave",
  "Leave Status",
  "Change Password",
  "Reports",
  "App rating",
  "Team attendance",
  "Manager Leave Apporval",
  "Team Report ",
  "Event Calender",
  "Logout"

];

List<Color> ManagermenuColors = [
  const Color(0xFFF44326),
  const Color(0xFFFF6E40),
  const Color(0xFF61BDFD),
  const Color(0xFFCB84FB),
  const Color(0xFF78E667),
  const Color(0xFFDA126D),
  const Color(0xFFFF6B6B),
  const Color(0xFFFF6B6B),
  const Color(0xFFF44326),
  const Color(0xFFF44326),
  const Color(0xFFF44326),

];

List<Icon> ManagermenuIcons = [
  const Icon(Icons.person, color: Colors.white, size: 38),
  const Icon(Icons.leave_bags_at_home_outlined, color: Colors.white, size: 35),
  const Icon(Icons.safety_check, color: Colors.white, size: 35),
  const Icon(Icons.lock, color: Colors.white, size: 35),
  const Icon(Icons.pending_actions, color: Colors.white, size: 35),
  const Icon(Icons.star_border, color: Colors.white, size: 35),
  const Icon(Icons.person_pin_outlined, color: Colors.white, size: 35),
  const Icon(Icons.man, color: Colors.white, size: 35),
  const Icon(Icons.receipt_long, color: Colors.white, size: 35),
  const Icon(Icons.calendar_month_sharp, color: Colors.white, size: 35),
  const Icon(Icons.logout, color: Colors.white, size: 35),

];