import 'package:finance_tracker/page/SettingsPage.dart';
import 'package:finance_tracker/service/database_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page/HomePage.dart';
import 'page/CalendarPage.dart';
import 'page/UserSetupPage.dart'; 

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Future<bool> _isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username');
    return name == null || name.isEmpty;
  }

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      routes: {
        '/setup': (context) => const UserSetupPage(),
        '/main': (context) => const MainApp(),
        '/settings': (context) => const SettingsPage(),
      },
      navigatorObservers: [routeObserver],
      home: FutureBuilder<bool>(
        future: _isFirstTimeUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isNewUser = snapshot.data!;
          return isNewUser ? const UserSetupPage() : const MainApp();
        },
      ),
    );
  }
}

// Your main app with tabs (Home and Calendar)
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final DatabaseService _databaseService = DatabaseService.instance;

  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  int currentIndex = 0;

  List<Widget> get screens => [
    HomePage(key: _homePageKey),
    CalendarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber[800],
        centerTitle: true,
        title: const Text(
          "Finance Tracker",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),

      drawer: Drawer(
        backgroundColor: Colors.amber[100],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
              ),
            ),

            // Dark Mode Toggle
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Toggle Dark Mode'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dark Mode toggle not yet implemented')),
                );
              },
            ),

            // Go to Settings
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer first

                // Push settings page and wait for it to return
                await Navigator.pushNamed(context, '/settings');

                // Trigger a reload of the home page if visible
                if (currentIndex == 0) {
                  _homePageKey.currentState?.reloadData();
                }
              },
            ),

            // Delete all transactions
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete All Data'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text('Are you sure you want to delete all transaction data?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await DatabaseService.instance.deleteAllTransactions(); // Add this method if you haven’t
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All transactions deleted')),
                  );
                }

                Navigator.pop(context);
              },
            ),

            // Reset preferences
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Reset Preferences'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/setup');
              },
            ),
          ],
        ),
      ),


      body: IndexedStack(
        index: currentIndex,
        children: screens
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.amber[800],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);

          if (index == 0) {
            _homePageKey.currentState?.reloadData();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Calendar"),
        ],
      ),
    );
  }
}