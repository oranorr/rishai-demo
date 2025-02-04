// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishDropdownMenu extends StatelessWidget {
  final String title;
  final String preSelectedData;
  final VoidCallback action;
  final bool? needsTrailing;
  const RishDropdownMenu({
    required this.title,
    required this.preSelectedData,
    required this.action,
    super.key,
    this.needsTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: context.styles.regularMedium
                .copyWith(color: RishColors.textSecondary),
          ),
          SizedBox(height: 8.h),
        ],
        GestureDetector(
          onTap: action,
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              color: RishColors.inputField,
              border: Border.all(color: RishColors.stroke),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      preSelectedData,
                      // 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      style: context.styles.regularMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (needsTrailing ?? true)
                    const RotatedBox(
                      quarterTurns: -1,
                      child: Icon(Icons.chevron_left_rounded),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
