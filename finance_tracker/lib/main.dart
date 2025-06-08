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
            SizedBox(
              height: 150,
              child: const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.amber,
                ),
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
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Reset Preferences'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Close the drawer
                Navigator.of(context).pop();

                // Optionally, navigate back to setup page or restart app flow:
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