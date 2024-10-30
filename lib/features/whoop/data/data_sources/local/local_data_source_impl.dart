import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';

@Singleton(as: WhoopLocalDataSource)
class WhoopLocalDataSourceImpl implements WhoopLocalDataSource {
  @override
  Future<WhoopDataEntity?> fetchSavedData() async {
    final data = await hive.retrieveLastData();
    return data;
    // if (data != null) {
    //   final then = data.askTime;
    //   // return data;
    //   if (whoopDateDifference(then)) {
    //     return data;
    //   } else {
    //     return null;
    //   }
    // } else {
    //   return null;
    // }
  }

  @override
  Future<void> saveData({required WhoopDataEntity data}) async {
    await hive.saveWhoopData(data: data);
  }
}
