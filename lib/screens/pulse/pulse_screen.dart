import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';
import '../transaction_detail/transaction_detail_screen.dart';

const _pieColors = {
  'Food': Color(0xFFFF6B6B),
  'Transport': Color(0xFF4ECDC4),
  'Shopping': Color(0xFF45B7D1),
  'Bills': Color(0xFF96CEB4),
  'Salary': Color(0xFF22C55E),
  'Entertainment': Color(0xFFFFEAA7),
  'Health': Color(0xFFDDA0DD),
  'Education': Color(0xFF98D8C8),
  'Travel': Color(0xFFF7DC6F),
  'Rent': Color(0xFFBB8FCE),
  'Subscriptions': Color(0xFF85C1E9),
  'Other': Color(0xFF6B7280),
};

class PulseScreen extends StatefulWidget {
  const PulseScreen({super.key});

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen> {
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month + 1, 0);
  }

  List<Transaction> _filteredByDate(List<Transaction> all) {
    return all.where((t) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      return !d.isBefore(_rangeStart) && !d.isAfter(_rangeEnd);
    }).toList();
  }

  List<FlSpot> _dailySpots(List<Transaction> filtered) {
    final days = _rangeEnd.difference(_rangeStart).inDays + 1;
    if (days > 100) return [];

    final dailyNet = <int, double>{};
    for (final t in filtered) {
      final offset = t.date.difference(_rangeStart).inDays;
      dailyNet[offset] = (dailyNet[offset] ?? 0) +
          (t.type == 'income' ? t.amount : -t.amount);
    }

    final spots = <FlSpot>[];
    double balance = 0;
    for (int i = 0; i < days; i++) {
      balance += dailyNet[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), balance));
    }
    return spots;
  }

  String _topCategory(Map<String, double> byCat) {
    if (byCat.isEmpty) return '';
    return byCat.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _topCategoryPct(Map<String, double> byCat, double totalExp) {
    if (byCat.isEmpty || totalExp == 0) return 0;
    final maxVal = byCat.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .value;
    return maxVal / totalExp;
  }

  IconData _iconForCategory(String category, List<Category> cats) {
    for (final c in cats) {
      if (c.name == category) return c.icon;
    }
    return Icons.grid_view;
  }

  void _openDateRangeSheet() {
    DateTime sheetStart = _rangeStart;
    DateTime sheetEnd = _rangeEnd;
    DateTime? pickStart;
    DateTime? pickEnd;
    int viewYear = _rangeStart.year;
    int viewMonth = _rangeStart.month;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setter) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: context.textSecondary
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Select Date Range',
                    style: TextStyle(
                      color: context.text, fontSize: 20,
                      fontWeight: FontWeight.w600)),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _quickPill('This Month', sheetStart, sheetEnd, () {
                          final n = DateTime.now();
                          setter(() {
                            sheetStart = DateTime(n.year, n.month, 1);
                            sheetEnd = DateTime(n.year, n.month + 1, 0);
                          });
                        }),
                        SizedBox(width: 8),
                        _quickPill('Last Month', sheetStart, sheetEnd, () {
                          final n = DateTime.now();
                          setter(() {
                            sheetStart = DateTime(n.year, n.month - 1, 1);
                            sheetEnd = DateTime(n.year, n.month, 0);
                          });
                        }),
                        SizedBox(width: 8),
                        _quickPill('Last 3 Months', sheetStart, sheetEnd, () {
                          final n = DateTime.now();
                          setter(() {
                            sheetStart = DateTime(n.year, n.month - 3, 1);
                            sheetEnd = DateTime(n.year, n.month + 1, 0);
                          });
                        }),
                        SizedBox(width: 8),
                        _quickPill('All Time', sheetStart, sheetEnd, () {
                          setter(() {
                            sheetStart = DateTime(2020, 1, 1);
                            sheetEnd = DateTime.now();
                          });
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _CalendarGrid(
                    viewYear: viewYear, viewMonth: viewMonth,
                    pickStart: pickStart, pickEnd: pickEnd,
                    onMonthChanged: (y, m) => setter(() {
                      viewYear = y; viewMonth = m;
                    }),
                    onDayTap: (day) {
                      setter(() {
                        final tapped = DateTime(viewYear, viewMonth, day);
                        if (pickStart == null ||
                            (pickStart != null && pickEnd != null)) {
                          pickStart = tapped;
                          pickEnd = null;
                          sheetStart = tapped;
                          sheetEnd = tapped;
                        } else {
                          if (tapped.isBefore(pickStart!)) {
                            pickStart = tapped;
                            sheetStart = tapped;
                          } else {
                            pickEnd = tapped;
                            sheetEnd = tapped;
                          }
                        }
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _rangeStart = sheetStart;
                          _rangeEnd = sheetEnd;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.text,
                        foregroundColor: context.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text('CONFIRM',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickPill(String label, DateTime rs, DateTime re, VoidCallback onTap) {
    final now = DateTime.now();
    final isActive = switch (label) {
      'This Month' => rs == DateTime(now.year, now.month, 1) &&
          re == DateTime(now.year, now.month + 1, 0),
      'Last Month' => rs == DateTime(now.year, now.month - 1, 1) &&
          re == DateTime(now.year, now.month, 0),
      _ => false,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? context.text : context.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(label,
          style: TextStyle(
            color: isActive ? context.background : context.text,
            fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final symbol = sp.currencySymbol;
    final f = NumberFormat('#,##0.0', 'en_US');
    final dateFmt = DateFormat('MMM d');

    return SafeArea(
      child: Column(
        children: [
          _PulseTopBar(),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, tp, _) {
                final filtered = _filteredByDate(tp.transactions);
                final byCat = tp.expensesByCategory;
                final totalExp = tp.totalExpenses;

                if (filtered.isEmpty) {
                  return _PulseEmptyState();
                }

                final spots = _dailySpots(filtered);
                final topCat = _topCategory(byCat);
                final topPct = _topCategoryPct(byCat, totalExp);
                final recent = filtered.length > 5
                    ? filtered.sublist(0, 5)
                    : filtered;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Pulse',
                            style: TextStyle(
                              color: context.text, fontSize: 28,
                              fontWeight: FontWeight.w700)),
                          SizedBox(width: 12),
                          Padding(
                            padding: EdgeInsets.only(bottom: 3),
                            child: GestureDetector(
                              onTap: _openDateRangeSheet,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.surface,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${dateFmt.format(_rangeStart)} - ${dateFmt.format(_rangeEnd)}',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.expand_more,
                                      size: 14,
                                      color: context.textSecondary
                                          .withValues(alpha: 0.6)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'TOTAL IN',
                              amount: tp.totalIncome,
                              symbol: symbol,
                              color: AppColors.income,
                              f: f,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'TOTAL OUT',
                              amount: totalExp,
                              symbol: symbol,
                              color: AppColors.expense,
                              f: f,
                            ),
                          ),
                        ],
                      ),
                      if (topCat.isNotEmpty) ...[
                        SizedBox(height: 20),
                        _TopCategoryRow(
                          category: topCat,
                          percentage: topPct,
                          totalExp: totalExp,
                          symbol: symbol,
                          f: f,
                        ),
                      ],
                      SizedBox(height: 24),
                      Text('BALANCE FLOW',
                        style: TextStyle(
                          color: context.textSecondary, fontSize: 13,
                          fontWeight: FontWeight.w500)),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: spots.length > 1
                            ? LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: _yInterval(spots),
                                    getDrawingHorizontalLine: (_) =>
                                        FlLine(
                                          color: context.border,
                                          strokeWidth: 1),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 44,
                                        getTitlesWidget: (value, _) {
                                          return Text(
                                            '$symbol${_shortFormat(value)}',
                                            style: TextStyle(
                                              color: AppColors
                                                  .darkTextSecondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: _bottomInterval(
                                            spots.length),
                                        getTitlesWidget: (value, _) {
                                          final day = _rangeStart
                                              .add(Duration(days: value
                                                  .toInt()));
                                          return Text(
                                            DateFormat('d MMM')
                                                .format(day),
                                            style: TextStyle(
                                              color: AppColors
                                                  .darkTextSecondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: false)),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      preventCurveOverShooting: true,
                                      color: context.text,
                                      barWidth: 2,
                                      dotData: FlDotData(
                                          show: false),
                                      belowBarData: BarAreaData(
                                          show: false),
                                    ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Text('Not enough data',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 13)),
                              ),
                      ),
                      SizedBox(height: 24),
                      Text('SPENDING ANALYSIS',
                        style: TextStyle(
                          color: context.textSecondary, fontSize: 13,
                          fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text(DateFormat('MMM yyyy').format(_rangeStart),
                        style: TextStyle(
                          color: context.textSecondary, fontSize: 11,
                          fontWeight: FontWeight.w400)),
                      SizedBox(height: 16),
                      if (byCat.isNotEmpty)
                        _SpendingAnalysis(
                          byCat: byCat,
                          totalExp: totalExp,
                          symbol: symbol,
                          f: f,
                        ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('RECENT MOVEMENTS',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('See All',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400)),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      ...recent.take(5).map((t) => _PulseTransactionTile(
                        transaction: t,
                        symbol: symbol,
                        f: f,
                        icon: _iconForCategory(t.category, sp.categories),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                  transaction: t),
                            )),
                      )),
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

  double _yInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    final vals = spots.map((s) => s.y).toList();
    final min = vals.reduce((a, b) => a < b ? a : b);
    final max = vals.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range < 100) return 50;
    if (range < 1000) return 200;
    if (range < 10000) return 2000;
    return (range / 5).ceilToDouble();
  }

  double _bottomInterval(int days) {
    if (days <= 7) return 1;
    if (days <= 14) return 2;
    if (days <= 31) return 5;
    if (days <= 62) return 10;
    return (days / 6).ceilToDouble();
  }

  String _shortFormat(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _PulseTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet,
            color: context.text, size: 22),
          SizedBox(width: 10),
          Text('Cashbook',
            style: TextStyle(
              color: context.text, fontSize: 18,
              fontWeight: FontWeight.w600)),
          Spacer(),
          Icon(Icons.notifications_outlined,
            color: context.textSecondary.withValues(alpha: 0.6),
            size: 22),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final Color color;
  final NumberFormat f;

  const _StatCard({
    required this.label, required this.amount, required this.symbol,
    required this.color, required this.f,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: TextStyle(
              color: context.textSecondary.withValues(alpha: 0.8),
              fontSize: 12, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text('$symbol${f.format(amount)}',
            style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  final String category;
  final double percentage;
  final double totalExp;
  final String symbol;
  final NumberFormat f;

  const _TopCategoryRow({
    required this.category, required this.percentage,
    required this.totalExp, required this.symbol, required this.f,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOP CATEGORY',
                style: TextStyle(
                  color: context.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12, fontWeight: FontWeight.w500)),
              Text('$category  ${(percentage * 100).toInt()}%',
                style: TextStyle(
                  color: context.text, fontSize: 14,
                  fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: context.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                  context.text),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingAnalysis extends StatelessWidget {
  final Map<String, double> byCat;
  final double totalExp;
  final String symbol;
  final NumberFormat f;

  const _SpendingAnalysis({
    required this.byCat, required this.totalExp,
    required this.symbol, required this.f,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Container(
          height: 180,
          alignment: Alignment.center,
          child: PieChart(
            PieChartData(
              sections: sorted.map((e) {
                return PieChartSectionData(
                  value: e.value,
                  color: _pieColors[e.key] ?? Color(0xFF6B7280),
                  radius: 40,
                  showTitle: false,
                );
              }).toList(),
              centerSpaceRadius: 60,
              sectionsSpace: 2,
            ),
          ),
        ),
        SizedBox(height: 12),
        Text('$symbol${f.format(totalExp)}',
          style: TextStyle(
            color: context.text, fontSize: 22,
            fontWeight: FontWeight.w700)),
        SizedBox(height: 24),
        ...sorted.map((e) {
          final pct = (e.value / totalExp * 100).toInt();
          final color = _pieColors[e.key] ?? Color(0xFF6B7280);
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(e.key,
                    style: TextStyle(
                      color: context.text, fontSize: 14,
                      fontWeight: FontWeight.w400)),
                ),
                Text('$pct%',
                  style: TextStyle(
                    color: context.textSecondary, fontSize: 14,
                    fontWeight: FontWeight.w400)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PulseTransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String symbol;
  final NumberFormat f;
  final IconData icon;
  final VoidCallback onTap;

  const _PulseTransactionTile({
    required this.transaction, required this.symbol, required this.f,
    required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final dateStr = DateFormat('d MMM').format(transaction.date);

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
            Icon(icon,
              color: context.textSecondary, size: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? transaction.category,
                    style: TextStyle(
                      color: context.text, fontSize: 15,
                      fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text('$dateStr • ${transaction.category}',
                    style: TextStyle(
                      color: context.textSecondary, fontSize: 13,
                      fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}$symbol${f.format(transaction.amount)}',
              style: TextStyle(
                color: isIncome ? AppColors.income : AppColors.expense,
                fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int viewYear;
  final int viewMonth;
  final DateTime? pickStart;
  final DateTime? pickEnd;
  final void Function(int year, int month) onMonthChanged;
  final void Function(int day) onDayTap;

  const _CalendarGrid({
    required this.viewYear, required this.viewMonth,
    required this.pickStart, required this.pickEnd,
    required this.onMonthChanged, required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(viewYear, viewMonth, 1);
    final daysInMonth = DateTime(viewYear, viewMonth + 1, 0).day;
    final startWeekday = firstDay.weekday;
    final offset = startWeekday == 7 ? 0 : startWeekday;
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left,
                  color: context.text, size: 24),
              onPressed: () {
                if (viewMonth == 1) {
                  onMonthChanged(viewYear - 1, 12);
                } else {
                  onMonthChanged(viewYear, viewMonth - 1);
                }
              },
            ),
            Text(DateFormat('MMMM yyyy').format(firstDay),
              style: TextStyle(
                color: context.text, fontSize: 16,
                fontWeight: FontWeight.w600)),
            IconButton(
              icon: Icon(Icons.chevron_right,
                  color: context.text, size: 24),
              onPressed: () {
                if (viewMonth == 12) {
                  onMonthChanged(viewYear + 1, 1);
                } else {
                  onMonthChanged(viewYear, viewMonth + 1);
                }
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                        style: TextStyle(
                          color: context.textSecondary
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    )),
                  ))
              .toList(),
        ),
        SizedBox(height: 4),
        ...List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - offset + 1;

              if (day < 1 || day > daysInMonth) {
                return Expanded(
                    child: SizedBox(height: 38));
              }

              final date = DateTime(viewYear, viewMonth, day);
              final isStart = pickStart != null &&
                  date == DateTime(pickStart!.year,
                      pickStart!.month, pickStart!.day);
              final isEnd = pickEnd != null &&
                  date == DateTime(pickEnd!.year,
                      pickEnd!.month, pickEnd!.day);
              final inRange = pickStart != null && pickEnd != null &&
                  date.isAfter(pickStart!) &&
                  date.isBefore(pickEnd!);

              Color bg = Colors.transparent;
              Color textColor = context.text;

              if (isStart || isEnd) {
                bg = isStart
                    ? AppColors.income
                    : AppColors.expense;
                textColor = context.background;
              } else if (inRange) {
                bg = context.surface;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(day),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text('$day',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: isStart || isEnd
                            ? FontWeight.w700
                            : FontWeight.w400)),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class _PulseEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Opacity(
          opacity: 0.25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: context.textSecondary,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 40),
                          FlSpot(1, 35),
                          FlSpot(2, 50),
                          FlSpot(3, 30),
                          FlSpot(4, 45),
                        ],
                        isCurved: true,
                        color: context.textSecondary,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text('Nothing to analyse yet',
                style: TextStyle(
                  color: context.text, fontSize: 20,
                  fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'Start logging transactions to see\nyour spending patterns',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary, fontSize: 14,
                  fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
