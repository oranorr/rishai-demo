import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/services/image_picker/image_picker_helper.dart';
import 'package:rishai/core/services/image_picker/image_picker_service.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart'
    show CustomMealEntry, createDiaryMealFromResponse;
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/camera_button.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/meal_type_selector.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/photos_gallery.dart';
import 'package:rishai/features/food_diary/presentation/widgets/diary_dropdown.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CustomMealItem Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Виджет для одного кастомного блюда.
///
/// **Функциональность:**
/// - Dropdown с содержимым блюда
/// - Галерея фотографий с плейсхолдерами
/// - Селектор типа приема пищи
/// - Текстовое поле описания
/// - Кнопка камеры
/// - Кнопка "Send"
/// - Кнопка удаления (X) если больше 1 блюда
///
class CustomMealItem extends StatefulWidget {
  const CustomMealItem({
    required this.meal,
    required this.mealIndex,
    required this.showDeleteButton,
    super.key,
  });

  /// Данные кастомного блюда
  final CustomMealEntry meal;

  /// Индекс блюда для отображения (1-based)
  final int mealIndex;

  /// Показывать ли кнопку удаления
  final bool showDeleteButton;

  @override
  State<CustomMealItem> createState() => _CustomMealItemState();
}

class _CustomMealItemState extends State<CustomMealItem> {
  // Сервис для работы с изображениями
  final ImagePickerService _imagePickerService = ImagePickerService();
  late final ImagePickerHelper _imagePickerHelper;

  // Контроллер для текстового поля
  late final TextEditingController _descriptionController;

  // Клиент для работы с LLM прокси
  late final LlmProxyClient _llmProxyClient;

  // Состояние загрузки при отправке
  bool _isLoading = false;

  // Состояние загрузки при регенерации
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _imagePickerHelper = ImagePickerHelper(_imagePickerService);
    _descriptionController =
        TextEditingController(text: widget.meal.description);
    _llmProxyClient = getIt.get<LlmProxyClient>();

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
    print(
      '[CustomMealItem._handleCameraTap] Нажатие на кнопку камеры для блюда ${widget.meal.id}',
    );

    // Вычисляем доступные слоты
    final availableSlots = FoodDiaryCubit.maxPhotos - widget.meal.photos.length;

    // Проверяем лимит фотографий
    if (availableSlots <= 0) {
      _showSnackbar('Maximum ${FoodDiaryCubit.maxPhotos} photos allowed');
      return;
    }

    if (!mounted) return;

    try {
      // Показываем диалог выбора источника
      final dynamic result =
          await _imagePickerHelper.showAppleStyleImageSourceDialog(
        context: context,
        imageQuality: FoodDiaryCubit.imageQuality,
        maxWidth: FoodDiaryCubit.maxImageWidth,
        maxHeight: FoodDiaryCubit.maxImageHeight,
        allowMultiple: true,
        limit: availableSlots,
      );

      // Обрабатываем результат
      if (result != null) {
        _handleImageResult(result);
      }
    } catch (e, stackTrace) {
      print('[CustomMealItem._handleCameraTap] Ошибка: $e');
      print('[CustomMealItem._handleCameraTap] StackTrace: $stackTrace');
      _showSnackbar(
        'Error accessing camera or gallery. Please check permissions.',
      );
    }
  }

  /// [_handleImageResult] Обрабатывает результат выбора изображений
  void _handleImageResult(result) {
    final cubit = context.read<FoodDiaryCubit>();

    if (result is XFile) {
      // Одна фотография
      cubit.add(CustomMealAddPhoto(mealId: widget.meal.id, photo: result));
    } else if (result is List<XFile>) {
      // Несколько фотографий
      if (result.isEmpty) {
        _showSnackbar(
          'Could not load photos. Please make sure they are downloaded from iCloud.',
        );
      } else {
        cubit.add(CustomMealAddPhotos(mealId: widget.meal.id, photos: result));
      }
    }
  }

  /// [_removePhoto] Удаляет фотографию по индексу
  void _removePhoto(int index) {
    print(
      '[CustomMealItem._removePhoto] Удаление индекса: $index для блюда ${widget.meal.id}',
    );
    final cubit = context.read<FoodDiaryCubit>();
    cubit.add(CustomMealRemovePhoto(mealId: widget.meal.id, photoIndex: index));
  }

  /// [_handleDelete] Обработчик удаления блюда
  void _handleDelete() {
    print('[CustomMealItem._handleDelete] Удаление блюда ${widget.meal.id}');
    final cubit = context.read<FoodDiaryCubit>();
    cubit.add(CustomMealRemove(mealId: widget.meal.id));
  }

  /// [_handleDeleteAnalyzedMeal] Обработчик удаления проанализированного блюда
  ///
  /// Если это не единственное блюдо - удаляет его.
  /// Если это единственное блюдо - заменяет его на пустую карточку.
  void _handleDeleteAnalyzedMeal() {
    print(
      '[CustomMealItem._handleDeleteAnalyzedMeal] Удаление проанализированного блюда ${widget.meal.id}',
    );

    final cubit = context.read<FoodDiaryCubit>();
    final currentState = cubit.state;

    // Проверяем, что находимся в правильном состоянии
    if (currentState is! DiaryEntryPageState) {
      print(
        '[CustomMealItem._handleDeleteAnalyzedMeal] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
      );
      return;
    }

    final customMealsCount = currentState.customMeals.length;

    print(
      '[CustomMealItem._handleDeleteAnalyzedMeal] Всего блюд: $customMealsCount',
    );

    if (customMealsCount > 1) {
      // Если больше одного блюда - просто удаляем
      print(
        '[CustomMealItem._handleDeleteAnalyzedMeal] Удаляем блюдо (блюд > 1)',
      );
      cubit.add(CustomMealRemove(mealId: widget.meal.id));
    } else {
      // Если это единственное блюдо - заменяем на пустое
      print(
        '[CustomMealItem._handleDeleteAnalyzedMeal] Единственное блюдо - заменяем на пустое',
      );
      cubit.add(CustomMealReset(mealId: widget.meal.id));
    }
  }

  /// [_handleToggleSelection] Обработчик переключения выбора блюда
  ///
  /// Добавляет или убирает проанализированное блюдо из списка выбранных
  /// для добавления в дневник.
  void _handleToggleSelection() {
    print(
      '[CustomMealItem._handleToggleSelection] Переключение выбора блюда ${widget.meal.id} (текущий: ${widget.meal.isSelected})',
    );

    final cubit = context.read<FoodDiaryCubit>();
    cubit.add(CustomMealToggleSelection(mealId: widget.meal.id));

    print(
      '[CustomMealItem._handleToggleSelection] ✅ Событие отправлено',
    );
  }

  /// [_handleRegenerateAnalysis] Обработчик регенерации анализа блюда
  ///
  /// Повторяет запрос анализа фотографий с теми же данными (фото и описание).
  /// Обновляет результат анализа после получения ответа от сервера.
  Future<void> _handleRegenerateAnalysis() async {
    print(
      '[CustomMealItem._handleRegenerateAnalysis] Регенерация анализа для блюда ${widget.meal.id}',
    );

    final photos = widget.meal.photos;
    final description = widget.meal.description;

    // Проверяем наличие фотографий
    if (photos.isEmpty) {
      print(
        '[CustomMealItem._handleRegenerateAnalysis] ⚠️ Нет фотографий для регенерации',
      );
      _showSnackbar('No photos available for regeneration');
      return;
    }

    try {
      // Устанавливаем состояние загрузки для регенерации
      setState(() {
        _isRegenerating = true;
      });

      print(
        '[CustomMealItem._handleRegenerateAnalysis] Отправка ${photos.length} фото на повторный анализ',
      );

      // Отправляем запрос на анализ
      final result = await _llmProxyClient.analyzeFoodPhoto(
        images: photos,
        description: description,
      );

      if (!mounted) return;

      print(
        '[CustomMealItem._handleRegenerateAnalysis] ✅ Получен новый результат: ${result.nameOfMeal}',
      );

      // Конвертируем ответ сервера в DiaryMeal
      final diaryMeal =
          createDiaryMealFromResponse(result, widget.meal.mealType);

      print(
        '[CustomMealItem._handleRegenerateAnalysis] 📊 Новый DiaryMeal создан: ${diaryMeal.title}, K=${diaryMeal.macros.kcal}ккал',
      );

      // Обновляем результат анализа в блюде
      final cubit = context.read<FoodDiaryCubit>();
      cubit.add(
        CustomMealSetAnalyzedResult(
          mealId: widget.meal.id,
          analyzedMeal: diaryMeal,
        ),
      );

      print(
        '[CustomMealItem._handleRegenerateAnalysis] ✅ Результат регенерации сохранен',
      );
    } catch (e, stackTrace) {
      print('[CustomMealItem._handleRegenerateAnalysis] ❌ Ошибка: $e');
      print(
        '[CustomMealItem._handleRegenerateAnalysis] StackTrace: $stackTrace',
      );

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
    print(
      '[CustomMealItem._handleSendRequest] Начало обработки запроса для блюда ${widget.meal.id}',
    );

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

      print(
        '[CustomMealItem._handleSendRequest] Отправка ${photos.length} фото на анализ',
      );

      // Отправляем запрос на анализ
      final result = await _llmProxyClient.analyzeFoodPhoto(
        images: photos,
        description: description,
      );

      if (!mounted) return;

      print(
        '[CustomMealItem._handleSendRequest] ✅ Получен результат: ${result.nameOfMeal}',
      );

      // Конвертируем ответ сервера в DiaryMeal
      final diaryMeal =
          createDiaryMealFromResponse(result, widget.meal.mealType);

      print(
        '[CustomMealItem._handleSendRequest] 📊 DiaryMeal создан: ${diaryMeal.title}, K=${diaryMeal.macros.kcal}ккал',
      );

      // Сохраняем результат анализа в блюде
      final cubit = context.read<FoodDiaryCubit>();
      cubit.add(
        CustomMealSetAnalyzedResult(
          mealId: widget.meal.id,
          analyzedMeal: diaryMeal,
        ),
      );

      print(
        '[CustomMealItem._handleSendRequest] ✅ Результат анализа сохранен в блюде',
      );
    } catch (e, stackTrace) {
      print('[CustomMealItem._handleSendRequest] ❌ Ошибка: $e');
      print('[CustomMealItem._handleSendRequest] StackTrace: $stackTrace');

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

  /// [_buildAnalyzedMealContent] Рендерит содержимое проанализированного блюда
  ///
  /// Отображает результаты анализа в read-only режиме:
  /// - Первая фотография пользователя (если есть)
  /// - Название блюда
  /// - Макронутриенты (белки, жиры, углеводы)
  /// - Калории
  Widget _buildAnalyzedMealContent(BuildContext context) {
    final analyzedMeal = widget.meal.analyzedMeal!;
    final hasPhoto = widget.meal.photos.isNotEmpty;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ┌─────────────────────────────────────────────────────────────────┐
              // │ Фотография блюда (если есть)                                     │
              // └─────────────────────────────────────────────────────────────────┘
              if (hasPhoto) ...[
                SizedBox(
                  width: 94.w,
                  height: 94.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.meal.photos.first.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // ┌─────────────────────────────────────────────────────────────────┐
              // │ Информация о блюде                                               │
              // └─────────────────────────────────────────────────────────────────┘
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ┌───────────────────────────────────────────────────────────────┐
                    // │ Название блюда                                                 │
                    // └───────────────────────────────────────────────────────────────┘
                    Text(
                      analyzedMeal.title,
                      style: context.styles.boldMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // ┌───────────────────────────────────────────────────────────────┐
                    // │ Информация о питательности                                     │
                    // └───────────────────────────────────────────────────────────────┘
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: [
                        // Макронутриенты
                        Text(
                          'Protein ${analyzedMeal.macros.protein}',
                          style: context.styles.regularSmall,
                        ),
                        Text(
                          'Fats ${analyzedMeal.macros.fat}',
                          style: context.styles.regularSmall,
                        ),
                        Text(
                          'Carbs ${analyzedMeal.macros.carbs}',
                          style: context.styles.regularSmall,
                        ),
                        // Калорийность
                        Text(
                          '${analyzedMeal.macros.kcal} Kcals',
                          style: context.styles.regularMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ┌─────────────────────────────────────────────────────────────────┐
          // │ Панель действий с кнопками                                       │
          // └─────────────────────────────────────────────────────────────────┘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Кнопка удаления
              GestureDetector(
                onTap: _isRegenerating ? null : _handleDeleteAnalyzedMeal,
                child: Opacity(
                  opacity: _isRegenerating ? 0.5 : 1.0,
                  child: SvgPicture.asset('assets/icons/trash.svg'),
                ),
              ),

              // Кнопка регенерации / Индикатор загрузки
              GestureDetector(
                onTap: _isRegenerating ? null : _handleRegenerateAnalysis,
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: _isRegenerating
                      ? CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            RishColors.primary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                ),
              ),

              // Кнопка подтверждения / выбора для добавления в дневник
              GestureDetector(
                onTap: _isRegenerating ? null : _handleToggleSelection,
                child: Opacity(
                  opacity: _isRegenerating ? 0.5 : 1.0,
                  child: SvgPicture.asset(
                    'assets/icons/checkmark-circle.svg',
                    colorFilter: ColorFilter.mode(
                      widget.meal.isSelected
                          ? RishColors.primary
                          : RishColors.textSecondary.withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// [_buildEditableMealContent] Рендерит содержимое редактируемого блюда
  ///
  /// Отображает поля для ввода данных:
  /// - Селектор типа приема пищи
  /// - Галерея фотографий
  /// - Поле описания
  /// - Кнопка отправки
  Widget _buildEditableMealContent(BuildContext context) {
    return Column(
      children: [
        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Селектор типа приема пищи                                        │
        // └─────────────────────────────────────────────────────────────────┘
        MealTypeSelector(
          selectedType: widget.meal.mealType,
          onTypeChanged: (type) {
            context.read<FoodDiaryCubit>().add(
                  CustomMealSetMealType(
                    mealId: widget.meal.id,
                    mealType: type,
                  ),
                );
          },
        ),
        SizedBox(height: 12.h),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Галерея фотографий (отображается всегда с плейсхолдерами)        │
        // └─────────────────────────────────────────────────────────────────┘
        PhotosGallery(
          photos: widget.meal.photos,
          onRemove: _removePhoto,
          onAddPhoto: _handleCameraTap,
        ),
        SizedBox(height: 12.h),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Поле ввода описания с кнопкой камеры                             │
        // └─────────────────────────────────────────────────────────────────┘
        DecoratedBox(
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Текстовое поле для описания блюда
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Add meal description',
                    hintStyle: context.styles.regularMedium.copyWith(
                      color: RishColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: context.styles.regularMedium,
                ),
              ),
              SizedBox(width: 8.w),

              // Круглая кнопка камеры
              CameraButton(
                photoCount: widget.meal.photos.length,
                onTap: _handleCameraTap,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Кнопка отправки                                                  │
        // └─────────────────────────────────────────────────────────────────┘
        RishButton.primary(
          title: 'send',
          enabled: widget.meal.hasPhotos || widget.meal.hasDescription,
          isLoading: _isLoading,
          action: _handleSendRequest,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Определяем заголовок dropdown
    // Если блюдо проанализировано - показываем название блюда
    // Иначе - показываем тип приема пищи или placeholder
    final dropdownTitle =
        widget.meal.mealType?.name.capitalize() ?? 'Choose from the list';
    //  widget.meal.isAnalyzed
    //     ? widget.meal.analyzedMeal!.title
    //     : (widget.meal.mealType?.name ?? 'Choose from the list');

    // Dropdown должен быть открыт если есть фото или если блюдо проанализировано
    final initiallyExpanded = widget.meal.hasPhotos || widget.meal.isAnalyzed;

    return Column(
      children: [
        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Кнопка удаления сверху (если больше 1 блюда)                     │
        // └─────────────────────────────────────────────────────────────────┘
        if (widget.showDeleteButton && !widget.meal.isAnalyzed)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _handleDelete,
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Delete meal',
                      style: context.styles.regularSmall.copyWith(
                        color: RishColors.error,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.delete_outline,
                      size: 16.w,
                      color: RishColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Dropdown с содержимым блюда                                      │
        // └─────────────────────────────────────────────────────────────────┘
        DiaryDropDown(
          title: dropdownTitle,
          initiallyExpanded: initiallyExpanded,
          child: widget.meal.isAnalyzed
              ? _buildAnalyzedMealContent(context)
              : _buildEditableMealContent(context),
        ),
      ],
    );
  }
}
