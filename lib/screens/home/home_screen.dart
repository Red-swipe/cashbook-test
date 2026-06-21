import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../log_transaction/log_transaction_screen.dart';
import '../transaction_detail/transaction_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  IconData _iconForCategory(String category, List<Category> cats) {
    for (final c in cats) {
      if (c.name == category) return c.icon;
    }
    return Icons.grid_view;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _TopBar(),
          Expanded(
            child: Consumer2<TransactionProvider, SettingsProvider>(
              builder: (context, tp, sp, _) {
                if (tp.transactions.isEmpty) {
                  return _EmptyState(onLogTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const LogTransactionScreen(),
                    );
                  });
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      _BalanceSection(
                        balance: tp.totalBalance,
                        income: tp.totalIncome,
                        expenses: tp.totalExpenses,
                        symbol: sp.currencySymbol,
                      ),
                      SizedBox(height: 24),
                      _SummaryCards(
                        income: tp.totalIncome,
                        expenses: tp.totalExpenses,
                        symbol: sp.currencySymbol,
                      ),
                      SizedBox(height: 32),
                      _RecentActivityHeader(),
                      SizedBox(height: 4),
                      ...tp.recentTransactions.map(
                        (t) => _TransactionItem(
                          transaction: t,
                          symbol: sp.currencySymbol,
                          icon: _iconForCategory(t.category, sp.categories),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(
                                  transaction: t,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 24),
                      _LogTransactionButton(onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const LogTransactionScreen(),
                        );
                      }),
                      SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet,
            color: context.text, size: 22),
          SizedBox(width: 10),
          Text(
            'Cashbook',
            style: TextStyle(
              color: context.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Icon(Icons.search,
            color: context.textSecondary.withValues(alpha: 0.6),
            size: 22),
        ],
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final String symbol;

  const _BalanceSection({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0.0', 'en_US');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Balance',
          style: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$symbol${f.format(balance)}',
          style: TextStyle(
            color: context.text,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.arrow_upward, color: AppColors.income, size: 18),
            SizedBox(width: 4),
            Text(
              '+$symbol${f.format(income)}',
              style: TextStyle(
                color: AppColors.income,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 20),
            Icon(Icons.arrow_downward, color: AppColors.expense, size: 18),
            SizedBox(width: 4),
            Text(
              '-$symbol${f.format(expenses)}',
              style: TextStyle(
                color: AppColors.expense,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double income;
  final double expenses;
  final String symbol;

  const _SummaryCards({
    required this.income,
    required this.expenses,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0.0', 'en_US');
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.savings,
                    color: AppColors.income, size: 20),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Savings',
                      style: TextStyle(
                        color: context.textSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text('$symbol${f.format(income)}',
                      style: TextStyle(
                        color: context.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.credit_card,
                    color: AppColors.expense, size: 20),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending',
                      style: TextStyle(
                        color: context.textSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text('$symbol${f.format(expenses)}',
                      style: TextStyle(
                        color: context.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            color: context.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'See All',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String symbol;
  final IconData icon;
  final VoidCallback onTap;

  const _TransactionItem({
    required this.transaction,
    required this.symbol,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0.0', 'en_US');
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final amountPrefix = isIncome ? '+' : '-';
    final dateStr = _formatDate(context, transaction.date);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.textSecondary, size: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? transaction.category,
                    style: TextStyle(
                      color: context.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$amountPrefix$symbol${f.format(transaction.amount)}',
              style: TextStyle(
                color: amountColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateDay == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class _LogTransactionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogTransactionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.text,
          foregroundColor: context.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              'LOG TRANSACTION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onLogTap;

  const _EmptyState({required this.onLogTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
              size: 64,
              color: context.textSecondary.withValues(alpha: 0.4)),
            SizedBox(height: 20),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: context.text,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the button below to log your first transaction and start tracking your finances.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onLogTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.text,
                  foregroundColor: context.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'LOG TRANSACTION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
