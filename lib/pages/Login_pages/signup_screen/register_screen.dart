import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  final String emp_code;
  final String comp_id;

  RegisterScreen({Key? key, required this.comp_id, required this.emp_code})
      : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Map<String, TextEditingController> _controllers = {
    'Company': TextEditingController(),
    'Project': TextEditingController(),
    'Full Name': TextEditingController(),
    'Employee id': TextEditingController(),
    'Shift': TextEditingController(),
    'Role': TextEditingController(),
  };

  List<Map<String, String>> shifts = []; // Initialize as an empty list

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchShifts();
  }
  String? _userId;

  Future<void> _fetchData() async {
    try {
      final userResponse = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v4/verifyEmployee'),
        body: json
            .encode({'emp_code': widget.emp_code, 'comp_id': widget.comp_id}),
        headers: {'Content-Type': 'application/json'},
      );

      if (userResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(userResponse.body);
        if (data['status'] == "1" && data['flag'] == "2") {
          final userDetails = data['emp_data'];

          // Populate the controllers with the data from the API
          _controllers['Company']?.text = userDetails['comp_name'] ?? '';
          _controllers['Project']?.text = userDetails['project_name'] ?? '';
          _controllers['Full Name']?.text =
              "${userDetails['first_name']} ${userDetails['last_name']}";
          _controllers['Employee id']?.text = userDetails['emp_code'] ?? '';
          _controllers['Role']?.text = userDetails['desg_name'] ?? '';
          _userId = userDetails['user_id'].toString();


          setState(() {});
        } else {
          _showDialog('Error', 'User data not found.');
        }
      } else {
        _showDialog('Error', 'Failed to load user data.');
      }
    } catch (e) {
      _showDialog('Error', 'An error occurred while fetching user data.');
    }
  }

  Future<void> _fetchShifts() async {
    try {
      final response = await http
          .get(Uri.parse('http://35.154.148.75/zarvis/api/v4/shiftList'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == "1") {
          setState(() {
            shifts =
                List<Map<String, String>>.from(data['dataset'].map((shift) => {
                      'shift_code': shift['shift_code'] as String,
                      'shift_name': shift['shift_name'] as String,
                    }));
          });
        } else {
          _showDialog('Error', 'Failed to load shifts data.');
        }
      } else {
        _showDialog('Error', 'Failed to load shifts data.');
      }
    } catch (e) {
      _showDialog('Error', 'An error occurred while fetching shifts data.');
    }
  }


  Future<void> _handleSubmit() async {
    String company = _controllers['Company']!.text;
    String project = _controllers['Project']!.text;
    String fullName = _controllers['Full Name']!.text;
    String employeeId = _controllers['Employee id']!.text;
    String shift = _controllers['Shift']!.text;
    String role = _controllers['Role']!.text;

    if (shift.isEmpty) {
      _showDialog(
        'Shift Code Missing',
        'Please select a shift code before submitting.',
        isSuccess: false,
      );
      return; // Exit the method early since shift is required
    }

    try {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v4/register'),
        body: json.encode({
          'emp_code': employeeId,
          'device_id': 'device_id',
          'emp_id': _userId,
          'shift_code': shift,
          'first_name': fullName.split(' ')[0],
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _showDialog(
          'Registration Status',
          responseData['message'],
          isSuccess: true, // Indicate success to navigate to login
        );
      } else {
        _showDialog('Registration Failed',
            'Failed to register. Please try again later.',
            isSuccess: false);
      }
    } catch (e) {
      _showDialog(
          'Registration Failed', 'An error occurred. Please try again later.',
          isSuccess: false);
    }
  }

  void _showDialog(String title, String content, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (isSuccess) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                        (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  "assets/images/zarvis.png",
                  height: 80.h,
                  width: 80.w,
                ),
              ),
              SizedBox(height: 20.h),
              ..._controllers.keys.map((label) {
                if (label == 'Shift') {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Container(
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
                            value: _controllers[label]?.text.isEmpty ?? true
                                ? null
                                : _controllers[label]?.text,
                            onChanged: (value) {
                              setState(() {
                                _controllers[label]?.text = value!;
                              });
                            },
                            items: [
                              const DropdownMenuItem(
                                value: '', // Empty value for initial state
                                child: Text('Select Shift'),
                              ),
                              ...shifts.map(
                                (shift) => DropdownMenuItem<String>(
                                  value: shift["shift_code"],
                                  child: Text(shift["shift_name"]!),
                                ),
                              )
                            ],
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 10.w),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Select Shift',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Container(
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
                            readOnly: label !=
                                'Shift', // Make text field non-editable except for 'Shift'
                            controller: _controllers[label],
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 10.w),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Enter your $label',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }).toList(),
              SizedBox(height: 10.h),
              Center(
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 100.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.red,
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
