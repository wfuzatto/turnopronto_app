import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/logo.svg',
      width: compact ? 176 : 205,
      height: compact ? 48 : 56,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
