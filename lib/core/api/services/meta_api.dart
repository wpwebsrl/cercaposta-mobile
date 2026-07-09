import '../../../shared/models/meta.dart';
import '../dio_factory.dart';
import '../json.dart';

/// Discovery: validate an arbitrary server URL before selecting it.
class MetaApi {
  Future<MetaInfo> fetch(String origin) async {
    final dio = buildDio('$origin/api/v1');
    final resp = await dio.get<dynamic>('/meta');
    return MetaInfo.fromJson(mapOf(resp.data));
  }
}
