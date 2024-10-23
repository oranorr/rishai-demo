// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/page_controller_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_state.dart';

part './mixins/auto_prompts_mixin.dart';
part './widgets/auto_prompts.dart';
part './widgets/chat_widget.dart';
part './widgets/header.dart';
part './widgets/input_send.dart';
part './widgets/message.dart';

class ChatPage extends StatefulWidget {
  final PageController controller;
  const ChatPage({
    super.key,
    required this.controller,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        const _Header(),
        const _ChatWidget(),
        _AutoPrompts(
          controller: widget.controller,
        ),
        const _InputAndSend(),
      ],
    );
  }
}
