import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';


import '../../untils/alert_widget.dart';



class Todayscreen extends StatefulWidget {
  String? deviceId;
  String? empCode;
  String? userId;
  String? clientId;
  String? projectCode;
  String? locationId;
  String? companyId;
  String? token;
  Todayscreen(
      {this.token,
      this.empCode,
      this.companyId,
      this.clientId,
      this.deviceId,
      this.locationId,
      this.projectCode,
      this.userId});

  @override
  State<Todayscreen> createState() => _TodayscreenState();
}

class _TodayscreenState extends State<Todayscreen> {
  //Duration _elapsedTime = Duration.zero;
  double screenHeight = 0;
  double screenWidth = 0;
  String employeeName = "Employee";
  String checkInTime = "--/--";
  String checkOutTime = "--/--";
  String reason = "";
  String checkInLocation = "--";
  String checkOutLocation = "--";
  String workingLocation = "--";
  String checkInWorkingLocation = "--";
  String checkOutWorkingLocation = "--";
  bool isCheckedIn = false;
  String sliderText = "Slide to Check In";
  Timer? timer;
  String currentTime = "";
  Duration totalWorkedDuration = Duration.zero;
  String totalHoursWorked = "00:00:00";
  String emp_name = "";
  bool isHandlingCheckIn = false;
  bool isDayCompleted = false;
  bool _isLoading = false;
  Timer? _timer;
  String empName = '';
  late GoogleMapController mapController;
  LatLng currentLatLng = LatLng(20.593683, 78.962883);
  String selectedWorkingLocation = "Client In";
  TextEditingController clientNameController = TextEditingController();
  TextEditingController remarksController = TextEditingController();

  get flutterLocalNotificationsPlugin => null;

  @override
  void initState() {
    super.initState();
    updateTime();
    timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => updateTime());
    loadAttendanceData();
    getUSerName();

    // Fetch initialization status when the screen loads
    fetchInitializationStatus();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  void handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> fetchInitializationStatus() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final response = await http
          .post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/initializeStatus'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          "emp_id": widget.empCode,
          "token": widget.token,
        }),
      )
          .timeout(Duration(seconds: 10)); // Set timeout duration

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "1" &&
            responseData["message"] == "show in") {
          // Set state to show "Slide to Check In"
          setState(() {
            sliderText = "Slide to Check In";
            isCheckedIn = false;
          });
        } else {
          // Set state to show "Slide to Check Out"
          setState(() {
            sliderText = "Slide to Check Out";
            isCheckedIn = true;
          });
        }
      } else {
        throw Exception('Failed to fetch initialization status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching initialization status: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void onSliderAction() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      Position position = await fetchUserLocation();
      String reason = "";
      String workingLocation = "In Office";
      if (!isCheckedIn) {
        await handleCheckIn(position, reason, workingLocation);
      } else {
        await handleCheckOut(position, reason, workingLocation);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error during slider action: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm:ss a').format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ///getuser name
  getUSerName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      emp_name = prefs.getString('emp_name')!;
      print(emp_name);
    });
  }

  Future<void> showLocationDialog(BuildContext context,
      bool isCheckingIn) async {
    if (isCheckingIn) {
      await handleCheckInProcess(context);
    } else {
      await showLocationAndMarkAttendance(context, false);
    }
  }

  Future<String> fetchLocationDetails(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude).timeout(
        const Duration(seconds: 5),
      );
      Placemark placemark = placemarks.first;
      return "${placemark.subLocality}, ${placemark.locality}";
    } catch (e) {
      print('Error fetching location details: $e');
      throw Exception('Error fetching location details: $e');
    }
  }

  //bool isHandlingCheckIn = false;
  bool isMissingAttendanceDialogShown = false;

  Future<void> showLocationAndMarkAttendance(BuildContext context,
      bool isCheckingIn) async {
    // Check for location permission
    var locationPermissionStatus = await Permission.location.request();

    if (locationPermissionStatus.isGranted) {
      Position position = await fetchUserLocation();
      String initialAddress =
      await fetchLocationDetails(position.latitude, position.longitude);

      List<Map<String, String>> reports = [];
      bool reportAdded = false;

      showDialog(
        context: context,
        builder: (context) {
          TextEditingController reasonController = TextEditingController();
          String selectedLocation = "In Office";

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Confirm Location"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.8,
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.3,
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                    position.latitude, position.longitude),
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('location'),
                                  position: LatLng(
                                      position.latitude, position.longitude),
                                ),
                              },
                            ),
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Current Location:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(initialAddress,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: () async {
                                  Position newPosition =
                                  await fetchUserLocation();
                                  setState(() {
                                    position = newPosition;
                                  });
                                },
                                child: const Icon(Icons.my_location),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.8,
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Working Location:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<String>(
                                value: selectedLocation,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedLocation = newValue!;
                                  });
                                },
                                items: <String>[
                                  'In Office',
                                  'Outside of Office'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your comment',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Comment is required';
                          }
                          return null;
                        },
                        minLines: 2,
                        maxLines: 4,
                      ),
                      if (!isCheckingIn)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red, // Text color
                          ),
                          onPressed: () {
                            showAddReportDialog(
                              context,
                              reports,
                                  () {
                                setState(() {
                                  reportAdded = true;
                                });
                              },
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add),
                              Text('Add Report'),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String reason = reasonController.text.trim();
                      bool isValid = reason.isNotEmpty;

                      if (isCheckingIn && !isValid) {
                        showCustomAlert(context, 'Comment is required');
                        return;
                      }

                      if (!isCheckingIn && (!isValid || !reportAdded)) {
                        showCustomAlert(
                            context, 'Comment and report are required');
                        return;
                      }
                      //
                      Navigator.of(context).pop(true);

                      if (isCheckingIn) {
                        await handleCheckIn(position, reason, selectedLocation);
                      } else {
                        await handleCheckOut(
                            position, reason, selectedLocation);
                        await createActivity(reports);
                      }
                    },
                    child: const Text('Mark Attendance'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      showCustomAlert(context, 'Location permission is required to continue.');
    }
  }
  void showAddReportDialog(BuildContext context,
      List<Map<String, String>> reports,
      Function onReportAdded,) async {


    Future<String?> getShiftCode() async {
      const String apiUrl = 'http://35.154.148.75/zarvis/api/v3/user';

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');  // Retrieve the token from SharedPreferences

        if (token == null) {
          print("No token found.");
          return null;  // If token is not available, return null
        }

        // Make API call
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $token',  // Pass token in Authorization header
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final userDetails = data['userDetails'];

          // Extract the shift_code from the response
          String shiftCode = userDetails['shift_code'];
          print("Shift Code from API: $shiftCode");

          return shiftCode;  // Return the shift code
        } else {
          print("Failed to fetch user data: ${response.statusCode}");
          return null;
        }
      } catch (e) {
        print("Error fetching shift code: $e");
        return null;
      }
    }

    String? shift = await getShiftCode();
    print("shift: $shift");


    // print('Retrieved Shift Code: $shift');// he shift value you saved earlier

    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();
    TextEditingController taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
                readOnly: true,
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    startTimeController.text = pickedTime.format(context);
                  }
                },
              ),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
                readOnly: true,
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    endTimeController.text = pickedTime.format(context);
                  }
                },
              ),
              TextField(
                controller: taskController,
                decoration: const InputDecoration(labelText: 'Task Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (startTimeController.text.isNotEmpty &&
                    endTimeController.text.isNotEmpty &&
                    taskController.text.isNotEmpty) {

                  // Function to parse time considering AM/PM
                  TimeOfDay parseTime(String time) {
                    final parts = time.split(' ');
                    final timeParts = parts[0].split(':');
                    int hour = int.parse(timeParts[0]);
                    int minute = int.parse(timeParts[1]);

                    if (parts[1].toLowerCase() == 'pm' && hour != 12) {
                      hour += 12;
                    } else if (parts[1].toLowerCase() == 'am' && hour == 12) {
                      hour = 0;
                    }

                    return TimeOfDay(hour: hour, minute: minute);
                  }

                  final startTime = parseTime(startTimeController.text);
                  final endTime = parseTime(endTimeController.text);

                  // Only apply validation if the user has SHIFT-1
                  if (shift == 'SHIFT-1') {
                    // Compare the times
                    if (startTime.hour < endTime.hour ||
                        (startTime.hour == endTime.hour &&
                            startTime.minute < endTime.minute)) {
                      reports.add({
                        "start_date_time": startTimeController.text,
                        "end_date_time": endTimeController.text,
                        "activity": taskController.text,
                      });
                      onReportAdded();
                      Navigator.of(context).pop();
                    } else {
                      showCustomAlert(
                          context, "End time must be greater than start time");
                    }
                  } else {
                    // If user is on a different shift (SHIFT-2, etc.), skip validation
                    reports.add({
                      "start_date_time": startTimeController.text,
                      "end_date_time": endTimeController.text,
                      "activity": taskController.text,
                    });
                    onReportAdded();
                    Navigator.of(context).pop();
                  }
                } else {
                  showCustomAlert(context, "All report fields are required");
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, String>> reports = [];

  Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert!'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showMissingAttendanceDialog(BuildContext context,
      String date) async {
    String? status;
    TextEditingController remarkController = TextEditingController();
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();

    bool? result = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  'To mark today\'s attendance, please fill the previous missing status'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Date: $date'),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: [
                        DropdownMenuItem(
                            value: 'Absent', child: Text('Absent')),
                        DropdownMenuItem(
                            value: 'Week-Off', child: Text('Week-off')),
                        DropdownMenuItem(
                            value: 'Public-Holiday',
                            child: Text('Public Holiday')),
                        DropdownMenuItem(
                            value: 'Comp-Off', child: Text('Comp-off')),
                        DropdownMenuItem(
                            value: 'present', child: Text('Present')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            status = value;
                          });
                        }
                      },
                      decoration: InputDecoration(labelText: 'Status'),
                    ),
                    if (status == 'present') ...[
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: startTimeController,
                              decoration: InputDecoration(
                                labelText: 'Check-in Time (HH:mm)',
                                border: OutlineInputBorder(),
                                hintText: 'Enter check-in time',
                              ),
                              readOnly: true,
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    startTimeController.text =
                                        pickedTime.format(context);
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: endTimeController,
                              decoration: InputDecoration(
                                labelText: 'Check-out Time (HH:mm)',
                                border: OutlineInputBorder(),
                                hintText: 'Enter check-out time',
                              ),
                              readOnly: true,
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    endTimeController.text =
                                        pickedTime.format(context);
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text('Add Report'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                showAddReportDialog(context, reports, () {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 10),
                    TextField(
                      controller: remarkController,
                      decoration: InputDecoration(
                        labelText: 'Remark',
                        border: OutlineInputBorder(),
                        hintText: 'Enter Remarks',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Next'),
                  onPressed: () async {
                    if (remarkController.text.isEmpty) {
                      await showErrorDialog(context, 'Remark is required');
                      return;
                    }

                    if (status == 'Present' &&
                        (startTimeController.text.isEmpty ||
                            endTimeController.text.isEmpty)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Check-in and Check-out times are required')),
                        );
                      }
                      return;
                    }

                    // Close the dialog
                    Navigator.of(context).pop(true);

                    // Call updateCalendarData
                    await updateCalendarData(
                        date, status!, remarkController.text);

                    if (status == 'present') {
                      // Parsing date and time
                      DateTime checkInDate = DateTime.parse(date);
                      //DateTime currentDateTime = DateTime.now();

                      // Formatting date and time
                      // String formattedCurrentTime =
                      // DateFormat('yyyy-MM-dd HH:mm:ss')
                      //     .format(currentDateTime);

                      // Format the check-in and check-out times properly
                      DateFormat inputFormat = DateFormat(
                          'hh:mm a'); // Change format to include AM/PM
                      DateTime parsedCheckInTime =
                      inputFormat.parse(startTimeController.text);
                      DateTime parsedCheckOutTime =
                      inputFormat.parse(endTimeController.text);

                      // Create new DateTime objects for formattedCheckInTime and formattedCheckOutTime
                      String formattedCheckInTime =
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(
                        DateTime(
                            checkInDate.year,
                            checkInDate.month,
                            checkInDate.day,
                            parsedCheckInTime.hour,
                            parsedCheckInTime.minute),
                      );

                      String formattedCheckOutTime =
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(
                        DateTime(
                            checkInDate.year,
                            checkInDate.month,
                            checkInDate.day,
                            parsedCheckOutTime.hour,
                            parsedCheckOutTime.minute),
                      );

                      try {
                        // Call empSignIn API
                        var signInResponse = await http.post(
                          Uri.parse(
                              'http://35.154.148.75/zarvis/api/v3/empSignIn'),
                          body: jsonEncode({
                            "device_id": widget.deviceId,
                            "emp_code": widget.empCode,
                            "user_id": widget.userId,
                            "client_id": widget.clientId,
                            "project_code": widget.projectCode,
                            "location_id": widget.locationId,
                            "company_id": widget.companyId,
                            "punch_in_lat": "0.0",
                            "punch_in_long": "0.0",
                            "punch_in_address": "",
                            "punch_in_remark": "Previous Missing Status",
                            "working_location": "Not Known",
                            "punch_in_date_time": formattedCheckInTime,
                            "attendancedate": formattedCheckInTime,
                            "attendance_manager_remark": "",
                            "in_geofence": "yes",
                          }),
                          headers: {
                            "Content-Type": "application/json",
                            "Authorization": "Bearer ${widget.token}"
                          },
                        );

                        if (signInResponse.statusCode == 200) {
                          // Call createActivity API
                          var createActivityResponse = await http.post(
                            Uri.parse(
                                'http://35.154.148.75/zarvis/api/v3/createActivity'),
                            body: jsonEncode({
                              "data": [
                                {
                                  "start_date_time": formattedCheckInTime,
                                  "end_date_time": formattedCheckOutTime,
                                  "activity": remarkController.text,
                                }
                              ],
                              "date": checkInDate
                                  .toIso8601String()
                                  .substring(0, 10),
                            }),
                            headers: {
                              "Content-Type": "application/json",
                              "Authorization": "Bearer ${widget.token}"
                            },
                          );

                          if (createActivityResponse.statusCode == 201) {
                            // Call empSignOut API only if createActivity was successful
                            var signOutResponse = await http.post(
                              Uri.parse(
                                  'http://35.154.148.75/zarvis/api/v3/empSignOut'),
                              body: jsonEncode({
                                "device_id": widget.deviceId,
                                "emp_code": widget.empCode,
                                "user_id": widget.userId,
                                "client_id": widget.clientId,
                                "project_code": widget.projectCode,
                                "location_id": widget.locationId,
                                "company_id": widget.companyId,
                                "punch_out_lat": "0.0",
                                "punch_out_long": "0.0",
                                "punch_out_address": "",
                                "punch_out_remark": "Previous Missing Status",
                                "working_location": "Not known",

                                "punch_out_date_time":formattedCheckOutTime,
                                "attendancedate": formattedCheckOutTime,
                                "in_geofence": "yes",
                              }),
                              headers: {
                                "Content-Type": "application/json",
                                "Authorization": "Bearer ${widget.token}"
                              },
                            );

                            if (mounted) {
                              if (signOutResponse.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Attendance marked successfully')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error in marking attendance out')),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                    Text('Error in creating activity')),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                  Text('Error in marking attendance in')),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('An error occurred: $e')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Status $status marked successfully for date $date')),
                        );
                      }
                    }
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        );
      },
    );
    isMissingAttendanceDialogShown = false; // reset
  }

  Future<void> createActivity(List<Map<String, String>> reports) async {
    const String apiUrl = 'http://35.154.148.75/zarvis/api/v3/createActivity';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      print('No token found. Unable to authenticate request.');
      return;
    }

    final DateTime now = DateTime.now();
    final String currentDate = DateFormat('yyyy-MM-dd').format(now);

    // Construct the data payload
    List<Map<String, String>> formattedReports = reports.map((report) {
      String startDateTime = '${currentDate} ${report['start_date_time']}';
      String endDateTime = '${currentDate} ${report['end_date_time']}';
      DateTime parsedStartDateTime =
      DateFormat('yyyy-MM-dd h:mm a').parse(startDateTime);
      DateTime parsedEndDateTime =
      DateFormat('yyyy-MM-dd h:mm a').parse(endDateTime);
      String formattedStartDateTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedStartDateTime);
      String formattedEndDateTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedEndDateTime);
      return {
        'start_date_time': formattedStartDateTime,
        'end_date_time': formattedEndDateTime,
        'activity': report['activity']!,
      };
    }).toList();

    // Log the payload for debugging
    String payload = json.encode({
      'data': formattedReports,
      'date': currentDate,
    });
    print('Request payload: $payload');

    try {
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      )
          .timeout(Duration(seconds: 10)); // Timeout after 10 seconds

      // Log the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle success
        print('Activity created successfully');
      } else {
        // Handle error
        print('Failed to create activity. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } on TimeoutException catch (_) {
      // Handle timeout exception
      print('The request timed out.');
      // Optionally retry or inform the user
    } on http.ClientException catch (e) {
      // Handle client exceptions (e.g., network issues)
      print('Client exception: $e');
    } catch (e) {
      // Handle other exceptions
      print('An error occurred: $e');
    }
  }


  Future<void> handleCheckInProcess(BuildContext context) async {
    try {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      final position = await fetchUserLocation();
      Navigator.of(context).pop();
      bool shouldProceed = false;

      final response = await http.post(
        Uri.parse(
            'http://35.154.148.75/zarvis/api/v3/checkPreviousOneWeekStatus'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"emp_id": widget.empCode, "token": widget.token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "0" &&
            responseData["message"] == "no data") {
          if (!isMissingAttendanceDialogShown) {
            isMissingAttendanceDialogShown = true;
            await showMissingAttendanceDialog(context, responseData["date"]);
            return;
          }
        } else if (responseData["status"] == "1" &&
            responseData["message"] == "go ahead") {
          shouldProceed = true;
        } else {
          throw Exception(
              'Unexpected response from checkPreviousOneWeekStatus API');
        }
      } else {
        throw Exception('Failed to check previous attendance');
      }

      if (shouldProceed) {
        await showLocationAndMarkAttendance(context, true);
      }
    } catch (e) {
      handleError('Error checking in: $e');
    }
  }


  Future<void> handleCheckIn(Position position, String reason,
      String workingLocation) async {
    if (isHandlingCheckIn) return;
    isHandlingCheckIn = true;

    final now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      String checkInTimeString = DateFormat('hh:mm a').format(DateTime.now());
      String checkInDate = now.toIso8601String();
      String checkInLocationString =
      await fetchLocationDetails(position.latitude, position.longitude);

      final checkInBody = {
        "device_id": widget.deviceId,
        "emp_code": widget.empCode,
        "user_id": widget.userId,
        "client_id": widget.clientId,
        "project_code": widget.projectCode,
        "location_id": widget.locationId,
        "company_id": widget.companyId,
        "punch_in_lat": position.latitude.toString(),
        "punch_in_long": position.longitude.toString(),
        "punch_in_address": checkInLocationString,
        "punch_in_remark": reason,
        "working_location": workingLocation,
        "punch_in_date_time": checkInDate,
        "attendancedate": checkInDate,
        "attendance_manager_remark": "",
        "in_geofence": "yes",
      };

      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/empSignIn'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(checkInBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "1") {
          setState(() {
            checkInTime = checkInTimeString;
            checkInLocation = checkInLocationString;
            isCheckedIn = true;
            sliderText = "Slide to Check Out";
            this.workingLocation = workingLocation;
          });

          // Save check-in data in SharedPreferences
          await prefs.setString('workingLocation', workingLocation);
          await prefs.setString('checkInTime', checkInTimeString);
          await prefs.setString('checkInDate', checkInDate);
          await prefs.setString('checkInLocation', checkInLocationString);
          await prefs.setString('lastCheckedDate', now.toString());
          await prefs.setDouble('checkInLatitude', position.latitude);
          await prefs.setDouble('checkInLongitude', position.longitude);
          await prefs.setBool('isCheckedIn', true);
          await prefs.setString('workingLocation', workingLocation);

        } else {
          throw Exception(responseData["message"]);
        }
      } else {
        throw Exception('Failed to check in');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error checking in: $e'),
      ));
    } finally {
      isHandlingCheckIn = false;
    }
  }






  bool isLoading = false;

  Future<void> updateCalendarData(String date, String status,
      String remark) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String emp_code = prefs.getString('emp_code') ?? "";
    String token = prefs.getString("token") ?? '';

    try {
      final response = await http
          .post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/updateCalenderData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'emp_code': emp_code,
          'date': date,
          'client_id': widget.clientId,
          'project_code': widget.projectCode,
          'location_id': widget.locationId,
          'status': status,
          'remark': remark,
        }),
      )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance marked successfully')),
        );
      } else {
        handleError('Failed to update calendar data');
      }
    } catch (e) {
      handleError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<Position> fetchUserLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Error fetching user location: $e');
    }
  }

  Future<void> handleCheckOut(Position position, String reason, String workingLocation) async {
    final now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      // Prepare payload for checkPreviousOneWeekStatus API
      final previousStatusPayload = {
        "emp_id": prefs.getString('emp_code')
      };


      // Debug print: Log payload data going to checkPreviousOneWeekStatus API
      print("Payload for checkPreviousOneWeekStatus API: $previousStatusPayload");
      final token = widget.token;
      // Call API to get the p_date
      final previousStatusResponse = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/checkPreviousOneWeekStatus'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },


        body: jsonEncode(previousStatusPayload),
      );

      String checkInDateOnly;

      if (previousStatusResponse.statusCode == 200) {
        final responseData = jsonDecode(previousStatusResponse.body);

        // Debug print: Log response data from checkPreviousOneWeekStatus API
        print("Response from checkPreviousOneWeekStatus API: $responseData");

        if (responseData["status"] == "1" && responseData["date"].isNotEmpty) {
          checkInDateOnly = responseData["date"]; // Always use the API response for check-in date
        } else {
          throw Exception("Invalid response: date not available");
        }
      } else {
        throw Exception("API Error: ${previousStatusResponse.body}");
      }

      // Format the checkout date and time
      String checkOutDateTime = "$checkInDateOnly ${DateFormat('HH:mm:ss').format(now)}";
      String checkOutLocationString = await fetchLocationDetails(position.latitude, position.longitude);
      String checkOutTimeString = DateFormat('hh:mm a').format(now);
      // Prepare payload for empSignOut API
      final checkOutBody = {
        "device_id": widget.deviceId,
        "emp_code": widget.empCode,
        "client_id": widget.clientId,
        "project_code": widget.projectCode,
        "location_id": widget.locationId,
        "company_id": widget.companyId,
        "punch_out_lat": position.latitude.toString(),
        "punch_out_long": position.longitude.toString(),
        "punch_out_address": checkOutLocationString,
        "punch_out_remark": reason,
        "working_location": workingLocation,
        "punch_out_date_time": now.toIso8601String(),
        "attendancedate": checkOutDateTime,
        "in_geofence": "yes"
      };

      // Debug print: Log payload data going to empSignOut API
      print("Payload for empSignOut API: $checkOutBody");

      // Make empSignOut API call
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/empSignOut'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(checkOutBody),
      );

      // Debug print: Log response data from empSignOut API
      print("Response from empSignOut API: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "1") {
          setState(() {
            checkOutTime = checkOutTimeString;
            checkOutLocation = checkOutLocationString;
            isCheckedIn = false;
            sliderText = "Slide to Check In";
            this.workingLocation = workingLocation;
          });

          await prefs.setString('checkOutTime', checkOutTimeString);
          await prefs.setString('checkOutDate', checkOutDateTime);
          await prefs.setString('checkOutLocation', checkOutLocationString);
          await prefs.setBool('isCheckedIn', false);
        } else {
          log(responseData["message"]);
          throw Exception(responseData["message"]);
        }
      } else {
        throw Exception('Failed to check out');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error checking out: $e'),
      ));
    }
  }



  //bool isDayCompleted = false;

  String currentAddress = "";

  Future<void> getCurrentAddress(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      final Placemark place = placemarks[0];
      setState(() {
        currentAddress =
        "${place.name}, ${place.locality}, ${place.postalCode}, ${place
            .country}";
      });
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  Future<void> showUpdateLocationDialog(BuildContext context) async {
    clientNameController.text = '';
    remarksController.text = '';

    // Check for location permission
    var locationPermissionStatus = await Permission.location.request();

    if (locationPermissionStatus.isGranted) {
      Position position = await fetchUserLocation();
      String initialAddress =
      await fetchLocationDetails(position.latitude, position.longitude);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Update Location"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Current Location: $initialAddress",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                    position.latitude, position.longitude),
                                zoom: 14.0,
                              ),
                              onMapCreated: (GoogleMapController controller) {
                                mapController = controller;
                              },
                              markers: {
                                Marker(
                                  markerId: const MarkerId("currentLocation"),
                                  position: LatLng(
                                      position.latitude, position.longitude),
                                ),
                              },
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: () async {
                                  Position newPosition =
                                  await fetchUserLocation();
                                  setState(() {
                                    position = newPosition;
                                  });
                                },
                                child: const Icon(Icons.my_location),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedWorkingLocation,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedWorkingLocation = newValue!;
                          });
                        },
                        items: <String>['Client In', 'Client Out']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Working Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          updateLocation();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Update Location'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      showCustomAlert(context, 'Location permission is required to continue.');
    }
  }

  Future<void> updateLocation() async {
    String now = DateTime.now().toIso8601String();

    final body = {
      "emp_code": widget.empCode,
      "punch_in_lat": currentLatLng.latitude.toString(),
      "punch_in_long": currentLatLng.longitude.toString(),
      "punch_in_address": checkInLocation,
      "company_id": widget.companyId,
      "device_id": widget.deviceId,
      "project_code": widget.projectCode,
      "client_id": widget.clientId,
      "location_id": widget.locationId,
      "attendancedate": now,
      "punch_in_date_time": now,
      "working_location": selectedWorkingLocation,
      "punch_in_remark": remarksController.text,
      "in_geofence": "yes",
      "client_name": clientNameController.text,
    };
    // Log the request body
    print("Request Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/updatelocation'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );
      print("Response: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "1") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Location updated successfully!'),
          ));
        } else {
          throw Exception(responseData["message"]);
        }
      } else {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating location: $e'),
      ));
    }
  }

  void loadAttendanceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checkInTime = prefs.getString('checkInTime') ?? "--/--";
      checkOutTime = prefs.getString('checkOutTime') ?? "--/--";
      checkInLocation = prefs.getString('checkInLocation') ?? "--";
      //punch_in_address
      checkOutLocation = prefs.getString('checkOutLocation') ?? "--";
      totalHoursWorked = prefs.getString('totalHoursWorked') ?? "00:00:00";
      checkInWorkingLocation =
          prefs.getString('checkInWorkingLocation') ?? "--";
      checkOutWorkingLocation =
          prefs.getString('checkOutWorkingLocation') ?? "--";
      isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      sliderText = isCheckedIn ? "Slide to Check Out" : "Slide to Check In";
      workingLocation = prefs.getString('workingLocation') ?? "--";
    }
    );
  }
  // Timer to calculate elapsed time based on check-in time






  // void showUpdateTimeDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       String selectedHour;
  //       TextEditingController remarkController = TextEditingController();
  //
  //       return AlertDialog(
  //         title: Text("Update Time"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: <Widget>[
  //             DropdownButtonFormField<String>(
  //               decoration: InputDecoration(
  //                 labelText: 'Select Hours',
  //                 border: OutlineInputBorder(),
  //               ),
  //               items: [
  //                 '1 hr',
  //                 '2 hrs',
  //                 '3 hrs',
  //                 '4 hrs',
  //                 'Until next shift',
  //               ].map((String value) {
  //                 return DropdownMenuItem<String>(
  //                   value: value,
  //                   child: Text(value),
  //                 );
  //               }).toList(),
  //               onChanged: (newValue) {
  //                 selectedHour = newValue!;
  //               },
  //             ),
  //             SizedBox(height: 20),
  //             TextField(
  //               controller: remarkController,
  //               decoration: InputDecoration(
  //                 labelText: 'Remark/Reason',
  //                 border: OutlineInputBorder(),
  //               ),
  //               maxLines: 1,
  //             ),
  //           ],
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text("Cancel"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           ElevatedButton(
  //             child: Text("Update"),
  //             onPressed: () {
  //               // Handle the update action with selectedHour and remarkController.text
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  // Fetch notifications from API
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v3/get_notifications'),
        body: {
          'emp_code': widget.empCode,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == "1") {
          List notifications = responseData['data'];
          return List<Map<String, dynamic>>.from(notifications);
        }
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
    return [];
  }

  // Display Notifications in a Dialog
  void showNotificationsDialog(BuildContext context) async {
    final notifications = await fetchNotifications();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Notifications"),
            content: notifications.isEmpty
                ? Text("No new notifications")
                : SizedBox(
              height: 300.h,
              width: 350.w,
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final title = notification['title'];
                  final body = notification['body'];
                  final createdAt = notification['created_at'];

                  return Card(
                    margin: EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Date Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                createdAt,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Body of Notification
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Welcome Text with Bell Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Welcome, ",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenHeight / 31,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: Colors.black54,
                      size: screenHeight / 28,
                    ),
                    onPressed: () {
                      showNotificationsDialog(context);
                    },

                  ),
                ],
              ),
              // Employee Name
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "$emp_name!",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: screenHeight / 18.h,
                  ),
                ),
              ),
              // Today's Status
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 20),
                child: Text(
                  "Today's Status",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenHeight / 28,
                  ),
                ),
              ),
              // Check-in and Check-out Status
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 32),
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18,
                      offset: Offset(2, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Check In
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Check In",
                            style: TextStyle(
                              fontSize: screenWidth / 18,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            checkInTime,
                            style: TextStyle(
                              fontSize: screenWidth / 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            checkInLocation,
                            style: TextStyle(
                              fontSize: screenWidth / 26,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Check Out
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Check Out",
                            style: TextStyle(
                              fontSize: screenWidth / 18,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            checkOutTime,
                            style: TextStyle(
                              fontSize: screenWidth / 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            checkOutLocation,
                            style: TextStyle(
                              fontSize: screenWidth / 26,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Current Date
              Container(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: DateTime
                        .now()
                        .day
                        .toString(),
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: screenWidth / 15,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth / 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Current Time
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  currentTime,
                  style: TextStyle(fontSize: screenWidth / 18),
                ),
              ),
              SizedBox(height: 10),
              // Total Hours Worked

              SizedBox(height: 10),
              // Working Location
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "Working Location: $workingLocation",
                  style: TextStyle(
                    fontSize: screenWidth / 18,
                    color: workingLocation == "In Office"
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Slide Action for Check-Out
              if (!isDayCompleted)
                SlideAction(
                  innerColor: Colors.red,
                  outerColor: Colors.white,
                  sliderButtonIconSize: 20.sp,
                  text: sliderText,
                  textColor: Colors.black54,
                  onSubmit: () {
                    if (isCheckedIn) {
                      showLocationDialog(
                          context, false); // Show location dialog for check-out
                    } else {
                      showLocationDialog(
                          context, true); // Show location dialog for check-in
                    }
                  },
                  height: 60.h,
                  sliderButtonYOffset: 4,
                ),
              SizedBox(
                height: 18,
              ),
              if (isCheckedIn && !isDayCompleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showUpdateLocationDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        icon: Icon(Icons.location_on),
                        label: Text('Update Location'),
                      ),
                    ),
                    SizedBox(width: 8),
                //     Expanded(
                //       child: ElevatedButton.icon(
                //         onPressed: () {
                //           showUpdateTimeDialog(context);
                //         },
                //         style: ElevatedButton.styleFrom(
                //             backgroundColor: Colors.red,
                //             foregroundColor: Colors.white),
                //         icon: Icon(Icons.access_time),
                //         label: Text('Update Time'),
                //       ),
                //     ),
                //   ],
                // ),
              if (isDayCompleted)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "You have completed your tasks for today.",
                    style: TextStyle(
                      fontSize: screenWidth / 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
      ]
      ),
          ),
        )
      );


  }
}
