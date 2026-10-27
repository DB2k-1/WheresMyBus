import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheres_my_bus/utils/pane_layout.dart';

/// Works out the home screen layout for a given screen.
Future<PaneLayout> layoutFor(
  WidgetTester tester, {
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
  List<DisplayFeature> features = const [],
}) async {
  late PaneLayout layout;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        displayFeatures: features,
      ),
      child: Builder(builder: (context) {
        layout = PaneLayout.of(context);
        return const SizedBox();
      }),
    ),
  );
  return layout;
}

void main() {
  testWidgets('portrait phone is a single column', (tester) async {
    final layout = await layoutFor(
      tester,
      size: const Size(440, 956),
      padding: const EdgeInsets.only(top: 62, bottom: 34),
    );
    expect(layout.twoPane, isFalse);
  });

  testWidgets('iPhone Duo inner display is side by side, split in the middle',
      (tester) async {
    final layout = await layoutFor(
      tester,
      size: const Size(678, 466),
      padding: const EdgeInsets.only(right: 84, bottom: 34),
    );
    expect(layout.isSideBySide, isTrue);
    expect(layout.leading, (594 - PaneLayout.paneGap) / 2);
  });

  testWidgets('landscape phone is side by side', (tester) async {
    final layout = await layoutFor(
      tester,
      size: const Size(956, 440),
      padding: const EdgeInsets.symmetric(horizontal: 62),
    );
    expect(layout.isSideBySide, isTrue);
  });

  testWidgets('open book foldable splits at the hinge', (tester) async {
    final layout = await layoutFor(
      tester,
      size: const Size(673, 841),
      features: const [
        DisplayFeature(
          bounds: Rect.fromLTWH(330, 0, 12, 841),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureFlat,
        ),
      ],
    );
    expect(layout.isSideBySide, isTrue);
    // The gap is centred on the hinge (x 336) and at least paneGap wide.
    expect(layout.leading, 336 - PaneLayout.paneGap / 2);
    expect(layout.gap, PaneLayout.paneGap);
  });

  testWidgets('half-folded with a horizontal fold is tabletop', (tester) async {
    final layout = await layoutFor(
      tester,
      size: const Size(412, 915),
      features: const [
        DisplayFeature(
          bounds: Rect.fromLTWH(0, 457, 412, 0),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ],
    );
    expect(layout.isTabletop, isTrue);
    expect(layout.tabletopTop, 457 - PaneLayout.paneGap / 2);
  });
}
