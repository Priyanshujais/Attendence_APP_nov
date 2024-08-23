
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:permission_handler/permission_handler.dart';

class TeamAttendanceReport extends StatefulWidget {
  final String clientId;
  final String companyId;
  final String projectId;
  final String empCode;
  final String locationId;

  const TeamAttendanceReport({
    Key? key,
    required this.clientId,
    required this.companyId,
    required this.projectId,
    required this.empCode,
    required this.locationId,
  }) : super(key: key);

  @override
  State<TeamAttendanceReport> createState() => _TeamAttendanceReportState();
}


class _TeamAttendanceReportState extends State<TeamAttendanceReport> {
  int totalEmployees = 0;
  int totalPresent = 0;
  int totalAbsent = 0;
  static const _pageSize = 10;
  List<Map<String, dynamic>> employeeData = [];


  // Page controller for swipe navigation
  late PageController _pageController;
  int _currentPageIndex = 0;

  final PagingController<int, Map<String, dynamic>> _pagingController =
  PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _pagingController.addPageRequestListener((pageKey) {
      fetchAttendanceData(0);
    });
  }

  Future<void> fetchAttendanceData(int pageKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token')!;

      final url = Uri.parse(
          'http://35.154.148.75/zarvis/api/v3/getTodayAttendence');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': widget.clientId,
          'company_id': widget.companyId,
          'project_id': widget.projectId,
          'emp_code': widget.empCode,
          'location_id': widget.locationId,
          'page': pageKey,
          'size': _pageSize,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Attendance data response: $jsonResponse');

        if (jsonResponse['status'] == '1') {
          // Filter out non-Map items
          final List<Map<String,
              dynamic>> newItems = (jsonResponse['attendance_data'] as List)
              .where((item) =>
          item is Map<String,
              dynamic>) // Filter only Map items
              .map((item) => item as Map<String, dynamic>)
              .toList();

          final isLastPage = newItems.length < _pageSize;
          if (isLastPage) {
            _pagingController.appendLastPage(newItems);
          } else {
            _pagingController.appendPage(newItems, pageKey + 1);
          }

          setState(() {
            totalEmployees = jsonResponse['countemployee'] ?? 0;
            totalPresent = jsonResponse['countpresent'] ?? 0;
            totalAbsent = jsonResponse['countabsent'] ?? 0;
          });
        } else {
          print(
              'API returned status 0 or other error: ${jsonResponse['message']}');
          _pagingController.error =
          'API returned status 0 or other error: ${jsonResponse['message']}';
        }
      } else {
        print('Failed to load attendance data: ${response.statusCode}');
        _pagingController.error =
        'Failed to load attendance data: ${response.statusCode}';
      }
    } catch (e) {
      print('Exception: Failed to load attendance data: $e');
      _pagingController.error = 'Exception: Failed to load attendance data: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Team Attendance Report",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoContainer(
                    "Employees", totalEmployees.toString(), Colors.blueAccent,
                    0),
                _buildInfoContainer(
                    "Present", totalPresent.toString(), Colors.green, 1),
                _buildInfoContainer(
                    "Absent", totalAbsent.toString(), Colors.red, 2),
              ],
            ),
          ),
          // Active Page Indicator
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                ActivePageIndicator(currentIndex: _currentPageIndex,
                    index: 0,
                    color: Colors.blueAccent),
                ActivePageIndicator(currentIndex: _currentPageIndex,
                    index: 1,
                    color: Colors.green),
                ActivePageIndicator(currentIndex: _currentPageIndex,
                    index: 2,
                    color: Colors.red),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                _buildAttendanceList('all'),
                // Adjust status or filter as needed
                _buildAttendanceList('present'),
                _buildAttendanceList('absent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(String title, String value, Color color,
      int index) {
    bool isActive = _currentPageIndex ==
        index; // Check if this container is active
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      },
      child: Card(
        elevation: isActive ? 10 : 3, // Increase elevation if active
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isActive ? color.withOpacity(1) : color.withOpacity(0.8),
                isActive ? color : color.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList(String status) {
    return PagedListView<int, Map<String, dynamic>>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
        itemBuilder: (context, attendance, index) {
          if (status == 'present' && attendance['flag'] != 'P') {
            return Container(); // Skip items that do not match the current status
          }
          if (status == 'absent' && attendance['flag'] != 'A') {
            return Container(); // Skip items that do not match the current status
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side: Employee Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${attendance['first_name']}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Phone: ${attendance['phone_no']}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    // Right Side: Employee Code and Call Icon
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [SizedBox(height: 10,),
                        Text(
                          ' ${attendance['emp_code']}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        IconButton(
                          icon: Icon(Icons.call),
                          color: Colors.green,
                          onPressed: () {
                            //phone_no
                            _makeCall(attendance['phone_no']);
                            // print('Making call to: ${attendance['9695778034']}');
                            // _makeCall(attendance['9695778034']);
                          },
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        // noItemsFoundBuilder: (context) => Center(child: Text('No data found')),
        firstPageProgressIndicatorBuilder: (context) =>
            Center(child: CircularProgressIndicator()),
        newPageProgressIndicatorBuilder: (context) =>
            Center(child: CircularProgressIndicator()),
      ),
    );
  }


  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    // Request permission
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
    }

    // Check if permission is granted before proceeding
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri');
    }
  }
}



class ActivePageIndicator extends StatelessWidget {
  final int currentIndex;
  final int index;
  final Color color;

  const ActivePageIndicator({
    Key? key,
    required this.currentIndex,
    required this.index,
    required this.color,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: currentIndex == index ? 120: 80,
      height: 10,
      decoration: BoxDecoration(
        color: currentIndex == index ? color : color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}