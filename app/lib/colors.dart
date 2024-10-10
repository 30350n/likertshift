import "package:flutter/material.dart";

class AppColors extends ThemeExtension<AppColors> {
  final Color connectedColor;

  const AppColors({required this.connectedColor});

  const AppColors.fromBrightness(Brightness brightness)
      : connectedColor = brightness == Brightness.light ? Colors.blue : Colors.greenAccent;

  @override
  ThemeExtension<AppColors> copyWith({Color? connectedColor}) {
    return AppColors(
      connectedColor: connectedColor ?? this.connectedColor,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(AppColors? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t)!,
    );
  }
}
