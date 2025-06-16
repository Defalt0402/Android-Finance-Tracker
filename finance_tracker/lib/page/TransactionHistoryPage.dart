import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:finance_tracker/service/database_service.dart';

class TransactionHistoryPage extends StatefulWidget {
  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<Map<String, dynamic>> _pastTransactions = [];
  List<Map<String, dynamic>> _upcomingTransactions = [];
  bool _upcomingExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final past = await _databaseService.getAllPastTransactions();
    final upcoming = await _databaseService.getUpcomingTransactions();

    setState(() {
      _pastTransactions = past;
      _upcomingTransactions = upcoming;
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> transactions) {
    return transactions.fold(
      0.0,
      (sum, txn) => sum + (txn['type'] == 'spend' ? -txn['amount'] : txn['amount']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group past transactions by date
    final groupedPast = <String, List<Map<String, dynamic>>>{};
    for (final txn in _pastTransactions) {
      final date = txn['date'];
      groupedPast.putIfAbsent(date, () => []).add(txn);
    }

    return Scaffold(
      backgroundColor: theme.drawerTheme.backgroundColor,
      appBar: AppBar(title: const Text("All Transactions")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _pastTransactions.isEmpty && _upcomingTransactions.isEmpty
            ? const Center(child: Text("No transactions yet."))
            : ListView(
                children: [
                  if (_upcomingTransactions.isNotEmpty)
                    ExpansionTile(
                      title: const Text(
                        "Upcoming Payments",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: _upcomingExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _upcomingExpanded = expanded;
                        });
                      },
                      children: _upcomingTransactions.map((txn) {
                        return _buildTransactionTile(txn, showDate: true);
                      }).toList(),
                    ),
                  const Divider(),
                  const SizedBox(height: 8),
                  for (final entry in groupedPast.entries) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMMd().format(DateTime.parse(entry.key)),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total: ${_calculateTotal(entry.value) < 0 ? '-' : '+'}£${_calculateTotal(entry.value).abs().toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    ...entry.value.map((txn) => _buildTransactionTile(txn)),
                    const Divider(),
                  ]
                ],
              ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> txn, {bool showDate = false}) {
    final date = showDate
        ? ' (${DateFormat.yMMMd().format(DateTime.parse(txn['date']))})'
        : '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        "${txn['reference'] ?? 'No reference'}$date",
        style: const TextStyle(fontSize: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${txn['type'] == 'spend' ? '-' : '+'}£${txn['amount'].toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: txn['type'] == 'spend' ? Colors.red : Colors.green,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final txnId = txn['id'];
              if (txnId != null) {
                await _databaseService.deleteTransaction(txnId);
                _loadTransactions();
              }
            },
          ),
        ],
      ),
    );
  }
}
