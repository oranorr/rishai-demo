part of '../login_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    required this.tabController,
    required this.buttonAction,
    required this.emailController,
    required this.formKey,
    super.key,
  });
  final TabController tabController;
  final VoidCallback buttonAction;
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Text(
            'Sign in',
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
            'Please enter your email to receive a One Time Password (OTP)',
            style: context.styles.regularLarge
                .copyWith(color: const Color(0xffA3A3A3)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 16.h,
          ),
        ),
        SliverToBoxAdapter(
          child: Form(
            key: formKey,
            child: RishTextField(
              controller: emailController,
              state: RishTextInputState.enabled,
              needsCounter: false,
              keyboardType: TextInputType.emailAddress,
              onChanged: (t) {},
              labelText: 'Email',
              hintText: 'Enter registred email',
              validator: _emailValidator,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _LowerPart(
            isFromCreate: false,
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
                text: "Don't have one? ",
                style: context.styles.regularLarge.copyWith(
                  color: RishColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: 'Create account',
                    style: context.styles.boldLarge.copyWith(
                      color: context.theme.colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => tabController.animateTo(0),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 16.h,
          ),
        ),
      ],
    );
  }
}
