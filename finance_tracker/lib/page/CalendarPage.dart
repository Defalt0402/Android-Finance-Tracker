import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:finance_tracker/service/database_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  final DatabaseService _databaseService = DatabaseService.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  double _dailyTotal = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTransactionsForDay(_selectedDay!);
  }

  void reloadData() {
    _selectedDay = _focusedDay;
    _loadTransactionsForDay(_selectedDay!);
  }

  Future<void> _loadTransactionsForDay(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final total = await _databaseService.getTotalForDay(formatted);
    final txns = await _databaseService.getTransactionsForDay(formatted);

    setState(() {
      _dailyTotal = total;
      _transactions = txns;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadTransactionsForDay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.drawerTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Calendar"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                        1,
                      );
                      _selectedDay = _focusedDay;
                    });
                    _loadTransactionsForDay(_focusedDay);
                  },
                ),

                Expanded(
                  child: Center(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _focusedDay,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          helpText: 'Select month and year',
                        );
                        if (picked != null) {
                          setState(() {
                            _focusedDay = picked;
                            _selectedDay = picked;
                          });
                          _loadTransactionsForDay(picked);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.yMMMM().format(_focusedDay),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                        1,
                      );
                      _selectedDay = _focusedDay;
                    });
                    _loadTransactionsForDay(_focusedDay);
                  },
                ),
              ],
            ),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: _onDaySelected,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              headerVisible: false, // Hide the default header
            ),
            const SizedBox(height: 16),
            Text(
              "Total: £${_dailyTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "Transactions on ${DateFormat.yMMMMd().format(_selectedDay!)}:",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(child: Text("No transactions for this day."))
                  : ListView.separated(
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final txn = _transactions[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        title: Text(
                          txn['reference'] ?? 'No reference',
                          style: const TextStyle(fontSize: 18),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${txn['type'] == 'spend' ? '-' : '+'}£${txn['amount'].toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: txn['type'] == 'spend' ? Colors.red : Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final txnId = txn['id'];
                                if (txnId != null) {
                                  await _databaseService.deleteTransaction(txnId);
                                  _loadTransactionsForDay(_selectedDay!);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ),
            ],
          ),
        ),

    );
  }
}