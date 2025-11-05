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
  /// Показывает диалог выбора источника изображения
  Future<void> _handleCameraTap() async {
    if (!mounted) return;

    try {
      // Используем обработчик для выбора изображений
      final result = await _imagePickerHandler.pickImages(
        context: context,
        currentPhotoCount: widget.meal.photos.length,
      );

      // Обрабатываем результат
      if (result != null) {
        _handleImageResult(result);
      }
    } catch (e) {
      _showSnackbar(
        e.toString().contains('Maximum')
            ? e.toString()
            : 'Error accessing camera or gallery. Please check permissions.',
      );
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

    try {
      // Устанавливаем состояние загрузки для регенерации
      setState(() {
        _isRegenerating = true;
      });

      // Используем обработчик для регенерации анализа
      final diaryMeal = await _mealAnalysisHandler.regenerateAnalysis(
        photos: photos,
        description: description,
        mealType: widget.meal.mealType,
      );

      if (!mounted) return;

      // Обновляем результат анализа в блюде
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
      _showSnackbar('Error regenerating analysis: $e');
    } finally {
      // Убираем состояние загрузки
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// [_handleSendRequest] Обрабатывает отправку запроса на анализ фотографий
  ///
  /// Валидирует наличие фото или описания, отправляет запрос на бекенд,
  /// конвертирует результат в DiaryMeal и сохраняет в блюде.
  Future<void> _handleSendRequest() async {
    final photos = widget.meal.photos;
    final description = widget.meal.description;

    // Валидация: должно быть хотя бы 1 фото ИЛИ описание
    if (photos.isEmpty && description.isEmpty) {
      _showSnackbar('Please add at least one photo or description');
      return;
    }

    // Если нет фотографий, но есть описание - требуем фото
    if (photos.isEmpty) {
      _showSnackbar('Please add at least one photo');
      return;
    }

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
      _showSnackbar('Error analyzing photo: $e');
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
