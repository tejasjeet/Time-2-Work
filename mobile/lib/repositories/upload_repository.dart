import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';

class UploadRepository {
  UploadRepository(this._api);

  final ApiClient _api;

  Future<({String url, String type})> uploadChatMedia(String filePath) async {
    final name = filePath.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: name),
    });
    final body = await _api.postMultipart('/uploads/chat', form);
    final map = unwrapMap(body);
    return (
      url: readString(map, ['url']) ?? '',
      type: readString(map, ['type']) ?? 'image',
    );
  }
}
