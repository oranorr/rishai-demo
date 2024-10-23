import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherSettings extends StatelessWidget {
  const OtherSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      centerTitle: true,
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: Text(
        'Other',
        style: context.styles.h2,
      ),
      child: Column(
        children: [
          for (int i = 0; i < data.length; i++)
            GestureDetector(
              onTap: () async {
                await launchUrl(Uri.parse(data[i]['url']!));
              },
              child: Column(
                children: [
                  SizedBox(
                    height: 70.h,
                    child: Row(
                      children: [
                        Text(
                          data[i]['title']!,
                          style: context.styles.regularLarge.copyWith(
                              color: i == 3 ? RishColors.primary : null),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: RishColors.textSecondary,
                        )
                      ],
                    ),
                  ),
                  if (i != 3)
                    const Divider(
                      color: RishColors.stroke,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const List<Map<String, String>> data = [
  {
    'title': 'Terms of Service',
    'url': 'https://rish.ai/terms-of-service',
  },
  {
    'title': 'Privacy Policy',
    'url': 'https://rish.ai/privacy-policy',
  },
  {
    'title': 'Help & Support',
    'url': 'https://rish.ai/contact',
  },
  {
    'title': 'COMING SOON PREMIUM FEATURES',
    'url': 'http://rish.ai/premium-features',
  },
];
