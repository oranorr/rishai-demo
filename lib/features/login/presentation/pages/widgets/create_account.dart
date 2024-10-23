part of '../login_screen.dart';

class CreateAccountPage extends StatelessWidget {
  final GlobalKey<FormState> _formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;

  final TabController tabController;
  final VoidCallback buttonAction;

  const CreateAccountPage({
    super.key,
    required GlobalKey<FormState> formKey,
    required this.nameController,
    required this.emailController,
    required this.tabController,
    required this.buttonAction,
  }) : _formKey = formKey;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverToBoxAdapter(
          child: Text(
            'Create account',
            style: context.styles.h1,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 4.h,
          ),
        ),
        SliverToBoxAdapter(
          child: Text(
            'Please enter your details ',
            style: context.styles.regularLarge
                .copyWith(color: const Color(0xffA3A3A3)),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 15,
          ),
        ),
        SliverToBoxAdapter(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RishTextField(
                    controller: nameController,
                    state: RishTextInputState.enabled,
                    needsCounter: false,
                    maxLines: 1,
                    maxLength: 20,
                    keyboardType: TextInputType.name,
                    onChanged: (t) {},
                    labelText: 'Name',
                    hintText: '-',
                    validator: _validateName),
                // SizedBox(
                //   height: 20.h,
                // ),
                RishTextField(
                  controller: emailController,
                  state: RishTextInputState.enabled,
                  needsCounter: false,
                  maxLines: 1,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (t) {},
                  labelText: 'Email',
                  hintText: '-',
                  validator: _emailValidator,
                ),
                // SizedBox(
                //   height: 16.h,
                // ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _LowerPart(
            isFromCreate: true,
            buttonAction: buttonAction,
            tabController: tabController,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: context.styles.regularMedium.copyWith(
                  color: RishColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: context.styles.boldLarge.copyWith(
                      color: context.theme.colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => tabController.animateTo(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    //     ],
    //   ),
    // );
  }
}
