import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_month_year_picker/simple_month_year_picker.dart';

class Calenderscreen extends StatefulWidget {
  const Calenderscreen({super.key});

  @override
  State<Calenderscreen> createState() => _CalenderscreenState();
}

class _CalenderscreenState extends State<Calenderscreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  String attendanceLog = "";
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadAttendanceLog();
  }

  void loadAttendanceLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      attendanceLog = prefs.getString('dailyLog') ?? 'No attendance records found.';
    });
  }

  void updateAttendanceLog(DateTime date) async {
    // Fetch the attendance log for the selected month from SharedPreferences or your data source
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String monthKey = DateFormat('MM-yyyy').format(date);
    setState(() {
      attendanceLog = prefs.getString(monthKey) ?? 'No attendance records found for ${DateFormat('MMMM yyyy').format(date)}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "My Attendance",
                style: TextStyle(fontSize: screenWidth / 18),
              ),
            ),
            Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 32),
                  child: Text(
                    DateFormat("MMMM yyyy").format(selectedDate),
                    style: TextStyle(fontSize: screenWidth / 18),
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 32),
                  child: GestureDetector(
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
                    child: Text(
                      "Pick a Month",
                      style: TextStyle(fontSize: screenWidth / 18, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 32),
              height: 150,
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
              child: Center(
                child: Text(
                  attendanceLog,
                  style: TextStyle(fontSize: screenWidth / 20, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
