import "package:flutter/material.dart";

class AppColors extends ThemeExtension<AppColors> {
  final Color connectedColor;
  final Color successColor;

  const AppColors({required this.connectedColor, required this.successColor});

  const AppColors.fromBrightness(Brightness brightness)
      : connectedColor = brightness == Brightness.light ? Colors.blue : Colors.greenAccent,
        successColor = Colors.green;

  @override
  ThemeExtension<AppColors> copyWith({Color? connectedColor, Color? successColor}) {
    return AppColors(
      connectedColor: connectedColor ?? this.connectedColor,
      successColor: successColor ?? this.successColor,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(AppColors? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
    );
  }
}
