// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rishai/core/router/app_navigation_service.dart' as _i453;
import 'package:rishai/core/router/navigator_key_provider.dart' as _i572;
import 'package:rishai/core/services/accounts_whitelist/accounts_whitelist_service.dart'
    as _i751;
import 'package:rishai/core/services/accounts_whitelist/accounts_whitelist_service_impl.dart'
    as _i748;
import 'package:rishai/core/services/adapty_service/adapty_repository.dart'
    as _i1067;
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart'
    as _i910;
import 'package:rishai/core/services/analytics/analytics_repository.dart'
    as _i149;
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart'
    as _i624;
import 'package:rishai/core/services/day_manager/day_manager.dart' as _i300;
import 'package:rishai/core/services/day_manager/day_manager_impl.dart'
    as _i629;
import 'package:rishai/core/services/directus/directus_repository.dart' as _i89;
import 'package:rishai/core/services/directus/directus_repository_impl.dart'
    as _i523;
import 'package:rishai/core/services/firebase/firebase_impl.dart' as _i201;
import 'package:rishai/core/services/firebase/firebase_repo.dart' as _i993;
import 'package:rishai/core/services/hive/hive_impl.dart' as _i410;
import 'package:rishai/core/services/notifications/notifications_service.dart'
    as _i492;
import 'package:rishai/core/services/notifications/notifications_service_impl.dart'
    as _i724;
import 'package:rishai/core/services/pefs/prefs_repository.dart' as _i97;
import 'package:rishai/core/services/version_check/version_check_service.dart'
    as _i570;
import 'package:rishai/core/services/version_check/version_check_service_impl.dart'
    as _i634;
import 'package:rishai/core/services/whoop_token_service.dart/token_service.dart'
    as _i820;
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart'
    as _i597;
import 'package:rishai/features/chat/data/chat_repository_impl.dart' as _i246;
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart'
    as _i947;
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart'
    as _i867;
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source_impl.dart'
    as _i467;
import 'package:rishai/features/chat/domain/repository/chat_repository.dart'
    as _i831;
import 'package:rishai/features/chat/domain/usecases/fetch_saved_snap_usecase.dart'
    as _i975;
import 'package:rishai/features/chat/domain/usecases/generate_week_plan_usecase.dart'
    as _i1015;
import 'package:rishai/features/chat/domain/usecases/init_gpt_usecase.dart'
    as _i241;
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart'
    as _i208;
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart'
    as _i799;
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart'
    as _i176;
import 'package:rishai/features/chat/domain/usecases/send_message_gpt_usecase.dart'
    as _i786;
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart' as _i666;
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart'
    as _i672;
import 'package:rishai/features/login/data/dara_sources/remote/remote_data_source.dart'
    as _i510;
import 'package:rishai/features/login/data/dara_sources/remote/remote_data_source_impl.dart'
    as _i675;
import 'package:rishai/features/login/data/repositories/login_repository_impl.dart'
    as _i1025;
import 'package:rishai/features/login/domain/repositories/login_repository.dart'
    as _i544;
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart'
    as _i734;
import 'package:rishai/features/login/domain/usecases/login_via_apple_usecase.dart'
    as _i914;
import 'package:rishai/features/login/domain/usecases/login_via_email_usecase.dart'
    as _i248;
import 'package:rishai/features/login/domain/usecases/login_via_google_usecase.dart'
    as _i1003;
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart'
    as _i1024;
import 'package:rishai/features/settings/domain/repository/feedback_repository.dart'
    as _i768;
import 'package:rishai/features/settings/domain/repository/feedback_repository_impl.dart'
    as _i534;
import 'package:rishai/features/settings/domain/usecase/send_feedback_usecase.dart'
    as _i242;
import 'package:rishai/features/user/data/data_sources/local/user_local_impl.dart'
    as _i461;
import 'package:rishai/features/user/data/data_sources/local/user_local_source.dart'
    as _i886;
import 'package:rishai/features/user/data/data_sources/remote/user_remote_impl.dart'
    as _i526;
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart'
    as _i948;
import 'package:rishai/features/user/data/repositories/user_repository_impl.dart'
    as _i670;
import 'package:rishai/features/user/domain/repositories/user_repository.dart'
    as _i926;
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart'
    as _i547;
import 'package:rishai/features/user/domain/usecases/update_user_usecase.dart'
    as _i663;
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart' as _i984;
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart'
    as _i1018;
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart'
    as _i734;
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source_impl.dart'
    as _i335;
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart'
    as _i675;
import 'package:rishai/features/whoop/data/repository/whoop_repository_impl.dart'
    as _i907;
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart'
    as _i897;
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart'
    as _i1055;
import 'package:rishai/features/whoop/domain/usecases/connect_whoop_usecase.dart'
    as _i513;
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart'
    as _i62;
import 'package:rishai/features/whoop/domain/usecases/get_body_data_usecase.dart'
    as _i1035;
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart'
    as _i757;
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart'
    as _i1051;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i572.NavigatorKeyProvider>(() => _i572.NavigatorKeyProvider());
    gh.factory<_i672.FoodDiaryCubit>(() => _i672.FoodDiaryCubit());
    gh.factory<_i947.LlmProxyClient>(() => _i947.LlmProxyClient());
    gh.singleton<_i97.PrefsRepository>(() => _i97.PrefsRepository());
    gh.singleton<_i149.AnalyticsRepository>(
        () => _i624.AnalyticsRepositoryImpl());
    gh.singleton<_i300.DayManager>(() => _i629.DayManagerImpl());
    gh.singleton<_i410.HiveRepo>(() => _i410.HiveImpl());
    gh.singleton<_i768.FeedbackRepository>(
        () => _i534.FeedbackRepositoryImpl());
    gh.singleton<_i993.FirebaseRepository>(
        () => _i201.FirebaseImplementation());
    gh.singleton<_i89.DirectusService>(() => _i523.DirectusRepositoryImpl());
    gh.singleton<_i734.WhoopLocalDataSource>(
        () => _i335.WhoopLocalDataSourceImpl());
    gh.singleton<_i820.WhoopTokenService>(() => _i597.WhoopTokenServiceImpl());
    gh.singleton<_i510.LoginRemoteDataSource>(
        () => _i675.RemoteDataSourceImpl());
    gh.singleton<_i751.AccountsWhiteListService>(
        () => _i748.AccountsWhiteListServiceImpl(gh<_i89.DirectusService>()));
    gh.singleton<_i1067.AdaptyRepository>(() => _i910.AdaptyRepositoryImpl());
    gh.singleton<_i675.WhoopRemoteDataSource>(
        () => _i675.WhoopRemoteDataSourceImpl());
    gh.singleton<_i886.UserLocalDataSource>(() => _i461.UserLocalDataImpl());
    gh.singleton<_i948.UserRemoteSource>(() => _i526.UserRemoteImpl());
    gh.lazySingleton<_i453.AppNavigationService>(
        () => _i453.AppNavigationService(gh<_i572.NavigatorKeyProvider>()));
    gh.factory<_i242.SendFeedbackUseCase>(
        () => _i242.SendFeedbackUseCase(gh<_i768.FeedbackRepository>()));
    gh.singleton<_i492.NotificationsService>(
        () => _i724.NotificationsServiceImpl());
    gh.singleton<_i897.WhoopRepository>(() => _i907.WhoopRepositoryImpl(
          remoteDataSource: gh<_i675.WhoopRemoteDataSource>(),
          localDataSource: gh<_i734.WhoopLocalDataSource>(),
        ));
    gh.singleton<_i926.UserRepository>(() => _i670.UserRepositoryImpl(
          remoteDataSource: gh<_i948.UserRemoteSource>(),
          localDataSource: gh<_i886.UserLocalDataSource>(),
          dayManager: gh<_i300.DayManager>(),
        ));
    gh.factory<_i663.UpdateUserUsecase>(
        () => _i663.UpdateUserUsecase(gh<_i926.UserRepository>()));
    gh.factory<_i547.GetUserDaysUsecase>(
        () => _i547.GetUserDaysUsecase(gh<_i926.UserRepository>()));
    gh.singleton<_i867.ChatRemoteDataSource>(
        () => _i467.ChatRemoteDataSourceImpl(gh<_i947.LlmProxyClient>()));
    gh.singleton<_i570.VersionCheckService>(
        () => _i634.VersionCheckServiceImpl(gh<_i89.DirectusService>()));
    gh.singleton<_i544.LoginRepository>(
        () => _i1025.LoginRepositoryImpl(gh<_i510.LoginRemoteDataSource>()));
    gh.factory<_i1003.LoginViaGoogleUsecase>(
        () => _i1003.LoginViaGoogleUsecase(gh<_i544.LoginRepository>()));
    gh.factory<_i734.CreateNewUserUsecase>(
        () => _i734.CreateNewUserUsecase(gh<_i544.LoginRepository>()));
    gh.factory<_i248.LoginViaEmailUsecase>(
        () => _i248.LoginViaEmailUsecase(gh<_i544.LoginRepository>()));
    gh.factory<_i914.LoginViaAppleUsecase>(
        () => _i914.LoginViaAppleUsecase(gh<_i544.LoginRepository>()));
    gh.factory<_i1035.WhoopGetBodyData>(
        () => _i1035.WhoopGetBodyData(gh<_i897.WhoopRepository>()));
    gh.factory<_i1055.ChangeModificatorOrSexUsecase>(() =>
        _i1055.ChangeModificatorOrSexUsecase(gh<_i897.WhoopRepository>()));
    gh.factory<_i757.WhoopGetDataUsecase>(
        () => _i757.WhoopGetDataUsecase(gh<_i897.WhoopRepository>()));
    gh.factory<_i62.DisconnectWhoopUsecase>(
        () => _i62.DisconnectWhoopUsecase(gh<_i897.WhoopRepository>()));
    gh.factory<_i513.ConnectWhoopUsecase>(
        () => _i513.ConnectWhoopUsecase(gh<_i897.WhoopRepository>()));
    gh.factory<_i1051.WhoopBloc>(() => _i1051.WhoopBloc(
          gh<_i513.ConnectWhoopUsecase>(),
          gh<_i757.WhoopGetDataUsecase>(),
          gh<_i1035.WhoopGetBodyData>(),
          gh<_i1055.ChangeModificatorOrSexUsecase>(),
          gh<_i62.DisconnectWhoopUsecase>(),
        ));
    gh.singleton<_i831.ChatRepository>(() => _i246.ChatRepositoryImpl(
          hive: gh<_i410.HiveRepo>(),
          remote: gh<_i867.ChatRemoteDataSource>(),
          userRepo: gh<_i926.UserRepository>(),
        ));
    gh.factory<_i984.UserBloc>(() => _i984.UserBloc(
          gh<_i663.UpdateUserUsecase>(),
          gh<_i547.GetUserDaysUsecase>(),
          gh<_i751.AccountsWhiteListService>(),
        ));
    gh.factory<_i1024.LoginBloc>(() => _i1024.LoginBloc(
          gh<_i1003.LoginViaGoogleUsecase>(),
          gh<_i734.CreateNewUserUsecase>(),
          gh<_i248.LoginViaEmailUsecase>(),
          gh<_i914.LoginViaAppleUsecase>(),
          gh<_i751.AccountsWhiteListService>(),
        ));
    gh.factory<_i241.InitGptUsecase>(
        () => _i241.InitGptUsecase(gh<_i831.ChatRepository>()));
    gh.factory<_i786.SendMessageGptUsecase>(
        () => _i786.SendMessageGptUsecase(gh<_i831.ChatRepository>()));
    gh.factory<_i799.ReplaceMealUsecase>(
        () => _i799.ReplaceMealUsecase(gh<_i831.ChatRepository>()));
    gh.factory<_i799.ReplaceMealUsecaseV2>(
        () => _i799.ReplaceMealUsecaseV2(gh<_i831.ChatRepository>()));
    gh.factory<_i975.FetchSavedSnapUsecase>(
        () => _i975.FetchSavedSnapUsecase(gh<_i831.ChatRepository>()));
    gh.factory<_i176.RequestPlanUsecaseV2>(
        () => _i176.RequestPlanUsecaseV2(gh<_i831.ChatRepository>()));
    gh.factory<_i208.ReplaceIngredientUsecase>(
        () => _i208.ReplaceIngredientUsecase(gh<_i831.ChatRepository>()));
    gh.factory<_i208.ReplaceIngredientUsecaseV2>(
        () => _i208.ReplaceIngredientUsecaseV2(gh<_i831.ChatRepository>()));
    gh.factory<_i666.ChatBloc>(() => _i666.ChatBloc(
          gh<_i241.InitGptUsecase>(),
          gh<_i176.RequestPlanUsecaseV2>(),
          gh<_i786.SendMessageGptUsecase>(),
          gh<_i975.FetchSavedSnapUsecase>(),
          gh<_i799.ReplaceMealUsecase>(),
          gh<_i208.ReplaceIngredientUsecase>(),
          gh<_i799.ReplaceMealUsecaseV2>(),
          gh<_i208.ReplaceIngredientUsecaseV2>(),
        ));
    gh.factory<_i1015.GenerateWeekPlanUsecaseV2>(
        () => _i1015.GenerateWeekPlanUsecaseV2(
              gh<_i831.ChatRepository>(),
              gh<_i176.RequestPlanUsecaseV2>(),
            ));
    gh.factory<_i1018.WeekPlanBloc>(
        () => _i1018.WeekPlanBloc(gh<_i1015.GenerateWeekPlanUsecaseV2>()));
    return this;
  }
}
