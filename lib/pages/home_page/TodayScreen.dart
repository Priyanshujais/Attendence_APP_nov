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


  String token = "";

  @override
  void initState() {
    super.initState();
    updateTime();
    timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => updateTime());
    loadAttendanceData();
    getUSerName();
    getToken();

    // Fetch initialization status when the screen loads
    fetchInitializationStatus();
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
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v2/initializeStatus'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          "emp_id": widget.empCode,
          "token": widget.token,
        }),
      ).timeout(Duration(seconds: 10)); // Set timeout duration

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "1" && responseData["message"] == "show in") {
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
      String reason = ""; // Modify this to get the actual reason input
      String workingLocation = "In Office"; // Or get the actual working location input

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
    timer?.cancel();
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
  Future<void> showLocationDialog(BuildContext context, bool isCheckingIn) async {
    if (isCheckingIn) {
      await handleCheckInProcess(context);
    } else {
      await showLocationAndMarkAttendance(context, false);
    }
  }

  Future<String> fetchLocationDetails(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      Placemark placemark = placemarks.first;
      print("${placemark.subLocality}, ${placemark.locality}");
      return "${placemark.subLocality}, ${placemark.locality}";
    } catch (e) {
      throw Exception('Error fetching location details');
    }
  }

  bool isHandlingCheckIn = false;
  bool isMissingAttendanceDialogShown = false;

  Future<void> showLocationAndMarkAttendance(BuildContext context, bool isCheckingIn) async {
    // Check for location permission
    var locationPermissionStatus = await Permission.location.request();

    if (locationPermissionStatus.isGranted) {
      Position position = await fetchUserLocation();
      String initialAddress = await fetchLocationDetails(position.latitude, position.longitude);

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
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(position.latitude, position.longitude),
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('location'),
                                  position: LatLng(position.latitude, position.longitude),
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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(initialAddress, style: const TextStyle(color: Colors.grey)),
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
                                  Position newPosition = await fetchUserLocation();
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
                          width: MediaQuery.of(context).size.width * 0.8,
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
                                items: <String>['In Office', 'Outside of Office']
                                    .map<DropdownMenuItem<String>>((String value) {
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
                        ),
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
                        showCustomAlert(context, 'Comment and report are required');
                        return;
                      }

                      Navigator.of(context).pop(true);

                      if (isCheckingIn) {
                        await handleCheckIn(position, reason, selectedLocation);
                      } else {
                        await handleCheckOut(position, reason, selectedLocation);
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


  void showAddReportDialog(
      BuildContext context,
      List<Map<String, String>> reports,
      Function onReportAdded,
      ) {
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
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    endTimeController.text = pickedTime.format(context,);
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
                  reports.add({
                    "start_date_time": startTimeController.text,
                    "end_date_time": endTimeController.text,
                    "activity": taskController.text,
                  });
                  onReportAdded();
                  Navigator.of(context).pop();
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
  Future<void> showMissingAttendanceDialog(String date) async {
    String status = 'absent';
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
              title: Text('To mark today\'s attendance, please fill the previous missing status'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Date: $date'),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: [
                        DropdownMenuItem(value: 'absent', child: Text('Absent')),
                        DropdownMenuItem(value: 'week-off', child: Text('Week-off')),
                        DropdownMenuItem(value: 'public-holiday', child: Text('Public Holiday')),
                        DropdownMenuItem(value: 'comp-off', child: Text('Comp-off')),
                        DropdownMenuItem(value: 'present', child: Text('Present')),
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
                                  startTimeController.text = pickedTime.format(context);
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
                                  endTimeController.text = pickedTime.format(context);
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text('Add Report'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.red,
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
                        hintText: 'Enter remarks',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Next'),
                  onPressed: () async {
                    if (status == 'present' && (startTimeController.text.isEmpty || endTimeController.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Check-in and Check-out times are required')),
                      );
                      return;
                    }

                    if (remarkController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Remark is required')),
                      );
                      return;
                    }

                    // Close the dialog and update calendar data
                    Navigator.of(context).pop(true);

                    await updateCalendarData(date, status, remarkController.text);

                    if (status == 'present') {
                      await handleCheckInProcess(context);
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

    isMissingAttendanceDialogShown = false; // Reset the flag after dialog interaction
  }




  Future<void> createActivity(List<Map<String, String>> reports) async {
    const String apiUrl = 'http://35.154.148.75/zarvis/api/v2/createActivity';
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
      DateTime parsedStartDateTime = DateFormat('yyyy-MM-dd h:mm a').parse(startDateTime);
      DateTime parsedEndDateTime = DateFormat('yyyy-MM-dd h:mm a').parse(endDateTime);
      String formattedStartDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedStartDateTime);
      String formattedEndDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedEndDateTime);
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
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      ).timeout(Duration(seconds: 10)); // Timeout after 10 seconds

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
      final position = await fetchUserLocation();
      bool shouldProceed = false;

      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v2/checkPreviousOneWeekStatus'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"emp_id": widget.empCode, "token": widget.token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "0" && responseData["message"] == "no data") {
          if (!isMissingAttendanceDialogShown) {
            isMissingAttendanceDialogShown = true;
            await showMissingAttendanceDialog(responseData["date"]);
            return;
          }
        } else if (responseData["status"] == "1" && responseData["message"] == "go ahead") {
          shouldProceed = true;
        } else {
          throw Exception('Unexpected response from checkPreviousOneWeekStatus API');
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


  Future<void> handleCheckIn(Position position, String reason, String workingLocation) async {
    if (isHandlingCheckIn) return;
    isHandlingCheckIn = true;

    final now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      String checkInTimeString = DateFormat('hh:mm a').format(now);
      String checkInDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      String checkInLocationString = await fetchLocationDetails(position.latitude, position.longitude);

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
        Uri.parse('http://35.154.148.75/zarvis/api/v2/empSignIn'),
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

          await prefs.setString('checkInTime', checkInTimeString);
          await prefs.setString('checkInDate', checkInDate);
          await prefs.setString('checkInLocation', checkInLocationString);
          await prefs.setString('lastCheckedDate', now.toString());
          await prefs.setDouble('checkInLatitude', position.latitude);
          await prefs.setDouble('checkInLongitude', position.longitude);
          await prefs.setBool('isCheckedIn', true);
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
  bool _isLoading = false;
  Future<void> updateCalendarData(String date, String status, String remark) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String emp_code = prefs.getString('emp_code') ?? "";
    String token = prefs.getString("token") ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v2/updateCalenderData'),
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
      ).timeout(Duration(seconds: 10));

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

  getToken()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
     token = prefs.getString('token')!;
    });
  }

  Future<void> handleCheckOut(
      Position position, String reason, String workingLocation) async {
    final now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      String checkOutTimeString = DateFormat('hh:mm a').format(now);
      String checkOutDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      String checkOutLocationString =
      await fetchLocationDetails(position.latitude, position.longitude);

      // Calculate duration between check-in and check-out
      DateTime lastCheckedDate = DateTime.parse(prefs.getString('checkInDate') ?? now.toString());
      Duration duration = now.difference(lastCheckedDate);
      String totalDuration = formatDuration(duration);

      // API body
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
        "punch_out_date_time": checkOutDate,
        "attendancedate": checkOutDate,
        "in_geofence": "yes"
      };

      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v2/empSignOut'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(checkOutBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == "1") {
          setState(() {
            checkOutTime = checkOutTimeString;
            checkOutLocation = checkOutLocationString;
            isCheckedIn = false;
            sliderText = "Slide to Check In";
            this.workingLocation = workingLocation;
            totalHoursWorked = totalDuration; // Update total hours worked
          });

          await prefs.setString('checkOutTime', checkOutTimeString);
          await prefs.setString('checkOutDate', checkOutDate);
          await prefs.setString('checkOutLocation', checkOutLocationString);
          await prefs.setBool('isCheckedIn', false);
          await prefs.setString('totalHoursWorked', totalDuration); // Save total hours worked
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
  bool isDayCompleted = false;



  void loadAttendanceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checkInTime = prefs.getString('checkInTime') ?? "--/--";
      checkOutTime = prefs.getString('checkOutTime') ?? "--/--";
      checkInLocation = prefs.getString('checkInLocation') ?? "--";
      checkOutLocation = prefs.getString('checkOutLocation') ?? "--";
      totalHoursWorked = prefs.getString('totalHoursWorked') ?? "00:00:00";
      checkInWorkingLocation =
          prefs.getString('checkInWorkingLocation') ?? "--";
      checkOutWorkingLocation =
          prefs.getString('checkOutWorkingLocation') ?? "--";
      isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      sliderText = isCheckedIn ? "Slide to Check Out" : "Slide to Check In";
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.h),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 1, bottom: 0),
                  child: Text(
                    "Welcome, ",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenHeight / 31.h,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "$emp_name",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: screenHeight / 18.h,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 20),
                  child: Text(
                    "Today's Status",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenHeight / 28.h,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 32),
                  height: 150.h,
                  decoration: const BoxDecoration(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Check In",
                              style: TextStyle(
                                  fontSize: screenWidth / 18.h,
                                  color: Colors.black54),
                            ),
                            Text(
                              checkInTime,
                              style: TextStyle(
                                  fontSize: screenWidth / 18.h,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              checkInLocation,
                              style: TextStyle(
                                  fontSize: screenWidth / 26.w,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Check Out",
                              style: TextStyle(
                                fontSize: screenWidth / 18.sp,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              checkOutTime,
                              style: TextStyle(
                                  fontSize: screenWidth / 18.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              checkOutLocation,
                              style: TextStyle(
                                  fontSize: screenWidth / 26.w,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      text: DateTime.now().day.toString(),
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: screenWidth / 15.w,
                          fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth / 20.w,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentTime,
                    style: TextStyle(fontSize: screenWidth / 18.w),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Total Hours Worked: $totalHoursWorked",
                    style: TextStyle(fontSize: screenWidth / 18.w),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    "Working Location: $workingLocation",
                    style: TextStyle(
                      fontSize: screenWidth / 18.sp,
                      color: workingLocation == "In Office"
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Conditionally show message instead of slider
                if (!isDayCompleted)
                  SlideAction(
                    innerColor: Colors.red,
                    outerColor: Colors.white,
                    sliderButtonIconSize: 25.sp,
                    text: sliderText,
                    textColor: Colors.black54,
                    onSubmit: () {
                      if (isCheckedIn) {
                        showLocationDialog(
                            context, false); // Show location dialog for check-out
                      } else {
                        showLocationDialog(
                            context,true); // Show location dialog for check-in
                      }
                    },
                    height: 60.h,
                    sliderButtonYOffset: 4,
                  ),
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
          ),
        ),
      ),
    );
  }
}

class MapDialog extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback onConfirm;

  const MapDialog({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Confirm Location"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8.w,
        height: MediaQuery.of(context).size.height * 0.5.h,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 16,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('location'),
              position: LatLng(latitude, longitude),
            ),
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
