import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'analytics_service.dart';

/// Automatic tracking wrapper for InkWell
class TrackedInkWell extends InkWell {
  TrackedInkWell({
    super.key,
    super.child,
    GestureTapCallback? onTap,
    GestureTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
    super.onHighlightChanged,
    super.onHover,
    super.mouseCursor,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.overlayColor,
    super.splashColor,
    super.splashFactory,
    super.radius,
    super.borderRadius,
    super.customBorder,
    super.enableFeedback,
    super.excludeFromSemantics,
    super.focusNode,
    super.canRequestFocus,
    super.onFocusChange,
    super.autofocus,
    String? trackingLabel,
    Map<String, dynamic>? trackingProperties,
  }) : super(
          onTap: onTap != null
              ? () {
                  // Track the tap
                  _trackInteraction(
                    'inkwell_tap',
                    trackingLabel ?? 'InkWell',
                    trackingProperties,
                  );
                  onTap();
                }
              : null,
          onDoubleTap: onDoubleTap != null
              ? () {
                  _trackInteraction(
                    'inkwell_double_tap',
                    trackingLabel ?? 'InkWell',
                    trackingProperties,
                  );
                  onDoubleTap();
                }
              : null,
          onLongPress: onLongPress != null
              ? () {
                  _trackInteraction(
                    'inkwell_long_press',
                    trackingLabel ?? 'InkWell',
                    trackingProperties,
                  );
                  onLongPress();
                }
              : null,
        );

  static void _trackInteraction(
    String action,
    String label,
    Map<String, dynamic>? properties,
  ) {
    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'InkWell',
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      },
    );
  }
}

/// Automatic tracking wrapper for GestureDetector
class TrackedGestureDetector extends GestureDetector {
  TrackedGestureDetector({
    super.key,
    super.child,
    GestureTapCallback? onTap,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    GestureTapCallback? onTapCancel,
    GestureTapCallback? onSecondaryTap,
    GestureTapDownCallback? onSecondaryTapDown,
    GestureTapUpCallback? onSecondaryTapUp,
    GestureTapCallback? onSecondaryTapCancel,
    GestureTapDownCallback? onTertiaryTapDown,
    GestureTapUpCallback? onTertiaryTapUp,
    GestureTapCallback? onTertiaryTapCancel,
    GestureTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
    GestureLongPressStartCallback? onLongPressStart,
    GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate,
    GestureLongPressUpCallback? onLongPressUp,
    GestureLongPressEndCallback? onLongPressEnd,
    GestureDragDownCallback? onVerticalDragDown,
    GestureDragStartCallback? onVerticalDragStart,
    GestureDragUpdateCallback? onVerticalDragUpdate,
    GestureDragEndCallback? onVerticalDragEnd,
    GestureDragCancelCallback? onVerticalDragCancel,
    GestureDragDownCallback? onHorizontalDragDown,
    GestureDragStartCallback? onHorizontalDragStart,
    GestureDragUpdateCallback? onHorizontalDragUpdate,
    GestureDragEndCallback? onHorizontalDragEnd,
    GestureDragCancelCallback? onHorizontalDragCancel,
    GestureDragDownCallback? onPanDown,
    GestureDragStartCallback? onPanStart,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
    GestureDragCancelCallback? onPanCancel,
    GestureScaleStartCallback? onScaleStart,
    GestureScaleUpdateCallback? onScaleUpdate,
    GestureScaleEndCallback? onScaleEnd,
    HitTestBehavior? behavior,
    bool excludeFromSemantics = false,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    String? trackingLabel,
    Map<String, dynamic>? trackingProperties,
  }) : super(
          onTap: onTap != null
              ? () {
                  _trackInteraction(
                    'gesture_tap',
                    trackingLabel ?? 'GestureDetector',
                    trackingProperties,
                  );
                  onTap();
                }
              : null,
          onTapDown: onTapDown,
          onTapUp: onTapUp,
          onTapCancel: onTapCancel,
          onSecondaryTap: onSecondaryTap,
          onSecondaryTapDown: onSecondaryTapDown,
          onSecondaryTapUp: onSecondaryTapUp,
          onSecondaryTapCancel: onSecondaryTapCancel,
          onTertiaryTapDown: onTertiaryTapDown,
          onTertiaryTapUp: onTertiaryTapUp,
          onTertiaryTapCancel: onTertiaryTapCancel,
          onDoubleTap: onDoubleTap != null
              ? () {
                  _trackInteraction(
                    'gesture_double_tap',
                    trackingLabel ?? 'GestureDetector',
                    trackingProperties,
                  );
                  onDoubleTap();
                }
              : null,
          onLongPress: onLongPress != null
              ? () {
                  _trackInteraction(
                    'gesture_long_press',
                    trackingLabel ?? 'GestureDetector',
                    trackingProperties,
                  );
                  onLongPress();
                }
              : null,
          onLongPressStart: onLongPressStart,
          onLongPressMoveUpdate: onLongPressMoveUpdate,
          onLongPressUp: onLongPressUp,
          onLongPressEnd: onLongPressEnd,
          onVerticalDragDown: onVerticalDragDown,
          onVerticalDragStart: onVerticalDragStart,
          onVerticalDragUpdate: onVerticalDragUpdate,
          onVerticalDragEnd: onVerticalDragEnd,
          onVerticalDragCancel: onVerticalDragCancel,
          onHorizontalDragDown: onHorizontalDragDown,
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
          onHorizontalDragCancel: onHorizontalDragCancel,
          onPanDown: onPanDown,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onPanCancel: onPanCancel,
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: onScaleEnd,
          behavior: behavior,
          excludeFromSemantics: excludeFromSemantics,
          dragStartBehavior: dragStartBehavior,
        );

  static void _trackInteraction(
    String action,
    String label,
    Map<String, dynamic>? properties,
  ) {
    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'GestureDetector',
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      },
    );
  }
}

/// Tracked ElevatedButton
class TrackedElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final String? trackingLabel;
  final Map<String, dynamic>? trackingProperties;

  const TrackedElevatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.trackingLabel,
    this.trackingProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null
          ? () {
              _trackButtonPress('elevated_button_pressed');
              onPressed!();
            }
          : null,
      onLongPress: onLongPress != null
          ? () {
              _trackButtonPress('elevated_button_long_pressed');
              onLongPress!();
            }
          : null,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  void _trackButtonPress(String action) {
    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'ElevatedButton',
        'label': trackingLabel ?? _extractTextFromChild(child),
        'timestamp': DateTime.now().toIso8601String(),
        ...?trackingProperties,
      },
    );
  }

  String _extractTextFromChild(Widget widget) {
    if (widget is Text) {
      return widget.data ?? 'Unknown';
    }
    return 'ElevatedButton';
  }
}

/// Tracked TextButton
class TrackedTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final String? trackingLabel;
  final Map<String, dynamic>? trackingProperties;

  const TrackedTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.trackingLabel,
    this.trackingProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed != null
          ? () {
              _trackButtonPress('text_button_pressed');
              onPressed!();
            }
          : null,
      onLongPress: onLongPress != null
          ? () {
              _trackButtonPress('text_button_long_pressed');
              onLongPress!();
            }
          : null,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  void _trackButtonPress(String action) {
    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'TextButton',
        'label': trackingLabel ?? _extractTextFromChild(child),
        'timestamp': DateTime.now().toIso8601String(),
        ...?trackingProperties,
      },
    );
  }

  String _extractTextFromChild(Widget widget) {
    if (widget is Text) {
      return widget.data ?? 'Unknown';
    }
    return 'TextButton';
  }
}

/// Tracked OutlinedButton
class TrackedOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final String? trackingLabel;
  final Map<String, dynamic>? trackingProperties;

  const TrackedOutlinedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.trackingLabel,
    this.trackingProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed != null
          ? () {
              _trackButtonPress('outlined_button_pressed');
              onPressed!();
            }
          : null,
      onLongPress: onLongPress != null
          ? () {
              _trackButtonPress('outlined_button_long_pressed');
              onLongPress!();
            }
          : null,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  void _trackButtonPress(String action) {
    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'OutlinedButton',
        'label': trackingLabel ?? _extractTextFromChild(child),
        'timestamp': DateTime.now().toIso8601String(),
        ...?trackingProperties,
      },
    );
  }

  String _extractTextFromChild(Widget widget) {
    if (widget is Text) {
      return widget.data ?? 'Unknown';
    }
    return 'OutlinedButton';
  }
}

/// Tracked IconButton
class TrackedIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final double? iconSize;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double? splashRadius;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final bool? enableFeedback;
  final BoxConstraints? constraints;
  final String? trackingLabel;
  final Map<String, dynamic>? trackingProperties;

  const TrackedIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.trackingLabel,
    this.trackingProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed != null
          ? () {
              _trackButtonPress();
              onPressed!();
            }
          : null,
      icon: icon,
      iconSize: iconSize,
      visualDensity: visualDensity,
      padding: padding,
      alignment: alignment,
      splashRadius: splashRadius,
      color: color,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      disabledColor: disabledColor,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      tooltip: tooltip,
      enableFeedback: enableFeedback,
      constraints: constraints,
    );
  }

  void _trackButtonPress() {
    AnalyticsService.instance.logEvent(
      'icon_button_pressed',
      properties: {
        'widget_type': 'IconButton',
        'label': trackingLabel ?? tooltip ?? 'IconButton',
        'timestamp': DateTime.now().toIso8601String(),
        ...?trackingProperties,
      },
    );
  }
}

/// Tracked Card with tap tracking
class TrackedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final bool semanticContainer;
  final String? trackingLabel;
  final Map<String, dynamic>? trackingProperties;

  const TrackedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.semanticContainer = true,
    this.trackingLabel,
    this.trackingProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation,
      shape: shape,
      borderOnForeground: borderOnForeground,
      margin: margin,
      clipBehavior: clipBehavior,
      semanticContainer: semanticContainer,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap != null
            ? () {
                _trackCardTap('card_tapped');
                onTap!();
              }
            : null,
        onLongPress: onLongPress != null
            ? () {
                _trackCardTap('card_long_pressed');
                onLongPress!();
              }
            : null,
        child: card,
      );
    }

    return card;
  }

  void _trackCardTap(String action) {
    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'Card',
        'label': trackingLabel ?? 'Card',
        'timestamp': DateTime.now().toIso8601String(),
        ...?trackingProperties,
      },
    );
  }
}

/// Tracked ListTile
class TrackedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool? dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final ListTileStyle? style;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final MouseCursor? mouseCursor;
  final bool selected;
  final Color? focusColor;
  final Color? hoverColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? tileColor;
  final Color? selectedTileColor;
  final bool? enableFeedback;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  final String? trackingLabel;
  final Map<String, dynamic>? trackingProperties;

  const TrackedListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.style,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.mouseCursor,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.trackingLabel,
    this.trackingProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      style: style,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding: contentPadding,
      enabled: enabled,
      onTap: onTap != null
          ? () {
              _trackListTileTap('list_tile_tapped');
              onTap!();
            }
          : null,
      onLongPress: onLongPress != null
          ? () {
              _trackListTileTap('list_tile_long_pressed');
              onLongPress!();
            }
          : null,
      mouseCursor: mouseCursor,
      selected: selected,
      focusColor: focusColor,
      hoverColor: hoverColor,
      focusNode: focusNode,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
    );
  }

  void _trackListTileTap(String action) {
    String label = trackingLabel ?? 'ListTile';

    // Try to extract title text if available
    if (title is Text) {
      label = (title as Text).data ?? label;
    }

    AnalyticsService.instance.logEvent(
      action,
      properties: {
        'widget_type': 'ListTile',
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
        ...?trackingProperties,
      },
    );
  }
}

/// Extension to easily wrap existing widgets with tracking
extension WidgetTrackingExtension on Widget {
  /// Wrap any widget with tap tracking
  Widget trackTap({
    required VoidCallback onTap,
    String? label,
    Map<String, dynamic>? properties,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
  }) {
    return TrackedGestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      trackingLabel: label,
      trackingProperties: properties,
      child: this,
    );
  }
}
