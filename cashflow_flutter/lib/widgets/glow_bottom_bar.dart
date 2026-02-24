import 'package:flutter/material.dart';

/// Custom floating glow bottom bar with subtle glow effect
class GlowBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> icons;
  final List<IconData> activeIcons;
  final Color glowColor;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final double height;
  final double iconSize;

  const GlowBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.activeIcons,
    this.glowColor = Colors.purpleAccent,
    this.activeColor = Colors.purpleAccent,
    this.inactiveColor = Colors.grey,
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.height = 56,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(icons.length, (index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(index),
            child: SizedBox(
              width: height,
              height: height,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? glowColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isSelected ? activeIcons[index] : icons[index],
                    color: isSelected ? activeColor : inactiveColor,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
