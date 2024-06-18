import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Color> _statusColors = {};

  // Define your status colors here
  final Map<String, Color> _statusColorMap = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Half-Day': Colors.orange,
    'Week-Off': Colors.blue,
    'Holiday': Colors.purple,
    'Comp-Off': Colors.yellow,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink.shade800,
      ),
      backgroundColor: Colors.red.shade400, // Scaffold background color
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Center(
            child: Container(
              height: 100,
              width: 380,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildStatusIndicators(),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 430,
            width: 380,
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _updateStatusColors(selectedDay);
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: Colors.black),
                weekendTextStyle: TextStyle(color: Colors.black),
                selectedTextStyle: TextStyle(color: Colors.white),
                todayTextStyle: TextStyle(color: Colors.red),
                todayDecoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.red),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.red,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.red,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                decoration: BoxDecoration(
                  color: Colors.lightGreen[200],
                ),
                weekdayStyle: TextStyle(color: Colors.black),
                weekendStyle: TextStyle(color: Colors.black),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final color = _statusColors[date];
                  if (color != null) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusIndicators() {
    return _statusColorMap.entries.map((entry) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: entry.value,
          ),
          SizedBox(height: 4),
          Text(
            entry.key,
            style: TextStyle(color: Colors.black),
          ),
        ],
      );
    }).toList();
  }

  void _updateStatusColors(DateTime selectedDay) {
    // Fetch the status for the selected day from your data source
    String status = fetchStatusForDate(selectedDay);

    if (status != null && _statusColorMap.containsKey(status)) {
      setState(() {
        _statusColors[selectedDay] = _statusColorMap[status]!;
      });
    }
  }

  // Mock function to fetch status for a given date
  // Replace this with actual implementation
  String fetchStatusForDate(DateTime date) {
    // For demonstration purposes, returning a random status
    List<String> statuses = _statusColorMap.keys.toList();
    return statuses[Random().nextInt(statuses.length)];
  }
}
