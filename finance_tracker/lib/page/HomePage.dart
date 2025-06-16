import 'package:finance_tracker/service/database_service.dart';
import 'package:finance_tracker/transaction_widget.dart';
import 'package:finance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with RouteAware {
  String _name = '';
  double _monthBudget = 0;
  double _weeklyBudget = 0;
  double _amountSpent = 0.0;
  double _weekSpent = 0;

  final DatabaseService _databaseService = DatabaseService.instance;

  late Future<Map<String, dynamic>> _graphDataFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMonthlySpending();
    _loadWeeklySpending();
    _graphDataFuture = _getGraphData();  
  }

  Future<void> _loadMonthlySpending() async {
    final now = DateTime.now();
    final yearMonth = DateFormat('yyyy-MM').format(now);

    final total = await _databaseService.getTotalForMonth(yearMonth);
    setState(() {
      _amountSpent = total;
    });
  }

  Future<void> _loadWeeklySpending() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final transactions = await _databaseService.getTransactionsBetween(
      startOfWeek,
      endOfWeek,
    );

    double total = 0.0;
    for (var tx in transactions) {
      final type = tx['type'] ?? 'spend';
      if (type == 'spend') {
        final amount = (tx['amount'] as num).toDouble();
        total += amount;
      }
    }

    setState(() {
      _weekSpent = total;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final monthBudget = prefs.getDouble('month_budget') ?? 0;
    final weeklyBudget = prefs.getDouble('week_budget') ?? (monthBudget / 4);

    await prefs.setDouble('week_budget', weeklyBudget); // Ensure it's stored

    setState(() {
      _name = prefs.getString('username') ?? 'User';
      _monthBudget = monthBudget;
      _weeklyBudget = weeklyBudget;
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
    _refreshGraphData();
    _loadWeeklySpending();
  }

  // Called when the current route is again visible after a pop.
  @override
  void didPopNext() {
    _loadMonthlySpending();
    _refreshGraphData();
  }

  Future<void> reloadData() async {
    // Reload data here (e.g., update amount spent)
    _loadUserData();
    _refreshGraphData();
    await _loadMonthlySpending();
    await _loadWeeklySpending();
  }

  Future<Map<String, dynamic>> _getGraphData() async {
    final now = DateTime.now();
    final yearMonth = DateFormat('yyyy-MM').format(now);
    final transactions = await _databaseService.getTransactionsForMonth(yearMonth);

    // Prepare for graph 1: average daily spend (excluding outliers)
    final dailyMap = <int, List<double>>{};
    final weekdayTotals = List.generate(7, (_) => <double>[]);

    for (var tx in transactions) {
      final date = DateTime.parse(tx['date']);
      final amount = (tx['amount'] as num).toDouble();
      final type = tx['type'] ?? 'spend';

      if (type == 'spend') {
        final day = date.day;
        dailyMap.putIfAbsent(day, () => []).add(amount);

        final weekday = (date.weekday + 6) % 7;
        weekdayTotals[weekday].add(amount);
      }
    }

    final avgWeekdaySpend = weekdayTotals
        .map((dayList) => dayList.isEmpty ? 0.0 : dayList.reduce((a, b) => a + b) / dayList.length)
        .toList();

    // Graph 2: total spending over time
    final List<FlSpot> spendingOverTime = [];
    double cumulative = 0;
    for (var i = 1; i <= now.day; i++) {
      final dayTxs = transactions.where((tx) {
        final date = DateTime.parse(tx['date']);
        return date.day == i;
      });

      double dayNetTotal = 0.0;
      for (var tx in dayTxs) {
        final amount = (tx['amount'] as num).toDouble();
        final type = tx['type'] ?? 'spend';
        dayNetTotal += type == 'spend' ? amount : -amount;
      }

      cumulative += dayNetTotal;
      spendingOverTime.add(FlSpot(i.toDouble(), cumulative));
    }

    // Graph 3: category totals using reference classification
    final categoryMap = <String, double>{};
    for (var tx in transactions) {
      if (tx['type'] == 'gain') continue;

      final reference = tx['reference'] ?? '';
      final category = classifyCategory(reference);
      final amount = (tx['amount'] as num).toDouble();
      categoryMap[category] = (categoryMap[category] ?? 0) + amount;
    }

    return {
      'averageDaily': avgWeekdaySpend,
      'spendingOverTime': spendingOverTime,
      'categoryMap': categoryMap,
    };
  }

  Future<void> _refreshGraphData() async {
  setState(() {
    _graphDataFuture = _getGraphData();
  });
}

  final Map<String, List<String>> categoryKeywords = {
    'Rent': ['rent', 'landlord', 'housing'],
    'Food': ['asda', 'tesco', 'sainsbury', 'mcdonald', 'kfc', 'burger', 'pizza', 'food', 'co-op'],
    'Bills': ['electric', 'gas', 'water', 'internet', 'phone', 'bt', 'o2', 'vodafone', 'bill'],
    'Transport': ['uber', 'train', 'bus', 'travel', 'taxi'],
    'Entertainment': ['netflix', 'spotify', 'amazon', 'disney', 'cinema', 'game'],
  };

  String classifyCategory(String reference) {
    final ref = reference.toLowerCase();
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (ref.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = (_monthBudget > 0) ? (_amountSpent / _monthBudget).clamp(0.0, 1.0) : 0.0;

    // Determine color based on progress
    Color getProgressColor(double value) {
      if (value < 0.4) return Colors.green;
      if (value < 0.7) return Colors.orange;
      return Colors.red;
    }

    double getWeeklyProgress() {
      return (_weeklyBudget > 0) ? (_weekSpent / _weeklyBudget).clamp(0.0, 1.0) : 0.0;
    }

    return Scaffold(
      backgroundColor: theme.drawerTheme.backgroundColor, 
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                // Welcome widget
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight, 
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
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.black),),
                      const Divider(color: Colors.black,),
                      Text("Montly Spending:",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              )),
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
                      const SizedBox(height: 24),
                      Text("Weekly Spending:",
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '£${_weekSpent.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 20, color: Colors.black54),
                            ),
                            TextSpan(
                              text: '/£${_weeklyBudget.toStringAsFixed(2)}',
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
                          value: getWeeklyProgress(),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            getProgressColor(getWeeklyProgress()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // add transaction widget
                AddTransactionWidget(
                  onTransactionAdded: () {
                    _loadMonthlySpending();
                    _refreshGraphData();
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<Map<String, dynamic>>(
                  future: _graphDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const Text("No data available.");
                    }
                    final avgPerWeekday = snapshot.data!['averageDaily'] as List<double>;
                    final overTime = snapshot.data!['spendingOverTime'] as List<FlSpot>;
                    final categories = snapshot.data!['categoryMap'] as Map<String, double>;
          
                    return Column(
                      children: [
                        // Graph 1: Average Daily Spend
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text("Average Daily Spend (Excl. Outliers)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 150,
                                  child: BarChart(
                                    BarChartData(
                                      barGroups: List.generate(7, (i) {
                                        return BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: avgPerWeekday[i],
                                              color: Colors.blue,
                                              width: 16,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      }),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          tooltipBgColor: Colors.black54,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final value = rod.toY;
                                            final formattedValue = value.toStringAsFixed(2);  // round to 2 decimal places
                                            return BarTooltipItem(
                                              '£$formattedValue',
                                              const TextStyle(color: Colors.white),
                                            );
                                          },
                                        ),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 100,
                                            reservedSize: 42,
                                            getTitlesWidget: (value, meta) => Text('£${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 10)),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 5,
                                            getTitlesWidget: (value, meta) {
                                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                              if (value < 0 || value > 6) return Text('');
                                              return Text(days[value.toInt()], style: TextStyle(fontSize: 14));
                                            },
                                          ),
                                        ),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      gridData: FlGridData(show: true),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Graph 2: Total Spending Over Time
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text("Spending Over Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: overTime,
                                          isCurved: false,
                                          color: Colors.green,
                                          dotData: FlDotData(show: false),
                                          belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.3)),
                                        ),
                                      ],
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 5,
                                            getTitlesWidget: (value, meta) {
                                              final now = DateTime.now();
                                              final day = value.toInt();
                                              if (day < 1 || day > now.day) return const SizedBox.shrink();

                                              final date = DateTime(now.year, now.month, day);
                                              final label = DateFormat('dd/MM').format(date);
                                              return Text(label, style: const TextStyle(fontSize: 10));
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 50,
                                            reservedSize: 42,
                                            getTitlesWidget: (value, meta) => Text('£${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 10)),
                                          ),
                                        ),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      gridData: FlGridData(show: true),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Graph 3: Category Pie Chart
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text("Spending by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: categories.entries.map((entry) {
                                        final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
                                        return PieChartSectionData(
                                          color: color,
                                          value: entry.value,
                                          title: '${entry.key} (£${entry.value.toStringAsFixed(0)})',
                                          radius: 50,
                                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        );
                                      }).toList(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}