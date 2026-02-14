// lib/core/utils/svg_utils.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class SvgUtils {
  static final Map<String, SvgPicture> _cache = {};

  static SvgPicture getPersonIcon({
    double width = 28,
    double height = 28,
    Color color = Colors.white,
  }) {
    final key = 'person_icon_${width}_${height}_${color.value}';

    if (!_cache.containsKey(key)) {
      _cache[key] = SvgPicture.asset(
        'assets/zapchat/person_icon.svg',
        width: width,
        height: height,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (context) => Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: const Icon(
            CupertinoIcons.person_fill,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    return _cache[key]!;
  }

  static Widget buildAvatar({
    double radius = 28,
    bool hasStory = false,
    bool isOnline = false,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasStory
                ? const LinearGradient(
              colors: [
                CupertinoColors.systemYellow,
                CupertinoColors.systemOrange,
                CupertinoColors.systemRed,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[800],
            child: ClipOval(
              child: SvgUtils.getPersonIcon(
                width: radius * 1.8,
                height: radius * 1.8,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}