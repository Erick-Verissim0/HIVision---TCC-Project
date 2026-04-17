import 'package:flutter/widgets.dart';

class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 640;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 640 && width < 1024;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1024;
}
