# Image Picker Service

Сервис для работы с выбором изображений и камерой в приложении.

## Возможности

- ✅ Выбор одного изображения из галереи
- ✅ Выбор нескольких изображений из галереи
- ✅ Съёмка фото с камеры
- ✅ Выбор нескольких медиафайлов (фото + видео)
- ✅ Запись видео с камеры
- ✅ Выбор видео из галереи
- ✅ Вспомогательные методы для конвертации XFile в File
- ✅ Проверка типа файла (изображение/видео)
- ✅ Готовые диалоги выбора источника (обычный и Apple-стиль)

## Использование

### Базовое использование ImagePickerService

```dart
// Создайте экземпляр сервиса
final imagePickerService = ImagePickerService();

// 1. Выбор одного изображения из галереи
final XFile? image = await imagePickerService.pickImageFromGallery(
  imageQuality: 80, // качество 0-100
  maxWidth: 1920,
  maxHeight: 1080,
);

if (image != null) {
  // Используйте изображение
  final File file = imagePickerService.xFileToFile(image);
}

// 2. Съёмка фото с камеры
final XFile? photo = await imagePickerService.takePhoto(
  imageQuality: 90,
  preferredCameraDevice: CameraDevice.rear, // или CameraDevice.front
);

// 3. Выбор нескольких изображений
final List<XFile> images = await imagePickerService.pickMultipleImages(
  imageQuality: 80,
  limit: 5, // максимум 5 изображений (работает на iOS 14+)
);

// 4. Выбор нескольких медиафайлов (фото + видео)
final List<XFile> media = await imagePickerService.pickMultipleMedia(
  imageQuality: 80,
  limit: 10,
);

// Конвертация в список File
final List<File> files = imagePickerService.xFilesToFiles(media);

// 5. Проверка типа файла
for (final file in media) {
  if (imagePickerService.isImage(file)) {
    print('Это изображение: ${file.name}');
  } else if (imagePickerService.isVideo(file)) {
    print('Это видео: ${file.name}');
  }
}
```

### Использование с диалогами (ImagePickerHelper)

```dart
// Создайте экземпляр helper'а
final imagePickerService = ImagePickerService();
final imagePickerHelper = ImagePickerHelper(imagePickerService);

// Вариант 1: Стандартный диалог
final dynamic result = await imagePickerHelper.showImageSourceDialog(
  context: context,
  imageQuality: 80,
  maxWidth: 1920,
  maxHeight: 1080,
  allowMultiple: false, // true для выбора нескольких изображений
);

if (result != null) {
  if (result is XFile) {
    // Одно изображение
    print('Выбрано изображение: ${result.path}');
  } else if (result is List<XFile>) {
    // Несколько изображений
    print('Выбрано ${result.length} изображений');
  }
}

// Вариант 2: Apple-стиль диалог (современный, элегантный UI)
final dynamic appleResult = await imagePickerHelper.showAppleStyleImageSourceDialog(
  context: context,
  imageQuality: 85,
  allowMultiple: true,
);
```

### Пример использования в виджете

```dart
class MyPhotoPickerWidget extends StatefulWidget {
  const MyPhotoPickerWidget({super.key});

  @override
  State<MyPhotoPickerWidget> createState() => _MyPhotoPickerWidgetState();
}

class _MyPhotoPickerWidgetState extends State<MyPhotoPickerWidget> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  late final ImagePickerHelper _imagePickerHelper;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _imagePickerHelper = ImagePickerHelper(_imagePickerService);
  }

  Future<void> _pickImage() async {
    // Показываем диалог выбора источника
    final result = await _imagePickerHelper.showAppleStyleImageSourceDialog(
      context: context,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
      allowMultiple: false,
    );

    if (result != null && result is XFile) {
      setState(() {
        _selectedImage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedImage != null)
          Image.file(
            File(_selectedImage!.path),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          )
        else
          const Placeholder(
            fallbackWidth: 200,
            fallbackHeight: 200,
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Выбрать фото'),
        ),
      ],
    );
  }
}
```

### Работа с несколькими изображениями (как в ContactPage)

```dart
class MultiImagePickerExample extends StatefulWidget {
  const MultiImagePickerExample({super.key});

  @override
  State<MultiImagePickerExample> createState() => _MultiImagePickerExampleState();
}

class _MultiImagePickerExampleState extends State<MultiImagePickerExample> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  List<XFile> _selectedImages = [];

  Future<void> _pickMultipleImages() async {
    final List<XFile> images = await _imagePickerService.pickMultipleMedia(
      imageQuality: 80,
      limit: 5,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        // Ограничиваем до 5 изображений
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(_selectedImages.length - 5);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Превью выбранных изображений
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final image = _selectedImages[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _imagePickerService.isImage(image)
                            ? Image.file(
                                File(image.path),
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.videocam, size: 40),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _removeImage(index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pickMultipleImages,
          child: const Text('Добавить фото/видео'),
        ),
      ],
    );
  }
}
```

## Разрешения

Не забудьте добавить необходимые разрешения в манифест приложения:

### iOS (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Нам нужен доступ к камере для съёмки фотографий</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Нам нужен доступ к галерее для выбора фотографий</string>
```

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>
```

## Особенности

### Apple-стиль диалог

Диалог в Apple-стиле (`showAppleStyleImageSourceDialog`) создан в соответствии с Apple Human Interface Guidelines:
- Современный минималистичный дизайн
- Скругленные углы (14px radius)
- Синий акцентный цвет для интерактивных элементов
- Отдельная кнопка "Отмена" внизу
- Плавные анимации и переходы
- Полупрозрачные разделители

Этот стиль идеально подходит для приложений, стремящихся к современному iOS-подобному UI.

## Зависимости

Сервис использует пакет `image_picker: ^1.1.2`, который уже добавлен в `pubspec.yaml`.

