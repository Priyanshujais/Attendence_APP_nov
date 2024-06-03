

import '../pages/home_page/drawer_pages/ApplyLeave.dart';
import '../pages/home_page/drawer_pages/ChangePassword.dart';
import '../pages/home_page/drawer_pages/Leave Status.dart';
import '../pages/home_page/drawer_pages/Report.dart';
import '../pages/home_page/drawer_pages/calendar_screen.dart';
import '../pages/home_page/drawer_pages/profile_screen.dart';

Map<String, dynamic> data = {
  "name": [
    'Profile',
    "Attendance Calendar",
    "Apply Leave",
    "Leave Status",
    "Change Password",
    "Report"
  ],
  "goto": [ProfileScreen(), CalendarScreen(), LeaveScreen(),LeaveStatus(), Changepassword(), ReportScreen()]
};
