import 'dart:io';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/core/widgets/snackbar.dart';

class Paywall extends StatefulWidget {
  const Paywall({super.key});

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  bool processing = false;
  AdaptyPaywallProduct? selectedProduct;

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
        appBar: AppBar(
          title: Text(
            'Buy our subscription',
            style: context.styles.h1,
          ),
        ),
        needsAppBar: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '''
1. Daily calculation of the target amount of calories and nutrients using a unique method based on Whoop activity data

2. Generation of personalized meal plans adapted to the user's goals and food preferences

3. Regeneration of any 1 meal per day of your choice

4. Up to 5 requests/day to the AI ​​coach on any nutrition-related issues

''',
              style: context.styles.regularMedium,
            ),
            const Spacer(),
            _SubButtons(
              callback: (p) {
                setState(() {
                  selectedProduct = p;
                });
              },
            ),
            const Spacer(),
            RishButton.primary(
              title: 'Buy',
              enabled: selectedProduct != null,
              isLoading: processing,
              action: () async {
                setState(() {
                  processing = true;
                });
                final res =
                    await adapty.makePurchase(product: selectedProduct!);
                processPurchaseResult(res);
              },
            ),
            SizedBox(height: 20.h),
          ],
        ));
  }

  void processPurchaseResult(String res) {
    if (res == 'SUCCESS') {
      appNavigationService.push(path: AppRoutes.homeScreen.path);
    } else if (res == 'CANCEL') {
      RishSnackbar().showSnackBar('Purchase was cancelled.');
    } else if (res.contains('Error')) {
      RishSnackbar().showSnackBar(res);
    }
    setState(() {
      processing = false;
    });
  }
}

class _SubButtons extends StatefulWidget {
  final Function(AdaptyPaywallProduct) callback;
  const _SubButtons({
    super.key,
    required this.callback,
  });

  @override
  State<_SubButtons> createState() => __SubButtonsState();
}

class __SubButtonsState extends State<_SubButtons> {
  int? indexSelected;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < adapty.products.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: GestureDetector(
              onTap: () {
                // print(adapty.products[i]);
                _select(i);
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: RishColors.formBackgroun,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        i == indexSelected ? Colors.white : RishColors.stroke,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 15.h,
                    // horizontal: 100.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Platform.isIOS
                            ? _getTitleIOs(adapty.products[i].vendorProductId)
                            : _getTitleAndroid(adapty.products[i]
                                .subscriptionDetails!.androidBasePlanId!),
                        style: context.styles.regularLarge,
                      ),
                      Text(
                        "${adapty.products[i].price.amount} ${adapty.products[i].price.currencySymbol}",
                        style: context.styles.regularMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _select(int i) {
    setState(() {
      indexSelected = i;
    });
    widget.callback(
      adapty.products[i],
    );
  }

  String _getTitleAndroid(String androidBasePlanId) {
    switch (androidBasePlanId) {
      case 'pivot-monthly':
        return 'Monthly subscription';
      case 'pivot-annual':
        return 'Annual subscription';

      default:
        return 'Some error?';
    }
  }

  String _getTitleIOs(String vendorId) {
    // print(vendorId);
    switch (vendorId) {
      case 'pivot_sub':
        return 'Monthly subscription';
      case 'pivot_annual':
        return 'Annual subscription';

      default:
        return 'Some error?';
    }
  }
}
