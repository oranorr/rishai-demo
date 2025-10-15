import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart'
    show adapty;
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/data/chat_repository_impl.dart'
    as chat_repo;
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source_impl.dart'
    as chat_remote;
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart'
    show whoopRemote;
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/connect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_body_data_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';
part 'whoop_event.dart';

final whoopBloc = getIt.get<WhoopBloc>();
final chatRemoteSrc = chat_remote.chatRemoteSrc;
final chatRepo = chat_repo.chatRepo;

@injectable
class WhoopBloc extends Bloc<WhoopEvent, WhoopState> {
  WhoopBloc(
    this.connectWhoopUsecase,
    this.getDataUsecase,
    this.getBodyUsecase,
    this.changeModificatorOrSexUsecase,
    this.disconnectWhoopUsecase,
  ) : super(
          WhoopMainState(
            status: Status.initial,
            day: DayEntity.empty(requestsLeft: chatBloc.state.requestsLeft),
            whoopConnected: false,
          ),
        ) {
    on<WhoopConnectEvent>(_connectWhoop);
    on<WhoopGetUserData>(_getUserData);
    on<InitWhoopOnLogin>(_initWhoopOnLogin);
    on<WhoopUserCalibrating>(_userCalibrating);
    on<WhoopRetrieveBodyData>(_getBodyData);
    on<WhoopChangeModificatorOrSex>(_changeModificatorOrSex);
    on<WhoopCheckDietChange>(_checkDietChange);
    on<WhoopUpdateDayByMealPlan>(_updateDayByMealPlan);
    on<WhoopDisconnect>(_disconnect);
    on<WhoopCheckForRefresh>(_checkForRefresh);
    on<WhoopUpdateCurrentDay>(_updateCurrentDay);
  }
  final ConnectWhoopUsecase connectWhoopUsecase;
  final WhoopGetDataUsecase getDataUsecase;
  final WhoopGetBodyData getBodyUsecase;
  final ChangeModificatorOrSexUsecase changeModificatorOrSexUsecase;
  final DisconnectWhoopUsecase disconnectWhoopUsecase;

  FutureOr<void> _connectWhoop(
    WhoopConnectEvent event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    if (!await prefsRepo.checkForWhoopDisclaimerAccpeted()) {
      await RishiDialog.whoopDisclaimer(event.context);
      return;
    }
    final res = await connectWhoopUsecase.call(const NoParams());
    bool success = false;
    final needsQuestionary = userBloc.state.user.needsQuestionary;

    await res.fold((fail) {
      RishSnackbar().showSnackBar(fail.message);
      emit(state.copyWith(status: Status.error));
    }, (_) async {
      success = true;
    });

    if (success) {
      // [FIX] Убираем race condition - _getBodyData вызывается только один раз
      // Если пользователь нуждается в опроснике, данные будут загружены после его завершения
      if (!needsQuestionary) {
        await _initWhoopOnLogin(const InitWhoopOnLogin(), emit);
      } else {
        // Для пользователей с опросником загружаем только body данные
        await _getBodyData(WhoopRetrieveBodyData(), emit);
      }
      await Future.delayed(Durations.medium1, () {
        appNavigationService.go(
          path: needsQuestionary
              ? AppRoutes.questionary.path
              : adapty.isActive
                  ? AppRoutes.homeScreen.path
                  : AppRoutes.paywall.path,
        );
        emit(state.copyWith(status: Status.initial));
      });
    }
  }

  FutureOr<void> _getUserData(
    WhoopGetUserData event,
    Emitter<WhoopState> emit,
  ) async {
    if (!event.isInitializing) {
      emit(state.copyWith(status: Status.loading));
    }

    try {
      final result = await getDataUsecase.call(
        GetDataParams(
          gender: event.gender,
          goal: event.goal,
          userId: userBloc.state.user.directusId,
        ),
      );

      await result.fold(
        (failure) async {
          log('Failed to get user data: ${failure.message}', name: 'WhoopBloc');
          emit(state.copyWith(status: Status.error));

          if (failure is WhoopFailedToReturnAccessToken) {
            final shouldReconnect =
                await wTokenService.shouldAttemptReconnect();
            if (shouldReconnect) {
              log('WHOOP connection needs to be refreshed');
              RishSnackbar().showSnackBar(
                'WHOOP connection needs to be refreshed. Please reconnect.',
              );
              appNavigationService.go(path: AppRoutes.whoopConnect.path);
              return;
            }
          }

          if (!event.isInitializing) {
            RishSnackbar().showSnackBar(
              'Failed to get WHOOP data: ${failure.message}. Please try reconnecting.',
            );
          }
        },
        (day) {
          emit(
            state.copyWith(
              status: Status.success,
              day: day,
              whoopConnected: true,
            ),
          );
        },
      );
    } on Exception catch (e) {
      log('Error getting user data: $e', name: 'WhoopBloc');
      emit(state.copyWith(status: Status.error));

      if (!event.isInitializing) {
        RishSnackbar().showSnackBar(
          'Failed to get WHOOP data. Please check your internet connection and try again.',
        );
      }
    }
  }

  FutureOr<void> _initWhoopOnLogin(
    InitWhoopOnLogin event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      emit(state.copyWith(status: Status.loading));
      UserEntity user = userBloc.state.user;
      final isTokenOk = await wTokenService.initService();
      await adapty.initAdapty();
      emit(state.copyWith(whoopConnected: isTokenOk));
      log('INIT TOKEN SERVICE RES: $isTokenOk');

      if (!isTokenOk) {
        // Проверяем, стоит ли пытаться переподключиться
        final shouldReconnect = await wTokenService.shouldAttemptReconnect();
        if (shouldReconnect) {
          log('Attempting to reconnect to WHOOP');
          // Очищаем старые данные перед переподключением
          await wTokenService.diconnect(user.directusId);
          // Перенаправляем на экран подключения вместо автоматической попытки
          RishSnackbar().showSnackBar(
            'WHOOP connection needs to be refreshed. Please reconnect.',
          );
          emit(state.copyWith(status: Status.initial));
          appNavigationService.go(path: AppRoutes.whoopConnect.path);
          return;
        }

        RishSnackbar().showSnackBar(
          'Unable to connect to WHOOP. Please reconnect your account.',
        );
        emit(state.copyWith(status: Status.initial));
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
        return;
      }

      log('retrieveing BODY data');
      await _getBodyData(WhoopRetrieveBodyData(), emit);

      if (!user.needsQuestionary) {
        log('retrieveing data');
        appNavigationService.go(path: AppRoutes.redirect.path);

        await _getUserData(
          WhoopGetUserData(
            user.gender!,
            user.userGoal!,
            isInitializing: true,
          ),
          emit,
        );

        if (state.status != Status.loading && state.status != Status.error) {
          chatBloc.add(InitChatBloc(directusId: user.directusId));

          // Используем централизованную логику инициализации дней из DayManager
          log(
            'Инициализация загрузки дней через DayManager',
            name: 'WhoopBloc',
          );
          final initResult = await dayManager.initializeUserDaysOnLogin(
            userId: user.directusId,
            newDay: state.day,
          );

          // Обработка результата инициализации
          if (!initResult.success) {
            // Показываем сообщение об ошибке только если загрузка полностью провалилась
            RishSnackbar().showSnackBar(
              initResult.errorMessage ?? 'Failed to load user data',
            );
            emit(state.copyWith(status: Status.error));
            return;
          } else if (initResult.partialSuccess) {
            // Частичная загрузка - не показываем ошибку
            log(
              'Частичная загрузка: ${initResult.daysLoaded} дней',
              name: 'WhoopBloc',
            );
          } else {
            log(
              'Все дни загружены успешно: ${initResult.daysLoaded} дней',
              name: 'WhoopBloc',
            );
          }

          // Дополнительная проверка состояния UserBloc перед навигацией
          log(
            'Проверка состояния UserBloc перед навигацией',
            name: 'WhoopBloc',
          );

          // [FIX] Поддерживаем состояние загрузки во время ожидания дней
          emit(state.copyWith(status: Status.loading));

          // Ждем, пока UserBloc завершит загрузку или достигнет стабильного состояния
          const maxWaitTime = Duration(seconds: 10);
          final waitStartTime = DateTime.now();

          while (DateTime.now().difference(waitStartTime) < maxWaitTime) {
            final userState = userBloc.state;

            // Проверяем, что UserBloc находится в стабильном состоянии
            if (userState.status == Status.success &&
                userState.days.isNotEmpty) {
              log(
                'UserBloc готов к навигации: ${userState.days.length} дней загружено',
                name: 'WhoopBloc',
              );
              break;
            } else if (userState.status == Status.error) {
              log('UserBloc завершился с ошибкой', name: 'WhoopBloc');
              break;
            }

            // Ждем небольшую задержку перед следующей проверкой
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // Финальная проверка состояния перед навигацией
          final finalUserState = userBloc.state;
          if (finalUserState.status == Status.loading) {
            log(
              'UserBloc все еще загружается, но продолжаем навигацию с предупреждением',
              name: 'WhoopBloc',
            );
            RishSnackbar().showSnackBar(
              'Данные все еще загружаются. Это может занять некоторое время.',
              isError: false,
            );
          } else if (finalUserState.days.isEmpty) {
            log(
              'UserBloc не содержит дней, показываем предупреждение',
              name: 'WhoopBloc',
            );
            RishSnackbar().showSnackBar(
              'Не удалось загрузить некоторые данные. Попробуйте обновить позже.',
              isError: false,
            );
          }

          // Переходим на домашний экран после завершения инициализации
          log('Навигация на главный экран', name: 'WhoopBloc');
          appNavigationService.go(
            path: adapty.isActive
                ? AppRoutes.homeScreen.path
                : AppRoutes.paywall.path,
          );
          emit(state.copyWith(status: Status.success));
          return;
        }
      } else {
        appNavigationService.go(path: AppRoutes.questionary.path);
        emit(state.copyWith(status: Status.initial));
        return;
      }
    } on Exception catch (e) {
      log('Error during WHOOP initialization: $e');
      RishSnackbar().showSnackBar(
        'Unable to connect to WHOOP. Please try again later.',
      );
      emit(state.copyWith(status: Status.initial));
    }
  }

  Future<void> _userCalibrating(
    WhoopUserCalibrating event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.initial));
    final remaining = await prefsRepo.calibratingDate();
    await Future.delayed(Durations.short1);
    emit(state.copyWith(calibratingCompleteDate: remaining));

    if (event.needsRedirect! && remaining != null) {
      appNavigationService.go(path: AppRoutes.calibratingScreen.path);
    } else {
      log('Calibrating done.');
    }
  }

  FutureOr<void> _getBodyData(
    WhoopRetrieveBodyData event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final bodyRes = await getBodyUsecase.call(const NoParams());

    await bodyRes.fold((l) async {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(
        'Failed to retrieve body data: ${l.message}, retrying...',
      );
      add(WhoopRetrieveBodyData());
    }, (r) async {
      UserEntity user = userBloc.state.user;
      final upd = user.copyWith(bodyMeasurements: r);
      emit(
        state.copyWith(
          status: Status.success,
        ),
      );
      userBloc.add(UpdateUserEvent(user: upd));
    });
  }

  FutureOr<void> _changeModificatorOrSex(
    WhoopChangeModificatorOrSex event,
    Emitter<WhoopState> emit,
  ) async {
    final user = userBloc.state.user;
    bool success = false;
    String errorMessage = 'Error happened. Please, try again';

    // Сохраняем текущий план питания
    final currentMealPlan = state.day.mealPlanEntity;

    // Предварительное обновление UI для мгновенной реакции
    // Делаем предварительный расчет макросов на основе новых значений
    final estimatedCalories =
        (1 + event.modificator) * state.day.weekTdeeAverage;
    final estimatedKcal = estimatedCalories.round();

    // Считаем примерное соотношение макросов по текущим
    // Используем пропорции из текущих макросов
    final currentMacros = state.day.macros;
    final currentTotal = currentMacros.kcal > 0
        ? currentMacros.kcal
        : 1; // Защита от деления на ноль

    // Проверяем, что текущие макросы не нулевые
    bool hasValidCurrentMacros = currentMacros.protein > 0 &&
        currentMacros.carbs > 0 &&
        currentMacros.fat > 0;

    // Создаем временные макросы с проверкой на валидность
    int tempProtein = 0;
    int tempCarbs = 0;
    int tempFat = 0;

    if (hasValidCurrentMacros) {
      // Если текущие макросы валидны, используем пропорции
      tempProtein =
          (currentMacros.protein * estimatedKcal / currentTotal).round();
      tempCarbs = (currentMacros.carbs * estimatedKcal / currentTotal).round();
      tempFat = (currentMacros.fat * estimatedKcal / currentTotal).round();
    } else {
      // Если текущие макросы невалидны, используем стандартное распределение
      // Примерно 30% белка, 50% углеводов, 20% жиров
      tempProtein = (0.3 * estimatedKcal / 4).round(); // Белки: 4 ккал/г
      tempCarbs = (0.5 * estimatedKcal / 4).round(); // Углеводы: 4 ккал/г
      tempFat = (0.2 * estimatedKcal / 9).round(); // Жиры: 9 ккал/г
    }

    // Проверка на нулевые значения
    tempProtein = tempProtein > 0 ? tempProtein : 1;
    tempCarbs = tempCarbs > 0 ? tempCarbs : 1;
    tempFat = tempFat > 0 ? tempFat : 1;

    final estimatedMacros = MacrosBreakdown(
      protein: tempProtein,
      carbs: tempCarbs,
      fat: tempFat,
      kcal: estimatedKcal,
    );

    // Обновляем UI с предварительными данными
    final preliminaryDay = state.day.copyWith(
      macros: estimatedMacros,
      mealPlanEntity: currentMealPlan,
    );
    emit(state.copyWith(day: preliminaryDay));

    // Затем запускаем полное обновление через usecase
    final res = await changeModificatorOrSexUsecase.call(
      ChangeModificatorOrSexParams(
        modificator: event.modificator,
        gender: event.gender,
        weekTdeeAverage: state.day.weekTdeeAverage,
        userId: user.directusId,
        lastTdee: state.day.healthMetrics.lastTdee,
        currentDiets: event.currentDiets, // Передаем актуальные диеты из event
      ),
    );

    await res.fold((failure) async {
      if (failure.runtimeType == WhoopDataDueToRefresh) {
        success = false;
        errorMessage = failure.message;
      }
    }, (macros) {
      success = true;

      // Проверяем, что полученные макросы валидны
      bool isValidMacros =
          macros.protein > 0 && macros.carbs > 0 && macros.fat > 0;

      if (isValidMacros) {
        // Обновляем день с точными данными из usecase
        final updatedDay = state.day.copyWith(
          macros: macros,
          mealPlanEntity: currentMealPlan,
        );
        emit(state.copyWith(day: updatedDay));
      } else {
        // Если полученные макросы невалидны, оставляем предварительные данные
        // и логируем проблему
        log(
          'Получены невалидные макросы из usecase: $macros',
          name: 'WhoopBloc',
        );

        // Можно также попробовать исправить невалидные значения
        MacrosBreakdown fixedMacros = macros.copyWith(
          protein:
              macros.protein > 0 ? macros.protein : estimatedMacros.protein,
          carbs: macros.carbs > 0 ? macros.carbs : estimatedMacros.carbs,
          fat: macros.fat > 0 ? macros.fat : estimatedMacros.fat,
        );

        final updatedDay = state.day.copyWith(
          macros: fixedMacros,
          mealPlanEntity: currentMealPlan,
        );
        emit(state.copyWith(day: updatedDay));
      }
    });

    if (!success) {
      await RishiDialog.showCustomDialog(
        event.context,
        isDissmissable: false,
        type: DialogType.info,
        actionDialogType: ActionDialogType.warning,
        text: errorMessage,
        action: () async {
          appNavigationService.go(path: AppRoutes.redirect.path);
        },
      );
    }
  }

  /// Проверяет изменение диеты на кето или карнивор и пересчитывает макросы при необходимости
  FutureOr<void> _checkDietChange(
    WhoopCheckDietChange event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      log('[WhoopBloc] Проверка изменения диеты', name: 'WhoopBloc');
      log(
        '[WhoopBloc] Предыдущие диеты: ${event.previousDiets}',
        name: 'WhoopBloc',
      );
      log('[WhoopBloc] Новые диеты: ${event.newDiets}', name: 'WhoopBloc');

      // Определяем тип предыдущей и текущей диеты
      final previousDietType =
          UserDataEntity.getSpecialDietType(event.previousDiets);
      final currentDietType = UserDataEntity.getSpecialDietType(event.newDiets);

      log(
        '[WhoopBloc] Предыдущий тип диеты: $previousDietType',
        name: 'WhoopBloc',
      );
      log('[WhoopBloc] Текущий тип диеты: $currentDietType', name: 'WhoopBloc');

      // Логика пересчета макросов - НУЖЕН ПЕРЕСЧЕТ если тип диеты изменился
      if (previousDietType == currentDietType) {
        // Тип диеты не изменился - пересчет НЕ нужен
        log(
          '[WhoopBloc] ✅ ТИП ДИЕТЫ НЕ ИЗМЕНИЛСЯ ($currentDietType)',
          name: 'WhoopBloc',
        );
        print(
          '✅ ТИП ДИЕТЫ НЕ ИЗМЕНИЛСЯ ($currentDietType) - пересчет макросов не требуется',
        );
        return;
      }

      // ТИП ДИЕТЫ ИЗМЕНИЛСЯ - делаем пересчет макросов
      log(
        '[WhoopBloc] 🔄 ИЗМЕНЕНИЕ ТИПА ДИЕТЫ: $previousDietType → $currentDietType',
        name: 'WhoopBloc',
      );

      // Логируем конкретный тип изменения
      if (currentDietType != null) {
        if (currentDietType == 'carnivore') {
          log('[WhoopBloc] ✅ ПЕРЕХОД НА CARNIVORE ДИЕТУ', name: 'WhoopBloc');
          print('🥩 ПЕРЕХОД НА CARNIVORE ДИЕТУ');
        } else if (currentDietType == 'keto') {
          log('[WhoopBloc] ✅ ПЕРЕХОД НА KETO ДИЕТУ', name: 'WhoopBloc');
          print('🥑 ПЕРЕХОД НА KETO ДИЕТУ');
        }
      } else {
        final standardDiets = event.newDiets
            .where(
              (diet) =>
                  diet.toLowerCase() != 'keto' &&
                  diet.toLowerCase() != 'carnivore',
            )
            .join(', ');
        log(
          '[WhoopBloc] 🔄 ПЕРЕХОД НА СТАНДАРТНУЮ ДИЕТУ: ${standardDiets.isEmpty ? "omnivore" : standardDiets}',
          name: 'WhoopBloc',
        );
        print(
          '🔄 ПЕРЕХОД НА СТАНДАРТНУЮ ДИЕТУ: ${standardDiets.isEmpty ? "omnivore" : standardDiets}',
        );
      }

      // Пересчитываем макросы для изменения типа диеты
      final needsSpecialAlgorithm = currentDietType != null;
      await _recalculateMacrosForDietChange(needsSpecialAlgorithm, emit);
    } catch (e, stackTrace) {
      log(
        '[WhoopBloc] Ошибка при проверке изменения диеты: $e',
        name: 'WhoopBloc',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Ошибка при проверке изменения диеты: $e');
    }
  }

  /// Пересчитывает макросы при изменении диеты
  Future<void> _recalculateMacrosForDietChange(
    bool useKetoCarnivoreAlgorithm,
    Emitter<WhoopState> emit,
  ) async {
    try {
      log(
        '[WhoopBloc] Начинаем пересчет макросов для диеты',
        name: 'WhoopBloc',
      );
      log(
        '[WhoopBloc] Тип алгоритма: ${useKetoCarnivoreAlgorithm ? "кето/карнивор" : "стандартный"}',
        name: 'WhoopBloc',
      );

      // Получаем текущие данные пользователя из Hive
      final userData = await hive.fetchUserDataEntity(
        userId: userBloc.state.user.directusId,
      );

      if (userData == null) {
        log(
          '[WhoopBloc] UserDataEntity не найден, пропускаем пересчет макросов',
          name: 'WhoopBloc',
        );
        return;
      }

      // Сохраняем старые макросы для сравнения
      final oldMacros = state.day.macros;
      log(
        '[WhoopBloc] Старые макросы: P=${oldMacros.protein}г, C=${oldMacros.carbs}г, F=${oldMacros.fat}г, K=${oldMacros.kcal}ккал',
        name: 'WhoopBloc',
      );

      // Рассчитываем новые макросы в зависимости от типа диеты
      final MacrosBreakdown newMacros;
      if (useKetoCarnivoreAlgorithm) {
        // Определяем конкретный тип специальной диеты
        final currentUser = userBloc.state.user;
        final currentDiets = currentUser.foodPreferences?.diets ?? [];
        final specialDietType = UserDataEntity.getSpecialDietType(currentDiets);

        switch (specialDietType) {
          case 'carnivore':
            log(
              '[WhoopBloc] 🥩 Применяю CARNIVORE алгоритм (1% углеводов, 30-35% белки, 65-70% жиры)',
              name: 'WhoopBloc',
            );
            newMacros = userData.calcMacrosForCarnivore();
            break;
          case 'keto':
            log(
              '[WhoopBloc] 🥑 Применяю KETO алгоритм (5-10% углеводов, 20-25% белки, 65-75% жиры)',
              name: 'WhoopBloc',
            );
            newMacros = userData.calcMacrosForKeto();
            break;
          default:
            // Fallback на keto алгоритм для совместимости
            log(
              '[WhoopBloc] ⚠️ Неопознанная специальная диета, используем KETO fallback алгоритм',
              name: 'WhoopBloc',
            );
            newMacros = userData.calcMacrosForKeto();
        }
      } else {
        log(
          '[WhoopBloc] 🍽️ Применяю СТАНДАРТНЫЙ алгоритм (обычное распределение)',
          name: 'WhoopBloc',
        );
        newMacros = userData.calcMacros();
      }

      log(
        '[WhoopBloc] Новые макросы: P=${newMacros.protein}г, C=${newMacros.carbs}г, F=${newMacros.fat}г, K=${newMacros.kcal}ккал',
        name: 'WhoopBloc',
      );

      // Показываем разницу в макросах
      final proteinDiff = newMacros.protein - oldMacros.protein;
      final carbsDiff = newMacros.carbs - oldMacros.carbs;
      final fatDiff = newMacros.fat - oldMacros.fat;

      log(
        '[WhoopBloc] Изменения: P${proteinDiff >= 0 ? "+" : ""}$proteinDiffг, C${carbsDiff >= 0 ? "+" : ""}$carbsDiffг, F${fatDiff >= 0 ? "+" : ""}$fatDiffг',
        name: 'WhoopBloc',
      );

      // Обновляем день с новыми макросами, сохраняя план питания
      final updatedDay = state.day.copyWith(
        macros: newMacros,
        // Сохраняем существующий план питания (согласно требованиям UX)
        mealPlanEntity: state.day.mealPlanEntity,
      );

      // Обновляем состояние
      emit(state.copyWith(day: updatedDay));

      // Сохраняем изменения - используем правильную логику обновления
      if (updatedDay.directusId > 0) {
        // День уже существует в Directus - обновляем напрямую
        log(
          '[WhoopBloc] 🔄 Обновляем существующий день с directusId: ${updatedDay.directusId}',
          name: 'WhoopBloc',
        );
        final raw = await directus.updateOne(
          collection: daysCollection,
          itemId: updatedDay.directusId.toString(),
          updateData:
              updatedDay.toDirectus(userId: userBloc.state.user.directusId),
        );
        final updatedFromDirectus = DayEntity.fromMap(raw);
        await hive.saveDay(data: updatedFromDirectus);
        log(
          '[WhoopBloc] ✅ День успешно обновлен в Directus без дублирования',
          name: 'WhoopBloc',
        );
      } else {
        // День не существует - создаем новый через dayManager
        log(
          '[WhoopBloc] ➕ Создаем новый день через dayManager',
          name: 'WhoopBloc',
        );
        await dayManager.createOrUpdateDay(day: updatedDay);
      }

      log(
        '[WhoopBloc] ✅ Макросы успешно пересчитаны и сохранены',
        name: 'WhoopBloc',
      );

      // Не показываем снек бар успеха при смене диеты
    } catch (e, stackTrace) {
      log(
        '[WhoopBloc] ❌ Ошибка при пересчете макросов: $e',
        name: 'WhoopBloc',
        error: e,
        stackTrace: stackTrace,
      );

      RishSnackbar().showSnackBar(
        'Error recalculating macros. Please try again.',
      );
    }
  }

  (double proteinPer, double carbsPer, double fatsPer) calculatePercentage() {
    int proteinKcal = state.day.macros.protein * 4;
    int carbsKcal = state.day.macros.carbs * 4;
    int fatsKcal = state.day.macros.fat * 9;

    final totalKcal = state.day.macros.kcal;

    double proteinPerc = (proteinKcal / totalKcal) * 100;
    double carbsPerc = (carbsKcal / totalKcal) * 100;
    double fatsPerc = (fatsKcal / totalKcal) * 100;

    int proteinRounded = proteinPerc.round();
    int carbsRounded = carbsPerc.round();
    int fatsRounded = fatsPerc.round();

    int totalRounded = proteinRounded + carbsRounded + fatsRounded;
    if (totalRounded != 100) {
      int difference = 100 - totalRounded;

      if (proteinRounded >= carbsRounded && proteinRounded >= fatsRounded) {
        proteinRounded += difference;
      } else if (carbsRounded >= proteinRounded &&
          carbsRounded >= fatsRounded) {
        carbsRounded += difference;
      } else {
        fatsRounded += difference;
      }
    }

    return (
      proteinRounded.toDouble(),
      carbsRounded.toDouble(),
      fatsRounded.toDouble()
    );
  }

  (int carbsKcal, int proteinKcal, int fatKcal) calculateMacrosInKcal() {
    int proteinKcal = state.day.macros.protein * 4;
    int carbsKcal = state.day.macros.carbs * 4;
    int fatsKcal = state.day.macros.fat * 9;
    return (carbsKcal, proteinKcal, fatsKcal);
  }

  FutureOr<void> _updateDayByMealPlan(
    WhoopUpdateDayByMealPlan event,
    Emitter<WhoopState> emit,
  ) async {
    log('Updating day by meal:');
    log('Event meal plan: ${event.mealPlanEntity}');
    log('Current state meal plan: ${state.day.mealPlanEntity}');

    // Создаем обновленный день
    final updatedDay = state.day.copyWith(
      mealPlanEntity: event.mealPlanEntity.copyWith(
        cycleId: state.day.cycleId,
      ),
      snap: ChatSnapshotEntity(
        messages: chatBloc.state.messages,
        date: DateTime.now(),
        requestsLeft: chatBloc.state.requestsLeft,
        mealPlan: event.mealPlanEntity.copyWith(
          cycleId: state.day.cycleId,
        ),
        threadId: chatRemoteSrc.threadId,
      ),
    );

    // Проверяем необходимость обновления в Directus
    bool needsDirectusUpdate = false;
    if (state.day.mealPlanEntity != event.mealPlanEntity ||
        !listEquals(state.day.snap.messages, chatBloc.state.messages) ||
        state.day.snap.requestsLeft != chatBloc.state.requestsLeft) {
      needsDirectusUpdate = true;
    }

    // Обновляем состояние локально
    emit(state.copyWith(day: updatedDay));

    // Если нужно, синхронизируем с бэкендом
    if (needsDirectusUpdate) {
      // final data =
      //     updatedDay.toDirectus(userId: userBloc.state.user.directusId);
      await dayManager.createOrUpdateDay(day: updatedDay);

      // await manageDayUsecase.call(
      //   ManageDayParams(
      //     userId: userBloc.state.user.directusId,
      //     dayMap: data,
      //     incomingDay: updatedDay,
      //   ),
      // );

      // Обновляем кэш чата
      await chatRepo.saveChatSnapShot(chatSnap: updatedDay.snap);
    }
  }

  FutureOr<void> _disconnect(
    WhoopDisconnect event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final res = await disconnectWhoopUsecase
          .call(DisconnecWhoopParams(userId: userBloc.state.user.directusId));
      res.fold((l) {
        emit(state.copyWith(status: Status.error));
        RishSnackbar().showSnackBar(
          'Error disconnecting your WHOOP account. Please, try again.',
        );
      }, (r) {
        emit(state.copyWith(status: Status.success));
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
      });
    } on Exception catch (e) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(
        'Error disconnecting your WHOOP account. Please, try again. Error: $e',
      );
    }
  }

  bool shouldKeepExistingMealPlan(DayEntity currentDay, DayEntity newDay) {
    // Проверяем, что дни относятся к одному и тому же дню
    final isSameDay = currentDay.dateTime.year == newDay.dateTime.year &&
        currentDay.dateTime.month == newDay.dateTime.month &&
        currentDay.dateTime.day == newDay.dateTime.day;

    // Проверяем, что у нас есть существующий план
    final hasExistingPlan = currentDay.mealPlanEntity != null;

    // Проверяем, что новый план не содержит более свежих данных
    final newPlanIsEmpty = newDay.mealPlanEntity == null;

    // Проверяем cycleId для определения актуальности данных
    final isSameCycle = currentDay.cycleId == newDay.cycleId;

    // Проверяем, что новый день не более свежий
    final isNewerDay = newDay.dateTime.isAfter(currentDay.dateTime);

    if (kDebugMode) {
      log(
        'Meal plan update decision:\n'
        'Current day: ${currentDay.dateTime}\n'
        'New day: ${newDay.dateTime}\n'
        'Same day: $isSameDay\n'
        'Has existing plan: $hasExistingPlan\n'
        'New plan is empty: $newPlanIsEmpty\n'
        'Same cycle: $isSameCycle\n'
        'Current cycle: ${currentDay.cycleId}\n'
        'New cycle: ${newDay.cycleId}\n'
        'Is newer day: $isNewerDay',
        name: 'WhoopBloc',
      );
    }

    // Сохраняем существующий план только если:
    // 1. Дни совпадают
    // 2. Есть существующий план
    // 3. Новый план пустой
    // 4. Циклы совпадают
    // 5. Новый день не более свежий
    return isSameDay &&
        hasExistingPlan &&
        newPlanIsEmpty &&
        isSameCycle &&
        !isNewerDay;
  }

  FutureOr<void> _checkForRefresh(
    WhoopCheckForRefresh event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    final isThereFreshData =
        await whoopRemote.pingLastCycle(cycleId: state.day.cycleId);

    if (isThereFreshData) {
      // Сначала делаем редирект на экран загрузки
      appNavigationService.go(path: AppRoutes.redirect.path);

      final result = await getDataUsecase.call(
        GetDataParams(
          gender: userBloc.state.user.gender!,
          goal: userBloc.state.user.userGoal!,
          userId: userBloc.state.user.directusId,
        ),
      );

      await result.fold(
        (failure) {
          emit(state.copyWith(status: Status.error));
          appNavigationService.go(
            path: adapty.isActive
                ? AppRoutes.homeScreen.path
                : AppRoutes.paywall.path,
          );
        },
        (newDay) async {
          // Сохраняем существующий снапшот
          final existingSnap = state.day.snap;

          // Определяем, нужно ли сохранить существующий план питания
          final mealPlanToUse = shouldKeepExistingMealPlan(state.day, newDay)
              ? state.day.mealPlanEntity
              : newDay.mealPlanEntity;

          // Обновляем день, сохраняя существующие данные где нужно
          final updatedDay = newDay.copyWith(
            mealPlanEntity: mealPlanToUse,
            snap: existingSnap,
          );

          // Обновляем состояние блока
          emit(state.copyWith(day: updatedDay));

          // Обновляем список дней
          userBloc.add(UserGetDays(newDay: updatedDay));

          // Синхронизируем состояние чата с выбранной датой
          chatBloc.add(ChatSyncWithSelectedDate());

          // Обновляем кэш чата за последние 7 дней
          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          await chatRepo.updateChatCache(
            directusId: userBloc.state.user.directusId,
            startDate: sevenDaysAgo,
            endDate: now,
          );

          // Завершаем загрузку и возвращаемся на главный экран
          emit(state.copyWith(status: Status.success));
          appNavigationService.go(
            path: adapty.isActive
                ? AppRoutes.homeScreen.path
                : AppRoutes.paywall.path,
          );

          // Показываем уведомление об успешном обновлении
          RishSnackbar()
              .showSnackBar('Your data has been updated', isError: false);
        },
      );
    } else {
      if (event.needsErrorSnack) {
        RishSnackbar().showWarningSnackBar(message: 'Your data is up to date');
      }
      emit(state.copyWith(status: Status.initial));
    }
  }

  FutureOr<void> _updateCurrentDay(
    WhoopUpdateCurrentDay event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      log(
        '[WhoopBloc] 📥 incoming welness: ${event.day.welnessEntity}',
        name: 'WhoopBloc',
      );

      // Сохраняем старое состояние для сравнения
      final oldDay = state.day;
      print(oldDay == event.day);
      // Обновляем текущий день
      emit(
        state.copyWith(
          day: event.day,
        ),
      );

      log(
        '[WhoopBloc] ✅ Состояние WhoopBloc обновлено, welness: ${state.day.welnessEntity}',
        name: 'WhoopBloc',
      );

      // Проверяем нужно ли обновить в Directus
      bool needsDirectusUpdate = false;

      // Если план питания был очищен
      if (oldDay.mealPlanEntity != null && event.day.mealPlanEntity == null) {
        needsDirectusUpdate = true;
        log(
          '[WhoopBloc] План питания очищен - обновляем в Directus',
          name: 'WhoopBloc',
        );
      }

      // Если обновилась wellness entity (дневниковые записи)
      if (oldDay.welnessEntity != event.day.welnessEntity) {
        needsDirectusUpdate = true;
        log(
          '[WhoopBloc] Wellness entity обновлена - обновляем в Directus',
          name: 'WhoopBloc',
        );
      }

      if (needsDirectusUpdate) {
        await dayManager.createOrUpdateDay(day: event.day);
        log(
          '[WhoopBloc] ✅ День успешно обновлен в Directus',
          name: 'WhoopBloc',
        );
      }

      // Обновляем список дней в UserBloc
      log(
        '[WhoopBloc] 🔄 Обновляем список дней в UserBloc. Wellness: ${event.day.welnessEntity?.welnessPercentage}%, блюд: ${event.day.welnessEntity?.consumedMeals.length ?? 0}',
        name: 'WhoopBloc',
      );
      userBloc.add(UserGetDays(newDay: event.day));

      // Синхронизируем чат с новым днем
      chatBloc.add(ChatSyncWithSelectedDate());
    } catch (e) {
      log('Error updating current day: $e');
      RishSnackbar().showSnackBar('Failed to update day. Please try again.');
    }
  }
}
