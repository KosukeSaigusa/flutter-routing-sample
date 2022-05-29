import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// 実際のレスポンスの代わりに対応する JSON の Mock データを返す
/// HTTP リクエストのインターセプタ。
class MockInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // JSON ファイルを特定して読み込む。
      // {rootDir}/assets/json/mock/ 以下の階層に
      // API の URL パスに対応する JSON ファイルが保存されている想定。
      final jsonFilePath = _getJsonFilePathFromRequestOptions(options);
      final byteData = await rootBundle.load(jsonFilePath);

      // JSON ファイルの内容を UTF-8 デコードする
      final dynamic data = json.decode(
        utf8.decode(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        ),
      );

      return handler.resolve(
        Response<dynamic>(
          data: data,
          // TODO: 期待されるステータスコードは API によって異なるはずだが
          //  どのようにして指定できるか調査して対応する。
          //  Request.options.method で期待されるステータスコードは特定できそう。
          //  または、API の URL パスか HTTP メソッドと成功レスポンスのステータスコードとの
          //  マッピングを定義しておくなど？
          statusCode: 200,
          requestOptions: options,
        ),
      );
    } on Exception {
      return handler.resolve(
        Response<dynamic>(
          // data: null,
          statusCode: 404,
          requestOptions: options,
        ),
      );
    }
  }

  /// HTTP リクエストのパスから、モックの JSON ファイルを特定する。
  /// 余分なパスパラメータがあれば、必要に応じてそれを正規表現で検証して
  /// 適切な JSON ファイルを特定できるようにする。
  String _getJsonFilePathFromRequestOptions(RequestOptions options) {
    // RequestOptions.path は URL パスであって、apiBaseURL は含まれていない。
    var path = options.path;

    // 末尾スラッシュを削除する
    path = path.replaceFirst(RegExp(r'/$'), '');

    // 正規表現による検証をここに列挙する
    // if (someRegExp.hasMatch(path)) {
    //   path = '...';
    // }

    // JSON ファイルのパスを作成して返す
    return baseDir + path + extension;
  }

  static const baseDir = 'assets/json/mock';
  static const extension = '.json';
}
