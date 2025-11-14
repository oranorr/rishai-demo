import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/settings/domain/other_legal_texts_repo.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = LegalTextsRepo();
    // final features = LegalTextsRepo().comingSoon.split('\n\n');
    final currentFeatures = repo.currentFeatures.split('\n');
    final comingSoonFeatures = repo.comingSoon.split('\n');

    return RishScaffold(
      centerTitle: true,
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: Text(
        'Current & coming soon features'.capitalize(),
        style: context.styles.h2,
      ),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildSection(
            context,
            'Current Features',
            currentFeatures,
            RishColors.primary,
          ),
          SizedBox(height: 24.h),
          _buildSection(
            context,
            'Coming Soon Features',
            comingSoonFeatures,
            RishColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> features,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.styles.h3.copyWith(
            color: color,
          ),
        ),
        SizedBox(height: 16.h),
        ...features.map(
          (feature) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.only(top: 8.h),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    feature.trim().replaceAll(RegExp(r'^\d+\.\s*'), ''),
                    style: context.styles.regularLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
