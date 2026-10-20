import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The same supplied passkey silhouette used by the Web and Desktop clients.
class PasskeyIcon extends StatelessWidget {
  const PasskeyIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final side = size ?? iconTheme.size ?? 24;
    final ink =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/icons/passkey.svg',
      width: side,
      height: side,
      colorFilter: ColorFilter.mode(
        ink.withValues(alpha: ink.a * (iconTheme.opacity ?? 1)),
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
    );
  }
}
