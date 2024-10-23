import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: context.styles.h3,
        ),
        SizedBox(height: 24.h),
        for (int i = 0; i < firstTilesData.length; i++)
          ListTile(
            onTap: () {
              context.push(firstTilesData[i]['path']);
            },
            leading: SvgPicture.asset(firstTilesData[i]['asset']),
            title: Text(
              firstTilesData[i]['label'],
              style: context.styles.regularLarge,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: RishColors.textSecondary,
            ),
          ),
        const Spacer(),
        const Divider(
          color: RishColors.stroke,
        ),
        for (int i = 0; i < lastTilesData.length; i++)
          ListTile(
            onTap: () {
              RishiDialog.showCustomDialog(
                context,
                type: DialogType.actionful,
                actionDialogType: i == 0
                    ? ActionDialogType.logout
                    : ActionDialogType.deleteAccount,
                action: i == 0
                    ? () {
                        //logout user here
                        loginBloc.add(LogoutEvent());
                      }
                    : () {
                        //delete account here
                        userBloc.add(UserDeleteAccount());
                      },
              );
            },
            leading: SvgPicture.asset(lastTilesData[i]['asset']),
            title: Text(
              lastTilesData[i]['label'],
              style: context.styles.regularLarge,
            ),
          ),
      ],
    );
  }
}

final List<Map<String, dynamic>> firstTilesData = [
  {
    'asset': 'assets/icons/user.svg',
    'label': 'Profile',
    'path': AppRoutes.profileSettings.path
  },
  {
    'asset': 'assets/icons/connection.svg',
    'label': 'Connection',
    'path': AppRoutes.connectionSettings.path
  },
  {
    'asset': 'assets/icons/notifications.svg',
    'label': 'Notification',
    'path': AppRoutes.notificationsSettings.path
  },
  {
    'asset': 'assets/icons/info.svg',
    'label': 'Other',
    'path': AppRoutes.otherSettings.path
  },
];

final List<Map<String, dynamic>> lastTilesData = [
  {
    'asset': 'assets/icons/logout.svg',
    'label': 'Log out',
  },
  {
    'asset': 'assets/icons/trash.svg',
    'label': 'Delete account',
  },
];
