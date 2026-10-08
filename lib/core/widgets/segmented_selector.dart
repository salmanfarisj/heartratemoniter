import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Wahoo-style segmented pill selector.
///
/// Used on the device-detail screen as `Heartrate | Speed | Control`.
/// Renders a single rounded pill with the selected tab filled in Wahoo
/// blue and the unselected tabs rendered as flat labels.
class SegmentedSelector<T> extends StatelessWidget {
  final List<SegmentedOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.pillGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt.value == selected;
          return GestureDetector(
            onTap: () => onChanged(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.paperWhite
                      : AppColors.charcoal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SegmentedOption<T> {
  final T value;
  final String label;
  const SegmentedOption(this.value, this.label);
}