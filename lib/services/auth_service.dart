import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// 현재 사용자 세션
  static Session? get currentSession => _supabase.auth.currentSession;

  /// 현재 JWT 토큰
  static String? get accessToken => currentSession?.accessToken;

  /// 현재 사용자 이메일
  static String? get userEmail => currentSession?.user.email;

  /// 로그인 상태 확인
  static bool get isLoggedIn => currentSession != null;

  /// 임시 로그인 (테스트용)
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Google OAuth 로그인
  static Future<bool> signInWithGoogle() async {
    try {
      // 개발 환경에서는 localhost, 운영 환경에서는 실제 도메인 사용
      final redirectUrl = kDebugMode
          ? null // localhost에서는 기본 리디렉션 사용
          : 'https://info.pocheonil.hs.kr/class/';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      return true;
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      return false;
    }
  }

  /// 로그아웃
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 인증 상태 변화 스트림
  static Stream<AuthState> get authStateStream =>
      _supabase.auth.onAuthStateChange;
}
