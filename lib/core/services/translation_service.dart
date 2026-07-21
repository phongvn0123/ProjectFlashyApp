import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint =
      'https://api.mymemory.translated.net/get';

  Future<String> translateEnglishToVietnamese(String text) async {
    final normalizedText = text.trim();

    if (normalizedText.isEmpty) {
      throw const TranslationException(
        'Nội dung cần dịch không được để trống.',
      );
    }

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': normalizedText,
        'langpair': 'en|vi',
      },
    );

    http.Response response;

    try {
      response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
    } on Exception catch (error) {
      throw TranslationException(
        'Không thể kết nối đến dịch vụ dịch: $error',
      );
    }

    if (response.statusCode != 200) {
      throw TranslationException(
        'Yêu cầu dịch thất bại, mã lỗi ${response.statusCode}.',
      );
    }

    Map<String, dynamic> json;

    try {
      json = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>;
    } on FormatException {
      throw const TranslationException(
        'Dữ liệu dịch trả về không hợp lệ.',
      );
    }

    final responseStatus = json['responseStatus'];

    if (responseStatus != null &&
        responseStatus.toString() != '200') {
      final details = json['responseDetails']?.toString();

      throw TranslationException(
        details == null || details.trim().isEmpty
            ? 'Dịch vụ dịch từ chối yêu cầu.'
            : details,
      );
    }

    final responseData = json['responseData'];

    if (responseData is! Map<String, dynamic>) {
      throw const TranslationException(
        'API không trả về kết quả dịch.',
      );
    }

    final translatedText =
    responseData['translatedText']?.toString().trim();

    if (translatedText == null || translatedText.isEmpty) {
      throw const TranslationException(
        'Không tìm thấy bản dịch phù hợp.',
      );
    }

    // Đôi lúc API trả lại nguyên văn khi không dịch được.
    if (translatedText.toLowerCase() ==
        normalizedText.toLowerCase()) {
      throw const TranslationException(
        'Không tìm thấy nghĩa tiếng Việt phù hợp.',
      );
    }

    return translatedText;
  }

  void dispose() {
    _client.close();
  }
}

class TranslationException implements Exception {
  const TranslationException(this.message);

  final String message;

  @override
  String toString() => message;
}