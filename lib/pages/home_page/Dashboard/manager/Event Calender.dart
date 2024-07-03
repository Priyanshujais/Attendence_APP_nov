import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Model class to represent leave event data
class LeaveEvent {
  final String name;
  final String empCode;
  final String leaveMessage;
  final String leaveType;
  final String status;
  final String firstName;
  final String lastName;

  LeaveEvent({
    required this.name,
    required this.empCode,
    required this.leaveMessage,
    required this.leaveType,
    required this.status,
    required this.firstName,
    required this.lastName,
  });
}

class EventCalendar extends StatefulWidget {
  const EventCalendar({Key? key}) : super(key: key);

  @override
  State<EventCalendar> createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  late Map<DateTime, List<String>> _events;
  late List<LeaveEvent> _selectedEvents;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = {}; // Remove holidays to show only user-added events
    _selectedEvents = [];
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Future<void> _fetchLeaveInfo(DateTime selectedDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rmEmpCode = prefs.getString('emp_code');
    String? token = prefs.getString('token');

    if (rmEmpCode != null && token != null) {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v2/leaveInfo'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'rm_emp_code': rmEmpCode,
          'date': selectedDate.toIso8601String(), // Convert DateTime to ISO 8601 format
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == '1') {
          List<dynamic> data = responseData['data'];
          List<LeaveEvent> events = data.map((event) => LeaveEvent(
            name: '${event['first_name']} ${event['last_name']}',
            empCode: event['emp_code'],
            leaveMessage: event['leave_message'],
            leaveType: event['leave_type'],
            status: event['status'],
            firstName: event['first_name'],
            lastName: event['last_name'],
          )).toList();

          setState(() {
            _selectedEvents = events;
          });
        } else {
          setState(() {
            _selectedEvents = [];
          });
        }
      } else {
        setState(() {
          _selectedEvents = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Emp leave calendar",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedEvents = [];
                    });
                    _fetchLeaveInfo(selectedDay);
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                  ),
                ),
                const SizedBox(height: 20.0),
                Expanded(
                  child: _selectedEvents.isNotEmpty
                      ? ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      return LeaveEventItem(
                        leaveEvent: _selectedEvents[index],
                      );
                    },
                  )
                      : Center(
                    child: Text(
                      'No events found for this day.',
                      style: TextStyle(fontSize: 16.0),
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

class LeaveEventItem extends StatefulWidget {
  final LeaveEvent leaveEvent;

  const LeaveEventItem({required this.leaveEvent});

  @override
  _LeaveEventItemState createState() => _LeaveEventItemState();
}

class _LeaveEventItemState extends State<LeaveEventItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Name: ${widget.leaveEvent.name}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Emp Code: ${widget.leaveEvent.empCode}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.0),
                  Text('Leave Message: ${widget.leaveEvent.leaveMessage}'),
                  Text('Leave Type: ${widget.leaveEvent.leaveType}'),
                  Text('Status: ${widget.leaveEvent.status}'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
