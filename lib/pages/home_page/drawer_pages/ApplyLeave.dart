import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedLeaveType = 'Select Leave Type';
  final List<String> _leaveTypes = [
    'Select Leave Type',
    'Emergency / Earned Leave',
    'Comp-off',
    'Half Day',
  ];

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _subjectController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    final String fromDate = _fromDateController.text;
    final String toDate = _toDateController.text;
    final String subject = _subjectController.text;
    final String reason = _reasonController.text;

    if (fromDate.isEmpty || toDate.isEmpty || subject.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    final url = Uri.parse('https://yourapi.com/submit_leave'); // Replace with your API endpoint
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'fromDate': fromDate,
        'toDate': toDate,
        'subject': subject,
        'reason': reason,
        'leaveType': _selectedLeaveType,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave applied successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply leave')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Apply Leave",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink.shade800,
      ),
      body: SingleChildScrollView(
    child: Container(
    height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
    padding: EdgeInsets.all(16.0),
    child: Center(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
              Text(
                "Apply Leave",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                height: 400.h,
                width: 400.w,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "From Date:",
                              style: TextStyle(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 40.h,
                              child: TextField(
                                controller: _fromDateController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.pink.shade800, // Set the border color
                                      width: 4.0.h, // Set the border width
                                    ),
                                  ),
                                  hintText: 'Select Date',
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_month_outlined),
                                    onPressed: () {
                                      _selectDate(context, _fromDateController);
                                    },
                                  ),
                                ),
                                readOnly: true,
                                onTap: () {
                                  _selectDate(context, _fromDateController);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "To Date:",
                              style: TextStyle(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 40.h,
                              child: TextField(
                                controller: _toDateController,
                                decoration: InputDecoration(
                                 border:  OutlineInputBorder(),
                                  hintText: 'Select Date',
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_month_outlined),
                                    onPressed: () {
                                      _selectDate(context, _toDateController);
                                    },
                                  ),
                                ),
                                readOnly: true,
                                onTap: () {
                                  _selectDate(context, _toDateController);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Subject:",
                              style: TextStyle(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 40.h,
                              child: TextField(
                                controller: _subjectController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter Subject',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Leave Type:",
                              style: TextStyle(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 40.h,
                              child: DropdownButtonFormField<String>(
                                value: _selectedLeaveType,
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedLeaveType = newValue!;
                                  });
                                },
                                items: _leaveTypes.map((leaveType) {
                                  return DropdownMenuItem<String>(
                                    value: leaveType,
                                    child: Text(leaveType),
                                  );
                                }).toList(),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Select Leave Type',
                                  suffixIcon: null, // Remove the down arrow icon
                                ),
                                icon: Icon(null), // Remove the down arrow icon
                                isExpanded: true, // Expand to fill available width
                              ),
                            ),
                          ),

                        ],
                      ),
                      SizedBox(height: 10.h),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Remarks:",
                              style: TextStyle(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 1.w,height: 50.h,), // Adjust as needed for spacing
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: _reasonController,
                              maxLength: 400,
                              maxLines: 2,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter Reason (max 400 characters)',
                                counterText: '', // This hides the counter text
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          child: Text(
                            "Apply",
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade800,
                            padding: EdgeInsets.symmetric(
                              horizontal: 120.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
