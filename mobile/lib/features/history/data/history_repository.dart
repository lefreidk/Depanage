import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../../../models/tow_request_model.dart';

class HistoryRepository {
  final _api = ApiClient.instance;

  Future<Result<List<TowRequestModel>>> fetchHistory() {
    return _api.get<List<TowRequestModel>>(
      '/api/requests/history',
      parser: (json) => (json as List).map((e) => TowRequestModel.fromJson(e)).toList(),
    );
  }
}
