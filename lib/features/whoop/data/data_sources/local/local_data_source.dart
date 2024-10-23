import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';

abstract class WhoopLocalDataSource {
  Future<void> saveData({required WhoopDataEntity data});
  Future<WhoopDataEntity?> fetchSavedData();
}
