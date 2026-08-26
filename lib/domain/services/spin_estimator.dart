import '../../core/ballistics_constants.dart';

/// 打ち出し方向とクラブパスの差(フェース・トゥ・パス)からサイドスピン量(rpm)を
/// 換算する(純粋関数)。
///
/// Dプレーン理論の経験則(打ち出し初期方向≈フェース角度)により、
/// フェース角度そのものを検出しなくても、打ち出し方向とクラブパスの差から
/// 曲がり幅の要因(フェース・トゥ・パス)を逆算できる。
class SpinEstimator {
  const SpinEstimator._();

  static double estimateSidespinRpm({
    required double launchDirectionDegrees,
    required double clubPathDegrees,
  }) {
    final faceToPathDegrees = launchDirectionDegrees - clubPathDegrees;
    return faceToPathDegrees *
        BallisticsConstants.sidespinRpmPerFaceToPathDegree;
  }
}
