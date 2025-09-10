import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class UserService {
  static final _supabase = Supabase.instance.client;

  /// 사용자 역할 확인
  static Future<String> getUserRole() async {
    final userEmail = AuthService.userEmail;
    if (userEmail == null) return 'guest';

    try {
      // 초기 관리자 이메일 확인
      if (userEmail == 'menamiji@pocheonil.hs.kr' ||
          userEmail == 'menamiji@gmail.com') {
        return 'admin';
      }

      // Supabase roles 테이블에서 역할 확인 (향후 구현)
      final userId = AuthService.currentSession?.user.id;
      if (userId != null) {
        final response = await _supabase
            .from('roles')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null && response['role'] != null) {
          return response['role'] as String;
        }
      }

      // 기본적으로 @pocheonil.hs.kr 도메인은 학생
      if (userEmail.endsWith('@pocheonil.hs.kr')) {
        return 'student';
      }

      return 'student';
    } catch (e) {
      debugPrint('역할 확인 오류: $e');
      // 오류 시 이메일 기반으로 판단
      if (userEmail == 'menamiji@pocheonil.hs.kr' ||
          userEmail == 'menamiji@gmail.com') {
        return 'admin';
      }
      return 'student';
    }
  }

  /// 관리자 여부 확인
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  /// 학생번호 추출 (이메일 로컬 파트)
  static String? getStudentNumber() {
    final userEmail = AuthService.userEmail;
    if (userEmail == null) return null;

    return userEmail.split('@')[0];
  }

  /// 사용자 표시명 생성
  static String getDisplayName() {
    final userEmail = AuthService.userEmail;
    if (userEmail == null) return '사용자';

    if (userEmail == 'menamiji@pocheonil.hs.kr' ||
        userEmail == 'menamiji@gmail.com') {
      return '관리자';
    }

    return userEmail.split('@')[0];
  }
}
