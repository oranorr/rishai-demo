part of '../widgets/custom_meal_item.dart';

mixin CustomMealItemMixin on State<CustomMealItem> {
  // Контроллер для текстового поля
  late final TextEditingController _descriptionController;

  // Обработчики логики
  late final ImagePickerHandler _imagePickerHandler;
  late final MealAnalysisHandler _mealAnalysisHandler;

  // Состояние загрузки при отправке
  bool _isLoading = false;

  // Состояние загрузки при регенерации
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.meal.description);
    _imagePickerHandler = ImagePickerHandler();
    _mealAnalysisHandler = MealAnalysisHandler();

    // Слушаем изменения в текстовом поле и обновляем кубит
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _descriptionController
      ..removeListener(_onDescriptionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomMealItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем текстовое поле если описание изменилось извне
    if (oldWidget.meal.description != widget.meal.description &&
        _descriptionController.text != widget.meal.description) {
      _descriptionController.text = widget.meal.description;
    }
  }

  /// [_onDescriptionChanged] Обработчик изменений текста описания
  void _onDescriptionChanged() {
    final cubit = context.read<FoodDiaryCubit>();

    // Обновляем описание для данного блюда
    cubit.add(
      CustomMealUpdateDescription(
        mealId: widget.meal.id,
        description: _descriptionController.text,
      ),
    );
  }

  /// [_handleCameraTap] Обработчик нажатия на кнопку камеры
  ///
  /// Показывает диалог выбора источника изображения.
  /// Для бесплатных пользователей проверяет 24-часовой лимит загрузки фотографий.
  Future<void> _handleCameraTap() async {
    if (!mounted) return;

    // ┌───────────────────────────────────────────────────────────────────┐
    // │ Проверка 24-часового лимита для бесплатных пользователей          │
    // └───────────────────────────────────────────────────────────────────┘
    // [freeUserPhotoLimitCheck] Проверяем лимит загрузки фотографий для
    // бесплатных пользователей перед выбором изображения
    if (!adapty.isActive) {
      // [canUploadPhoto] Проверяем, прошло ли 24 часа с последней загрузки
      final canUploadPhoto = prefsRepo.canFreeUserUploadPhoto();

      if (!canUploadPhoto) {
        // [limitExceeded] Лимит не истек - показываем диалог и блокируем добавление
        final lastUploadTime = prefsRepo.getLastFreeUserPhotoUploadTime();
        final timeRemaining = lastUploadTime != null
            ? DateTime.now().difference(lastUploadTime)
            : Duration.zero;
        final hoursRemaining = 24 - timeRemaining.inHours;

        log(
          '[CustomMealItemMixin._handleCameraTap] ⚠️ Лимит загрузки фотографий не истек. Осталось часов: $hoursRemaining',
        );

        // Показываем диалог о лимите
        await RishiDialog.showPhotoUploadLimitDialog(
          context,
          hoursRemaining: hoursRemaining,
          onUpgrade: () {
            // [navigateToPaywall] Переходим на экран paywall для обновления подписки
            appNavigationService.go(path: AppRoutes.paywall.path);
          },
        );
        return;
      }
    }

    try {
      // Вычисляем максимальное количество фотографий для данного блюда
      // на основе подписки и типа блюда
      final maxPhotos =
          FoodDiaryCubit.getMaxPhotosForMeal(widget.meal.mealType);

      // Используем обработчик для выбора изображений
      final result = await _imagePickerHandler.pickImages(
        context: context,
        currentPhotoCount: widget.meal.photos.length,
        maxPhotos: maxPhotos,
      );

      // Обрабатываем результат
      // Если result == null, пользователь отменил выбор - это нормально, не показываем ошибку
      if (result != null) {
        _handleImageResult(result);
      }
    } catch (e) {
      // Показываем ошибку только если это реальная ошибка, а не отмена выбора
      final errorMessage = e.toString();

      // Если это ошибка лимита фотографий - показываем конкретное сообщение
      if (errorMessage.contains('Maximum')) {
        _showSnackbar(errorMessage);
      }
      // Если это ошибка разрешений - показываем сообщение о разрешениях
      else if (errorMessage.toLowerCase().contains('permission') ||
          errorMessage.toLowerCase().contains('denied')) {
        _showSnackbar(
          'Error accessing camera or gallery. Please check permissions.',
        );
      }
      // Для других ошибок тоже показываем сообщение, но более общее
      else {
        print('[CustomMealItemMixin._handleCameraTap] Неожиданная ошибка: $e');
        // Не показываем снек для неизвестных ошибок, возможно это просто отмена
      }
    }
  }

  /// [_handleImageResult] Обрабатывает результат выбора изображений
  void _handleImageResult(result) {
    final cubit = context.read<FoodDiaryCubit>();

    // Конвертируем результат в список XFile
    final photos = _imagePickerHandler.handleImageResult(result);

    // Добавляем фотографии в кубит
    if (photos.length == 1) {
      cubit
          .add(CustomMealAddPhoto(mealId: widget.meal.id, photo: photos.first));
    } else {
      cubit.add(CustomMealAddPhotos(mealId: widget.meal.id, photos: photos));
    }
  }

  /// [_removePhoto] Удаляет фотографию по индексу
  void _removePhoto(int index) {
    final cubit = context.read<FoodDiaryCubit>();
    cubit.add(CustomMealRemovePhoto(mealId: widget.meal.id, photoIndex: index));
  }

  /// [_handleDelete] Обработчик удаления блюда
  void _handleDelete() {
    final cubit = context.read<FoodDiaryCubit>();
    cubit.add(CustomMealRemove(mealId: widget.meal.id));
  }

  /// [_handleDeleteAnalyzedMeal] Обработчик удаления проанализированного блюда
  ///
  /// Если это не единственное блюдо - удаляет его.
  /// Если это единственное блюдо - заменяет его на пустую карточку.
  void _handleDeleteAnalyzedMeal() {
    final cubit = context.read<FoodDiaryCubit>();
    final currentState = cubit.state;

    // Проверяем, что находимся в правильном состоянии
    if (currentState is! DiaryEntryPageState) {
      return;
    }

    final customMealsCount = currentState.customMeals.length;

    if (customMealsCount > 1) {
      // Если больше одного блюда - просто удаляем
      cubit.add(CustomMealRemove(mealId: widget.meal.id));
    } else {
      // Если это единственное блюдо - заменяем на пустое
      cubit.add(CustomMealReset(mealId: widget.meal.id));
    }
  }

  /// [_handleToggleSelection] Обработчик переключения выбора блюда
  ///
  /// Добавляет или убирает проанализированное блюдо из списка выбранных
  /// для добавления в дневник.
  void _handleToggleSelection() {
    final cubit = context.read<FoodDiaryCubit>();
    cubit.add(CustomMealToggleSelection(mealId: widget.meal.id));
  }

  /// [_handleRegenerateAnalysis] Обработчик регенерации анализа блюда
  ///
  /// Повторяет запрос анализа фотографий с теми же данными (фото и описание).
  /// Обновляет результат анализа после получения ответа от сервера.
  Future<void> _handleRegenerateAnalysis() async {
    final photos = widget.meal.photos;
    final description = widget.meal.description;
    final cubit = context.read<FoodDiaryCubit>();

    try {
      // [setState] Устанавливаем локальное состояние загрузки для регенерации
      setState(() {
        _isRegenerating = true;
      });

      // [cubit] Отправляем событие начала регенерации для блокировки кнопки добавления
      cubit.add(
        CustomMealStartRegenerating(mealId: widget.meal.id),
      );

      // [regenerateAnalysis] Используем обработчик для регенерации анализа
      final diaryMeal = await _mealAnalysisHandler.regenerateAnalysis(
        photos: photos,
        description: description,
        mealType: widget.meal.mealType,
      );

      if (!mounted) return;

      // [cubit] Обновляем результат анализа в блюде
      cubit.add(
        CustomMealSetAnalyzedResult(
          mealId: widget.meal.id,
          analyzedMeal: diaryMeal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // [showSnackbar] Показываем ошибку пользователю
      _showSnackbar('Something failed, please try again');
    } finally {
      // [cubit] Отправляем событие окончания регенерации для разблокировки кнопки
      if (mounted) {
        cubit.add(
          CustomMealStopRegenerating(mealId: widget.meal.id),
        );
      }

      // [setState] Убираем локальное состояние загрузки
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  /// [_showSnackbar] Показывает уведомление пользователю
  void _showSnackbar(String message) {
    if (!mounted) return;
    RishSnackbar().showSnackBar(message);
  }

  /// [_handleSendRequest] Обрабатывает отправку запроса на анализ фотографий
  ///
  /// Валидирует наличие фото или описания, отправляет запрос на бекенд,
  /// конвертирует результат в DiaryMeal и сохраняет в блюде.
  Future<void> _handleSendRequest() async {
    final photos = widget.meal.photos;
    final description = widget.meal.description;

    try {
      // Устанавливаем состояние загрузки
      setState(() {
        _isLoading = true;
      });
      // Используем обработчик для анализа блюда
      final diaryMeal = await _mealAnalysisHandler.analyzeMeal(
        photos: photos,
        description: description,
        mealType: widget.meal.mealType,
      );

      if (!mounted) return;

      // Сохраняем результат анализа в блюде
      final cubit = context.read<FoodDiaryCubit>();
      cubit.add(
        CustomMealSetAnalyzedResult(
          mealId: widget.meal.id,
          analyzedMeal: diaryMeal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Показываем ошибку пользователю
      _showSnackbar('Something failed, please try again');
    } finally {
      // Убираем состояние загрузки
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
