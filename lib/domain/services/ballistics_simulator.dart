import 'dart:math' as math;

import '../../core/ball_constants.dart';
import '../../core/ballistics_constants.dart';
import '../models/trajectory_point.dart';

/// 抗力+マグヌス効果(揚力)を考慮したRK4数値積分による弾道シミュレーション(純粋関数)。
///
/// スピンは2Dのボール中心トラッキングのみでは実測できないため、呼び出し側が
/// バックスピン量・サイドスピン量を仮定値として渡す想定
/// (デフォルトは `BallisticsConstants` の仮定値)。
/// スピン軸は飛行中一定と仮定し、バックスピン軸は打ち出し方向に直交する水平軸、
/// サイドスピン軸は鉛直(Y)軸に固定する簡易モデルを採用する。
/// 揚力係数はBearman-Harveyの経験式 `Cl = 1 / (2 + 1/S)` (Sはスピン比)を用いる。
class BallisticsSimulator {
  const BallisticsSimulator._();

  static List<TrajectoryPoint> simulate({
    required double v0,
    required double launchAngleDegrees,
    required double launchDirectionDegrees,
    double backspinRpm = BallisticsConstants.assumedBackspinRpm,
    double sidespinRpm = BallisticsConstants.assumedSidespinRpm,
    double dt = 0.005,
    double dragCoefficient = BallisticsConstants.dragCoefficient,
    double airDensityKgPerCubicMeter =
        BallisticsConstants.airDensityKgPerCubicMeter,
    double ballMassKg = BallConstants.massKg,
    double ballRadiusMeters = BallConstants.radiusMeters,
  }) {
    final theta = launchAngleDegrees * math.pi / 180;
    final phi = launchDirectionDegrees * math.pi / 180;

    final up = const _Vector3(0, 1, 0);
    final right = _Vector3(math.cos(phi), 0, -math.sin(phi));

    final backspinRad = backspinRpm * 2 * math.pi / 60;
    final sidespinRad = sidespinRpm * 2 * math.pi / 60;
    // マグヌス力は velocity × omega の向きに働く。バックスピン軸(right)は
    // この向きのままで上向きの揚力になるが、サイドスピン軸(up)は符号を反転させないと
    // 正のサイドスピンが左曲がりになってしまうため、-up*sidespinRadとする。
    final omega = right * backspinRad - up * sidespinRad;

    final crossSectionArea = math.pi * ballRadiusMeters * ballRadiusMeters;
    final gravityForce = _Vector3(
      0,
      -ballMassKg * BallConstants.gravityMetersPerSecondSquared,
      0,
    );

    ({_Vector3 dPosition, _Vector3 dVelocity}) derivative(
      _Vector3 position,
      _Vector3 velocity,
    ) {
      final speed = velocity.length;
      var force = gravityForce;

      if (speed > 0) {
        final dragMagnitude =
            0.5 *
            airDensityKgPerCubicMeter *
            dragCoefficient *
            crossSectionArea *
            speed *
            speed;
        force = force + velocity.normalized() * -dragMagnitude;

        final omegaLength = omega.length;
        if (omegaLength > 0) {
          final spinRatio = (ballRadiusMeters * omegaLength) / speed;
          final liftCoefficient = 1 / (2 + 1 / spinRatio);
          final liftMagnitude =
              0.5 *
              airDensityKgPerCubicMeter *
              liftCoefficient *
              crossSectionArea *
              speed *
              speed;
          final magnusDirection = velocity.cross(omega);
          if (magnusDirection.length > 0) {
            force = force + magnusDirection.normalized() * liftMagnitude;
          }
        }
      }

      return (dPosition: velocity, dVelocity: force * (1 / ballMassKg));
    }

    var position = const _Vector3(0, 0, 0);
    var velocity = _Vector3(
      v0 * math.cos(theta) * math.sin(phi),
      v0 * math.sin(theta),
      v0 * math.cos(theta) * math.cos(phi),
    );
    var t = 0.0;

    final points = <TrajectoryPoint>[
      TrajectoryPoint(
        t: t,
        x: position.x,
        y: position.y,
        z: position.z,
        isMeasured: false,
      ),
    ];

    while (true) {
      final k1 = derivative(position, velocity);
      final k2 = derivative(
        position + k1.dPosition * (dt / 2),
        velocity + k1.dVelocity * (dt / 2),
      );
      final k3 = derivative(
        position + k2.dPosition * (dt / 2),
        velocity + k2.dVelocity * (dt / 2),
      );
      final k4 = derivative(
        position + k3.dPosition * dt,
        velocity + k3.dVelocity * dt,
      );

      final nextPosition =
          position +
          (k1.dPosition +
                  k2.dPosition * 2 +
                  k3.dPosition * 2 +
                  k4.dPosition) *
              (dt / 6);
      final nextVelocity =
          velocity +
          (k1.dVelocity +
                  k2.dVelocity * 2 +
                  k3.dVelocity * 2 +
                  k4.dVelocity) *
              (dt / 6);

      if (nextPosition.y <= 0) {
        final ratio = position.y / (position.y - nextPosition.y);
        final landingT = t + dt * ratio;
        final landingPosition =
            position + (nextPosition - position) * ratio;
        points.add(
          TrajectoryPoint(
            t: landingT,
            x: landingPosition.x,
            y: 0,
            z: landingPosition.z,
            isMeasured: false,
          ),
        );
        break;
      }

      position = nextPosition;
      velocity = nextVelocity;
      t += dt;
      points.add(
        TrajectoryPoint(
          t: t,
          x: position.x,
          y: position.y,
          z: position.z,
          isMeasured: false,
        ),
      );
    }

    return points;
  }
}

class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _Vector3 operator +(_Vector3 other) =>
      _Vector3(x + other.x, y + other.y, z + other.z);

  _Vector3 operator -(_Vector3 other) =>
      _Vector3(x - other.x, y - other.y, z - other.z);

  _Vector3 operator *(double scalar) =>
      _Vector3(x * scalar, y * scalar, z * scalar);

  double get length => math.sqrt(x * x + y * y + z * z);

  _Vector3 normalized() {
    final l = length;
    return l == 0 ? this : _Vector3(x / l, y / l, z / l);
  }

  _Vector3 cross(_Vector3 other) => _Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );
}
