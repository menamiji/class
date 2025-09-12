import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      // StreamBuilder가 자동으로 처리하므로 직접 네비게이션하지 않음
      await AuthService.signOut();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService.userEmail ?? '관리자';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class 관리자'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    UserService.getDisplayName(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'info',
                enabled: false,
                child: Text('로그인: $userEmail'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: '과목 관리'),
            Tab(icon: Icon(Icons.folder), text: '콘텐츠 관리'),
            Tab(icon: Icon(Icons.people), text: '권한 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SubjectManagementTab(),
          ContentManagementTab(),
          PermissionManagementTab(),
        ],
      ),
    );
  }
}

// 과목 관리 탭
class SubjectManagementTab extends StatefulWidget {
  const SubjectManagementTab({super.key});

  @override
  State<SubjectManagementTab> createState() => _SubjectManagementTabState();
}

class _SubjectManagementTabState extends State<SubjectManagementTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  final _addSubjectController = TextEditingController();
  final _editSubjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _addSubjectController.dispose();
    _editSubjectController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    debugPrint('🔍 DEBUG: Supabase에서 과목 데이터 로드 시도...');
    try {
      final response = await _supabase
          .from('subjects')
          .select('*')
          .order('order_index', ascending: true);

      debugPrint('🔍 DEBUG: Supabase 응답: $response');

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      debugPrint('🔍 DEBUG: 로드된 과목 수: ${_subjects.length}');

      // 테이블이 비어있으면 기본 데이터 추가 시도
      if (_subjects.isEmpty) {
        debugPrint('🔍 DEBUG: 테이블이 비어있음. 기본 데이터 추가 시도...');
        await _createDefaultSubject();
      }
    } catch (e) {
      debugPrint('🔍 DEBUG: Supabase 로드 오류: $e');
      // RLS 정책 문제나 테이블 없음 - 기본값으로 폴백하되 상태는 로딩 완료로 설정
      setState(() {
        _subjects = []; // 빈 배열로 시작
        _isLoading = false;
      });

      // 사용자에게 RLS 설정 필요 알림
      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('42501')) {
        debugPrint('🚨 DEBUG: RLS 정책 문제 - Supabase 대시보드에서 정책 설정 필요');
      }
    }
  }

  Future<void> _createDefaultSubject() async {
    try {
      final defaultSubject = {
        'name': '정보처리와 관리',
        'is_enabled': true,
        'order_index': 1,
      };

      debugPrint('🔍 DEBUG: 기본 과목 생성 시도: $defaultSubject');
      final response = await _supabase
          .from('subjects')
          .insert(defaultSubject)
          .select()
          .single();

      debugPrint('🔍 DEBUG: 기본 과목 생성 성공: $response');

      setState(() {
        _subjects = [response];
      });
    } catch (e) {
      debugPrint('🔍 DEBUG: 기본 과목 생성 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '과목 목록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
                label: const Text('과목 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: subject['is_enabled']
                          ? Colors.green
                          : Colors.grey,
                      child: Text('${subject['order_index']}'),
                    ),
                    title: Text(subject['name']),
                    subtitle: Text(subject['is_enabled'] ? '활성화됨' : '비활성화됨'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: subject['is_enabled'],
                          onChanged: (value) =>
                              _toggleSubjectEnabled(subject, value),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editSubject(subject);
                            } else if (value == 'delete') {
                              _deleteSubject(index);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addSubject() {
    debugPrint('🔧 DEBUG: _addSubject() 호출됨');
    _addSubjectController.clear(); // 입력 필드 초기화

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('과목 추가'),
        content: TextField(
          controller: _addSubjectController,
          decoration: const InputDecoration(
            labelText: '과목명',
            border: OutlineInputBorder(),
            hintText: '예: 정보처리와관리',
          ),
          autofocus: true,
          onSubmitted: (_) => _performAddSubject(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: _performAddSubject,
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAddSubject() async {
    final subjectName = _addSubjectController.text.trim();
    debugPrint('🔧 DEBUG: _performAddSubject() 호출됨 - 입력값: "$subjectName"');

    if (subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('과목명을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 중복 체크
    if (_subjects.any((subject) => subject['name'] == subjectName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 존재하는 과목입니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context);

    try {
      // Supabase에 새 과목 저장 시도
      final newOrderIndex = _subjects.length + 1;
      final newSubject = {
        'name': subjectName,
        'is_enabled': true,
        'order_index': newOrderIndex,
      };

      debugPrint('🔧 DEBUG: Supabase에 저장 시도: $newSubject');
      final response = await _supabase
          .from('subjects')
          .insert(newSubject)
          .select()
          .single();

      debugPrint('🔧 DEBUG: Supabase 저장 성공: $response');

      // 로컬 상태 업데이트
      setState(() {
        _subjects.add(response);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 과목 "$subjectName"이 Supabase에 저장되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('🔧 DEBUG: 과목 추가 완료: $subjectName, 총 개수: ${_subjects.length}');
    } catch (e) {
      debugPrint('🔧 DEBUG: Supabase 저장 오류: $e');

      String errorMessage = '데이터베이스 저장 실패';
      Color messageColor = Colors.red;

      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('42501')) {
        errorMessage = '🚨 RLS 정책 문제!\nSupabase 대시보드에서 관리자 정책을 추가해주세요.';
        messageColor = Colors.orange;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage\n과목: "$subjectName"'),
          backgroundColor: messageColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _toggleSubjectEnabled(
    Map<String, dynamic> subject,
    bool newValue,
  ) async {
    debugPrint('🔥 TOGGLE DEBUG: 시작');
    debugPrint('🔥 TOGGLE DEBUG: subject = $subject');
    debugPrint('🔥 TOGGLE DEBUG: newValue = $newValue');
    debugPrint('🔥 TOGGLE DEBUG: subject_id = ${subject["id"]}');
    debugPrint(
      '🔥 TOGGLE DEBUG: subject_id_type = ${subject["id"].runtimeType}',
    );

    try {
      // Supabase에 업데이트
      debugPrint('🔥 TOGGLE DEBUG: Supabase 업데이트 시도...');
      final result = await _supabase
          .from('subjects')
          .update({'is_enabled': newValue})
          .eq('id', subject['id']);

      debugPrint('🔥 TOGGLE DEBUG: Supabase 응답: $result');
      debugPrint('🔥 TOGGLE DEBUG: 업데이트 성공!');

      // 로컬 상태 업데이트
      setState(() {
        subject['is_enabled'] = newValue;
      });

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ "${subject["name"]}" ${newValue ? "활성화" : "비활성화"}되었습니다!',
          ),
          backgroundColor: newValue ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      debugPrint('🔧 DEBUG: 활성화 상태 변경 완료: ${subject["name"]} = $newValue');
    } catch (e) {
      debugPrint('🔥 TOGGLE DEBUG: 오류 발생!');
      debugPrint('🔥 TOGGLE DEBUG: 오류 타입: ${e.runtimeType}');
      debugPrint('🔥 TOGGLE DEBUG: 오류 내용: $e');
      debugPrint('🔥 TOGGLE DEBUG: 오류 문자열: ${e.toString()}');

      String errorMessage = '데이터베이스 업데이트 실패';
      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('42501')) {
        errorMessage = '🚨 RLS 정책 문제!\nSupabase 대시보드에서 관리자 정책을 추가해주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage\n과목: "${subject["name"]}"'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _editSubject(Map<String, dynamic> subject) {
    _editSubjectController.text = subject['name'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('과목 수정'),
        content: TextField(
          controller: _editSubjectController,
          decoration: const InputDecoration(
            labelText: '과목명',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => _performEditSubject(subject),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => _performEditSubject(subject),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Future<void> _performEditSubject(Map<String, dynamic> subject) async {
    final newSubjectName = _editSubjectController.text.trim();
    final originalName = subject['name'];

    if (newSubjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('과목명을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 변경사항이 없는 경우
    if (newSubjectName == originalName) {
      Navigator.pop(context);
      return;
    }

    // 중복 체크 (자신 제외)
    if (_subjects.any(
      (s) => s['id'] != subject['id'] && s['name'] == newSubjectName,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 존재하는 과목입니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context);

    try {
      // Supabase에 업데이트
      debugPrint(
        '🔧 DEBUG: Supabase에 과목명 업데이트 시도: $originalName → $newSubjectName',
      );
      await _supabase
          .from('subjects')
          .update({'name': newSubjectName})
          .eq('id', subject['id']);

      debugPrint('🔧 DEBUG: Supabase 과목명 업데이트 성공');

      // 로컬 상태 업데이트
      setState(() {
        final index = _subjects.indexWhere((s) => s['id'] == subject['id']);
        if (index != -1) {
          _subjects[index]['name'] = newSubjectName;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 과목이 "$newSubjectName"으로 Supabase에 저장되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('🔧 DEBUG: 과목명 수정 완료: $originalName → $newSubjectName');
    } catch (e) {
      debugPrint('🔧 DEBUG: Supabase 과목명 업데이트 실패: $e');

      String errorMessage = '데이터베이스 업데이트 실패';
      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('42501')) {
        errorMessage = '🚨 RLS 정책 문제!\nSupabase 대시보드에서 관리자 정책을 추가해주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ $errorMessage\n과목: "$originalName" → "$newSubjectName"',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _deleteSubject(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('과목 삭제'),
        content: const Text('정말로 이 과목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => _performDeleteSubject(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteSubject(int index) async {
    final subject = _subjects[index];
    final subjectName = subject['name'];

    debugPrint('🔥 DELETE DEBUG: 삭제 시작');
    debugPrint('🔥 DELETE DEBUG: index = $index');
    debugPrint('🔥 DELETE DEBUG: subject = $subject');
    debugPrint('🔥 DELETE DEBUG: subject_id = ${subject["id"]}');
    debugPrint(
      '🔥 DELETE DEBUG: subject_id_type = ${subject["id"].runtimeType}',
    );

    Navigator.pop(context);

    try {
      // Supabase에서 삭제
      debugPrint('🔥 DELETE DEBUG: Supabase 삭제 시도...');
      final result = await _supabase
          .from('subjects')
          .delete()
          .eq('id', subject['id']);

      debugPrint('🔥 DELETE DEBUG: Supabase 응답: $result');
      debugPrint('🔥 DELETE DEBUG: 삭제 성공!');

      // 로컬 상태에서 삭제
      setState(() {
        _subjects.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 과목 "$subjectName"이 Supabase에서 삭제되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint(
        '🔧 DEBUG: 과목 삭제 완료: $subjectName, 남은 개수: ${_subjects.length}',
      );
    } catch (e) {
      debugPrint('🔥 DELETE DEBUG: 오류 발생!');
      debugPrint('🔥 DELETE DEBUG: 오류 타입: ${e.runtimeType}');
      debugPrint('🔥 DELETE DEBUG: 오류 내용: $e');
      debugPrint('🔥 DELETE DEBUG: 오류 문자열: ${e.toString()}');

      String errorMessage = '데이터베이스 삭제 실패';
      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('42501')) {
        errorMessage = '🚨 RLS 정책 문제!\nSupabase 대시보드에서 관리자 정책을 추가해주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage\n과목: "$subjectName"'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

// 콘텐츠 관리 탭
class ContentManagementTab extends StatefulWidget {
  const ContentManagementTab({super.key});

  @override
  State<ContentManagementTab> createState() => _ContentManagementTabState();
}

class _ContentManagementTabState extends State<ContentManagementTab> {
  final List<Map<String, dynamic>> _categories = [
    {
      'name': '스프레드시트',
      'items': [
        {
          'name': '기본시트 작성',
          'files': [
            {'name': '데이터입력.xlsx', 'size': 102400},
            {'name': '함수활용.xlsx', 'size': 156800},
          ],
        },
        {
          'name': '차트 만들기',
          'files': [
            {'name': '차트예제.xlsx', 'size': 204800},
          ],
        },
      ],
    },
    {
      'name': '워드프로세서',
      'items': [
        {
          'name': '문서 작성',
          'files': [
            {'name': '기본문서.docx', 'size': 81920},
          ],
        },
      ],
    },
    {
      'name': '프레젠테이션',
      'items': [
        {
          'name': '발표 자료',
          'files': [
            {'name': '발표템플릿.pptx', 'size': 512000},
          ],
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '콘텐츠 관리',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _uploadContent,
                icon: const Icon(Icons.upload_file),
                label: const Text('파일 업로드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '저장 경로: /mnt/nas-class/content/<과목>/<카테고리>/<항목>/<파일명>',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, categoryIndex) {
                final category = _categories[categoryIndex];
                return ExpansionTile(
                  title: Text(
                    category['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: Icon(
                    _getCategoryIcon(category['name']),
                    color: Colors.deepPurple,
                  ),
                  children: [
                    ...category['items'].map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: ExpansionTile(
                          title: Text(item['name']),
                          leading: const Icon(Icons.folder_open, size: 20),
                          children: [
                            ...item['files'].map<Widget>((file) {
                              return ListTile(
                                contentPadding: const EdgeInsets.only(
                                  left: 64.0,
                                ),
                                leading: const Icon(
                                  Icons.insert_drive_file,
                                  size: 16,
                                ),
                                title: Text(file['name']),
                                subtitle: Text(_formatFileSize(file['size'])),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  onPressed: () =>
                                      _deleteFile(categoryIndex, item, file),
                                ),
                              );
                            }).toList(),
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 64.0),
                              leading: const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.green,
                              ),
                              title: const Text('파일 추가'),
                              onTap: () => _addFileToItem(
                                category['name'],
                                item['name'],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case '스프레드시트':
        return Icons.table_chart;
      case '워드프로세서':
        return Icons.description;
      case '프레젠테이션':
        return Icons.slideshow;
      default:
        return Icons.folder;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  void _uploadContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('콘텐츠 업로드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '항목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 파일 선택 로직
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('파일 선택'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 업로드 로직
              Navigator.pop(context);
            },
            child: const Text('업로드'),
          ),
        ],
      ),
    );
  }

  void _addFileToItem(String category, String item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$category > $item에 파일 추가'),
        content: ElevatedButton.icon(
          onPressed: () {
            // TODO: 파일 선택 및 업로드 로직
          },
          icon: const Icon(Icons.attach_file),
          label: const Text('파일 선택'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _deleteFile(
    int categoryIndex,
    Map<String, dynamic> item,
    Map<String, dynamic> file,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('${file['name']} 파일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item['files'].remove(file);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${file['name']} 파일이 삭제되었습니다'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// 권한 관리 탭
class PermissionManagementTab extends StatefulWidget {
  const PermissionManagementTab({super.key});

  @override
  State<PermissionManagementTab> createState() =>
      _PermissionManagementTabState();
}

class _PermissionManagementTabState extends State<PermissionManagementTab> {
  final List<Map<String, dynamic>> _users = [
    {
      'email': 'menamiji@pocheonil.hs.kr',
      'role': 'admin',
      'name': '관리자',
      'last_login': '2025-09-10 14:30:00',
    },
    {
      'email': '2510401@pocheonil.hs.kr',
      'role': 'student',
      'name': '김학생',
      'last_login': '2025-09-10 10:15:00',
    },
    {
      'email': '2510402@pocheonil.hs.kr',
      'role': 'student',
      'name': '이학생',
      'last_login': '2025-09-09 16:45:00',
    },
  ];

  final List<String> _allowedDomains = ['pocheonil.hs.kr'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '권한 관리',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 허용 도메인 설정
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '허용 도메인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allowedDomains
                        .map(
                          (domain) => Chip(
                            label: Text('@$domain'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _allowedDomains.remove(domain);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addDomain,
                    icon: const Icon(Icons.add),
                    label: const Text('도메인 추가'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 사용자 목록
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '사용자 목록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.person_add),
                label: const Text('사용자 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user['role']),
                      child: Icon(
                        _getRoleIcon(user['role']),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user['name'] ?? user['email']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email']),
                        Text(
                          '마지막 로그인: ${user['last_login']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: user['role'],
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('관리자'),
                            ),
                            DropdownMenuItem(
                              value: 'teacher',
                              child: Text('교사'),
                            ),
                            DropdownMenuItem(
                              value: 'student',
                              child: Text('학생'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                user['role'] = value;
                              });
                            }
                          },
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteUser(index);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.school;
      case 'student':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  void _addDomain() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('도메인 추가'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '도메인 (예: example.com)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _allowedDomains.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _addUser() {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        final nameController = TextEditingController();
        String selectedRole = 'student';

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('사용자 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: '역할',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('관리자')),
                    DropdownMenuItem(value: 'teacher', child: Text('교사')),
                    DropdownMenuItem(value: 'student', child: Text('학생')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (emailController.text.isNotEmpty &&
                      nameController.text.isNotEmpty) {
                    this.setState(() {
                      _users.add({
                        'email': emailController.text,
                        'role': selectedRole,
                        'name': nameController.text,
                        'last_login': '미접속',
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('추가'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteUser(int index) {
    final user = _users[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 삭제'),
        content: Text('${user['name']} (${user['email']}) 사용자를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _users.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
