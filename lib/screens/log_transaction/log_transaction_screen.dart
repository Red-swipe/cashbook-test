import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';

class LogTransactionScreen extends StatefulWidget {
  final model.Transaction? existingTransaction;

  const LogTransactionScreen({super.key, this.existingTransaction});

  @override
  State<LogTransactionScreen> createState() => _LogTransactionScreenState();
}

class _LogTransactionScreenState extends State<LogTransactionScreen> {
  late int _cents;
  late bool _isExpense;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    final t = widget.existingTransaction;
    if (t != null) {
      _cents = (t.amount * 10).round();
      _isExpense = t.type == 'expense';
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _descriptionController.text = t.description ?? '';
    } else {
      _cents = 0;
      _isExpense = true;
      _selectedCategory = 'Food';
      _selectedDate = DateTime.now();
    }
  }

  bool get _isEditing => widget.existingTransaction != null;

  String get _displayAmount {
    final dollars = _cents ~/ 10;
    final decimal = _cents % 10;
    final f = NumberFormat('#,##0', 'en_US');
    return '${f.format(dollars)}.$decimal';
  }

  double get _parsedAmount => _cents / 10;

  void _onDigitTap(int digit) {
    setState(() {
      if (_cents >= 999999999) return;
      _cents = _cents * 10 + digit;
    });
  }

  void _onBackspace() {
    setState(() {
      _cents = _cents ~/ 10;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${DateFormat('MMM d, yyyy').format(date)}';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              surface: context.background,
              primary: context.text,
              onSurface: context.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_cents == 0) return;
    try {
      final tp = context.read<TransactionProvider>();

      final t = model.Transaction(
        id: widget.existingTransaction?.id,
        amount: _parsedAmount,
        type: _isExpense ? 'expense' : 'income',
        category: _selectedCategory,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        date: _selectedDate,
        createdAt: widget.existingTransaction?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await tp.updateTransaction(t);
      } else {
        await tp.addTransaction(t);
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      debugPrint('_saveTransaction error: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: mq.size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModalHeader(title: _isEditing ? 'Edit Transaction' : 'Log Transaction'),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _AmountDisplay(
                    symbol: symbol,
                    display: _displayAmount,
                  ),
                  const SizedBox(height: 24),
                  _TypeToggle(
                    isExpense: _isExpense,
                    onToggle: (v) => setState(() => _isExpense = v),
                  ),
                  const SizedBox(height: 24),
                  _CategorySelector(
                    categories: context.read<SettingsProvider>().categories,
                    selected: _selectedCategory,
                    onSelected: (c) => setState(() => _selectedCategory = c),
                  ),
                  const SizedBox(height: 20),
                  _DateField(
                    display: _formatDate(_selectedDate),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  _DescriptionField(
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 24),
                  _Numpad(
                    onDigitTap: _onDigitTap,
                    onBackspace: _onBackspace,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                    child: _SaveButton(
                      isExpense: _isExpense,
                      isEditing: _isEditing,
                      onTap: _saveTransaction,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  final String title;
  const _ModalHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: context.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final String symbol;
  final String display;

  const _AmountDisplay({
    required this.symbol,
    required this.display,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.account_balance_wallet,
          size: 28,
          color: context.textSecondary.withValues(alpha: 0.6),
        ),
        SizedBox(height: 8),
        Text(
          'AMOUNT',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.05,
            color: context.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                symbol,
                style: TextStyle(
                  color: context.textSecondary.withValues(alpha: 0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 4),
            Text(
              display,
              style: TextStyle(
                color: context.text,
                fontSize: 48,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onToggle;

  const _TypeToggle({
    required this.isExpense,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isExpense ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Expense',
                    style: TextStyle(
                      color: isExpense
                          ? context.background
                          : AppColors.expense,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isExpense ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: TextStyle(
                      color: !isExpense
                          ? context.background
                          : AppColors.income,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final name = cat.name;
        final icon = cat.icon;
        final isSelected = selected == name;

        return GestureDetector(
          onTap: () => onSelected(name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? context.text : context.surface,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? context.background : context.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? context.background : context.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  final String display;
  final VoidCallback onTap;

  const _DateField({
    required this.display,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: context.textSecondary.withValues(alpha: 0.6),
            ),
            SizedBox(width: 12),
            Text(
              display,
              style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.textSecondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: context.text,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: 'Add a note (optional)',
        hintStyle: TextStyle(
          color: context.textSecondary.withValues(alpha: 0.6),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: context.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      ),
      maxLines: 3,
      minLines: 1,
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(int digit) onDigitTap;
  final VoidCallback onBackspace;

  const _Numpad({
    required this.onDigitTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          _NumpadRow(
            keys: ['1', '2', '3'],
            onDigitTap: onDigitTap,
            onBackspace: onBackspace,
          ),
          _NumpadRow(
            keys: ['4', '5', '6'],
            onDigitTap: onDigitTap,
            onBackspace: onBackspace,
          ),
          _NumpadRow(
            keys: ['7', '8', '9'],
            onDigitTap: onDigitTap,
            onBackspace: onBackspace,
          ),
          Row(
            children: [
              Expanded(child: _NumpadKey(
                label: '.',
                onTap: () {},
                textStyle: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              )),
              Expanded(child: _NumpadKey(
                label: '0',
                onTap: () => onDigitTap(0),
                textStyle: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              )),
              Expanded(child: _NumpadKey(
                label: '',
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
                textStyle: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumpadRow extends StatelessWidget {
  final List<String> keys;
  final void Function(int digit) onDigitTap;
  final VoidCallback onBackspace;

  const _NumpadRow({
    required this.keys,
    required this.onDigitTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: keys.map((key) {
        if (key == '.') {
          return Expanded(child: _NumpadKey(
            label: '.',
            onTap: () {},
            textStyle: TextStyle(
              color: context.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ));
        }
        if (key == 'backspace') {
          return Expanded(child: _NumpadKey(
            label: '',
            icon: Icons.backspace_outlined,
            onTap: onBackspace,
            textStyle: TextStyle(
              color: context.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ));
        }
        final digit = int.parse(key);
        return Expanded(child: _NumpadKey(
          label: key,
          onTap: () => onDigitTap(digit),
          textStyle: TextStyle(
            color: context.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ));
      }).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final TextStyle textStyle;

  const _NumpadKey({
    required this.label,
    this.icon,
    required this.onTap,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final keyHeight = (h * 0.065).clamp(44.0, 60.0);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: keyHeight,
        child: Material(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: context.text, size: 22)
                  : Text(label, style: textStyle),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isExpense;
  final bool isEditing;
  final Future<void> Function() onTap;

  const _SaveButton({
    required this.isExpense,
    required this.isEditing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () async { await onTap(); },
        style: ElevatedButton.styleFrom(
          backgroundColor: isExpense ? AppColors.expense : AppColors.income,
          foregroundColor: context.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Text(
          isEditing ? 'UPDATE TRANSACTION' : 'SAVE TRANSACTION',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
