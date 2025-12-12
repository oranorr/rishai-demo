part of 'wellness_page.dart';

/// [RecommendationService] Публичный сервис для получения текущей рекомендации
/// Используется для передачи рекомендации в контекст чата
class RecommendationService {
  RecommendationService._();

  /// [getCurrentRecommendation] Получает текущую рекомендацию на основе макросов
  /// Возвращает текущую рекомендацию или null, если рекомендации нет
  static String? getCurrentRecommendation() {
    return _RecommendationsWidgetState.getCurrentRecommendation();
  }
}

/// Класс для анализа состояния макросов и определения сценария рекомендаций
class _MacrosAnalyzer {
  /// Анализирует состояние макросов и определяет дефицит/профицит
  /// Возвращает карту с ключами: 'kcal', 'protein', 'carbs', 'fat'
  /// Значения: true = дефицит, false = профицит
  static Map<String, bool> _analyzeMacrosStatus(
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    return {
      'kcal': consumedMacros.kcal < targetMacros.kcal,
      'protein': consumedMacros.protein < targetMacros.protein,
      'carbs': consumedMacros.carbs < targetMacros.carbs,
      'fat': consumedMacros.fat < targetMacros.fat,
    };
  }

  /// Возвращает список макросов в дефиците
  static List<String> getDeficitMacros(
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    final status = _analyzeMacrosStatus(targetMacros, consumedMacros);
    final deficitMacros = <String>[];

    if (status['kcal'] ?? false) deficitMacros.add('calories');
    if (status['protein'] ?? false) deficitMacros.add('protein');
    if (status['carbs'] ?? false) deficitMacros.add('carbs');
    if (status['fat'] ?? false) deficitMacros.add('fats');

    return deficitMacros;
  }

  /// Возвращает список макросов в профиците
  static List<String> getSurplusMacros(
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    final status = _analyzeMacrosStatus(targetMacros, consumedMacros);
    final surplusMacros = <String>[];

    if (status['kcal'] == false) surplusMacros.add('calories');
    if (status['protein'] == false) surplusMacros.add('protein');
    if (status['carbs'] == false) surplusMacros.add('carbs');
    if (status['fat'] == false) surplusMacros.add('fats');

    return surplusMacros;
  }

  /// Форматирует список макросов в читаемую строку
  /// Например: ["protein", "carbs"] -> "protein and carbs"
  static String formatMacrosList(List<String> macros) {
    if (macros.isEmpty) return '';
    if (macros.length == 1) return macros.first;
    if (macros.length == 2) return '${macros.first} and ${macros.last}';
    return '${macros.sublist(0, macros.length - 1).join(', ')}, and ${macros.last}';
  }

  /// Определяет сценарий рекомендаций (1, 2, 3, 4)
  /// 1: Все цели достигнуты или превышены (нет дефицита)
  /// 2: Дефицит калорий + смешанные макросы
  /// 3: Профицит калорий, но дефицит некоторых макросов
  /// 4: Все в профиците
  static int _getRecommendationScenario(
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    final status = _analyzeMacrosStatus(targetMacros, consumedMacros);
    final isKcalDeficit = status['kcal'] ?? false;
    final isKcalSurplus = status['kcal'] == false;
    final deficitMacros = getDeficitMacros(targetMacros, consumedMacros);

    // Сценарий 4: Все в профиците (нет дефицита ни по одному макросу)
    if (deficitMacros.isEmpty) {
      return 4;
    }

    // Сценарий 3: Профицит калорий, но дефицит некоторых макросов
    if (isKcalSurplus && deficitMacros.isNotEmpty) {
      return 3;
    }

    // Сценарий 2: Дефицит калорий + смешанные макросы
    if (isKcalDeficit) {
      return 2;
    }

    // По умолчанию сценарий 2 (дефицит калорий)
    return 2;
  }

  /// Анализирует макросы и возвращает результат анализа
  static _MacrosAnalysisResult analyze(
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    final scenario = _getRecommendationScenario(targetMacros, consumedMacros);
    final deficitMacros = getDeficitMacros(targetMacros, consumedMacros);
    final surplusMacros = getSurplusMacros(targetMacros, consumedMacros);

    return _MacrosAnalysisResult(
      scenario: scenario,
      deficitMacros: deficitMacros,
      surplusMacros: surplusMacros,
      deficitMacrosFormatted: formatMacrosList(deficitMacros),
      surplusMacrosFormatted: formatMacrosList(surplusMacros),
    );
  }
}

/// Результат анализа макросов
class _MacrosAnalysisResult {
  _MacrosAnalysisResult({
    required this.scenario,
    required this.deficitMacros,
    required this.surplusMacros,
    required this.deficitMacrosFormatted,
    required this.surplusMacrosFormatted,
  });

  /// Сценарий (1, 2, 3, 4)
  final int scenario;

  /// Список макросов в дефиците
  final List<String> deficitMacros;

  /// Список макросов в профиците
  final List<String> surplusMacros;

  /// Отформатированный список макросов в дефиците
  final String deficitMacrosFormatted;

  /// Отформатированный список макросов в профиците
  final String surplusMacrosFormatted;
}

/// Виджет с рекомендациями по питанию
class _RecommendationsWidget extends StatefulWidget {
  const _RecommendationsWidget();

  @override
  State<_RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<_RecommendationsWidget> {
  bool _isLoading = false;
  String? _recommendation;
  bool _hasError =
      false; // Флаг для отслеживания ошибки при загрузке рекомендации

  // Кэш рекомендаций: ключ - хеш макросов, значение - рекомендация
  static final Map<String, String> _recommendationCache = {};

  // Последний ключ кэша для отслеживания изменений
  String? _lastCacheKey;

  // [previousRecommendation] Предыдущая рекомендация для передачи в следующий запрос
  // Используется для генерации нового блюда отличного от предыдущего
  static String? _previousRecommendation;

  @override
  void initState() {
    super.initState();
    // [loadOnOpen] Загружаем рекомендации при каждом открытии страницы
    // Используем forceRefresh: true чтобы гарантировать генерацию даже если данные не изменились
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendation(forceRefresh: true);
    });
  }

  /// Генерирует ключ кэша на основе макросов
  String _generateCacheKey(
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    return '${targetMacros.kcal}_${targetMacros.protein}_${targetMacros.carbs}_${targetMacros.fat}_'
        '${consumedMacros.kcal}_${consumedMacros.protein}_${consumedMacros.carbs}_${consumedMacros.fat}';
  }

  /// [getCurrentRecommendation] Статический метод для получения текущей рекомендации
  /// Используется для передачи рекомендации в контекст чата
  /// Возвращает текущую рекомендацию на основе макросов из whoopBloc или null, если рекомендации нет
  static String? getCurrentRecommendation() {
    try {
      final whoopState = whoopBloc.state;
      final welnessEntity = whoopState.day.welnessEntity;
      final targetMacros = whoopState.day.macros;
      final consumedMacros = welnessEntity?.consumedMacros ??
          MacrosBreakdown(
            kcal: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
          );

      // Генерируем ключ кэша для текущего состояния
      final cacheKey =
          '${targetMacros.kcal}_${targetMacros.protein}_${targetMacros.carbs}_${targetMacros.fat}_'
          '${consumedMacros.kcal}_${consumedMacros.protein}_${consumedMacros.carbs}_${consumedMacros.fat}';

      // Возвращаем рекомендацию из кэша, если она есть
      return _recommendationCache[cacheKey];
    } catch (e) {
      // В случае ошибки возвращаем null
      return null;
    }
  }

  /// Загружает рекомендацию на основе анализа макросов
  Future<void> _loadRecommendation({bool forceRefresh = false}) async {
    // Получаем данные из блоков
    final whoopState = whoopBloc.state;
    final userState = userBloc.state;

    final welnessEntity = whoopState.day.welnessEntity;
    final targetMacros = whoopState.day.macros;
    final consumedMacros = welnessEntity?.consumedMacros ??
        MacrosBreakdown(
          kcal: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        );

    final foodPreferences = userState.user.foodPreferences;

    // Генерируем ключ кэша
    final cacheKey = _generateCacheKey(targetMacros, consumedMacros);

    // [checkDataChange] Проверяем, изменились ли данные
    // Если forceRefresh = true, пропускаем эту проверку и всегда генерируем рекомендацию
    if (!forceRefresh && cacheKey == _lastCacheKey && _recommendation != null) {
      // Данные не изменились, рекомендация уже загружена
      return;
    }

    _lastCacheKey = cacheKey;

    // Анализируем макросы
    final analysis = _MacrosAnalyzer.analyze(targetMacros, consumedMacros);

    // Определяем, нужен ли запрос к API
    final needsApiRequest = analysis.scenario == 2;

    // [checkCache] Проверяем кэш для всех сценариев
    // Если forceRefresh = true, пропускаем кэш и всегда генерируем новую рекомендацию
    if (!forceRefresh && _recommendationCache.containsKey(cacheKey)) {
      final cachedRecommendation = _recommendationCache[cacheKey]!;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _recommendation = cachedRecommendation;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = needsApiRequest;
        _recommendation = null;
      });
    }

    // Формируем хардкодед сообщение на основе сценария
    String hardcodedMessage = '';
    switch (analysis.scenario) {
      case 1:
        // Все цели достигнуты или превышены
        hardcodedMessage =
            'You have already surpassed your targets for the day.';
        break;
      case 2:
        // Дефицит калорий + смешанные макросы
        // Исключаем "calories" из списка дефицитных макросов, так как они уже упомянуты в начале предложения
        final deficitMacrosWithoutCalories = analysis.deficitMacros
            .where((macro) => macro != 'calories')
            .toList();
        final deficitMacrosFormattedWithoutCalories =
            _MacrosAnalyzer.formatMacrosList(deficitMacrosWithoutCalories);

        if (analysis.surplusMacros.isNotEmpty) {
          if (deficitMacrosFormattedWithoutCalories.isNotEmpty) {
            hardcodedMessage =
                'You are in a deficit for calories for the day along with $deficitMacrosFormattedWithoutCalories, but you have met your ${analysis.surplusMacrosFormatted} targets for the day. You still have some calories, $deficitMacrosFormattedWithoutCalories available to consume.';
          } else {
            // Если кроме калорий нет других дефицитных макросов
            hardcodedMessage =
                'You are in a deficit for calories for the day, but you have met your ${analysis.surplusMacrosFormatted} targets for the day. You still have some calories available to consume.';
          }
        } else {
          if (deficitMacrosFormattedWithoutCalories.isNotEmpty) {
            hardcodedMessage =
                'You are in a deficit for calories for the day along with $deficitMacrosFormattedWithoutCalories. You still have some calories, $deficitMacrosFormattedWithoutCalories available to consume.';
          } else {
            // Если кроме калорий нет других дефицитных макросов
            hardcodedMessage =
                'You are in a deficit for calories for the day. You still have some calories available to consume.';
          }
        }
        break;
      case 3:
        // Профицит калорий, но дефицит некоторых макросов
        hardcodedMessage =
            'You have hit your calorie targets for the day, but missed your ${analysis.deficitMacrosFormatted} targets, and ate in surplus with your ${analysis.surplusMacrosFormatted}. Something to be mindful of moving forward.';
        break;
      case 4:
        // Все в профиците
        hardcodedMessage =
            'You have already surpassed your targets for the day.';
        break;
    }

    // Если нужен запрос к API (сценарий 2)
    if (needsApiRequest && foodPreferences != null) {
      try {
        final llmProxyClient = getIt.get<LlmProxyClient>();

        // [buildComment] Формируем comment с предыдущей рекомендацией
        // Если есть предыдущая рекомендация, добавляем её в запрос
        String? comment;
        if (_previousRecommendation != null &&
            _previousRecommendation!.isNotEmpty) {
          comment =
              'Here is my previous recommendation: $_previousRecommendation. Please suggest a dish different from the previous one';
        }

        // Формируем запрос
        final request = RecommendationRequest(
          foodPreferences: {
            'diets': foodPreferences.diets,
            'cuisines': foodPreferences.cuisines,
            'restrictions': foodPreferences.restrictions,
          },
          consumedMacros: consumedMacros.toMap(),
          targetMacros: targetMacros.toMap(),
          comment: comment,
        );

        // Запрашиваем рекомендацию от ИИ
        final aiRecommendation =
            await llmProxyClient.getRecommendation(request);

        if (mounted) {
          String finalRecommendation;
          bool hasError = false;

          // Объединяем хардкодед часть и AI рекомендацию
          if (aiRecommendation != null && aiRecommendation.isNotEmpty) {
            // Успешно получили рекомендацию от AI
            // Формируем рекомендацию с учетом наличия профицитных макросов
            if (analysis.surplusMacrosFormatted.isNotEmpty) {
              // Если есть профицитные макросы, добавляем "while low in"
              finalRecommendation =
                  '$hardcodedMessage\n\nI would recommend you eat something high in ${analysis.deficitMacrosFormatted}, while low in ${analysis.surplusMacrosFormatted}. $aiRecommendation';
            } else {
              // Если нет профицитных макросов, не добавляем "while low in"
              finalRecommendation =
                  '$hardcodedMessage\n\nI would recommend you eat something high in ${analysis.deficitMacrosFormatted}. $aiRecommendation';
            }
            // [savePreviousRecommendation] Сохраняем текущую рекомендацию как предыдущую
            // для использования в следующем запросе
            _previousRecommendation = finalRecommendation;
            // Сохраняем в кэш только при успешном получении рекомендации
            _recommendationCache[cacheKey] = finalRecommendation;
          } else {
            // Если API вернул null или пустую строку, это ошибка
            // Показываем только хардкодед сообщение и устанавливаем флаг ошибки
            finalRecommendation = hardcodedMessage;
            hasError = true;
            // Не сохраняем в кэш при ошибке, чтобы можно было повторить попытку
          }

          setState(() {
            _isLoading = false;
            _hasError =
                hasError; // Устанавливаем флаг ошибки в зависимости от результата
            _recommendation = finalRecommendation;
          });
        }
      } catch (e) {
        // При ошибке показываем только хардкодед сообщение и устанавливаем флаг ошибки
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true; // Устанавливаем флаг ошибки
            _recommendation = hardcodedMessage;
          });
        }
      }
    } else {
      // Для сценариев без API просто показываем хардкодед сообщение
      // Сохраняем в кэш для быстрого доступа
      _recommendationCache[cacheKey] = hardcodedMessage;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false; // Сбрасываем флаг ошибки для сценариев без API
          _recommendation = hardcodedMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      listener: (context, state) {
        // Отслеживаем изменения wellness score или consumedMacros
        if (!mounted) return;

        final welnessEntity = state.day.welnessEntity;
        final consumedMacros = welnessEntity?.consumedMacros ??
            MacrosBreakdown(
              kcal: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
            );
        final targetMacros = state.day.macros;

        // Генерируем ключ кэша для текущего состояния
        final currentCacheKey = _generateCacheKey(targetMacros, consumedMacros);

        // Если данные изменились, обновляем рекомендации
        // Проверяем, что ключ действительно изменился и виджет еще mounted
        if (currentCacheKey != _lastCacheKey && mounted) {
          _loadRecommendation();
        }
      },
      builder: (context, state) {
        final welnessEntity = state.day.welnessEntity;
        final targetMacros = state.day.macros; // Целевые макросы
        final consumedMacros = welnessEntity?.consumedMacros ??
            MacrosBreakdown(
              kcal: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
            ); // Потребленные макросы

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w).copyWith(bottom: 4.h),
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой информации
              Row(
                children: [
                  Text(
                    'Nutritional Intelligence',
                    style: context.styles.boldLarge,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async => RishiDialog.infoPopup(
                      context,
                      '''
Recommendations change dynamically over the day as you capture meals.

Staying within ±10% of your daily goal gives the highest score.

Going beyond 100% reduces your score progressively, as overeating affects energy balance and recovery.

Pivot's nutritional intelligence instantly analyzes your day and recommends foods to fill your remaining targets.

Scores above target are penalized to encourage balanced nutrition, not overeating.''',
                      title: 'Nutritional Intelligence',
                    ),
                    child: SvgPicture.asset('assets/icons/info_round.svg'),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // AI рекомендации (динамические)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: RishColors.stroke,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: RishColors.primary,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Текст рекомендации
                          Text(
                            _recommendation ?? 'Loading recommendations...',
                            style: context.styles.regularMedium
                                .copyWith(color: RishColors.primary),
                            // textAlign: TextAlign.center,
                          ),
                          // Кнопка "Try again" при ошибке
                          if (_hasError) ...[
                            SizedBox(height: 16.h),
                            RishButton.secondary(
                              title: 'Try again',
                              action: () {
                                // Сбрасываем флаг ошибки и перезагружаем рекомендацию
                                setState(() {
                                  _hasError = false;
                                });
                                _loadRecommendation(forceRefresh: true);
                              },
                              width: double.infinity,
                            ),
                          ],
                        ],
                      ),
              ),
              SizedBox(height: 20.h),

              // Макросы с прогресс-барами
              ..._buildMacroWidgets(context, targetMacros, consumedMacros),
            ],
          ),
        );
      },
    );
  }

  /// Создает виджеты для отображения макросов
  List<Widget> _buildMacroWidgets(
    BuildContext context,
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    final macrosData = [
      _MacrosData(
        title: 'Calories',
        status: _getCaloriesStatus(targetMacros.kcal, consumedMacros.kcal),
        text: _getCaloriesText(targetMacros.kcal, consumedMacros.kcal),
        color: RishColors.calories,
        consumed: consumedMacros.kcal.toDouble(),
        target: targetMacros.kcal.toDouble(),
      ),
      _MacrosData(
        title: 'Proteins',
        status: _getProteinStatus(targetMacros.protein, consumedMacros.protein),
        text: _getProteinText(targetMacros.protein, consumedMacros.protein),
        color: RishColors.protein,
        consumed: consumedMacros.protein.toDouble(),
        target: targetMacros.protein.toDouble(),
      ),
      _MacrosData(
        title: 'Carbs',
        status: _getCarbsStatus(targetMacros.carbs, consumedMacros.carbs),
        text: _getCarbsText(targetMacros.carbs, consumedMacros.carbs),
        color: RishColors.carbs,
        consumed: consumedMacros.carbs.toDouble(),
        target: targetMacros.carbs.toDouble(),
      ),
      _MacrosData(
        title: 'Fats',
        status: _getFatsStatus(targetMacros.fat, consumedMacros.fat),
        text: _getFatsText(targetMacros.fat, consumedMacros.fat),
        color: RishColors.fat,
        consumed: consumedMacros.fat.toDouble(),
        target: targetMacros.fat.toDouble(),
      ),
    ];

    return macrosData.map((macro) => _MacroWidget(macro: macro)).toList();
  }

  // Методы для определения статуса калорий
  String _getCaloriesStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getCaloriesText(int target, int consumed) {
    // [numberFormatter] Форматируем числа с запятыми для тысяч
    final numberFormatter = NumberFormat('#,###');

    if (consumed < target) {
      final deficit = target - consumed;
      return 'You are in a deficit and need to consume ${numberFormatter.format(deficit)} more kcals.';
    } else {
      final surplus = consumed - target;
      return 'You are eating in a surplus and have consumed ${numberFormatter.format(surplus)} more than your daily target.';
    }
  }

  // Методы для определения статуса белков
  String _getProteinStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getProteinText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return "You are under-eating protein and need to consume $deficit grams to meet today's target.";
    } else {
      final surplus = consumed - target;
      return 'You have surpassed your protein target by $surplus grams for today.';
    }
  }

  // Методы для определения статуса углеводов
  String _getCarbsStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getCarbsText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return "You can still consume $deficit grams of carbs to meet today's target.";
    } else {
      final surplus = consumed - target;
      return 'You have surpassed your carbs target by $surplus grams for today.';
    }
  }

  // Методы для определения статуса жиров
  String _getFatsStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getFatsText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return "You can still consume $deficit grams of fats to meet today's target.";
    } else {
      final surplus = consumed - target;
      return 'You have surpassed your fats target by $surplus grams for today.';
    }
  }
}

/// Модель данных для макроса
class _MacrosData {
  _MacrosData({
    required this.title,
    required this.status,
    required this.text,
    required this.color,
    required this.consumed,
    required this.target,
  });

  final String title;
  final String status;
  final String text;
  final Color color;
  final double consumed;
  final double target;
}

/// Виджет для отображения одного макроса с прогресс-баром
class _MacroWidget extends StatelessWidget {
  const _MacroWidget({
    required this.macro,
  });

  final _MacrosData macro;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RishColors.stroke,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и статус
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                macro.title,
                style: context.styles.boldLarge.copyWith(
                  color: macro.color,
                ),
              ),
              Text(
                macro.status,
                style: context.styles.boldLarge.copyWith(
                  color: macro.color,
                ),
              ),
            ],
          ),

          // Описание
          Text(
            macro.text,
            style: context.styles.regularMedium,
          ),
        ],
      ),
    );
  }
}
