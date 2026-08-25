// test/features/analyzing/analysis_controller_test.dart
//
// analyze()は同じ動画・同じタップ位置に対しては決定論的に失敗するため、
// Riverpodの標準リトライ(最大10回、指数バックオフ)は意味が無く、実機では
// 1回あたりの解析コスト(全フレームへの実推論)が大きいため「解析中」画面が
// 極端に長く止まって見える問題があった。リトライ回数を3回までに制限する
// analysisRetryPolicy を対象にした単体テスト。
import 'package:dan_do/features/analyzing/analysis_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analysisRetryPolicy', () {
    test('3回目までのリトライ(retryCount=0,1,2)は再試行間隔を返す', () {
      final error = Exception('解析エラーのテスト用');
      expect(analysisRetryPolicy(0, error), isNotNull);
      expect(analysisRetryPolicy(1, error), isNotNull);
      expect(analysisRetryPolicy(2, error), isNotNull);
    });

    test('4回目以降(retryCount>=3)はnullを返しリトライを打ち切る', () {
      final error = Exception('解析エラーのテスト用');
      expect(analysisRetryPolicy(3, error), isNull);
      expect(analysisRetryPolicy(10, error), isNull);
    });
  });
}
