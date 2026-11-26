import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RangeIndicatorBar extends StatelessWidget {
  final List<Color> segmentColors;
  final List<String> segmentLabels;
  final int activeIndex;
  final String title;
  final String? subtitle;

  const RangeIndicatorBar({
    super.key,
    required this.segmentColors,
    required this.segmentLabels,
    required this.activeIndex,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = activeIndex.clamp(0, segmentColors.length - 1);
    final activeColor = segmentColors[safeIndex];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: activeColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: List.generate(segmentColors.length, (i) {
              final isSelected = i == safeIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: isSelected ? 12 : 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? segmentColors[i]
                              : segmentColors[i].withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_drop_up_rounded,
                        size: 20,
                        color: isSelected
                            ? segmentColors[i]
                            : Colors.transparent,
                      ),
                      Text(
                        segmentLabels[i],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.mainText
                              : AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
