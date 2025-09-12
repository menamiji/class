import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late ClassApiClient _apiClient;
  List<dynamic> _submissions = [];
  bool _isLoading = false;
  String _today = '';

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyyMMdd').format(DateTime.now());

    final jwt = AuthService.accessToken;
    _apiClient = ClassApiClient(
      baseUrl: 'https://info.pocheonil.hs.kr',
      jwt: jwt,
    );

    // 백엔드 API가 구현될 때까지 임시 비활성화
    // _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.listToday(_today);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['data'] != null) {
          setState(() {
            _submissions = data['data']['files'] ?? [];
          });
        }
      } else {
        _showError('제출 목록을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      _showError('네트워크 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        for (final file in result.files) {
          if (file.path != null) {
            final response = await _apiClient.uploadFile(file.path!);

            if (response.statusCode != 200) {
              _showError('${file.name} 업로드 실패: ${response.statusCode}');
            }
          }
        }

        _showSuccess('${result.files.length}개 파일이 업로드되었습니다!');
        _loadSubmissions(); // 목록 새로고침
      } catch (e) {
        _showError('파일 업로드 중 오류 발생: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFile(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('$filename을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final response = await _apiClient.deleteFile(_today, filename);

        if (response.statusCode == 200) {
          _showSuccess('$filename이 삭제되었습니다');
          _loadSubmissions(); // 목록 새로고침
        } else {
          _showError('파일 삭제 실패: ${response.statusCode}');
        }
      } catch (e) {
        _showError('파일 삭제 중 오류 발생: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      // StreamBuilder가 자동으로 처리하므로 직접 네비게이션하지 않음
      await AuthService.signOut();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService.userEmail ?? '사용자';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class 파일 제출'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text(userEmail), const Icon(Icons.arrow_drop_down)],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('로그아웃'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘 날짜: $_today',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('제출된 파일: ${_submissions.length}개'),
              ],
            ),
          ),

          // 파일 업로드 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('파일 업로드'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          // 제출된 파일 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSubmissions,
                    child: _submissions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '아직 제출된 파일이 없습니다',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text('위의 "파일 업로드" 버튼을 눌러 파일을 제출하세요'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _submissions.length,
                            itemBuilder: (context, index) {
                              final file = _submissions[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.blue,
                                  ),
                                  title: Text(file['name'] ?? '알 수 없는 파일'),
                                  subtitle: Text(
                                    '크기: ${_formatFileSize(file['size'] ?? 0)}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteFile(file['name'] ?? ''),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
