import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 5),
                height: 5,
                width: 5,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
