import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _weeklyBudgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('username') ?? '';
    _budgetController.text =
        prefs.getDouble('month_budget')?.toStringAsFixed(2) ?? '';
    _weeklyBudgetController.text =
        prefs.getDouble('week_budget')?.toStringAsFixed(2) ?? '';
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _nameController.text.trim());

    final monthlyBudget = double.tryParse(_budgetController.text.trim());
    final weeklyBudget = double.tryParse(_weeklyBudgetController.text.trim());

    if (monthlyBudget != null) {
      await prefs.setDouble('month_budget', monthlyBudget);
    }
    if (weeklyBudget != null) {
      await prefs.setDouble('week_budget', weeklyBudget);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: theme.drawerTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Monthly Budget (£)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              style: TextStyle(color: Colors.black),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 1500.00',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Weekly Budget (£)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _weeklyBudgetController,
              style: TextStyle(color: Colors.black),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 375.00',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColorLight,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
