part of '../login_screen.dart';

class _LowerPart extends StatelessWidget {
  const _LowerPart({
    required this.isFromCreate,
    required this.buttonAction,
    required this.tabController,
  });
  final bool isFromCreate;
  final VoidCallback buttonAction;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text:
                'By ${isFromCreate ? 'signing up' : 'logging in'}, you agree to our ',
            style: context.styles.regularMedium
                .copyWith(color: RishColors.textSecondary),
            children: [
              TextSpan(
                text: 'Terms of Service ',
                style: context.styles.boldMedium
                    .copyWith(color: RishColors.textSecondary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async => launchUrl(
                        Uri.parse(
                          'https://thepivotapp.ai/terms-of-service',
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
                style: context.styles.boldMedium
                    .copyWith(color: RishColors.textSecondary),
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
        SizedBox(
          height: 24.h,
        ),
        BlocBuilder<WhoopBloc, WhoopState>(
          bloc: whoopBloc,
          builder: (context, whoopState) {
            return BlocBuilder<LoginBloc, LoginState>(
              bloc: loginBloc,
              builder: (context, state) {
                return RishButton.primary(
                  title: isFromCreate ? 'Create account' : 'Login',
                  action: buttonAction,
                  enabled: true,
                  isLoading: state.status == Status.loading ||
                      whoopState.status == Status.loading,
                );
              },
            );
          },
        ),
        SizedBox(
          height: 20.h,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 52.w),
          child: Row(
            children: [
              const Expanded(
                child: Divider(
                  thickness: 1,
                  color: RishColors.stroke,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'or Sign in with',
                  style: context.styles.regularMedium
                      .copyWith(color: RishColors.textSecondary),
                ),
              ),
              const Expanded(
                child: Divider(
                  thickness: 1,
                  color: RishColors.stroke,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24.h,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < (Platform.isAndroid ? 1 : 2); i++)
              Padding(
                padding: EdgeInsets.only(right: 8.w, left: 8.w),
                child: GestureDetector(
                  onTap: i == 0
                      ? () {
                          loginBloc.add(const LoginViaGoogle());
                        }
                      : () {
                          if (Platform.isIOS) {
                            loginBloc.add(LoginViaApple());
                          }
                        },
                  child: Container(
                    height: 48.h,
                    width: 72.w,
                    decoration: BoxDecoration(
                      color: RishColors.formBackgroun,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset(
                      i == 0 ? 'assets/google.svg' : 'assets/apple.svg',
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
