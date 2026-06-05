import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static final List<IconData> _iconOptions = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.bolt,
    Icons.work,
    Icons.play_circle,
    Icons.favorite,
    Icons.menu_book,
    Icons.flight,
    Icons.home,
    Icons.autorenew,
    Icons.grid_view,
    Icons.pets,
    Icons.wine_bar,
    Icons.sports_esports,
    Icons.health_and_safety,
    Icons.phone_android,
    Icons.wifi,
    Icons.local_grocery_store,
    Icons.card_giftcard,
    Icons.monetization_on,
    Icons.account_balance,
    Icons.construction,
    Icons.coffee,
  ];

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final cats = sp.categories;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        title: Text(
          'Categories',
          style: TextStyle(
            color: context.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.text),
            onPressed: () => _addCategory(context, sp),
          ),
        ],
      ),
      body: cats.isEmpty
          ? Center(
              child: Text(
                'No categories',
                style: TextStyle(color: context.textSecondary),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: cats.length,
              separatorBuilder: (_, _) => SizedBox(height: 4),
              itemBuilder: (context, index) {
                final cat = cats[index];
                return _CategoryTile(
                  category: cat,
                  onToggle: () => sp.toggleCategory(cat.id!),
                  onRename: () => _renameCategory(context, sp, cat),
                  onDelete: () => _deleteCategory(context, sp, cat),
                );
              },
            ),
    );
  }

  void _addCategory(BuildContext context, SettingsProvider sp) {
    final nameController = TextEditingController();
    IconData selectedIcon = _iconOptions.first;
    final iconNotifier = ValueNotifier<IconData>(selectedIcon);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: context.surface,
          title: Text('Add Category',
              style: TextStyle(color: context.text)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: TextStyle(color: context.text),
                    decoration: InputDecoration(
                      hintText: 'Category name',
                      hintStyle:
                          TextStyle(color: context.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: context.textSecondary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: context.text),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose Icon',
                        style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13)),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _iconOptions.length,
                      itemBuilder: (context, i) {
                        final icon = _iconOptions[i];
                        final isSelected = icon.codePoint ==
                            iconNotifier.value.codePoint;
                        return GestureDetector(
                          onTap: () {
                            iconNotifier.value = icon;
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.text
                                  : context.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? context.text
                                    : context.textSecondary
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(icon,
                                size: 22,
                                color: isSelected
                                    ? context.background
                                    : context.text),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final selected = iconNotifier.value;
                try {
                  await sp.addCategory(Category(
                    name: name,
                    iconCodePoint: selected.codePoint,
                    iconFontFamily:
                        selected.fontFamily ?? 'MaterialIcons',
                  ));
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                } catch (e) {
                  debugPrint('addCategory error: $e');
                }
              },
              child: Text('Add',
                  style: TextStyle(color: context.text)),
            ),
          ],
        ),
      ),
    );
  }

  void _renameCategory(
      BuildContext context, SettingsProvider sp, Category cat) {
    final controller = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Rename Category',
            style: TextStyle(color: context.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.text),
          decoration: InputDecoration(
            hintText: 'New name',
            hintStyle: TextStyle(color: context.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: context.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.text),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != cat.name) {
                sp.renameCategory(cat.id!, newName);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style: TextStyle(color: context.text)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(
      BuildContext context, SettingsProvider sp, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Delete Category',
            style: TextStyle(color: AppColors.expense)),
        content: Text(
          'Delete "${cat.name}"? Transactions using this category will keep the name but lose the icon association.',
          style: TextStyle(color: context.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              sp.deleteCategory(cat.id!);
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final Future<void> Function() onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onRename,
        onLongPress: onDelete,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(category.icon, size: 24, color: context.text),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: category.enabled
                        ? context.text
                        : context.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: category.enabled,
                onChanged: (_) { onToggle(); },
                activeThumbColor: context.text,
                inactiveThumbColor: context.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
