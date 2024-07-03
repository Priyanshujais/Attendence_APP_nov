import 'dart:convert';
import 'dart:developer';
import 'package:simple_month_year_picker/simple_month_year_picker.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Calenderscreen extends StatefulWidget {
  const Calenderscreen({Key? key}) : super(key: key);

  @override
  State<Calenderscreen> createState() => _CalenderscreenState();
}

class _CalenderscreenState extends State<Calenderscreen> {
  List<Map<String, dynamic>> attendanceData = [];
  DateTime selectedDate = DateTime.now();
  int empId = 0; // Your employee ID, fetched from SharedPreferences
  String token = ""; // Your token, fetched from SharedPreferences

  @override
  void initState() {
    super.initState();
    loadAttendanceLog();
  }

  void loadAttendanceLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      empId = prefs.getInt('emp_id') ?? 0;
      token = prefs.getString('token') ?? '';
    });
    updateAttendanceLog(selectedDate);
  }

  void updateAttendanceLog(DateTime date) async {
    String apiUrl = 'http://35.154.148.75/zarvis/api/v2/getMonthlyListing';
    String monthKey = DateFormat('MM-yyyy').format(date);

    // Prepare request headers
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Prepare request body
    Map<String, dynamic> body = {
      'emp_id': empId,
      'month': monthKey,
    };

    // Make API call
    http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Parse response JSON
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['data'];

      // Log the received data for debugging
      print('Received data: ${jsonEncode(data)}');

      // Update attendance data
      setState(() {
        attendanceData = List<Map<String, dynamic>>.from(data);
      });
    } else {
      // Handle API error
      print('API Error: ${response.statusCode}');
      setState(() {
        attendanceData = [];
      });
    }
  }


  Widget buildAttendanceRecord(Map<String, dynamic> record) {
    String title = record['title'] ?? 'Unknown';
    String day = DateFormat('EEEE').format(DateTime.parse(record['date']));
    String date = DateFormat('MMM dd').format(DateTime.parse(record['date']));
    String punchIn = record['punchInDT'] != null
        ? DateFormat.Hm().format(DateTime.parse(record['punchInDT']))
        : 'N/A';
    String punchOut = record['punchOutDT'] != null
        ? DateFormat.Hm().format(DateTime.parse(record['punchOutDT']))
        : 'N/A';
    String totalWorkingTime = record['totalWorkingTime'] ?? '00:00:00';
    log(record['totalWorkingTime']);
    Color statusColor = Colors.grey; // Default color

    // Determine color based on title
    switch (title.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        break;
      case 'absent':
        statusColor = Colors.red;
        break;
      case 'half day':
        statusColor = Colors.pink;
        break;
      case 'week-off':
        statusColor = Colors.blue;
        break;
      case 'holiday':
        statusColor = Colors.lightBlue;
        break;
      case 'comp-off':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1), // Use opacity for background color
        border: Border.all(
          color: statusColor,
          width: 2,
        ), // Border color based on status
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$day, $date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Check In: $punchIn',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Check Out: $punchOut',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Total Working Hours: $totalWorkingTime',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final month = await SimpleMonthYearPicker.showMonthYearPickerDialog(
                  context: context,
                  titleTextStyle: TextStyle(),
                  selectionColor: Colors.red,
                  monthTextStyle: TextStyle(),
                  yearTextStyle: TextStyle(),
                  disableFuture: true,
                );
                if (month != null) {
                  setState(() {
                    selectedDate = month;
                  });
                  updateAttendanceLog(month);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat("MMMM yyyy").format(selectedDate),
                    style: TextStyle(fontSize: 20),
                  ),
                  Row(
                    children: [
                      Text('Pick a Month'),
                      SizedBox(width: 8),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (attendanceData.isEmpty)
              Center(child: Text('No attendance records found')),
            Column(
              children: attendanceData
                  .map((record) => buildAttendanceRecord(record))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
