# CustomMealsSection Library

Библиотека для управления кастомными блюдами в дневнике питания.

## Структура

```
custom_meals_section/
├── custom_meals_section.dart     # Главный экспорт библиотеки
├── widgets/
│   ├── custom_meal_item.dart     # Виджет одного блюда
│   ├── meal_type_selector.dart   # Селектор типа приема пищи
│   ├── photos_gallery.dart       # Галерея фотографий с плейсхолдерами
│   ├── photo_preview_item.dart   # Превью фотографии
│   ├── photo_placeholder.dart    # Плейсхолдер для пустого слота
│   ├── camera_button.dart        # Кнопка камеры
│   └── dashed_border_painter.dart # CustomPainter для пунктирной границы
└── README.md
```

## Использование

```dart
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/custom_meals_section.dart';

// В вашем виджете
const CustomMealsSection()
```

## Основные компоненты

### CustomMealsSection
Главный виджет секции. Отображает список кастомных блюд и кнопку "Add more".

**Функции:**
- Отображение массива блюд из `customMeals` в стейте кубита
- Кнопка "Add more" для добавления новых блюд
- Автоматическое управление состоянием через BLoC

### CustomMealItem
Виджет для одного кастомного блюда.

**Функции:**
- Dropdown с автоматическим expand/collapse
- Галерея фотографий (3 слота с плейсхолдерами)
- Селектор типа приема пищи
- Текстовое поле описания
- Кнопка камеры для добавления фото
- Кнопка "Send" для отправки на анализ
- Кнопка "Delete meal" (если блюд > 1)

### PhotosGallery
Галерея с 3 слотами для фотографий.

**Особенности:**
- Всегда отображает 3 слота
- Занятые слоты = превью фото
- Пустые слоты = плейсхолдеры с пунктирной границей

### MealTypeSelector
Селектор типа приема пищи (завтрак, обед, ужин, перекус).

**UI/UX:**
- Радиокнопки для каждого типа
- Разделители между элементами
- Primary цвет для выбранного элемента

## События BLoC

Библиотека использует следующие события кубита:

- `CustomMealAdd` - добавить новое блюдо
- `CustomMealRemove` - удалить блюдо
- `CustomMealUpdatePhotos` - обновить список фото
- `CustomMealAddPhoto` / `CustomMealAddPhotos` - добавить фото
- `CustomMealRemovePhoto` - удалить фото
- `CustomMealUpdateDescription` - обновить описание
- `CustomMealSetMealType` - установить тип приема пищи

## Дизайн

Библиотека следует **Apple Human Interface Guidelines**:

- ✅ Минималистичный дизайн
- ✅ Плавные анимации
- ✅ Понятные визуальные подсказки (плейсхолдеры)
- ✅ Четкая иерархия информации
- ✅ Адаптивные размеры через ScreenUtil

## Зависимости

- `flutter_bloc` - управление состоянием
- `flutter_screenutil` - адаптивные размеры
- `image_picker` - выбор фотографий
- Внутренние зависимости проекта (DI, темы, сервисы)

