import 'redisTerpiezInfo.dart';

Future<Map<String, dynamic>?> fetchFirstTerpiezWithName(
    Redisterpiezinfo redisInfo) async {
  final locations = await redisInfo.getTerpiezLocations();

  if (locations.isNotEmpty) {
    final first = locations.first;
    final terpiezDetails = await redisInfo.getTerpiezInfo(first['id']);
    final imageData =
        await redisInfo.fetchImageDataFromRedis(terpiezDetails['image']);

    return {
      ...first,
      'name': terpiezDetails['name'] ?? 'Unknown',
      'image64': imageData['image64'],
    };
  } else {
    return null;
  }
}
