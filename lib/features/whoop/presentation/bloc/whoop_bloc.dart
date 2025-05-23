import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart'
    show adapty;
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
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
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/connect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_body_data_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'whoop_event.dart';

final whoopBloc = GetIt.I<WhoopBloc>();
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
      await _getBodyData(WhoopRetrieveBodyData(), emit);
      if (!needsQuestionary) {
        await _initWhoopOnLogin(const InitWhoopOnLogin(), emit);
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

          // Создаем комплитер для ожидания загрузки дней
          final completer = Completer<bool>();

          // Переменная для отслеживания статуса загрузки
          bool loadingHasStarted = false;
          bool loadingInProgress = false;
          int totalDaysToLoad = userBloc.state.user.daysIds.length;
          int daysLoadedSoFar = 0;

          // Вычисляем адаптивное время ожидания в зависимости от количества дней
          // Базовое время 20 секунд + дополнительное время на каждые 50 дней
          const baseTimeout = 20;
          final adaptiveTimeout =
              baseTimeout + ((totalDaysToLoad / 50).ceil() * 10);
          log(
            'Using adaptive timeout of $adaptiveTimeout seconds for $totalDaysToLoad days',
            name: 'WhoopBloc',
          );

          // Подписываемся на состояние UserBloc
          final subscription = userBloc.stream.listen((userState) {
            log(
              'UserBloc state change: ${userState.status}, days: ${userState.days.length}',
              name: 'WhoopBloc',
            );

            // Проверяем начало загрузки
            if (userState.status == Status.loading) {
              loadingHasStarted = true;
              loadingInProgress = true;
              log('Days loading has started', name: 'WhoopBloc');
            }

            // Отслеживаем прогресс загрузки
            if (loadingInProgress && userState.days.length > daysLoadedSoFar) {
              daysLoadedSoFar = userState.days.length;
              log(
                'Loading progress: $daysLoadedSoFar/$totalDaysToLoad days',
                name: 'WhoopBloc',
              );
            }

            // Успешное завершение загрузки
            if (userState.status == Status.success &&
                loadingHasStarted &&
                !completer.isCompleted) {
              loadingInProgress = false;
              log(
                'Days loading completed successfully (${userState.days.length} days)',
                name: 'WhoopBloc',
              );

              // Проверяем, что в списке есть хотя бы один день
              if (userState.days.isNotEmpty) {
                completer.complete(true);
              } else {
                log(
                  'Warning: Successful state but empty days list',
                  name: 'WhoopBloc',
                );
                completer.complete(false);
              }
            }

            // Завершение с ошибкой
            if (userState.status == Status.error &&
                loadingHasStarted &&
                !completer.isCompleted) {
              loadingInProgress = false;
              log('Days loading completed with error', name: 'WhoopBloc');
              completer.complete(false);
            }
          });

          // Запускаем загрузку дней
          log('Starting days loading...', name: 'WhoopBloc');
          userBloc.add(UserGetDays(newDay: state.day));

          // Ждем загрузки дней с таймаутом
          bool loadingResult = false;
          bool didTimeout = false;

          try {
            // Создаем Future для таймаута
            final timeoutFuture =
                Future.delayed(Duration(seconds: adaptiveTimeout)).then((_) {
              if (!completer.isCompleted) {
                log(
                  'Timeout waiting for days to load after $adaptiveTimeout seconds',
                  name: 'WhoopBloc',
                );

                // Проверяем, идет ли загрузка все еще
                if (loadingInProgress && daysLoadedSoFar > 0) {
                  // Если загрузка идет и уже загружено какое-то количество дней,
                  // считаем это частичным успехом и не прерываем загрузку
                  log(
                    'Loading still in progress with $daysLoadedSoFar days loaded, continuing without error',
                    name: 'WhoopBloc',
                  );
                  // Здесь мы НЕ завершаем completer, чтобы загрузка могла продолжиться
                  didTimeout = true;
                  return true; // Считаем частичный успех
                } else {
                  // Если нет прогресса, завершаем с ошибкой
                  didTimeout = true;
                  completer.complete(false);
                  return false;
                }
              }
              return true;
            });

            // Ждем результата от completer
            loadingResult = await completer.future;

            // Отменяем таймаут, если возможно (хотя это не всегда работает)
            timeoutFuture.ignore();

            log(
              'Days loading result: $loadingResult, timeout: $didTimeout, days loaded: $daysLoadedSoFar',
              name: 'WhoopBloc',
            );
          } catch (e) {
            log('Error waiting for days: $e', name: 'WhoopBloc');
            loadingResult = false;
          } finally {
            // Отписываемся от стрима
            subscription.cancel();
          }

          // Обработка результата загрузки - показываем сообщение только если действительно произошла ошибка
          if (!loadingResult && didTimeout && daysLoadedSoFar == 0) {
            // Реальная ошибка таймаута - ничего не загрузилось
            RishSnackbar().showSnackBar(
              'Loading time exceeded. Possible connection issues.',
            );
          } else if (!loadingResult && !didTimeout) {
            // Другая ошибка загрузки
            RishSnackbar().showSnackBar(
              'An error occurred while loading data. Please check your connection.',
            );
          } else if (didTimeout && daysLoadedSoFar > 0) {
            // Частичная загрузка - успешно загрузилась часть данных
            log(
              'Partial success: loaded $daysLoadedSoFar days before timeout',
              name: 'WhoopBloc',
            );
            // Не показываем ошибку, т.к. загрузка частично успешна
          } else {
            log('All days loaded successfully', name: 'WhoopBloc');
          }

          // Переходим на домашний экран только после завершения загрузки или таймаута
          log('Navigation to home screen', name: 'WhoopBloc');

          // Делаем финальную проверку состояний перед навигацией
          bool userBlocReady = userBloc.state.status == Status.success &&
              userBloc.state.days.isNotEmpty;
          bool partialSuccess = didTimeout &&
              daysLoadedSoFar > 0; // Считаем частичный успех тоже приемлемым
          bool whoopBlocReady = state.status != Status.error;

          log(
            'Final check before navigation: UserBloc ready: $userBlocReady, Partial success: $partialSuccess, WhoopBloc ready: $whoopBlocReady',
            name: 'WhoopBloc',
          );

          if (!userBlocReady && !partialSuccess) {
            log(
              'Warning: UserBloc is not fully ready for navigation!',
              name: 'WhoopBloc',
            );
          }

          // Даже если полная загрузка не завершена, но есть частичный успех - продолжаем
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
      await dayManager.createDay(day: updatedDay);

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
      // Обновляем текущий день
      emit(state.copyWith(day: event.day));

      // Если план питания был очищен, обновляем в Directus
      if (state.day.mealPlanEntity != null &&
          event.day.mealPlanEntity == null) {
        // final data =
        //     event.day.toDirectus(userId: userBloc.state.user.directusId);
        await dayManager.createDay(day: event.day);
        // await manageDayUsecase.call(
        //   ManageDayParams(
        //     userId: userBloc.state.user.directusId,
        //     dayMap: data,
        //     incomingDay: event.day,
        //   ),
        // );
      }

      // Синхронизируем чат с новым днем
      chatBloc.add(ChatSyncWithSelectedDate());
    } catch (e) {
      log('Error updating current day: $e');
      RishSnackbar().showSnackBar('Failed to update day. Please try again.');
    }
  }
}
