import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/settings/presentation/settings_pages/other.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({
    required this.entity,
    super.key,
  });
  final OtherEntity entity;

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          entity.title,
          style: context.styles.h3,
        ),
      ),
      child: ListView(
        children: [
          if (entity.type == OtherType.ref)
            RichText(
              text: TextSpan(
                children: _buildTextWithLinks(entity.body),
                style: context.styles.regularMedium,
              ),
            )
          else
            Text(
              entity.body,
              style: context.styles.regularMedium,
            ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTextWithLinks(String text) {
    final RegExp linkRegExp = RegExp(
      r'https?:\/\/[a-zA-Z0-9\-._~:/?#@!$&()*+,;=%]+',
    );

    final List<TextSpan> spans = [];
    final matches = linkRegExp.allMatches(text);
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
          ),
        );
      }

      final String link = match.group(0)!;
      spans.add(
        TextSpan(
          text: link,
          style: const TextStyle(
            color: RishColors.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri url = Uri.parse(link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                throw Exception('Could not launch $link');
              }
            },
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
        ),
      );
    }

    return spans;
  }
}
