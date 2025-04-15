import 'package:flutter/material.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a non-dismissible dialog requiring the user to update the app.
Future<void> showUpdateDialog(BuildContext context, String storeUrl) async {
  final styles = context.styles;

  await showDialog<void>(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (BuildContext dialogContext) {
      return WillPopScope(
        onWillPop: () async => false, // Prevents closing with the back button
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Update Available', // Translated
            style: styles.h3,
            textAlign: TextAlign.center,
          ),
          content: Text(
            "We've added new features and fixed bugs. Please update the app to the latest version to continue.", // Translated
            style: styles.regularMedium,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding:
              const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          actions: <Widget>[
            RishButton.primary(
              title: 'Update', // Translated
              enabled: true,
              isLoading: false,
              action: () async {
                final Uri url = Uri.parse(storeUrl);
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print('Could not launch $storeUrl');
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          // Removed const
                          content: Text(
                            'Could not open the app store.',
                          ), // Translated
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print('Error launching URL: $e');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        // Removed const
                        content: Text(
                          'An error occurred while opening the store.',
                        ), // Translated
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Simple screen that shows the update dialog on build.
class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({required this.storeUrl, super.key});
  final String storeUrl;

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _dialogShown = false; // Flag to show the dialog only once

  @override
  void initState() {
    super.initState();
    // Removing the call from here
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     showUpdateDialog(context, widget.storeUrl);
    //   }
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call the dialog here, after dependencies (including theme) are set
    if (!_dialogShown) {
      // Use Future.delayed to ensure execution after the build cycle
      Future.delayed(Duration.zero, () {
        if (mounted) {
          showUpdateDialog(context, widget.storeUrl);
          setState(() {
            _dialogShown = true; // Mark that the dialog has been shown
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show an indicator while the dialog is not shown
    return Scaffold(
      body: Center(
        child: _dialogShown ? Container() : const CircularProgressIndicator(),
      ),
    );
  }
}
