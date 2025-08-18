import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const BASE_URL = 'http://180.83.245.145:8000/';
Widget svgIcon(String name, {double width = 24, double height = 24, Color? color, BoxFit? boxFit}) => SvgPicture.asset(
      name,
      width: width,
      height: height,
      fit: boxFit ?? BoxFit.contain,
      color: color,
    );
