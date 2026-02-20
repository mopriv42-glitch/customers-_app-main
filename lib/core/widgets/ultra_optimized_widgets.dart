import 'package:flutter/material.dart';

/// Ultra-optimized container with minimal rebuilds and maximum performance
class UltraOptimizedContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final Color? color;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final BoxConstraints? constraints;
  final Matrix4? transform;

  const UltraOptimizedContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.color,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.constraints,
    this.transform,
  });

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary for maximum performance
    return RepaintBoundary(
      child: Container(
        padding: padding,
        margin: margin,
        decoration: decoration,
        color: color,
        width: width,
        height: height,
        alignment: alignment,
        clipBehavior: clipBehavior,
        constraints: constraints,
        transform: transform,
        child: child,
      ),
    );
  }
}

/// Ultra-optimized card with minimal rebuilds
class UltraOptimizedCard extends StatelessWidget {
  final Widget? child;
  final Color? color;
  final Color? shadowColor;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? padding;

  const UltraOptimizedCard({
    super.key,
    this.child,
    this.color,
    this.shadowColor,
    this.elevation,
    this.margin,
    this.clipBehavior = Clip.none,
    this.shape,
    this.borderOnForeground = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        color: color,
        shadowColor: shadowColor,
        elevation: elevation,
        margin: margin,
        clipBehavior: clipBehavior,
        shape: shape,
        borderOnForeground: borderOnForeground,
        child: padding != null
            ? Padding(
                padding: padding!,
                child: child,
              )
            : child,
      ),
    );
  }
}

/// Ultra-optimized text with minimal rebuilds
class UltraOptimizedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const UltraOptimizedText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Text(
        data,
        key: key,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaleFactor != null
            ? TextScaler.linear(textScaleFactor!)
            : null,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      ),
    );
  }
}

/// Ultra-optimized button with minimal rebuilds
class UltraOptimizedElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final Widget? child;

  const UltraOptimizedElevatedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ElevatedButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        style: style,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}

/// Ultra-optimized icon with minimal rebuilds
class UltraOptimizedIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;

  const UltraOptimizedIcon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Icon(
        icon,
        key: key,
        size: size,
        fill: fill,
        weight: weight,
        grade: grade,
        opticalSize: opticalSize,
        color: color,
        shadows: shadows,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
      ),
    );
  }
}

/// Ultra-optimized list tile with minimal rebuilds
class UltraOptimizedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool? isThreeLine;
  final bool? dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final ListTileStyle? listTileStyle;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? tileColor;
  final Color? selectedTileColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool? enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MouseCursor? mouseCursor;
  final bool? selected;
  final Color? focusColor;
  final Color? hoverColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool? enableFeedback;

  const UltraOptimizedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine,
    this.dense,
    this.visualDensity,
    this.shape,
    this.listTileStyle,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.tileColor,
    this.selectedTileColor,
    this.contentPadding,
    this.enabled,
    this.onTap,
    this.onLongPress,
    this.mouseCursor,
    this.selected,
    this.focusColor,
    this.hoverColor,
    this.focusNode,
    this.autofocus = false,
    this.enableFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        isThreeLine: isThreeLine,
        dense: dense,
        visualDensity: visualDensity,
        shape: shape,
        selectedColor: selectedColor,
        iconColor: iconColor,
        textColor: textColor,
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        contentPadding: contentPadding,
        enabled: enabled ?? true,
        onTap: onTap,
        onLongPress: onLongPress,
        mouseCursor: mouseCursor,
        selected: selected ?? false,
        focusColor: focusColor,
        hoverColor: hoverColor,
        focusNode: focusNode,
        autofocus: autofocus,
        enableFeedback: enableFeedback ?? true,
      ),
    );
  }
}
