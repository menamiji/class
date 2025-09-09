import 'package:http/http.dart' as http;

class ClassApiClient {
  final String baseUrl; // 예: https://info.pocheonil.hs.kr
  final String? jwt;

  ClassApiClient({required this.baseUrl, required this.jwt});

  Map<String, String> _auth() => {
    'Authorization': 'Bearer $jwt',
    'Content-Type': 'application/json',
  };

  /// 파일 업로드
  Future<http.Response> uploadFile(String filePath) async {
    final uri = Uri.parse('$baseUrl/class/api/submissions/upload');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Authorization': 'Bearer $jwt'})
      ..files.add(await http.MultipartFile.fromPath('files', filePath));
    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }

  /// 오늘 제출 목록 조회
  Future<http.Response> listToday(String yyyymmdd) async {
    final uri = Uri.parse('$baseUrl/class/api/submissions?date=$yyyymmdd');
    return http.get(uri, headers: _auth());
  }

  /// 파일 삭제
  Future<http.Response> deleteFile(String yyyymmdd, String filename) async {
    final uri = Uri.parse(
      '$baseUrl/class/api/submissions/file?date_key=$yyyymmdd&filename=$filename',
    );
    return http.delete(uri, headers: _auth());
  }

  /// 헬스체크
  Future<http.Response> healthCheck() async {
    final uri = Uri.parse('$baseUrl/class/api/healthz');
    return http.get(uri);
  }

  /// 과목 콘텐츠 목록 조회
  Future<http.Response> getSubjectContents(String subjectId) async {
    final uri = Uri.parse('$baseUrl/class/api/subjects/$subjectId/contents');
    return http.get(uri, headers: _auth());
  }
}
