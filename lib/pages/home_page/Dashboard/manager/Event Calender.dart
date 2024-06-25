import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class EventCalendar extends StatefulWidget {
  const EventCalendar({super.key});

  @override
  State<EventCalendar> createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  late Map<DateTime, List<String>> _events;
  late List<String> _selectedEvents;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = {
      DateTime.utc(2024, 1, 1): ['New Year\'s Day'],
      DateTime.utc(2024, 1, 14): ['Makar Sankranti/Pongal'],
      DateTime.utc(2024, 1, 26): ['Republic Day'],
      DateTime.utc(2024, 3, 8): ['Maha Shivaratri'],
      DateTime.utc(2024, 3, 25): ['Holi'],
      DateTime.utc(2024, 4, 14): ['Dr. Ambedkar Jayanti'],
      DateTime.utc(2024, 4, 17): ['Mahavir Jayanti'],
      DateTime.utc(2024, 4, 21): ['Ram Navami'],
      DateTime.utc(2024, 4, 24): ['Mahavir Jayanti'],
      DateTime.utc(2024, 4, 29): ['Good Friday'],
      DateTime.utc(2024, 5, 1): ['Labour Day'],
      DateTime.utc(2024, 6, 20): ['Eid al-Fitr'],
      DateTime.utc(2024, 7, 7): ['Bakrid/Eid al-Adha'],
      DateTime.utc(2024, 8, 15): ['Independence Day'],
      DateTime.utc(2024, 8, 19): ['Raksha Bandhan'],
      DateTime.utc(2024, 9, 5): ['Janmashtami'],
      DateTime.utc(2024, 9, 17): ['Ganesh Chaturthi'],
      DateTime.utc(2024, 10, 2): ['Gandhi Jayanti'],
      DateTime.utc(2024, 10, 12): ['Dussehra'],
      DateTime.utc(2024, 10, 20): ['Eid e Milad'],
      DateTime.utc(2024, 10, 31): ['Diwali'],
      DateTime.utc(2024, 11, 1): ['Govardhan Puja'],
      DateTime.utc(2024, 11, 2): ['Bhai Dooj'],
      DateTime.utc(2024, 11, 15): ['Chhath Puja'],
      DateTime.utc(2024, 11, 30): ['Guru Nanak Jayanti'],
      DateTime.utc(2024, 12, 25): ['Christmas'],

      // Add more holidays and events here
    };
    _selectedEvents = _events[_selectedDay] ?? [];
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Event Calendar",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _focusedDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  selectableDayPredicate: (DateTime day) => true,
                );
                if (picked != null && picked != _focusedDay) {
                  setState(() {
                    _focusedDay = picked;
                    _selectedDay = picked;
                    _selectedEvents = _getEventsForDay(picked);
                  });
                }
              },
            ),
          ],
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
                      _selectedEvents = _getEventsForDay(selectedDay);
                    });
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
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            title: Text(_selectedEvents[index]),
                          ),
                        ),
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
