import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';

class DriverRepository {
  final _api = ApiClient.instance;

  Future<Result<void>> apply({
    required String fullName,
    required String licenseNumber,
    required String licenseExpiry,
    required String plateNumber,
    required int vehicleYear,
    required List<String> vehicleTypes,
    required Map<String, String?> documents,
  }) {
    return _api.post<void>(
      '/api/drivers/apply',
      body: {
        'fullName': fullName,
        'licenseNumber': licenseNumber,
        'licenseExpiry': licenseExpiry,
        'plateNumber': plateNumber,
        'vehicleYear': vehicleYear,
        'vehicleTypes': vehicleTypes,
        'documents': documents,
      },
      parser: (_) {},
    );
  }
}
