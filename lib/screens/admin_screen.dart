import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

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
  final List<Map<String, dynamic>> _subjects = [
    {'id': '1', 'name': '정보처리와 관리', 'is_enabled': true, 'order_index': 1},
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
                          onChanged: (value) {
                            setState(() {
                              subject['is_enabled'] = value;
                            });
                          },
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('과목 추가'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: '과목명',
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
              // TODO: 과목 추가 로직
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _editSubject(Map<String, dynamic> subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('과목 수정'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: '과목명',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: subject['name']),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 과목 수정 로직
              Navigator.pop(context);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
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
            onPressed: () {
              setState(() {
                _subjects.removeAt(index);
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
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
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
                  value: selectedRole,
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
