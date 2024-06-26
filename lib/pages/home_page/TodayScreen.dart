import 'dart:async';
import 'dart:convert';

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

  // Define your office location coordinates
  final double officeLatitude =
  28.607440000000004; // Replace with your office latitude
  final double officeLongitude =
  77.3807874269844; // Replace with your office longitude
  final double officeRadius = 10; // Radius in meters for office proximity check

  @override
  void initState() {
    super.initState();
    updateTime();
    timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => updateTime());
    loadAttendanceData();
    getUSerName();
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
    emp_name = prefs.getString('emp_name')!;
    setState(() {
      print(emp_name);
    });
  }

  Future<void> showLocationDialog(bool isCheckingIn) async {
    var locationPermissionStatus = await Permission.location.request();

    if (locationPermissionStatus.isGranted) {
      Position position = await fetchUserLocation();
      bool isAtOffice =
      isLocationAtOffice(position.latitude, position.longitude);

      // Fetch the initial address using reverse geocoding
      String initialAddress =
      await fetchLocationDetails(position.latitude, position.longitude);

      showDialog(
        context: context,
        builder: (context) {
          TextEditingController reasonController = TextEditingController();

          return AlertDialog(
            title: const Text("Confirm Location"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                            LatLng(position.latitude, position.longitude),
                            zoom: 16,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('location'),
                              position:
                              LatLng(position.latitude, position.longitude),
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  initialAddress,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAtOffice)
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for being outside office',
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Close the dialog with cancel result
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String reason = reasonController.text.trim();
                  Navigator.of(context)
                      .pop(true); // Close the dialog with confirm result

                  if (isCheckingIn) {
                    await handleCheckIn(position, reason);
                  } else {
                    await handleCheckOut(position, reason);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location permission is required to continue.'),
      ));
    }
  }

  Future<void> handleCheckIn(Position position, String reason) async {
    final now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      String checkInTimeString = DateFormat('hh:mm a').format(now);
      String checkInDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      String checkInLocationString =
      await fetchLocationDetails(position.latitude, position.longitude);

      // API body
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
        "punch_in_remark": "reason",
        "working_location": "In Office",
        "punch_in_date_time": checkInDate,
        "attendancedate": checkInDate,
        "attendance_manager_remark": "I am In",
        "in_geofence": "yes"
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
            workingLocation =
            isLocationAtOffice(position.latitude, position.longitude)
                ? "In Office"
                : "Outside of Office";
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
    }
  }

  bool isDayCompleted = false;
  Future<void> handleCheckOut(Position position, String reason) async {
    final now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      String checkOutTimeString = DateFormat('hh:mm a').format(now);
      String checkOutDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      String checkOutLocationString =
      await fetchLocationDetails(position.latitude, position.longitude);

      // Calculate duration between check-in and check-out
      DateTime lastCheckedDate =
      DateTime.parse(prefs.getString('lastCheckedDate') ?? now.toString());
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
        "working_location":
        isLocationAtOffice(position.latitude, position.longitude)
            ? "In Office"
            : "Outside of Office",
        "punch_out_date_time": checkOutDate,
        "attendancedate": checkOutDate,
        "in_geofence": isLocationAtOffice(position.latitude, position.longitude)
            ? "yes"
            : "no"
      };

      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v2/empSignOut'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}',
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
            totalHoursWorked = totalDuration;
            workingLocation =
            isLocationAtOffice(position.latitude, position.longitude)
                ? "In Office"
                : "Outside of Office";
          });

          await prefs.setString('checkOutTime', checkOutTimeString);
          await prefs.setString('checkOutDate', checkOutDate);
          await prefs.setString('checkOutLocation', checkOutLocationString);
          await prefs.setString('totalHoursWorked', totalDuration);
          await prefs.setBool('isCheckedIn', false);
        } else {
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

  Future<Position> fetchUserLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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

  bool isLocationAtOffice(double latitude, double longitude) {
    double distanceInMeters = Geolocator.distanceBetween(
      officeLatitude,
      officeLongitude,
      latitude,
      longitude,
    );
    return distanceInMeters <= officeRadius;
  }

  void resetTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      checkInTime = "--/--";
      checkOutTime = "--/--";
      checkInLocation = "--";
      checkOutLocation = "--";
      totalWorkedDuration = Duration.zero;
      totalHoursWorked = "00:00:00";
      isCheckedIn = false;
      sliderText = "Slide to Check In";
      workingLocation = "--";
    });
  }

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
                          fontSize: screenWidth / 18.w,
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
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentTime,
                    style: TextStyle(fontSize: screenWidth / 18.w),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Total Hours Worked: $totalHoursWorked",
                    style: TextStyle(fontSize: screenWidth / 18.w),
                  ),
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
                            false); // Show location dialog for check-out
                      } else {
                        showLocationDialog(
                            true); // Show location dialog for check-in
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