import 'package:flutter/material.dart';
import '../user_preferences.dart';

class UserSetupPage extends StatefulWidget {
  const UserSetupPage({super.key});

  @override
  State<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends State<UserSetupPage> {

  int step = 0;

  final nameController = TextEditingController();
  final numberController = TextEditingController();

  void _nextStep() {
    setState(() {
      step += 1;
    });
  }
  
  Future<void> _finishSetup() async {
    final name = nameController.text.trim();
    final monthBudget = int.tryParse(numberController.text.trim());

    if (name.isEmpty || monthBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid values.")),
      );
      return;
    }

    await UserPreferences.setName(name);
    await UserPreferences.setMonthBudget(monthBudget);
    await UserPreferences.setDarkModeFlag(false);

    Navigator.pushReplacementNamed(context, '/main');
  }

  Widget _buildStep1() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,  // <-- Shrink-wrap column vertically
          children: [
            Text(
              "Step 1 of 2", 
              style: TextStyle(fontSize: 16)
            ),
            SizedBox(height: 20),
            Text(
              "What is your name?", 
              style: TextStyle(fontSize: 20)
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextStep,
              child: Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[600],
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Step 2 of 2",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "What is your monthly budget?",
              style: TextStyle(fontSize: 20)
            ),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monthly budget"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _finishSetup,
              child: const Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.amber[800],
        title: const Center(child: Text("Welcome!")),
      ),
      body: Transform.translate(
        offset: Offset(0, -40),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IndexedStack(
            index: step,
            children: [
              _buildStep1(),
              _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }
}