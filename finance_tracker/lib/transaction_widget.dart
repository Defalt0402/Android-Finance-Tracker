import 'package:intl/intl.dart'; // you already have this
import 'package:flutter/material.dart';
import 'package:finance_tracker/service/database_service.dart';

class AddTransactionWidget extends StatefulWidget {
  final VoidCallback onTransactionAdded;

  const AddTransactionWidget({required this.onTransactionAdded, Key? key}) : super(key: key);

  @override
  _AddTransactionWidgetState createState() => _AddTransactionWidgetState();
}

class _AddTransactionWidgetState extends State<AddTransactionWidget> {
  bool isRecurring = false;
  String _transactionType = 'spend'; 

  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime singleDate = DateTime.now();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String frequency = 'Monthly';

  Future<void> _submit() async {
    final double? amount = double.tryParse(_amountController.text);
    final String reference = _referenceController.text;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (!isRecurring) {
      await DatabaseService.instance.insertTransaction(DateFormat('yyyy-MM-dd').format(singleDate), amount, reference, _transactionType);
    } else {
      DateTime current = startDate;
      while (!current.isAfter(endDate)) {
        await DatabaseService.instance.insertTransaction(DateFormat('yyyy-MM-dd').format(current), amount, reference, _transactionType);
        switch (frequency) {
          case 'Daily':
            current = current.add(Duration(days: 1));
            break;
          case 'Weekly':
            current = current.add(Duration(days: 7));
            break;
          case 'Monthly':
            final nextMonth = DateTime(current.year, current.month + 1, 1);
            final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
            final day = current.day <= lastDayOfNextMonth ? current.day : lastDayOfNextMonth;
            current = DateTime(nextMonth.year, nextMonth.month, day);
            break;
        }
      }
    }

    widget.onTransactionAdded();
    _referenceController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColorLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ToggleButtons(
                borderColor: Colors.black38,
                selectedBorderColor: Colors.black38,
                selectedColor: theme.toggleButtonsTheme.selectedColor,
                fillColor: theme.toggleButtonsTheme.fillColor,
                isSelected: [!isRecurring, isRecurring],
                onPressed: (index) => setState(() => isRecurring = index == 1),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text("Single", style: TextStyle(color: Colors.black))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Recurring", style: TextStyle(color: Colors.black))),
                ],
              ),
              ToggleButtons(
                borderColor: Colors.black38,
                selectedBorderColor: Colors.black38,
                selectedColor: theme.toggleButtonsTheme.selectedColor,
                isSelected: [_transactionType == 'spend', _transactionType == 'gain'],
                onPressed: (index) {
                  setState(() => _transactionType = index == 0 ? 'spend' : 'gain');
                },
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text("Spend", style: TextStyle(color: Colors.black))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Gain", style: TextStyle(color: Colors.black))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount (£)', labelStyle: TextStyle(color: Colors.black)),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(labelText: 'Reference', labelStyle: TextStyle(color: Colors.black)),
          ),
          const SizedBox(height: 8),
          if (!isRecurring)
            Row(
              children: [
                const Text('Date: ', style: TextStyle(color: Colors.black),),
                TextButton(
                  child: Text(DateFormat('yyyy-MM-dd').format(singleDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: singleDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => singleDate = picked);
                  },
                ),
              ],
            ),
          if (isRecurring)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Start: ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      child: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('End: ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      child: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: frequency,
                  onChanged: (value) => setState(() => frequency = value!),
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submit,
            child: const Text("Add Transaction"),
          )
        ],
      ),
    );
  }
}
