import 'package:finance_tracker/service/database_service.dart';
import 'package:finance_tracker/transaction_widget.dart';
import 'package:finance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with RouteAware {
  String _name = '';
  double _monthBudget = 0;
  double _amountSpent = 0.0;

  final DatabaseService _databaseService = DatabaseService.instance;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMonthlySpending();
  }

  Future<void> _loadMonthlySpending() async {
    final now = DateTime.now();
    final yearMonth = DateFormat('yyyy-MM').format(now);

    final total = await _databaseService.getTotalForMonth(yearMonth);
    setState(() {
      _amountSpent = total;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('username') ?? 'User';
      _monthBudget = prefs.getDouble('month_budget') ?? 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when the current route has been pushed.
  @override
  void didPush() {
    _loadMonthlySpending();
  }

  // Called when the current route is again visible after a pop.
  @override
  void didPopNext() {
    _loadMonthlySpending();
  }

  Future<void> reloadData() async {
    // Reload data here (e.g., update amount spent)
    await _loadMonthlySpending();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_monthBudget > 0) ? (_amountSpent / _monthBudget).clamp(0.0, 1.0) : 0.0;

    // Determine color based on progress
    Color getProgressColor(double value) {
      if (value < 0.4) return Colors.green;
      if (value < 0.7) return Colors.orange;
      return Colors.red;
    }

    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.amber[800],
        title: const Text("Home"),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Welcome widget
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[600],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome, $_name!",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '£${_amountSpent.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20, 
                              color: Colors.black54)
                            ),
                          TextSpan(
                            text: '/£${_monthBudget.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 30),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(progress)),
                      ),
                    ),
                  ],
                ),
              ),
              // add transaction widget
              AddTransactionWidget(
                onTransactionAdded: () {
                  _loadMonthlySpending();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}