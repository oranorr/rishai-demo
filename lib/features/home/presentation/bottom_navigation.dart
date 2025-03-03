import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishiBottonNavigationBar extends StatefulWidget {
  const RishiBottonNavigationBar({
    required this.jump,
    required this.currentPage,
    super.key,
  });
  final Function(int) jump;
  final int currentPage;

  @override
  State<RishiBottonNavigationBar> createState() =>
      _RishiBottonNavigationBarState();
}

List<Map<String, String>> dests = [
  {
    'name': 'Chat',
    'asset': 'assets/icons/chat.svg',
  },
  {
    'name': 'Prep',
    'asset': 'assets/icons/chat.svg',
  },
  {
    'name': 'Home',
    'asset': 'assets/icons/home.svg',
  },
  {
    'name': 'Settings',
    'asset': 'assets/icons/settings.svg',
  },
];

class _RishiBottonNavigationBarState extends State<RishiBottonNavigationBar> {
  @override
  Widget build(BuildContext context) {
    int selected = widget.currentPage;
    return SizedBox(
      height: Platform.isAndroid ? 68.h : null,
      child: BottomNavigationBar(
        onTap: (value) {
          setState(() {
            selected = value;
          });
          widget.jump(value);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: selected,
        selectedLabelStyle:
            context.styles.regularMedium.copyWith(color: RishColors.primary),
        unselectedLabelStyle: context.styles.regularMedium,
        unselectedItemColor: RishColors.textSecondary,
        selectedItemColor: context.theme.colorScheme.primary,
        items: [
          for (int i = 0; i < dests.length; i++)
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                dests[i]['asset']!,
                colorFilter: selected == i
                    ? ColorFilter.mode(
                        context.theme.colorScheme.primary,
                        BlendMode.srcIn,
                      )
                    : null,
              ),
              label: dests[i]['name'],
              backgroundColor: Colors.transparent,
            ),
        ],
      ),
    );
  }
}
