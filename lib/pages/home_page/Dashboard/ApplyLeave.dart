import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApplyLeave extends StatefulWidget {
  const ApplyLeave({Key? key}) : super(key: key);

  @override
  State<ApplyLeave> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<ApplyLeave> {
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

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
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

    if (fromDate.isEmpty ||
        toDate.isEmpty ||
        subject.isEmpty ||
        reason.isEmpty ||
        _selectedLeaveType == 'Select Leave Type') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;

    final url = Uri.parse(
        'http://35.154.148.75/zarvis/api/v2/ApplyLeave'); // Replace with your API endpoint
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'emp_code': "E1614", // Replace with actual emp_code
        'leave_from_date': fromDate,
        'leave_to_date': toDate,
        'Subject': subject,
        'leave_message': reason,
        'leaveType': _selectedLeaveType,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == '1') {
        _showThankYouDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('Failed to apply leave: ${jsonResponse['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply leave')),
      );
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Thank You!"),
          content: const Text(
              "Your leave application has been submitted successfully."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(360, 690));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Apply Leave",
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
                'assets/images/zarvis.png', // Replace with your background image asset
                // fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
              height: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Apply Leave",
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(24),
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(20)),
                    SingleChildScrollView(
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
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: ScreenUtil().setHeight(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _fromDateController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: ScreenUtil().setHeight(10),
                                          horizontal:
                                          ScreenUtil().setWidth(10)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Select Date',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () {
                                          _selectDate(
                                              context, _fromDateController);
                                        },
                                      ),
                                    ),
                                    readOnly: true,
                                    onTap: () {
                                      _selectDate(
                                          context, _fromDateController);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenUtil().setHeight(10)),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "To Date:",
                                  style: TextStyle(
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: ScreenUtil().setHeight(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _toDateController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: ScreenUtil().setHeight(10),
                                          horizontal:
                                          ScreenUtil().setWidth(10)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Select Date',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () {
                                          _selectDate(
                                              context, _toDateController);
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
                          SizedBox(height: ScreenUtil().setHeight(10)),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Subject:",
                                  style: TextStyle(
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: ScreenUtil().setHeight(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _subjectController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: ScreenUtil().setHeight(10),
                                          horizontal:
                                          ScreenUtil().setWidth(10)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Enter Subject',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenUtil().setHeight(10)),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Leave Type:",
                                  style: TextStyle(
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: ScreenUtil().setHeight(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
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
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: ScreenUtil().setHeight(10),
                                          horizontal:
                                          ScreenUtil().setWidth(10)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Select Leave type ',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenUtil().setHeight(10)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Reason:",
                                  style: TextStyle(
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: ScreenUtil().setWidth(10)),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _reasonController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: ScreenUtil().setHeight(10),
                                          horizontal:
                                          ScreenUtil().setWidth(10)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Enter Reason',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenUtil().setHeight(20)),
                          Center(
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              child: Text(
                                "Apply",
                                style: TextStyle(
                                  fontSize: ScreenUtil().setSp(18),
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                  horizontal: ScreenUtil().setWidth(80),
                                  vertical: ScreenUtil().setHeight(12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
