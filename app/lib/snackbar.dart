import "package:flutter/material.dart";

import "package:likertshift/colors.dart";

void showSnackbarMessage(
  BuildContext context,
  String message, {
  IconData? icon,
  bool? success,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final theme = Theme.of(context);
  final appColors = theme.extension<AppColors>();
  messenger.hideCurrentSnackBar();

  final backgroundColor = success != null
      ? success
          ? appColors?.successColor ?? Colors.green
          : theme.brightness == Brightness.light
              ? theme.colorScheme.error
              : theme.colorScheme.errorContainer
      : theme.colorScheme.surfaceContainerHigh;

  final color = !(success ?? true)
      ? theme.brightness == Brightness.light
          ? theme.colorScheme.onError
          : theme.colorScheme.onErrorContainer
      : null;

  final iconData = icon ??
      (success != null
          ? success
              ? Icons.check
              : Icons.error
          : null);

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
      content: GestureDetector(
        onTap: messenger.hideCurrentSnackBar,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          children: [
            if (iconData != null) Icon(iconData, color: color),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    ),
  );
}
