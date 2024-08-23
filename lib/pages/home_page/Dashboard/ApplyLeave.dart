import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zarvis_app/pages/home_page/HomeScreen.dart';

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
    'Emergency ',
     'Earned Leave',
    'Comp-off',
    'Half Day',
  ];

  bool _isLoading = false;
  bool _hasError = false;

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

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    String? empCode = prefs.getString('emp_code');


    final url = Uri.parse('http://35.154.148.75/zarvis/api/v3/ApplyLeave');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'emp_code': empCode.toString(),
        'leave_from_date': fromDate,
        'leave_to_date': toDate,
        'Subject': subject,
        'leave_message': reason,
        'leave_type': _selectedLeaveType,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == '1') {
        _showThankYouDialog(

        );
      } else {
        setState(() {
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to apply leave: ${jsonResponse['message']}')),
        );
      }
    } else {
      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply leave')),
      );
    }
  }
  Future<void> saveDataToSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('deviceId', 'yourDeviceId');
    await prefs.setString('empCode', 'yourEmpCode');
    await prefs.setString('userId', 'yourUserId');
    await prefs.setString('clientId', 'yourClientId');
    await prefs.setString('projectCode', 'yourProjectCode');
    await prefs.setString('locationId', 'yourLocationId');
    await prefs.setString('companyId', 'yourCompanyId');
    await prefs.setString('token', 'yourToken');
  }

  Future<void> _showThankYouDialog() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the data from SharedPreferences
    String deviceId = prefs.getString('deviceId') ?? '';
    String empCode = prefs.getString('empCode') ?? '';
    String userId = prefs.getString('userId') ?? '';
    String clientId = prefs.getString('clientId') ?? '';
    String projectCode = prefs.getString('projectCode') ?? '';
    String locationId = prefs.getString('locationId') ?? '';
    String companyId = prefs.getString('companyId') ?? '';
    String token = prefs.getString('token') ?? '';

    // Print the data for debugging
    print('Device ID: $deviceId');
    print('Emp Code: $empCode');
    print('User ID: $userId');
    print('Client ID: $clientId');
    print('Project Code: $projectCode');
    print('Location ID: $locationId');
    print('Company ID: $companyId');
    print('Token: $token');

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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Homescreen(
                      token: token,
                      locationId: locationId,
                      userId: userId,
                      projectCode: projectCode,
                      deviceId: deviceId,
                      clientId: clientId,
                      companyId: companyId,
                      empCode: empCode,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));

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
                //fit: BoxFit.cover,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextFieldRow(
                          "From Date:",
                          _fromDateController,
                          "Select Date",
                          _selectDate,
                        ),
                        SizedBox(height: ScreenUtil().setHeight(10)),
                        _buildTextFieldRow(
                          "To Date:",
                          _toDateController,
                          "Select Date",
                          _selectDate,
                        ),
                        SizedBox(height: ScreenUtil().setHeight(10)),
                        _buildTextFieldRow(
                          "Subject:",
                          _subjectController,
                          "Enter Subject",
                          null,
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
                                      child: Text(
                                        leaveType,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: ScreenUtil().setHeight(10),
                                      horizontal: ScreenUtil().setWidth(10),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'Select Leave type',
                                  ),
                                  isExpanded: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ScreenUtil().setHeight(10)),
                        _buildReasonField(),
                        SizedBox(height: ScreenUtil().setHeight(20)),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Text(
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
                        if (_hasError)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Failed to apply leave. Please try again.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildTextFieldRow(String labelText, TextEditingController controller,
      String hintText, Function? onTap) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            labelText,
            style: TextStyle(
                fontSize: ScreenUtil().setSp(18), fontWeight: FontWeight.bold),
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
              controller: controller,
              onTap: onTap != null ? () => onTap(context, controller) : null,
              readOnly: onTap != null,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    vertical: ScreenUtil().setHeight(10),
                    horizontal: ScreenUtil().setWidth(10)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                hintText: hintText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "Reason:",
            style: TextStyle(
                fontSize: ScreenUtil().setSp(18), fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            height: ScreenUtil().setHeight(80),
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
                    horizontal: ScreenUtil().setWidth(10)),
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
    );
  }
}
