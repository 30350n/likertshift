import "package:flutter/material.dart";

class AppColors extends ThemeExtension<AppColors> {
  final Color connectedColor;
  final Color successColor;
  final Color activeRouteColor;
  final Color pastRouteColor;

  const AppColors({
    required this.connectedColor,
    required this.successColor,
    required this.activeRouteColor,
    required this.pastRouteColor,
  });

  AppColors.fromBrightness(Brightness brightness)
      : connectedColor = brightness == Brightness.light ? Colors.blue : Colors.greenAccent,
        successColor = Colors.green,
        activeRouteColor =
            brightness == Brightness.light ? Colors.orange.shade700 : Colors.orange.shade400,
        pastRouteColor = Colors.blueAccent.shade100;

  @override
  ThemeExtension<AppColors> copyWith({
    Color? connectedColor,
    Color? successColor,
    Color? activeRouteColor,
    Color? pastRouteColor,
  }) {
    return AppColors(
      connectedColor: connectedColor ?? this.connectedColor,
      successColor: successColor ?? this.successColor,
      activeRouteColor: activeRouteColor ?? this.activeRouteColor,
      pastRouteColor: pastRouteColor ?? this.pastRouteColor,
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
      activeRouteColor: Color.lerp(activeRouteColor, other.activeRouteColor, t)!,
      pastRouteColor: Color.lerp(pastRouteColor, other.pastRouteColor, t)!,
    );
  }
}
