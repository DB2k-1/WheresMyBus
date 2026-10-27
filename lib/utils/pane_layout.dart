import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState;

import 'package:flutter/widgets.dart';

/// How the home screen splits on wide or folding displays.
///
/// - Single column below [twoPaneMinWidth] (a normal phone in portrait).
/// - Side by side at [twoPaneMinWidth] and up (iPhone Duo inner display, an
///   open Android foldable, a phone in landscape): the stop list in the leading pane and
///   the selected stop in the trailing pane. The split follows the fold or
///   hinge when Flutter reports one (Android foldables), otherwise it sits in
///   the middle, which is where iPhone Duo folds.
/// - Tabletop when the device is half-folded with the fold across the screen
///   (Galaxy Z Flip in Flex Mode, a book foldable held like a laptop): the
///   selected stop in the top half and the stop list in the bottom half.
class PaneLayout {
  // Wider than any phone in portrait (about 440pt max), narrower than the
  // usable width of iPhone Duo's inner display (594pt beside its 84pt side
  // inset) and an open book foldable held upright (about 670dp).
  static const double twoPaneMinWidth = 560;
  static const double paneGap = 16;

  /// Width of the pane holding the stop list, not counting side safe areas.
  final double leading;

  /// Space between the two panes (the hinge, or [paneGap]).
  final double gap;

  final bool twoPane;

  /// In tabletop, the height of the top half (from the top of the screen).
  final double? tabletopTop;

  const PaneLayout._({
    required this.twoPane,
    required this.leading,
    required this.gap,
    this.tabletopTop,
  });

  bool get isTabletop => tabletopTop != null;
  bool get isSideBySide => twoPane && tabletopTop == null;

  static PaneLayout of(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double width = size.width - padding.left - padding.right;
    final List<DisplayFeature> features = MediaQuery.displayFeaturesOf(context);

    for (final DisplayFeature feature in features) {
      final Rect bounds = feature.bounds;
      if (feature.state == DisplayFeatureState.postureHalfOpened &&
          bounds.width >= size.width * 0.9) {
        final double gap = math.max(bounds.height, paneGap);
        return PaneLayout._(
          twoPane: true,
          leading: width,
          gap: gap,
          tabletopTop: bounds.center.dy - gap / 2,
        );
      }
    }

    if (width < twoPaneMinWidth) {
      return PaneLayout._(twoPane: false, leading: width, gap: 0);
    }

    for (final DisplayFeature feature in features) {
      final Rect bounds = feature.bounds;
      final bool separates =
          bounds.shortestSide > 0 ||
          feature.state == DisplayFeatureState.postureHalfOpened;
      if (separates && bounds.height >= size.height * 0.9) {
        final double gap = math.max(bounds.width, paneGap);
        return PaneLayout._(
          twoPane: true,
          leading: bounds.center.dx - padding.left - gap / 2,
          gap: gap,
        );
      }
    }

    return PaneLayout._(
      twoPane: true,
      leading: (width - paneGap) / 2,
      gap: paneGap,
    );
  }
}
