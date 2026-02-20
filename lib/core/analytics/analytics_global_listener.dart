import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'analytics_service.dart';

/// Global tap listener that captures ALL taps in the app
/// This works in conjunction with TrackedWidgets to provide complete analytics coverage
class AnalyticsGlobalListener extends StatefulWidget {
  final Widget child;
  final bool enableGlobalTracking;
  final bool enableDebugInfo;

  const AnalyticsGlobalListener({
    required this.child,
    this.enableGlobalTracking = true,
    this.enableDebugInfo = false,
    super.key,
  });

  @override
  State<AnalyticsGlobalListener> createState() =>
      _AnalyticsGlobalListenerState();
}

class _AnalyticsGlobalListenerState extends State<AnalyticsGlobalListener> {
  // Track recent taps to avoid duplicates (TrackedWidgets already send events)
  final Set<String> _recentTaps = {};
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 AnalyticsGlobalListener initialized');
    debugPrint(
        '   Global tracking: ${widget.enableGlobalTracking ? "ENABLED" : "DISABLED"}');
    debugPrint(
        '   Debug info: ${widget.enableDebugInfo ? "ENABLED" : "DISABLED"}');
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enableGlobalTracking) return;

    // Debounce: ignore taps within 100ms
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 100) {
      return;
    }
    _lastTapTime = now;

    _processTap(event.position);
  }

  void _processTap(Offset globalPosition) {
    try {
      final result = HitTestResult();
      RendererBinding.instance.hitTest(result, globalPosition);

      String? foundLabel;
      String? renderType;
      String? widgetType;
      String? widgetKey;
      String? semanticsLabel;
      String? buttonText;
      List<String> widgetPath = [];
      List<RenderObject> renderObjects = [];

      // Scan the hit test path
      for (final entry in result.path) {
        final target = entry.target;

        // Only process RenderObjects
        if (target is! RenderObject) continue;

        renderObjects.add(target);

        // Get render type (first one found)
        renderType ??= target.runtimeType.toString();

        // Try to extract information (ALWAYS, not just in debug mode)
        final creator = _getDebugCreator(target);

        if (widget.enableDebugInfo && creator == null) {
          debugPrint('⚠️ debugCreator is NULL for: ${target.runtimeType}');
        }

        if (creator != null) {
          final wType = creator.widget.runtimeType.toString();

          // Add to path only if debug enabled
          if (widget.enableDebugInfo) {
            widgetPath.add(wType);
            debugPrint('   Found widget: $wType');
          }

          // Check if this is a tracked widget (skip to avoid duplicates)
          if (_isTrackedWidget(wType)) {
            if (widget.enableDebugInfo) {
              debugPrint(
                  '⚠️ Skipping global tracking for $wType (already tracked)');
            }
            return;
          }

          // Store first meaningful widget type (Button, Card, ListTile, etc.)
          if (widgetType == null && _isInteractiveWidget(wType)) {
            widgetType = wType;
            if (widget.enableDebugInfo) {
              debugPrint('   ✅ Interactive widget found: $wType');
            }
          }

          // Try to extract button text from widget
          buttonText ??= _extractButtonText(creator.widget);
        }

        // Try semantics label
        semanticsLabel ??= _extractSemanticsLabel(target);

        // Try key
        widgetKey ??= _extractKeyFromRenderObject(target);

        // If we found analytics key, use it as label
        if (widgetKey != null && widgetKey.startsWith('analytics:')) {
          foundLabel = widgetKey.replaceFirst('analytics:', '');
          break;
        }
      }

      // Try to extract text from RenderParagraph (button text)
      buttonText ??= _extractTextFromRenderObjects(renderObjects);

      if (widget.enableDebugInfo) {
        debugPrint('   Button text extracted: $buttonText');
        debugPrint('   Semantics label: $semanticsLabel');
        debugPrint('   Widget key: $widgetKey');
      }

      // Use button text, semantics, or key as label (priority order)
      // Filter out GlobalKey and other non-useful keys
      String? cleanKey = widgetKey;
      if (cleanKey != null &&
          (cleanKey.contains('GlobalKey') || cleanKey.contains('#'))) {
        if (widget.enableDebugInfo) {
          debugPrint('   ⚠️ Ignoring GlobalKey: $cleanKey');
        }
        cleanKey = null; // Ignore GlobalKey
      }

      foundLabel ??= buttonText ?? semanticsLabel ?? cleanKey;

      if (widget.enableDebugInfo) {
        debugPrint('   Final label: $foundLabel');
      }

      // Use widget type from widget tree, fallback to render type
      String? finalWidgetType = widgetType ?? renderType;

      // In release mode, try to infer widget type from render type
      if (widgetType == null && renderType != null) {
        finalWidgetType =
            _inferWidgetTypeFromRenderType(renderType, renderObjects);
      }

      // Skip if no useful information found
      if (finalWidgetType == null ||
          finalWidgetType.contains('Listener') ||
          finalWidgetType.contains('GestureRecognizer')) {
        return;
      }

      // Determine event name based on widget type
      String eventName = 'global_tap';
      debugPrint('   Widget type: $finalWidgetType');
      debugPrint('   Widget path: ${widgetPath.take(5).join(' > ')}');
      if (finalWidgetType.contains('Button')) {
        if (finalWidgetType.contains('Elevated')) {
          eventName = 'elevated_button_pressed';
        } else if (finalWidgetType.contains('Text')) {
          eventName = 'text_button_pressed';
        } else if (finalWidgetType.contains('Outlined')) {
          eventName = 'outlined_button_pressed';
        } else if (finalWidgetType.contains('Icon')) {
          eventName = 'icon_button_pressed';
        } else {
          eventName = 'button_pressed';
        }
      } else if (finalWidgetType.contains('Card')) {
        eventName = 'card_tapped';
      } else if (finalWidgetType.contains('ListTile')) {
        eventName = 'list_tile_tapped';
      } else if (finalWidgetType.contains('InkWell')) {
        eventName = 'inkwell_tap';
      } else if (finalWidgetType.contains('GestureDetector')) {
        eventName = 'gesture_tap';
      }

      // Create analytics event
      final eventData = {
        'widget_type': finalWidgetType,
        'label': foundLabel ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'position': {
          'x': globalPosition.dx.toStringAsFixed(1),
          'y': globalPosition.dy.toStringAsFixed(1),
        },
        'has_label': foundLabel != null,
        'current_screen': NavigationService.router?.state.uri.toString(),
        if (widget.enableDebugInfo && widgetPath.isNotEmpty)
          'widget_path': widgetPath.take(5).join(' > '),
      };

      // Send to analytics with proper event name
      _sendAnalytics(eventName, eventData);
    } catch (e, s) {
      debugPrint('❌ Analytics capture error: $e');
      if (widget.enableDebugInfo) {
        debugPrint('Stack trace: $s');
      }
    }
  }

  /// Check if widget is already tracked by TrackedWidgets
  bool _isTrackedWidget(String widgetType) {
    // Only skip widgets that are EXPLICITLY tracked (have "Tracked" prefix)
    return widgetType.contains('Tracked');
  }

  /// Check if widget is an interactive widget we want to track
  bool _isInteractiveWidget(String widgetType) {
    return widgetType.contains('Button') ||
        widgetType.contains('Card') ||
        widgetType.contains('ListTile') ||
        widgetType.contains('InkWell') ||
        widgetType.contains('GestureDetector') ||
        widgetType.contains('Chip') ||
        widgetType.contains('Switch') ||
        widgetType.contains('Checkbox') ||
        widgetType.contains('Radio');
  }

  /// Infer widget type from render object type (for release mode)
  String _inferWidgetTypeFromRenderType(
      String renderType, List<RenderObject> renderObjects) {
    // Check if there's a RenderConstrainedBox + RenderDecoratedBox pattern (typical for buttons)
    final hasConstrainedBox = renderObjects
        .any((ro) => ro.runtimeType.toString().contains('ConstrainedBox'));
    final hasDecoratedBox = renderObjects
        .any((ro) => ro.runtimeType.toString().contains('DecoratedBox'));
    final hasParagraph = renderObjects
        .any((ro) => ro.runtimeType.toString().contains('Paragraph'));
    final hasSemanticsAnnotations = renderObjects.any(
        (ro) => ro.runtimeType.toString().contains('SemanticsAnnotations'));

    // Pattern matching for common widgets
    if (hasSemanticsAnnotations && hasDecoratedBox && hasParagraph) {
      // Likely a Button (ElevatedButton, TextButton, etc.)
      if (hasConstrainedBox) {
        return 'ElevatedButton'; // Most common button type
      }
      return 'Button';
    }

    if (renderType.contains('Paragraph') && hasParagraph) {
      // If it's just a paragraph with constraints, likely a button
      if (hasConstrainedBox || hasDecoratedBox) {
        return 'TextButton';
      }
    }

    if (renderType.contains('DecoratedBox')) {
      // Could be a Card or Container with tap
      if (hasSemanticsAnnotations) {
        return 'Card';
      }
      return 'InkWell';
    }

    // Fallback to render type
    return renderType;
  }

  /// Extract button text from widget (debug mode only)
  String? _extractButtonText(dynamic widget) {
    try {
      // Check if widget has a child property
      if (widget.runtimeType.toString().contains('Button')) {
        final dynamic w = widget;
        // Try to get child
        if (w.child != null) {
          final child = w.child;
          if (child is Text && child.data != null) {
            return child.data;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extract text from RenderParagraph in the render tree
  String? _extractTextFromRenderObjects(List<RenderObject> renderObjects) {
    try {
      for (final ro in renderObjects) {
        if (ro.runtimeType.toString() == 'RenderParagraph') {
          // Try to extract text from RenderParagraph
          final dynamic paragraph = ro;
          try {
            final text = paragraph.text;
            if (text != null) {
              // Extract plain text from TextSpan
              final plainText = _extractPlainText(text);
              if (plainText != null && plainText.isNotEmpty) {
                return plainText;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extract plain text from TextSpan
  String? _extractPlainText(dynamic textSpan) {
    try {
      if (textSpan == null) return null;

      final buffer = StringBuffer();

      // Get text from current span
      if (textSpan.text != null) {
        buffer.write(textSpan.text);
      }

      // Get text from children
      if (textSpan.children != null) {
        for (final child in textSpan.children) {
          final childText = _extractPlainText(child);
          if (childText != null) {
            buffer.write(childText);
          }
        }
      }

      return buffer.toString();
    } catch (_) {
      return null;
    }
  }

  /// Extract semantics label from RenderObject
  String? _extractSemanticsLabel(RenderObject target) {
    try {
      // Try to get semantics from the render object
      final semanticsNode = target.debugSemantics;
      if (semanticsNode != null) {
        final config = semanticsNode.getSemanticsData();
        if (config.label.isNotEmpty) {
          return config.label;
        }
      }
    } catch (_) {
      // Semantics not available
    }
    return null;
  }

  /// Get debug creator (works in debug mode only, but we try anyway)
  _DebugCreator? _getDebugCreator(RenderObject target) {
    if (!kDebugMode) {
      // In release mode, debugCreator is not available
      // But we can still try to get widget info from semantics or render type
      return null;
    }

    _DebugCreator? result;
    assert(() {
      try {
        final dynamic ro = target;
        final creator = ro.debugCreator;
        if (creator != null) {
          result = _DebugCreator(creator.element, creator.widget);
        }
      } catch (_) {}
      return true;
    }());
    return result;
  }

  /// Extract key from RenderObject via debugCreator
  String? _extractKeyFromRenderObject(RenderObject target) {
    String? keyValue;
    assert(() {
      try {
        final dynamic ro = target;
        final creator = ro.debugCreator;
        if (creator != null) {
          final elem = creator.element;
          final k = elem.widget.key;
          if (k is ValueKey) {
            keyValue = k.value?.toString();
          } else if (k != null) {
            keyValue = k.toString();
          }
        }
      } catch (_) {}
      return true;
    }());
    return keyValue;
  }

  /// Send analytics to backend
  void _sendAnalytics(String eventName, Map<String, dynamic> data) {
    // Generate unique tap identifier to avoid duplicates
    final tapId =
        '${data['widget_type']}_${data['position']['x']}_${data['position']['y']}';

    // Check if we already tracked this tap recently
    if (_recentTaps.contains(tapId)) {
      debugPrint('⚠️ Skipping duplicate tap: $tapId');
      return;
    }

    // Add to recent taps
    _recentTaps.add(tapId);
    Future.delayed(const Duration(seconds: 1), () {
      _recentTaps.remove(tapId);
    });

    // Log the event
    if (widget.enableDebugInfo) {
      debugPrint('👆 GLOBAL TAP CAPTURED:');
      debugPrint('   Event: $eventName');
      debugPrint('   Type: ${data['widget_type']}');
      debugPrint('   Label: ${data['label']}');
      debugPrint('   Position: ${data['position']}');
      if (data.containsKey('widget_path')) {
        debugPrint('   Path: ${data['widget_path']}');
      }
    }

    // Send to AnalyticsService with proper event name
    AnalyticsService.instance.logEvent(
      eventName,
      properties: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enableGlobalTracking ? _handlePointerDown : null,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _recentTaps.clear();
    super.dispose();
  }
}

/// Debug helper class
class _DebugCreator {
  final dynamic element;
  final dynamic widget;
  _DebugCreator(this.element, this.widget);
}

/// Extension to add analytics key to any widget
extension AnalyticsKeyExtension on Widget {
  /// Add analytics key to track this widget in global listener
  Widget withAnalyticsKey(String label) {
    return KeyedSubtree(
      key: ValueKey('analytics:$label'),
      child: this,
    );
  }

  /// Add semantics label for better tracking
  Widget withAnalyticsLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }
}
