import 'dart:convert';

import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';

class AliceHttpCall {
  final int id;
  String client = "";
  bool loading = true;
  bool secure = false;
  String method = "";
  String endpoint = "";
  String server = "";
  String uri = "";
  int duration = 0;

  AliceHttpRequest? request;
  AliceHttpResponse? response;
  AliceHttpError? error;

  AliceHttpCall(this.id) {
    loading = true;
  }

  setResponse(AliceHttpResponse response) {
    this.response = response;
    loading = false;
  }

  String getCurlCommand() {
    bool compressed = false;
    final List<String> lines = [];
    lines.add('curl \\');
    lines.add('  -X $method \\');
    final headers = Map<String, dynamic>.from(request?.headers ?? {});
    headers.remove('content-length');
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'accept-encoding' && value == 'gzip') {
        compressed = true;
      }
      lines.add("  -H '${key}: ${value}' \\");
    });
    if (request?.body != null && request!.body.toString().isNotEmpty) {
      try {
        final requestBody = jsonEncode(request?.body);
        final escaped = requestBody
            .replaceAll('\\', r'\\')
            .replaceAll('"', r'\"')
            .replaceAll('\n', r'\n');
        lines.add('  --data "$escaped" \\');
      } catch (_) {
        final escaped = request!.body
            .toString()
            .replaceAll('\\', r'\\')
            .replaceAll('"', r'\"')
            .replaceAll('\n', r'\n');
        lines.add('  --data "$escaped" \\');
      }
    }
    final formDataFields = request?.formDataFields;
    if (formDataFields != null && formDataFields.isNotEmpty) {
      for (final field in formDataFields) {
        lines.add("  --form '${field.name}=${field.value}' \\");
      }
    }
    final formDataFiles = request?.formDataFiles;
    if (formDataFiles != null && formDataFiles.isNotEmpty) {
      for (final file in formDataFiles) {
        lines.add("  --form '${file.fileName}=@${file.fileName}' \\");
      }
    }
    String query = '';
    if (request?.queryParameters != null &&
        request!.queryParameters.isNotEmpty) {
      final queryParams = request!.queryParameters;
      query = '?' +
          queryParams.entries
              .map((e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
              .join('&');
    }
    if (compressed) {
      lines.add('  --compressed \\');
    }
    final url = "${secure ? 'https' : 'http'}://$server$endpoint$query";
    lines.add('  "$url"');
    return lines.join('\n');
  }
}
