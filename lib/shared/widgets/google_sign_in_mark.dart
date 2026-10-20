import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The same four-colour Google G used by the Web and Desktop clients.
class GoogleSignInMark extends StatelessWidget {
  const GoogleSignInMark({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the SVG's brand colours instead of inheriting the button's icon tint.
    return SvgPicture.asset(
      'assets/icons/google-sign-in.svg',
      width: 16,
      height: 16,
      excludeFromSemantics: true,
    );
  }
}
