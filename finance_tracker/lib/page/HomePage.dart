import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = '';
  int _monthBudget = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('username') ?? 'User';
      _monthBudget = prefs.getInt('month_budget') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double amountSpent = 2000.0;
    final double progress = (_monthBudget > 0) ? (amountSpent / _monthBudget).clamp(0.0, 1.0) : 0.0;

    // Determine color based on progress
    Color getProgressColor(double value) {
      if (value < 0.5) return Colors.green;
      if (value < 0.8) return Colors.orange;
      return Colors.red;
    }

    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.amber[800],
        title: const Text("Home"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                          text: '£$amountSpent',
                          style: TextStyle(
                            fontSize: 20, 
                            color: Colors.black54)
                          ),
                        TextSpan(
                          text: '/£$_monthBudget',
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
          ],
        ),
      ),
    );
  }
}