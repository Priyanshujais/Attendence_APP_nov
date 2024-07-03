import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:simple_month_year_picker/simple_month_year_picker.dart';

class Calenderscreen extends StatefulWidget {
  const Calenderscreen({Key? key}) : super(key: key);

  @override
  State<Calenderscreen> createState() => _CalendarscreenState();
}

class _CalendarscreenState extends State<Calenderscreen> {
  List<Map<String, dynamic>> attendanceData = [];
  DateTime selectedDate = DateTime.now();
  String emp_id = ''; // Your employee ID, fetched from SharedPreferences
  String token = ""; // Your token, fetched from SharedPreferences
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    loadAttendanceLog();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method will be called when the dependencies change,
    // such as when the user navigates to this page
    if (emp_id.isNotEmpty) {
      updateAttendanceLog(selectedDate);
    }
  }

  void loadAttendanceLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emp_id = prefs.getString('emp_code') ?? '';
      token = prefs.getString('token') ?? '';
     // log("Loaded emp_id: $emp_id, token: $token");
    });

    if (emp_id.isNotEmpty) {
      updateAttendanceLog(selectedDate);
    }
  }

  Future<void> updateAttendanceLog(DateTime date) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    String apiUrl = 'http://35.154.148.75/zarvis/api/v2/getMonthlyListing';
    String monthKey = DateFormat('MM-yyyy').format(date);

    // Prepare request headers
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Prepare request body
    Map<String, dynamic> body = {
      'emp_id': emp_id,
      'month': monthKey,
    };
    log("Request body: ${jsonEncode(body)}");

    // Make API call
    http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    //log("API response status: ${response.statusCode}");
    //log("API response body: ${response.body}");

    if (response.statusCode == 200) {
      // Parse response JSON
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse['data'] != null) {
        List<dynamic> data = jsonResponse['data'];

        setState(() {
          attendanceData = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          attendanceData = [];
          _isLoading = false;
        });
      }
    } else {
      // Handle API error
      setState(() {
        attendanceData = [];
        _isLoading = false;
        _hasError = true;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to fetch attendance data. Please try again later.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  Widget buildAttendanceRecord(Map<String, dynamic> record) {
    String title = record['title'] ?? 'Unknown';
    String day = DateFormat('EEEE').format(DateTime.parse(record['date']));
    String date = DateFormat('MMM dd').format(DateTime.parse(record['date']));
    String punchIn = record['punchInDT'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(record['punchInDT']))
        : 'N/A';

    String punchOut;
    String totalWorkingTime;
    if (record['punchOutDT'] == "No Out Time." || record['totalWorkingTime'] == "No Out Time.") {
      punchOut = 'N/A';
      totalWorkingTime = 'N/A';
    } else {
      punchOut = record['punchOutDT'] != null
          ? DateFormat('hh:mm a').format(DateTime.parse(record['punchOutDT']))
          : 'N/A';
      totalWorkingTime = record['totalWorkingTime'] ?? '00:00:00';
    }

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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check In: $punchIn',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Check Out: $punchOut',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Working Hours: $totalWorkingTime',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final month = await SimpleMonthYearPicker.showMonthYearPickerDialog(
                  context: context,
                  titleTextStyle: const TextStyle(),
                  selectionColor: Colors.red,
                  monthTextStyle: const TextStyle(),
                  yearTextStyle: const TextStyle(),
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
                    style: const TextStyle(fontSize: 20),
                  ),
                  const Row(
                    children:  [
                      Text('Pick a Month'),
                      SizedBox(width: 8),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_hasError)
              const Center(child: Text('Failed to fetch attendance data. Please try again later.')),
            if (!_hasError && attendanceData.isEmpty)
              const Center(child: Text('No attendance records found')),
            if (!_hasError && attendanceData.isNotEmpty)
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
