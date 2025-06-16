import 'package:finance_tracker/page/SettingsPage.dart';
import 'package:finance_tracker/page/TransactionHistoryPage.dart';
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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<bool> _isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username');
    return name == null || name.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.amber[800],
        primaryColorLight: Colors.amber[600],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.amber[800],
          foregroundColor: Colors.black,  // text and icons in appbar
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.amber[100],
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(  // headline6 is often used for titles like DrawerHeader
            color: Colors.black, // set drawer header text color here
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.amber[800],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
        ),
        toggleButtonsTheme: ToggleButtonsThemeData(
          selectedColor: Colors.amber[900],
          fillColor: Colors.amber[900],
        )
      ),
      darkTheme: ThemeData.dark(),  // you can customize this too
      themeMode: _themeMode,
      routes: {
        '/setup': (context) => const UserSetupPage(),
        '/main': (context) => MainApp(toggleTheme: _toggleTheme),
        '/settings': (context) => const SettingsPage(),
        '/transactions': (context) => TransactionHistoryPage(),
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
          return isNewUser ? const UserSetupPage() : MainApp(toggleTheme: _toggleTheme);
        },
      ),
    );
  }
}

// Your main app with tabs (Home and Calendar)
class MainApp extends StatefulWidget {
  final Future<void> Function(bool) toggleTheme;
  const MainApp({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final DatabaseService _databaseService = DatabaseService.instance;

  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<TransactionHistoryPageState> _transactionsPageKey = GlobalKey<TransactionHistoryPageState>();
  final GlobalKey<CalendarPageState> _calendarPageKey = GlobalKey<CalendarPageState>();
  int currentIndex = 0;

  List<Widget> get screens => [
    HomePage(key: _homePageKey),
    CalendarPage(key: _calendarPageKey),
    TransactionHistoryPage(key: _transactionsPageKey)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          "Finance Tracker",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),

      drawer: Drawer(
        backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                    child: Center(
                      child: Text(
                        'Menu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),

                  // Dark Mode Toggle
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Toggle Dark Mode'),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final isDark = prefs.getBool('isDarkMode') ?? false;
                      await widget.toggleTheme(!isDark);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dark mode ${!isDark ? "enabled" : "disabled"}')),
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
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Reset'),
                          content: const Text('This will clear your preferences and restart setup. Continue?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reset', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.of(context).pop(); // close drawer
                        Navigator.pushReplacementNamed(context, '/setup');
                      }
                    },
                  ),
                ],
              ),
            ),

            // Footer text at bottom of drawer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Made by Lewis Murphy (Defalt0402), 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
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
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);

          if (index == 0) {
            _homePageKey.currentState?.reloadData();
          } else if (index == 1) {
            _calendarPageKey.currentState?.reloadData();
          } else if (index == 2) {
            _transactionsPageKey.currentState?.reloadData();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: "Transactions"),
        ],
      ),
    );
  }
}
