import 'package:flutter/material.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';

import 'package:rishai/features/settings/presentation/settings_pages/other.dart';

class LegalPage extends StatelessWidget {
  final OtherEntity entity;
  const LegalPage({
    super.key,
    required this.entity,
  });

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: true,
        title: Text(
          entity.title,
          style: context.styles.h3,
        ),
      ),
      child: ListView(
        children: [
          Text(
            entity.body,
            style: context.styles.regularMedium,
          )
        ],
      ),
    );
  }
}
