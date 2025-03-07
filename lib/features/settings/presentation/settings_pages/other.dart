// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/settings/domain/other_legal_texts_repo.dart';
import 'package:rishai/features/settings/presentation/settings_pages/legal_page.dart';

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
      child: ListView.separated(
        itemCount: data.length,
        separatorBuilder: (context, index) {
          return const Divider(
            thickness: 1,
            color: RishColors.stroke,
          );
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => LegalPage(
                    entity: data[index],
                  ),
                ),
              );
            },
            child: SizedBox(
              height: 70.h,
              child: Row(
                children: [
                  Text(
                    data[index].title,
                    style: context.styles.regularLarge.copyWith(
                      color: index == 5 ? RishColors.primary : null,
                    ),
                  ),
                  const Spacer(),
                  const RotatedBox(
                    quarterTurns: 2,
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: RishColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // ),
    );
  }
}

List<OtherEntity> data = [
  OtherEntity(
    title: 'Terms of Service',
    body: LegalTextsRepo().tos,
    type: OtherType.tos,
  ),
  OtherEntity(
    title: 'Privacy Policy',
    body: LegalTextsRepo().pp,
    type: OtherType.pp,
  ),
  OtherEntity(
    title: 'Disclaimer',
    body: LegalTextsRepo().disclaimer,
    type: OtherType.disclaimer,
  ),
  OtherEntity(
    title: 'CITATIONS, REFERENCES & SOURCES',
    body: LegalTextsRepo().references,
    type: OtherType.ref,
  ),
  OtherEntity(
    title: 'Help & Support',
    body: LegalTextsRepo().help,
    type: OtherType.help,
  ),
  OtherEntity(
    title: 'Current & coming soon features',
    body: LegalTextsRepo().comingSoon,
    type: OtherType.premium,
  ),
];

class OtherEntity {
  final String title;
  final String body;
  final OtherType type;
  OtherEntity({
    required this.title,
    required this.body,
    required this.type,
  });
}

enum OtherType {
  tos,
  pp,
  disclaimer,
  help,
  premium,
  ref,
}

//  {
//     'title': 'Terms of Service',
//   },
//   {
//     'title': 'Privacy Policy',
//   },
//   {
//     'title': 'Help & Support',
//   },
//   // {
//   //   'title': 'COMING SOON PREMIUM FEATURES',
//   //   'url': 'http://rish.ai/premium-features',
//   // },
