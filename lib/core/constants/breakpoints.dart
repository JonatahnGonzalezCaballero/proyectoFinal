import 'package:flutter/widgets.dart';

/// Puntos para diseño responsive (móvil / tablet / escritorio).
class Breakpoints {
  Breakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;
}

enum DeviceType { mobile, tablet, desktop }

DeviceType deviceTypeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < Breakpoints.mobileMax) return DeviceType.mobile;
  if (width < Breakpoints.tabletMax) return DeviceType.tablet;
  return DeviceType.desktop;
}