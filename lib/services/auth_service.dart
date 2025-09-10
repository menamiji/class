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
      // 웹 환경에서는 현재 페이지(서브패스 포함)로 리디렉션,
      // 그 외(모바일/데스크톱)에서는 운영 도메인 사용
      String? redirectUrl;
      if (kIsWeb) {
        final current = Uri
            .base; // e.g., https://info.pocheonil.hs.kr/class/ or http://localhost:5173/
        final base = '${current.origin}${current.path}';
        redirectUrl = base.endsWith('/') ? base : '$base/';
      } else if (!kDebugMode) {
        redirectUrl = 'https://info.pocheonil.hs.kr/class/';
      }

      if (kIsWeb) {
        // 웹 환경에서는 리디렉션이 발생하므로 바로 성공으로 처리
        _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
        return true;
      } else {
        // 모바일/데스크톱 환경에서는 응답을 기다림
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
        return true;
      }
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
