import 'package:audioplayers/audioplayers.dart';

// 타이머 완료 시 사운드 재생 유틸리티
class SoundPlayer {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // 타이머 완료 알림음 반복 재생
  static Future<void> playCompletionSound() async {
    try {
      // ReleaseMode.loop로 설정하여 반복 재생
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('99AE7C445D542D7F13.mp3'));
    } catch (e) {
      // 사운드 재생 실패 시 에러 무시 (앱 동작에는 영향 없음)
      // 프로덕션에서는 로깅 프레임워크 사용 권장
    }
  }

  // 사운드 중지 (리셋 버튼 클릭 시)
  static Future<void> stopSound() async {
    await _audioPlayer.stop();
  }

  // AudioPlayer 리소스 해제
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
