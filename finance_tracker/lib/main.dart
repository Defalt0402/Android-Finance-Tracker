import 'package:flutter/material.dart';
import 'page/HomePage.dart';
import 'page/CalendarPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  int currentIndex = 0;
  final screens = [
    HomePage(),
    CalendarPage()
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber[800],
          title: Text("Finance Tracker"),
        ),

        body: IndexedStack(
          index: currentIndex,
          children: screens),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.amber[800],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
              ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: "Calendar",
              ) 
          ]),
        ),
      );
  }
}