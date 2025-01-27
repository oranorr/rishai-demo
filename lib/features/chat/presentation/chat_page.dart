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
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_state.dart';

part './widgets/auto_prompts.dart';
part './widgets/chat_widget.dart';
part './widgets/header.dart';
part './widgets/input_send.dart';
part './widgets/message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.controller,
    super.key,
  });
  final PageController controller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TextEditingController controller;
  bool sendActive = false;

  @override
  void initState() {
    controller = TextEditingController()
      ..addListener(() {
        setState(() {
          sendActive =
              controller.text.isNotEmpty && chatBloc.state.mealPlan != null;
        });
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        const _Header(),
        const _ChatWidget(),
        _AutoPrompts(
          controller: widget.controller,
          isThereText: controller.text.isNotEmpty,
        ),
        _InputAndSend(
          textEditingController: controller,
          sendActive: sendActive,
        ),
      ],
    );
  }
}
