import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamAttendanceReport extends StatefulWidget {
  final String clientId;
  final String companyId;
  final String projectId;
  final String empCode;
  final String locationId;

  const TeamAttendanceReport({
    Key? key,
    required this.clientId,
    required this.companyId,
    required this.projectId,
    required this.empCode,
    required this.locationId,
  }) : super(key: key);

  @override
  State<TeamAttendanceReport> createState() => _TeamAttendanceReportState();
}

class _TeamAttendanceReportState extends State<TeamAttendanceReport> {
  int totalEmployees = 0;
  int totalPresent = 0;
  int totalAbsent = 0;
  List<Map<String, dynamic>> employeeData = [];

  // Page controller for swipe navigation
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
    _pageController = PageController(initialPage: 0);
  }

  Future<void> fetchAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token')!;

      final url = Uri.parse(
          'http://35.154.148.75/zarvis/api/v2/getTodayAttendence');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': widget.clientId,
          'company_id': widget.companyId,
          'project_id': widget.projectId,
          'emp_code': widget.empCode,
          'location_id': widget.locationId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Attendance data response: $jsonResponse');

        if (jsonResponse['status'] == '1') {
          setState(() {
            totalEmployees = jsonResponse['countemployee'] ?? 0;
            totalPresent = jsonResponse['countpresent'] ?? 0;
            totalAbsent = jsonResponse['countabsent'] ?? 0;

            if (jsonResponse['attendance_data'] != null &&
                jsonResponse['attendance_data'] is List) {
              List<dynamic> attendanceData = jsonResponse['attendance_data'];
              employeeData = attendanceData
                  .where((emp) => emp is Map<String, dynamic>)
                  .map((emp) => emp as Map<String, dynamic>)
                  .toList();
            }
          });
        } else {
          // Handle API error scenario
          print(
              'API returned status 0 or other error: ${jsonResponse['message']}');
        }
      } else {
        // Handle HTTP error scenario
        print('Failed to load attendance data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle other errors like network issues, etc.
      print('Exception: Failed to load attendance data: $e');
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Team Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoContainer(
                    "Total Emp", totalEmployees.toString(), Colors.red, 0),
                _buildInfoContainer(
                    "Total Present", totalPresent.toString(), Colors.green, 1),
                _buildInfoContainer(
                    "Total Absent", totalAbsent.toString(), Colors.pink, 2),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                _buildEmployeeList(employeeData),
                _buildEmployeeList(
                    employeeData.where((emp) => emp['status'] == 'Present')
                        .toList()),
                _buildEmployeeList(
                    employeeData.where((emp) => emp['status'] == 'Absent')
                        .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(String title, String value, Color color, int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList(List<Map<String, dynamic>> employees) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: ScreenUtil().setHeight(8.0),
            horizontal: ScreenUtil().setWidth(
                16.0), // Adjust horizontal padding as needed
          ),
          child: Container(
            padding: EdgeInsets.all(ScreenUtil().setWidth(16.0)),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(8.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3, // Adjust flex values as needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['first_name'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(18.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ScreenUtil().setHeight(4.0)),
                      Text(
                        employee['phone_no'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(16.0),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1, // Adjust flex values as needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        employee['emp_code'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(16.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.call, color: Colors.green),
                        onPressed: () {
                          _makePhoneCall(employee['phone_no']);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}