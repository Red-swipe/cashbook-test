import 'package:flutter/material.dart';
import '../../../theme/colored_context.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++)
                Column(
                  children: [
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: context.textSecondary,
                        indent: 56,
                      ),
                    children[i],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
