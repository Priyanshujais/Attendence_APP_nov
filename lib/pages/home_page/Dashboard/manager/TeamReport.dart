import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Teamreport extends StatefulWidget {
  const Teamreport({Key? key}) : super(key: key);

  @override
  State<Teamreport> createState() => _TeamreportState();
}

class _TeamreportState extends State<Teamreport> {
  DateTime selectedDate = DateTime.now();
  TextEditingController empCodeController = TextEditingController();
  bool isLoading = false;
  bool noDataFound = false;
  List<dynamic> fetchedData = [];
  List<Map<String, String>> employeeList = [];
  String? selectedEmployeeCode;

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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Missing authentication details')),
      );
      return;
    }

    String formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String empCode = empCodeController.text;

    final response = await http.post(
      Uri.parse(
          'http://35.154.148.75/zarvis/api/v3/attendance-for-team-leader'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Failed to fetch data')),
      );
    }
  }

  Future<void> _fetchEmployeeList() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? rmEmpCode = prefs.getString('emp_code');

    if (token == null || rmEmpCode == null) {
      setState(() {
        isLoading = false;
      });
      print("Token or employee code is missing.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://35.154.148.75/zarvis/api/v3/emp-listing?rm_emp_code=$rmEmpCode'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == '1') {
          setState(() {
            employeeList = List<Map<String, String>>.from(
              responseData['data'].map((e) => {
                    'emp_code':
                        e['emp_code'].toString(), // Ensure conversion to string
                    'first_name': e['first_name']
                        .toString(), // Ensure conversion to string
                  }),
            );
          });
          print("Employee list fetched successfully.");
        } else {
          print("Error in API response: ${responseData['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${responseData['message']}")),
          );
        }
      } else {
        print("Failed to fetch employee list: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to fetch employee list: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception occurred: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatTime(String dateTime) {
    DateTime parsedDateTime = DateTime.parse(dateTime);
    return DateFormat('hh:mm a').format(parsedDateTime);
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployeeList(); // Fetch employee list when the widget initializes
  }

  @override
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Team Report",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Center(
                child: Image.asset(
                  "assets/images/zarvis.png",
                  fit: BoxFit.cover, // Ensure the image covers the screen
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(
                  "Generate a Report",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),

                // Date Selection
                Text(
                  "Select Date",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8.r,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                    ),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () => _selectDate(context),
                        icon: Icon(Icons.calendar_today, size: 24.r),
                        color: Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 14.h, horizontal: 16.w),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Employee Code Dropdown or TextField
                Text(
                  "Select Employee Code",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8.r,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedEmployeeCode,
                    hint: Text(
                      'Select Employee',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                    ),
                    items: employeeList.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['emp_code'],
                        child: Text(
                          '${employee['first_name']} (${employee['emp_code']})',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedEmployeeCode = newValue;
                        empCodeController.text = newValue ?? '';
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 14.h, horizontal: 16.w),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 80.w, vertical: 15.h),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Data Display
                if (isLoading) Center(child: CircularProgressIndicator()),
                if (!isLoading && noDataFound)
                  Center(
                    child: Text(
                      "No data found",
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!isLoading && fetchedData.isNotEmpty) ...[
                  for (var employee in fetchedData)
                    if (employee["data"] != null && employee["data"].isNotEmpty)
                      Card(
                        margin: EdgeInsets.only(bottom: 16.h),
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var entry in employee["data"])
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Start Time",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.sp),
                                            ),
                                            Text(
                                              _formatTime(
                                                  entry["start_date_time"]),
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "End Time",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.sp),
                                            ),
                                            Text(
                                              _formatTime(
                                                  entry["end_date_time"]),
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Remark",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.sp),
                                            ),
                                            Text(
                                              entry["activity"],
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
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
