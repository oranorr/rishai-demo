double kjToKcal = 0.239006;
double kgToLbs = 2.205;

/// Версия схемы данных Hive
///
/// ВАЖНО: Эту версию нужно увеличивать при любом изменении схемы данных:
/// - Добавление новых @HiveType или @HiveField
/// - Изменение typeId или номеров HiveField
/// - Изменение структуры существующих сущностей
/// - Добавление новых enum значений
///
const int hiveSchemaVersion = 4;

//Если возвращает false — то прила начнет тащить данные с вупа

// bool whoopDateDifference(DateTime askTime) {
//   final now = DateTime.now();
//   final diff = now.difference(askTime);
//   // print(diff);
//   return kDebugMode ? diff.inMinutes < 1 : diff.inDays <= 1;
//   // return kDebugMode ? diff.inMinutes < 50 : diff.inDays <= 1;
// }

// bool chatIsActual(DateTime askTime) {
//   final now = DateTime.now();

//   return now.year == askTime.year &&
//       now.month == askTime.month &&
//       now.day == askTime.day;
// }

bool emptifyWhoopData = false;
