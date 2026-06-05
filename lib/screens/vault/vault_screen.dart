import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';
import '../transaction_detail/transaction_detail_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month + 1, 0);
  }

  List<Transaction> _filtered(List<Transaction> all) {
    var result = all.where((t) {
      final dateDay = DateTime(t.date.year, t.date.month, t.date.day);
      return !dateDay.isBefore(_rangeStart) && !dateDay.isAfter(_rangeEnd);
    }).toList();

    if (_selectedCategory != 'All') {
      result = result.where((t) => t.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        final description = t.description?.toLowerCase() ?? '';
        final category = t.category.toLowerCase();
        return description.contains(query) || category.contains(query);
      }).toList();
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  String _groupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == today.subtract(Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  IconData _iconForCategory(String category, List<Category> cats) {
    for (final c in cats) {
      if (c.name == category) return c.icon;
    }
    return Icons.grid_view;
  }

  void _openDateRangeSheet() {
    DateTime tempStart = _rangeStart;
    DateTime tempEnd = _rangeEnd;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        DateTime sheetStart = tempStart;
        DateTime sheetEnd = tempEnd;
        DateTime? pickStart;
        DateTime? pickEnd;
        int viewYear = tempStart.year;
        int viewMonth = tempStart.month;

        void applyQuick(DateTimeRange range, StateSetter setter) {
          setter(() {
            sheetStart = range.start;
            sheetEnd = range.end;
          });
        }

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
                        color: context.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Select Date Range',
                    style: TextStyle(
                      color: context.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _quickPill('This Month', setter, sheetStart, sheetEnd,
                            () {
                          final n = DateTime.now();
                          applyQuick(
                            DateTimeRange(
                              start: DateTime(n.year, n.month, 1),
                              end: DateTime(n.year, n.month + 1, 0),
                            ), setter);
                        }),
                        SizedBox(width: 8),
                        _quickPill('Last Month', setter, sheetStart, sheetEnd,
                            () {
                          final n = DateTime.now();
                          applyQuick(
                            DateTimeRange(
                              start: DateTime(n.year, n.month - 1, 1),
                              end: DateTime(n.year, n.month, 0),
                            ), setter);
                        }),
                        SizedBox(width: 8),
                        _quickPill('Last 3 Months', setter, sheetStart, sheetEnd,
                            () {
                          final n = DateTime.now();
                          applyQuick(
                            DateTimeRange(
                              start: DateTime(n.year, n.month - 3, 1),
                              end: DateTime(n.year, n.month + 1, 0),
                            ), setter);
                        }),
                        SizedBox(width: 8),
                        _quickPill('All Time', setter, sheetStart, sheetEnd,
                            () {
                          applyQuick(
                            DateTimeRange(
                              start: DateTime(2020, 1, 1),
                              end: DateTime.now(),
                            ), setter);
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _CalendarWidget(
                    viewYear: viewYear,
                    viewMonth: viewMonth,
                    rangeStart: sheetStart,
                    rangeEnd: sheetEnd,
                    onMonthChanged: (y, m) {
                      setter(() {
                        viewYear = y;
                        viewMonth = m;
                      });
                    },
                    onDayTap: (day) {
                      setter(() {
                        final tapped = DateTime(viewYear, viewMonth, day);
                        if (pickStart == null || (pickStart != null && pickEnd != null)) {
                          pickStart = tapped;
                          pickEnd = null;
                          sheetStart = tapped;
                          sheetEnd = tapped;
                        } else {
                          if (tapped.isBefore(pickStart!)) {
                            pickStart = tapped;
                            sheetStart = tapped;
                            sheetEnd = pickEnd ?? tapped;
                          } else {
                            pickEnd = tapped;
                            sheetEnd = tapped;
                          }
                        }
                      });
                    },
                    pickStart: pickStart,
                    pickEnd: pickEnd,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
                      child: Text(
                        'CONFIRM',
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
            );
          },
        );
      },
    );
  }

  Widget _quickPill(String label, StateSetter setter,
      DateTime rangeStart, DateTime rangeEnd, VoidCallback onTap) {
    final now = DateTime.now();
    final isActive = switch (label) {
      'This Month' => rangeStart == DateTime(now.year, now.month, 1) &&
          rangeEnd == DateTime(now.year, now.month + 1, 0),
      'Last Month' => rangeStart == DateTime(now.year, now.month - 1, 1) &&
          rangeEnd == DateTime(now.year, now.month, 0),
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
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? context.background : context.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          _VaultTopBar(),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: context.text),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(
                  color: context.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search,
                    color: context.textSecondary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, tp, _) {
                final filtered = _filtered(tp.transactions);
                final totalAmount = filtered.fold(0.0, (sum, t) =>
                    t.type == 'income' ? sum + t.amount : sum - t.amount);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Vault',
                            style: TextStyle(
                              color: context.text,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '${filtered.length} transactions · $symbol${f.format(totalAmount)}',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _DateRangeRow(
                        display:
                            '${dateFmt.format(_rangeStart)} - ${dateFmt.format(_rangeEnd)}',
                        onTap: _openDateRangeSheet,
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 1 + sp.categories.length,
                          itemBuilder: (context, index) {
                            final cats = sp.categories;
                            final isAll = index == 0;
                            final name = isAll ? 'All' : cats[index - 1].name;
                            final isSelected = _selectedCategory == name;

                            return Padding(
                              padding: EdgeInsets.only(
                                  right: index < (1 + cats.length - 1)
                                      ? 8
                                      : 0),
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedCategory = name),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.text
                                        : context.surface,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? context.background
                                          : context.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      if (filtered.isEmpty)
                        _EmptyFilterState(
                          onClear: () => setState(() {
                            _selectedCategory = 'All';
                            _searchQuery = '';
                            final now = DateTime.now();
                            _rangeStart = DateTime(now.year, now.month, 1);
                            _rangeEnd = DateTime(now.year, now.month + 1, 0);
                          }),
                        )
                      else
                        ..._buildGroupedList(filtered, symbol, f, context, sp.categories),
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

  List<Widget> _buildGroupedList(List<Transaction> list,
      String symbol, NumberFormat f, BuildContext context,
      List<Category> cats) {
    final grouped = <String, List<Transaction>>{};
    for (final t in list) {
      final key = _groupKey(t.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }

    final keyOrder = <String>[];
    for (final t in list) {
      final key = _groupKey(t.date);
      if (!keyOrder.contains(key)) keyOrder.add(key);
    }

    final widgets = <Widget>[];
    for (final key in keyOrder) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Text(
          key,
          style: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ));

      for (final t in grouped[key]!) {
        final isIncome = t.type == 'income';
        widgets.add(_VaultTransactionItem(
          transaction: t,
          symbol: symbol,
          f: f,
          icon: _iconForCategory(t.category, cats),
          isIncome: isIncome,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transaction: t),
              ),
            );
          },
        ));
      }

      widgets.add(SizedBox(height: 12));
    }

    return widgets;
  }
}

class _VaultTopBar extends StatelessWidget {
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
          Icon(Icons.filter_list,
            color: context.textSecondary.withValues(alpha: 0.6),
            size: 22),
        ],
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  final String display;
  final VoidCallback onTap;

  const _DateRangeRow({required this.display, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today,
              size: 16,
              color: context.textSecondary.withValues(alpha: 0.6)),
            SizedBox(width: 8),
            Text(
              display,
              style: TextStyle(
                color: context.text,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.expand_more,
              size: 18,
              color: context.textSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _VaultTransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String symbol;
  final NumberFormat f;
  final IconData icon;
  final bool isIncome;
  final VoidCallback onTap;

  const _VaultTransactionItem({
    required this.transaction,
    required this.symbol,
    required this.f,
    required this.icon,
    required this.isIncome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(icon, color: context.textSecondary, size: 22),
              ),
            ),
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
                    transaction.category,
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
              '${isIncome ? '+' : '-'}$symbol${f.format(transaction.amount)}',
              style: TextStyle(
                color: isIncome ? AppColors.income : AppColors.expense,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFilterState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        child: Column(
          children: [
            Icon(Icons.search_off,
              size: 56,
              color: context.textSecondary.withValues(alpha: 0.4)),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                color: context.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different filter or date range',
              style: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: context.text,
                side: BorderSide(color: context.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Clear all filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final int viewYear;
  final int viewMonth;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final void Function(int year, int month) onMonthChanged;
  final void Function(int day) onDayTap;
  final DateTime? pickStart;
  final DateTime? pickEnd;

  const _CalendarWidget({
    required this.viewYear,
    required this.viewMonth,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.pickStart,
    required this.pickEnd,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(viewYear, viewMonth, 1);
    final daysInMonth = DateTime(viewYear, viewMonth + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon ... 7=Sun
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
            Text(
              DateFormat('MMMM yyyy').format(firstDay),
              style: TextStyle(
                color: context.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                return Expanded(child: SizedBox(height: 38));
              }

              final date = DateTime(viewYear, viewMonth, day);
              final isStart = pickStart != null &&
                  date == DateTime(pickStart!.year, pickStart!.month, pickStart!.day);
              final isEnd = pickEnd != null &&
                  date == DateTime(pickEnd!.year, pickEnd!.month, pickEnd!.day);
              final inRange = pickStart != null && pickEnd != null &&
                  date.isAfter(pickStart!) && date.isBefore(pickEnd!);
              final isToday = date == DateTime.now();

              Color bg = Colors.transparent;
              Color textColor = context.text;

              if (isStart || isEnd) {
                bg = isStart ? AppColors.income : AppColors.expense;
                textColor = context.background;
              } else if (inRange) {
                bg = context.surface;
              } else if (isToday) {
                textColor = context.text;
              }

              final isBeforeStart = pickStart != null &&
                  date.isBefore(DateTime(pickStart!.year, pickStart!.month, pickStart!.day));
              if (isBeforeStart) {
                textColor = context.textSecondary.withValues(alpha: 0.4);
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
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight:
                            isStart || isEnd ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
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
