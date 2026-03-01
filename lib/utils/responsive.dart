import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;

  bool get isSmall => width < 600;
  bool get isMedium => width >= 600 && width < 900;
  bool get isLarge => width >= 900 && width < 1200;
  bool get isXLarge => width >= 1200;

  int get gridColumns {
    if (isSmall) return 3;
    if (isMedium) return 4;
    if (isLarge) return 5;
    return 6;
  }

  double get consoleCardWidth {
    if (isSmall) return 160;
    if (isMedium) return 180;
    if (isLarge) return 200;
    return 220;
  }

  double get consoleCardHeight => consoleCardWidth * 1.5;

  double get gridSpacing {
    if (isSmall) return 12;
    if (isMedium) return 16;
    if (isLarge) return 18;
    return 20;
  }

  EdgeInsets get pagePadding {
    if (isSmall) return const EdgeInsets.all(16);
    if (isMedium) return const EdgeInsets.all(20);
    if (isLarge) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  double get horizontalPadding {
    if (isSmall) return 16;
    if (isMedium) return 24;
    if (isLarge) return 32;
    return 40;
  }

  double fontSize(double baseSize) {
    if (isSmall) return baseSize * 0.9;
    if (isMedium) return baseSize;
    if (isLarge) return baseSize * 1.05;
    return baseSize * 1.1;
  }

  double iconSize(double baseSize) {
    if (isSmall) return baseSize * 0.85;
    if (isMedium) return baseSize;
    if (isLarge) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  double get cardRadius {
    if (isSmall) return 16;
    if (isMedium) return 18;
    if (isLarge) return 20;
    return 22;
  }

  static Responsive of(BuildContext context) => Responsive(context);
}
