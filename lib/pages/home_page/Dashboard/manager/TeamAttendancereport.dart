import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token')!;

      final url = Uri.parse('http://35.154.148.75/zarvis/api/v2/getTodayAttendence');
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

            if (jsonResponse['attendance_data'] != null && jsonResponse['attendance_data'] is List) {
              List<dynamic> attendanceData = jsonResponse['attendance_data'];
              employeeData = attendanceData
                  .where((emp) => emp is Map<String, dynamic>)
                  .map((emp) => emp as Map<String, dynamic>)
                  .toList();
            }
          });
        } else {
          // Handle API error scenario
          print('API returned status 0 or other error: ${jsonResponse['message']}');
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
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoContainer("Total Emp", totalEmployees.toString(), Colors.red),
                _buildInfoContainer("Total Present", totalPresent.toString(), Colors.green),
                _buildInfoContainer("Total Absent", totalAbsent.toString(), Colors.pink),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: employeeData.length,
              itemBuilder: (context, index) {
                final employee = employeeData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee['first_name'] ?? '',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              employee['phone_no'] ?? '',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              employee['emp_code'] ?? '',
                              style: TextStyle(
                                fontSize: 16.0,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(String title, String value, Color color) {
    return Container(
      color: color,
      width: 130,
      height: 80,
      child: Center(
        child: Text(
          "$title\n$value",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
