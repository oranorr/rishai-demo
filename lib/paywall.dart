import 'dart:io';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class Paywall extends StatefulWidget {
  const Paywall({super.key});

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  bool processing = false;
  late bool isFreeTrialAvailable;
  late String price;
  AdaptyPaywallProduct? selectedProduct;

  @override
  void initState() {
    selectedProduct = adapty.products.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isFreeTrialAvailable = adapty.isTrialActive;
    // adapty.test();
    price = selectedProduct!.price.localizedString!;
    // '${selectedProduct!.price.currencySymbol}${(selectedProduct!.price.amount).toStringAsFixed(2)}';
    // print(selectedProduct!.price);
    return RishScaffold(
      needsAppBar: false,
      child: ListView(
        shrinkWrap: true,
        children: [
          SizedBox(height: 16.h),
          if (isFreeTrialAvailable) ...[
            Text(
              'Enjoy a fully featured 30-day FREE trial!',
              style: context.styles.h1,
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
            ),
            SizedBox(height: 16.h),
            Text(
              'Start your journey without any commitment.',
              style: context.styles.h3.copyWith(),
              textAlign: TextAlign.center,
            ),
          ],
          if (!isFreeTrialAvailable)
            Text(
              'To continue enjoying Pivot and all its features, subscribe now for only $price per ${selectedProduct!.subscription!.period.unit.name}',
              // 'To continue enjoying Pivot and all its features, subscribe now for only $price per ${selectedProduct!.subscriptionDetails!.subscriptionPeriod.unit.name}',
              // 'Subscribe now for $price to continue enjoying Pivot and all its features.',
              style: context.styles.h2.copyWith(color: RishColors.primary),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 16.h),
          ...nices.map(
            (nice) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h).copyWith(top: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check,
                      color: RishColors.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      nice,
                      maxLines: 10,
                      softWrap: true,
                      style: context.styles.regularLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Your subscription will automatically renew at $price per ${selectedProduct!.subscription!.period.unit.name}, after the 1-month trial ends.',
            // 'Your subscription will automatically renew at $price after the trial ends.',
            style: context.styles.regularMedium,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 4,
          ),
          SizedBox(height: 28.h),
          _SubButtons(
            callback: (product) {
              setState(() {
                selectedProduct = product;
              });
            },
          ),
          SizedBox(height: 16.h),
          if (!isFreeTrialAvailable)
            Text(
              _getSubtitle(
                selectedProduct!.subscription!.period.unit.name,
                price,
              ),
              style: context.styles.boldLarge,
              textAlign: TextAlign.center,
            ),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              text: 'Cancel anytime. ',
              style: context.styles.boldMedium,
              children: [
                TextSpan(
                  text: 'Restore Purchases.',
                  style: context.styles.regularMedium.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async => restore(),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'By subscribing you agree to our ',
              style: context.styles.regularMedium
                  .copyWith(color: RishColors.textSecondary),
              children: [
                TextSpan(
                  text: Platform.isAndroid
                      ? 'Terms of Service '
                      : 'Terms of Use ',
                  style: context.styles.boldMedium.copyWith(
                    color: RishColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async => launchUrl(
                          Uri.parse(
                            Platform.isAndroid
                                ? 'https://thepivotapp.ai/terms-of-service'
                                : 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                          ),
                        ),
                ),
                TextSpan(
                  text: '& ',
                  style: context.styles.boldMedium
                      .copyWith(color: RishColors.textSecondary),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: context.styles.boldMedium.copyWith(
                    color: RishColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async => launchUrl(
                          Uri.parse(
                            'https://thepivotapp.ai/privacy-policy',
                          ),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          RishButton.primary(
            title: isFreeTrialAvailable
                ? 'Start free trial!'
                : 'Purchase subscription',
            enabled: !processing,
            isLoading: processing,
            action: () async {
              setState(() {
                processing = true;
              });
              final res = await adapty.makePurchase(product: selectedProduct!);
              processPurchaseResult(res);
            },
          ),
          if (kDebugMode) ...[
            SizedBox(height: 20.h),
            Center(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.homeScreen.path),
                child: Text(
                  'Skip',
                  style: context.styles.boldLarge.copyWith(
                    color: RishColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> restore() async {
    setState(() {
      processing = true;
    });
    final res = await adapty.restorePurchases();
    switch (res) {
      case 'ACTIVE':
        appNavigationService.go(path: AppRoutes.homeScreen.path);
      case 'NO_ACTIVE':
        RishSnackbar().showSnackBar('No purchases were found');
      case 'ERROR':
        RishSnackbar().showSnackBar('Some error occured. Please, try again.');
      default:
    }
    setState(() {
      processing = false;
    });
  }

  String _getSubtitle(String duration, String price) {
    return '1 month for free, then $price per $duration.';
  }

  List<String> nices = [
    'Daily calorie and macronutrient targets inline with your fitness goal, calculated using our proprietary algorithm based on WHOOP data.',
    'Create daily meal plans tailored to your taste profile and dietary preferences, aligned with your goals.',
    // 'Regeneration of any 1 meal per day of your choice.',
    'Chat with our AI coach on anything nutrition related. (limited to 5 questions a day)',
  ];

  void processPurchaseResult(String res) {
    if (res == 'SUCCESS') {
      appNavigationService.go(path: AppRoutes.homeScreen.path);
    } else if (res == 'CANCEL') {
      RishSnackbar().showSnackBar('Purchase was cancelled.');
    } else if (res == 'ALREADY_EXISTS') {
      RishSnackbar()
          .showSnackBar('Subscription is already linked to another account.');
    } else if (res.contains('Error')) {
      RishSnackbar().showSnackBar(res);
    }
    setState(() {
      processing = false;
    });
  }
}

class _SubButtons extends StatefulWidget {
  const _SubButtons({
    required this.callback,
  });
  final Function(AdaptyPaywallProduct) callback;

  @override
  State<_SubButtons> createState() => __SubButtonsState();
}

class __SubButtonsState extends State<_SubButtons> {
  int indexSelected = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < adapty.products.length; i++)
          Padding(
            padding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => _select(i),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 106.h,
                    width: 152.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 2,
                        color: i == indexSelected
                            ? RishColors.primary
                            : RishColors.textSecondary,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Platform.isIOS
                                ? _getTitleIOs(
                                    adapty.products[i].vendorProductId,
                                  )
                                : '1 ${adapty.products[i].subscription!.period.unit.name}',
                            style:
                                context.styles.boldMedium.copyWith(height: 0),
                          ),
                          FittedBox(
                            child: _getPrice(i, context, i == indexSelected),
                          ),
                          if (i == 1)
                            FittedBox(
                              child: Text(
                                '${adapty.products[i].price.currencySymbol}${(adapty.products[i].price.amount / 12).toStringAsFixed(2)} per month.\nSave 20%',
                                textAlign: TextAlign.center,
                                style: context.styles.regularSmall.copyWith(
                                  color: RishColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (i == 1)
                    Positioned(
                      top: -15.h,
                      left: 26.w,
                      right: 26.w,
                      child: Container(
                        width: 100.w,
                        height: 25.h,
                        decoration: BoxDecoration(
                          color: indexSelected == 1
                              ? RishColors.primary
                              : RishColors.textSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          Platform.isAndroid ? 'Best offer' : 'Save 20%',
                          style: context.styles.boldSmall.copyWith(
                            color: RishColors.formBackgroun,
                            // height: 1.5.h,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _getPrice(int i, BuildContext context, bool isSelected) {
    if (i == 0) {
      return Text(
        adapty.products[i].price.localizedString!,
        // "${adapty.products[i].price.currencySymbol}${adapty.products[i].price.amount.toStringAsFixed(2)}",
        style: context.styles.h3.copyWith(
          color: isSelected ? null : RishColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          height: 1.5,
        ),
      );
    } else {
      return RichText(
        maxLines: 2,
        textAlign: TextAlign.center,
        text: TextSpan(
          text: adapty.products[i].price.localizedString,
          // '${adapty.products[i].price.currencySymbol}${adapty.products[i].price.amount.toStringAsFixed(2)}',
          style: context.styles.h3.copyWith(
            decoration: TextDecoration.none,
            color: isSelected ? null : RishColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            height: 1.5,
          ),
        ),
        // TextSpan(
        //     text:
        //         '${adapty.products[i].price.currencySymbol}${(adapty.products[0].price.amount * 12).toStringAsFixed(2)}',
        //     style: context.styles.boldLarge.copyWith(
        //       decoration: TextDecoration.lineThrough,
        //       color: RishColors.textSecondary,
        //       height: 1.5,
        //     ),
        //     children: [
        //       TextSpan(
        //         text:
        //             '\n${adapty.products[i].price.currencySymbol}${adapty.products[i].price.amount.toStringAsFixed(2)}',
        //         style: context.styles.h3.copyWith(
        //             decoration: TextDecoration.none,
        //             color: isSelected ? null : RishColors.textSecondary,
        //             fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
        //             height: 1.5),
        //       ),
        //     ]),
      );
    }
  }

  void _select(int i) {
    setState(() {
      indexSelected = i;
    });
    widget.callback(
      adapty.products[i],
    );
  }

  String _getTitleIOs(String vendorId) {
    // print(vendorId);
    switch (vendorId) {
      case 'pivot_sub':
        return '1 month';
      case 'pivot_annual':
        return '1 year';

      default:
        return 'Some error?';
    }
  }
}
