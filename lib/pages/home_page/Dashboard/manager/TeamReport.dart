import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Teamreport extends StatefulWidget {
  const Teamreport({Key? key}) : super(key: key);

  @override
  State<Teamreport> createState() => _TeamreportState();
}

class _TeamreportState extends State<Teamreport> {
  DateTime selectedDate = DateTime.now();
  TextEditingController empCodeController = TextEditingController();
  bool isLoading = false;
  List<dynamic> fetchedData = [];
  bool noDataFound = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      noDataFound = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? rmEmpCode = prefs.getString('emp_code');

    if (token == null || rmEmpCode == null) {
      // Handle missing token or employee code
      return;
    }

    String formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String empCode = empCodeController.text;

    final response = await http.post(
      Uri.parse('http://35.154.148.75/zarvis/api/v2/attendance-for-team-leader'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'date': formattedDate,
        'rm_emp_code': rmEmpCode,
        'emp_code': empCode,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['data'] != null && responseData['data'].isNotEmpty) {
        var data = responseData['data'];
        bool hasActivity = false;
        for (var employee in data) {
          if (employee['data'] != null && employee['data'].isNotEmpty) {
            hasActivity = true;
            break;
          }
        }
        setState(() {
          fetchedData = data;
          noDataFound = !hasActivity;
          isLoading = false;
        });
      } else {
        setState(() {
          fetchedData = [];
          noDataFound = true;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        fetchedData = [];
        noDataFound = true;
        isLoading = false;
      });
      // Handle error
    }
  }

  String _formatTime(String dateTime) {
    DateTime parsedDateTime = DateTime.parse(dateTime);
    return DateFormat('hh:mm a').format(parsedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Team Report",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                "assets/images/zarvis.png",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Image.asset(
                        "assets/images/zarvis.png",
                        height: 100,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text: "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                              ),
                              decoration: InputDecoration(
                                labelText: 'Select Date',
                                labelStyle: TextStyle(color: Colors.black),
                                suffixIcon: IconButton(
                                  onPressed: () => _selectDate(context),
                                  icon: Icon(Icons.calendar_today),
                                  color: Colors.red,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: empCodeController,
                            decoration: InputDecoration(
                              labelText: 'Enter Employee Code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            ),
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: _fetchData,
                               style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 15.h),
                            ),
                              child: Text(
                                "Submit",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (isLoading) Center(child: CircularProgressIndicator()),
                if (!isLoading && noDataFound)
                  Center(
                    child: Text(
                      "No data found",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!isLoading && fetchedData.isNotEmpty) ...[
                  for (var employee in fetchedData)
                    if (employee['data'] != null && employee['data'].isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var entry in employee['data'])
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Start Time",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(_formatTime(entry['start_date_time'])),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "End Time",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(_formatTime(entry['end_date_time'])),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Task",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(entry['activity']),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
