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
  Map<String, dynamic>? detailedAttendanceData;
  DateTime selectedDate = DateTime.now();
  String emp_id = ''; // Your employee ID, fetched from SharedPreferences
  String token = ""; // Your token, fetched from SharedPreferences
  bool _isLoading = false;
  bool _hasError = false;
  DateTime? expandedDate;

  @override
  void initState() {
    super.initState();
    loadAttendanceLog();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (emp_id.isNotEmpty) {
      updateAttendanceLog(selectedDate);
    }
  }

  void loadAttendanceLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emp_id = prefs.getString('emp_code') ?? '';
      token = prefs.getString('token') ?? '';
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

    String apiUrl = 'http://35.154.148.75/zarvis/api/v4/getMonthlyListing';
    String monthKey = DateFormat('MM-yyyy').format(date);

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    Map<String, dynamic> body = {
      'emp_id': emp_id,
      'month': monthKey,
    };

    log("Request body: ${jsonEncode(body)}");

    try {
      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
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
    } catch (e) {
      setState(() {
        attendanceData = [];
        _isLoading = false;
        _hasError = true;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Network error: Please check your internet connection and try again.'),
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


  Future<void> fetchDetailedAttendanceLog(DateTime date) async {
    String apiUrl = 'http://35.154.148.75/zarvis/api/v4/getSingleDayDetail';
    String dateKey = DateFormat('yyyy-MM-dd').format(date);

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    Map<String, dynamic> body = {
      'emp_id': emp_id,
      'date': dateKey,
    };

    log("Request body for detailed data: ${jsonEncode(body)}");

    try {
      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        log("Response data: $jsonResponse");  // Log the response to check if data is present

        if (jsonResponse['data'] != null) {
          setState(() {
            detailedAttendanceData = jsonResponse['data'];

            // Check if locationUpdates exists and contains valid entries
            if (detailedAttendanceData?['locationUpdates'] != null &&
                detailedAttendanceData!['locationUpdates'].isNotEmpty) {
              var locationUpdate = detailedAttendanceData!['locationUpdates'][0];

              // Update fields only if they contain valid data
              detailedAttendanceData?['punch_in_date_time'] = locationUpdate['punch_in_date_time'] ?? 'N/A';
              detailedAttendanceData?['punch_in_address'] = locationUpdate['punch_in_address'] ?? 'N/A';

              log("Updated punch_in_date_time: ${detailedAttendanceData?['punch_in_date_time']}");
              log("Updated punch_in_address: ${detailedAttendanceData?['punch_in_address']}");
            } else {
              // Set fields as 'N/A' if location updates are not valid
              detailedAttendanceData?['punch_in_date_time'] = 'N/A';
              detailedAttendanceData?['punch_in_address'] = 'N/A';
            }
          });
        } else {
          setState(() {
            detailedAttendanceData = null;
          });
          log("Data field in response is null.");
        }
      } else {
        _showErrorDialog();
        log("Error response status: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog();
      log("Exception caught: $e");
    }
  }

// Helper function to show the error dialog
  void _showErrorDialog() {
    setState(() {
      detailedAttendanceData = null;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text(
            'Failed to fetch detailed attendance data. Please try again later.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    if (record['punchOutDT'] == "No Out Time." ||
        record['totalWorkingTime'] == "No Out Time." ||
        record['totalWorkingTime'] == "00:00:00") {
      punchOut = 'N/A';
      totalWorkingTime = 'N/A';
    } else {
      punchOut = record['punchOutDT'] != null
          ? DateFormat('hh:mm a').format(DateTime.parse(record['punchOutDT']))
          : 'N/A';
      totalWorkingTime = record['totalWorkingTime'] ?? '00:00:00';
    }

    Color statusColor = Colors.grey;

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

    return GestureDetector(
      onTap: () {
        setState(() {
          if (expandedDate == DateTime.parse(record['date'])) {
            expandedDate = null;
            detailedAttendanceData = null;
          } else {
            expandedDate = DateTime.parse(record['date']);
            fetchDetailedAttendanceLog(expandedDate!);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          border: Border.all(
            color: statusColor,
            width: 2,
          ),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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

            if (punchIn != 'N/A' && punchIn != "12:00 AM")
              Text(
                'Check In: $punchIn',
                style: const TextStyle(fontSize: 14),
              ),
            if (punchOut != 'N/A' && punchOut != "12:00 AM")
              Text(
                'Check Out: $punchOut',
                style: const TextStyle(fontSize: 14),
              ),
            if (totalWorkingTime != 'N/A' && totalWorkingTime != "00:00:00")
              Text(
                'Total Working Hours: $totalWorkingTime',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),

            if (expandedDate == DateTime.parse(record['date']) &&
                detailedAttendanceData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (detailedAttendanceData?['punchInTime'] != null)
                    Text(
                      'Punch In Time: ${detailedAttendanceData!['punchInTime']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (detailedAttendanceData?['punchOutTime'] != null)
                    Text(
                      'Punch Out Time: ${detailedAttendanceData!['punchOutTime']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (detailedAttendanceData?['punchInRemark'] != null)
                    Text(
                      'Punch In Remark: ${detailedAttendanceData!['punchInRemark']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (detailedAttendanceData?['punchOutRemark'] != null)
                    Text(
                      'Punch Out Remark: ${detailedAttendanceData!['punchOutRemark']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (detailedAttendanceData?['punchInAddress'] != null)
                    Text(
                      'Punch In Address: ${detailedAttendanceData!['punchInAddress']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (detailedAttendanceData?['punchOutAddress'] != null)
                    Text(
                      'Punch Out Address: ${detailedAttendanceData!['punchOutAddress']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  const Divider(),
                  ...detailedAttendanceData!['locationUpdates']
                      .map<Widget>((update) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (update['client_name'] != null)
                          Text(
                            'Client Name: ${update['client_name']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (update['punch_in_address'] != null)
                          Text(
                            'Update Address: ${update['punch_in_address']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (update['punch_in_date_time'] != null)
                          Text(
                            'Update Date and Time: ${update['punch_in_date_time']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }


  void _selectMonth(BuildContext context) async {
    final selected = await SimpleMonthYearPicker.showMonthYearPickerDialog(
      context: context,
      disableFuture: true,
      //disablePast: false,
    );
    if (selected != null) {
      setState(() {
        selectedDate = selected;
      });
      updateAttendanceLog(selected);
    }
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
                    children: [
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
