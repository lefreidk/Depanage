import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';

class RatingRepository {
  final _api = ApiClient.instance;

  Future<Result<void>> rateTrip(String tripId, int rating, List<String> tags) {
    return _api.post<void>(
      '/api/trips/$tripId/rate',
      body: {'rating': rating, 'tags': tags},
      parser: (_) {},
    );
  }
}
