import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

class ConnectionSettings extends StatelessWidget {
  const ConnectionSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      centerTitle: true,
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: Text(
        'Connection',
        style: context.styles.h2,
      ),
      child: Column(
        children: [
          for (int i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Text(
                    '${data[i]['title']} is ${data[i]['status'] == ConnectionStatus.connected ? 'connected' : 'disconnected'}',
                    style: context.styles.regularMedium,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      whoopBloc.add(WhoopDisconnect());
                    },
                    child: Builder(builder: (context) {
                      ConnectionStatus status = data[i]['status'];

                      return Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: resolveColor(status, context)),
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 12.h, horizontal: 16.w),
                          child: Text(
                            resolveLabel(status),
                            style: context.styles.boldMedium
                                .copyWith(color: resolveColor(status, context)),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color resolveColor(ConnectionStatus status, BuildContext context) {
    switch (status) {
      case ConnectionStatus.connected:
        return context.theme.colorScheme.error;
      case ConnectionStatus.disconnected:
        return RishColors.success;
      case ConnectionStatus.disabled:
        return RishColors.stroke;
      default:
        return Colors.pink;
    }
  }

  String resolveLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Disconnect';
      case ConnectionStatus.disconnected:
        return 'Connect';
      case ConnectionStatus.disabled:
        return 'Connect (soon)';
      default:
        return 'error';
    }
  }
}

const List<Map<String, dynamic>> data = [
  {
    'title': 'Whoop',
    'status': ConnectionStatus.connected,
  },
  {
    'title': 'Apple',
    'status': ConnectionStatus.disabled,
  },
  {
    'title': 'Garmin',
    'status': ConnectionStatus.disabled,
  },
  {
    'title': 'FitBit',
    'status': ConnectionStatus.disabled,
  },
  {
    'title': 'Oura',
    'status': ConnectionStatus.disabled,
  },
  {
    'title': 'MyFitnessPal',
    'status': ConnectionStatus.disabled,
  },
];

enum ConnectionStatus {
  connected,
  disconnected,
  disabled,
}
