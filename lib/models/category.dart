import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final bool enabled;

  const Category({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.enabled = true,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'icon_code_point': iconCodePoint,
    'icon_font_family': iconFontFamily,
    'enabled': enabled ? 1 : 0,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    iconCodePoint: map['icon_code_point'] as int,
    iconFontFamily: map['icon_font_family'] as String,
    enabled: (map['enabled'] as int) == 1,
  );

  Category copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    bool? enabled,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        iconFontFamily: iconFontFamily ?? this.iconFontFamily,
        enabled: enabled ?? this.enabled,
      );
}
