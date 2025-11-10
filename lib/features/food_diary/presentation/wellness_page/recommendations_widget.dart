part of 'wellness_page.dart';

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
  static String _formatMacrosList(List<String> macros) {
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
      deficitMacrosFormatted: _formatMacrosList(deficitMacros),
      surplusMacrosFormatted: _formatMacrosList(surplusMacros),
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

  // Кэш рекомендаций: ключ - хеш макросов, значение - рекомендация
  static final Map<String, String> _recommendationCache = {};

  // Последний ключ кэша для отслеживания изменений
  String? _lastCacheKey;

  @override
  void initState() {
    super.initState();
    // Загружаем рекомендации при открытии виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendation();
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

    // Проверяем, изменились ли данные
    if (!forceRefresh && cacheKey == _lastCacheKey && _recommendation != null) {
      // Данные не изменились, рекомендация уже загружена
      return;
    }

    _lastCacheKey = cacheKey;

    // Анализируем макросы
    final analysis = _MacrosAnalyzer.analyze(targetMacros, consumedMacros);

    // Определяем, нужен ли запрос к API
    final needsApiRequest = analysis.scenario == 2;

    // Проверяем кэш для всех сценариев
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
        if (analysis.surplusMacros.isNotEmpty) {
          hardcodedMessage =
              'You are in a deficit for calories for the day along with ${analysis.deficitMacrosFormatted}, but you have met your ${analysis.surplusMacrosFormatted} targets for the day. You still have some ${analysis.deficitMacrosFormatted} available to consume.';
        } else {
          hardcodedMessage =
              'You are in a deficit for calories for the day along with ${analysis.deficitMacrosFormatted}. You still have some ${analysis.deficitMacrosFormatted} available to consume.';
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

        // Формируем запрос
        final request = RecommendationRequest(
          foodPreferences: {
            'diets': foodPreferences.diets,
            'cuisines': foodPreferences.cuisines,
            'restrictions': foodPreferences.restrictions,
          },
          consumedMacros: consumedMacros.toMap(),
          targetMacros: targetMacros.toMap(),
        );

        // Запрашиваем рекомендацию от ИИ
        final aiRecommendation =
            await llmProxyClient.getRecommendation(request);

        if (mounted) {
          String finalRecommendation;
          // Объединяем хардкодед часть и AI рекомендацию
          if (aiRecommendation != null && aiRecommendation.isNotEmpty) {
            finalRecommendation =
                '$hardcodedMessage\n\nI would recommend you eat something high in ${analysis.deficitMacrosFormatted}, while low in ${analysis.surplusMacrosFormatted} - such as $aiRecommendation';
          } else {
            // Если API вернул null, показываем только хардкодед сообщение
            finalRecommendation = hardcodedMessage;
          }

          // Сохраняем в кэш
          _recommendationCache[cacheKey] = finalRecommendation;

          setState(() {
            _isLoading = false;
            _recommendation = finalRecommendation;
          });
        }
      } catch (e) {
        // При ошибке показываем только хардкодед сообщение
        if (mounted) {
          setState(() {
            _isLoading = false;
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
                    'Recommendations',
                    style: context.styles.boldLarge,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => () {},
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
                    : Text(
                        _recommendation ?? 'Loading recommendations...',
                        style: context.styles.regularMedium
                            .copyWith(color: RishColors.primary),
                        textAlign: TextAlign.center,
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
    if (consumed < target) {
      final deficit = target - consumed;
      return 'You are in a deficit and need to consume $deficit more kcals.';
    } else {
      final surplus = consumed - target;
      return 'You are eating in a surplus and have consumed $surplus more than your daily target.';
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
