import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../../../models/workshop_model.dart';

class WorkshopRepository {
  final _api = ApiClient.instance;

  Future<Result<List<WorkshopModel>>> fetchWorkshops() {
    return _api.get<List<WorkshopModel>>(
      '/api/workshops',
      parser: (json) => (json as List).map((e) => WorkshopModel.fromJson(e)).toList(),
    );
  }
}
