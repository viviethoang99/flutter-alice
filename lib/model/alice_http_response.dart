class AliceHttpResponse {
  int status = 0;
  int size = 0;
  DateTime time = DateTime.now();
  bool isDataDecoded = false;
  dynamic body;
  Map<String, String>? headers;
}
