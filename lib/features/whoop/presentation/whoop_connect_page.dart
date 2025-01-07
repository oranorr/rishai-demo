import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

class WhoopConnectPage extends StatelessWidget {
  const WhoopConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      child: Column(
        children: [
          Container(
            height: 374.h,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Stack(
              // fit: StackFit.expand,
              children: [
                Align(
                  child: Container(
                    width: 312.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RishColors.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                Align(
                  child: Container(
                    width: 248.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RishColors.primary.withOpacity(0.4),
                    ),
                  ),
                ),
                Align(
                  child: Container(
                    width: 186.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: RishColors.primary,
                    ),
                  ),
                ),
                Align(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/whoop_logo.svg',
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24.h,
          ),
          Text(
            'Sync your WHOOP for Personalized insights',
            style: context.styles.h3,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 8.h,
          ),
          Text(
            'Tap "Connect WHOOP" to grant Pivot access to your WHOOP data.',
            textAlign: TextAlign.center,
            style: context.styles.regularLarge
                .copyWith(color: const Color(0xffA8A8A8)),
          ),
          const Spacer(),
          BlocBuilder<WhoopBloc, WhoopState>(
            bloc: whoopBloc,
            builder: (context, state) {
              return RishButton.primary(
                title: 'Connect WHOOP',
                enabled: true,
                isLoading: state.status == Status.loading,
                action: () {
                  whoopBloc.add(WhoopConnectEvent(context));
                },
              );
            },
          ),
          // SizedBox(
          //   height: 8.h,
          // ),
          // RishButton.primary(
          //   title: 'Get user data',
          //   enabled: true,
          //   isLoading: false,
          //   action: () {

          //   },
          // ),
          // const SizedBox(
          //   height: 20,
          // ),
        ],
      ),
    );
  }
}
