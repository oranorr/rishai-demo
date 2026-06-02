import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';

import 'package:rishai/core/theme/theme_colors.dart';

class RishScaffold extends StatelessWidget {
  const RishScaffold({
    required this.child,
    super.key,
    this.appBarLabel,
    this.appBarActions,
    this.implyLeading,
    this.centerChildren,
    this.leadingAction,
    this.needsAppBar,
    this.bottomNavigationBar,
    this.centerTitle,
    this.appBar,
    this.needsBottomPadding,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });
  final Widget? appBarLabel;
  final List<Widget>? appBarActions;
  final bool? implyLeading;
  final bool? centerChildren;
  final VoidCallback? leadingAction;
  final Widget child;
  final bool? needsAppBar;
  final Widget? bottomNavigationBar;
  final bool? centerTitle;
  final AppBar? appBar;
  final bool? needsBottomPadding;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
  // [build] Scaffold на весь экран — иначе SafeArea снаружи оставляет
  // «чёрную бороду» под home indicator (фон не рисуется в нижней зоне).
    final surfaceColor = context.theme.colorScheme.surface;
    final hasBottomNav = bottomNavigationBar != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: surfaceColor,
      bottomNavigationBar: hasBottomNav
          ? ColoredBox(
              color: surfaceColor,
              child: SafeArea(
                top: false,
                bottom: true,
                child: bottomNavigationBar!,
              ),
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      appBar: needsAppBar ?? true
          ? PreferredSize(
              preferredSize: Size.fromHeight(50.h),
              child: appBar ??
                  AppBar(
                    automaticallyImplyLeading: false,
                    elevation: 0,
                    backgroundColor: surfaceColor,
                    centerTitle: centerTitle,
                    leading: implyLeading ?? false
                        ? GestureDetector(
                            onTap: leadingAction ??
                                () {
                                  context.pop();
                                },
                            child: Padding(
                              padding: EdgeInsets.only(left: 16.w),
                              child: Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: RishColors.inputField,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : null,
                    title: appBarLabel,
                  ),
            )
          : null,
      body: SafeArea(
        top: false,
        // [body] Нижний inset только без bottomNavigationBar — иначе двойной отступ.
        bottom: !hasBottomNav,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h)
              .copyWith(bottom: needsBottomPadding ?? true ? 16.h : 0),
          child: child,
        ),
      ),
    );
  }
}
