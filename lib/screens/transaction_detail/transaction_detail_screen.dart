import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';
import '../log_transaction/log_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final model.Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  IconData _iconForCategory(String category, List<Category> cats) {
    for (final c in cats) {
      if (c.name == category) return c.icon;
    }
    return Icons.grid_view;
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final symbol = sp.currencySymbol;
    final f = NumberFormat('#,##0.0', 'en_US');
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final amountPrefix = isIncome ? '+' : '-';
    final icon = _iconForCategory(transaction.category, sp.categories);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Detail',
          style: TextStyle(
            color: context.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    Text(
                      '$amountPrefix$symbol${f.format(transaction.amount)}',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 28),
                    Icon(icon, size: 64, color: context.text),
                    SizedBox(height: 12),
                    Text(
                      transaction.category,
                      style: TextStyle(
                        color: context.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 28),
                    Divider(
                      color: context.border, thickness: 1, height: 1),
                    SizedBox(height: 20),
                    _DetailRow(
                      label: 'Date',
                      child: Text(
                        DateFormat('EEEE, MMMM d, yyyy · h:mm a')
                            .format(transaction.date),
                        style: TextStyle(
                          color: context.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _DetailRow(
                      label: 'Type',
                      child: Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _DetailRow(
                      label: 'Description',
                      child: Text(
                        transaction.description ?? 'No description added',
                        style: TextStyle(
                          color: transaction.description != null
                              ? context.text
                              : context.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => LogTransactionScreen(
                            existingTransaction: transaction,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.text),
                        foregroundColor: context.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'EDIT TRANSACTION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _confirmDelete(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                        foregroundColor: context.text,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'DELETE TRANSACTION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text(
          'Delete Transaction?',
          style: TextStyle(
            color: context.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will be permanently removed.',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.textSecondary),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<TransactionProvider>()
                  .deleteTransaction(transaction.id!);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.expense,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DELETE',
                style: TextStyle(
                  color: context.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
