import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'comparison_widget.dart';
part 'recommendations_widget.dart';

class WellnessPage extends StatelessWidget {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        return RishScaffold(
          needsAppBar: true,
          implyLeading: true,
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  'Daily Nutritional Wellness',
                  style: context.styles.h2,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => () {},
                  child: SvgPicture.asset('assets/icons/info_round.svg'),
                ),
              ],
            ),
          ),
          child: ListView(
            children: [
              Container(
                width: double.infinity,
                height: 311.h,
                decoration: BoxDecoration(
                  color: RishColors.formBackgroun,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'animation goes brrrr\n ${state.day.welnessEntity?.welnessPercentage}',
                  ),
                ),
              ),
              SizedBox(
                height: 40.h,
              ),
              const _RecommendationsWidget(),
              SizedBox(
                height: 20.h,
              ),
              const _ComparisonWidget(),
            ],
          ),
        );
      },
    );
  }
}
