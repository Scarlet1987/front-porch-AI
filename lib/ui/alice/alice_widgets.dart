// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition shared widgets. Flat, simple, no runtime font loading,
// minimal shadows. Colors come from AppColors (already teal).

import 'package:flutter/material.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// A card with the Alice look: teal-tinted surface, hairline border,
/// 16px radius. No heavy shadows.
class AliceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AliceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Section header with the teal accent bar: title + subtitle.
class AliceSectionHead extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? barColor;

  const AliceSectionHead({
    super.key,
    required this.title,
    this.subtitle,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 20,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: barColor ?? AppColors.porchAmber,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary / ghost buttons in the Alice style.
class AliceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool small;
  final bool block;

  const AliceButton({
    super.key,
    required this.label,
    this.onPressed,
    this.ghost = false,
    this.small = false,
    this.block = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: ghost ? Colors.transparent : AppColors.porchAmber,
      foregroundColor: ghost
          ? Theme.of(context).colorScheme.onSurface
          : AppColors.onChaosAccent,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 12 : 16,
        vertical: small ? 7 : 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(small ? 10 : 12),
        side: ghost
            ? BorderSide(color: AppColors.borderOf(context))
            : BorderSide.none,
      ),
      elevation: 0,
      textStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: small ? 13 : 14,
      ),
    );
    final btn = ghost
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );
    if (block) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}

/// Small pill chip.
class AliceChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AliceChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: color ?? theme.dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Circular avatar with initial letter.
class AliceAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? background;

  const AliceAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    // Deterministic color from name hash, in the teal/pink/blue family.
    final palette = [
      AppColors.porchAmber,
      const Color(0xFFC2437F),
      const Color(0xFF0F766E),
      const Color(0xFF3366A3),
      const Color(0xFFF472B6),
    ];
    final bg = background ?? palette[name.hashCode.abs() % palette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Segmented control (Simple / Balanced / Advanced style).
class AliceSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const AliceSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : assert(values.length == labels.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sunkenSurfaceOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++)
            _segButton(context, values[i], labels[i]),
        ],
      ),
    );
  }

  Widget _segButton(BuildContext context, T value, String label) {
    final isOn = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? AppColors.porchAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
            color: isOn ? AppColors.onChaosAccent : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

/// Collapsible section: header button with chevron, body folds away.
/// Used for the MC board sections.
class AliceCollapsibleSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color? barColor;
  final Widget child;
  final bool initiallyOpen;

  const AliceCollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    this.barColor,
    required this.child,
    this.initiallyOpen = false,
  });

  @override
  State<AliceCollapsibleSection> createState() =>
      _AliceCollapsibleSectionState();
}

class _AliceCollapsibleSectionState extends State<AliceCollapsibleSection> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderOf(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: widget.barColor ?? AppColors.porchAmber,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// Key-value row used across Alice screens.
class AliceKeyValue extends StatelessWidget {
  final String label;
  final String value;

  const AliceKeyValue({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
