import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }

  // الحصول على عرض نسبي (مثلاً: 10.w تعني 10% من عرض الشاشة)
  static double w(double percentage) => blockSizeHorizontal * percentage;

  // الحصول على ارتفاع نسبي (مثلاً: 20.h تعني 20% من ارتفاع الشاشة)
  static double h(double percentage) => blockSizeVertical * percentage;

  // الحصول على حجم خط نسبي
  static double sp(double fontSize) => blockSizeHorizontal * (fontSize / 3.75);
}

// Extension لسهولة الاستخدام داخل الـ Widgets
extension ResponsiveSizeExtension on num {
  double get w => ResponsiveHelper.w(this.toDouble());
  double get h => ResponsiveHelper.h(this.toDouble());
  double get sp => ResponsiveHelper.sp(this.toDouble());
}