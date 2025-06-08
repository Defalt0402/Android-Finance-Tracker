import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  static Future<void> setMonthBudget(int number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('month_budget', number);
  }

  static Future<int> getMonthBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('month_budget') ?? 0;
  }

  static Future<void> setDarkModeFlag(bool flag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', flag);
  }

  static Future<bool> getDarkModeFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }
}