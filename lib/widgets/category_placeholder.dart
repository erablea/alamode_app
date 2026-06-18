import 'dart:math' as math;
import 'package:flutter/material.dart';

class CategoryPlaceholder extends StatelessWidget {
  final String? category;
  final double height;

  const CategoryPlaceholder({super.key, this.category, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFF2F2F2),
      child: CustomPaint(
        painter: _getPainter(category),
      ),
    );
  }

  CustomPainter _getPainter(String? category) {
    switch (category) {
      case 'クッキー':
        return _CookiePainter();
      case 'ショコラ':
        return _ChocolatePainter();
      case 'ゼリー・プリン':
        return _PuddingPainter();
      case '和菓子':
        return _WagashiPainter();
      case '焼き菓子':
        return _BakedPainter();
      case 'キャンディ':
      case 'キャンデー':
        return _CandyPainter();
      case 'ケーキ':
        return _CakePainter();
      default:
        return _DefaultSweetPainter();
    }
  }
}

// ─── 共通カラー ───────────────────────────────────────────
const _c1 = Color(0xFFBBBBBB); // 濃いグレー（輪郭・影）
const _c2 = Color(0xFFD4D4D4); // 中間グレー（面）
const _c3 = Color(0xFFE8E8E8); // 薄いグレー（ハイライト）
const _c4 = Color(0xFFF2F2F2); // 背景と同色（抜き）

// ─── クッキー ─────────────────────────────────────────────
class _CookiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.34;

    final fill = Paint()..color = _c2;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dot = Paint()..color = _c1;
    final chip = Paint()..color = _c1;

    // 本体
    canvas.drawCircle(Offset(cx, cy), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, border);

    // ぎざぎざ縁
    final path = Path();
    const n = 16;
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi / n) * i;
      final outerR = r + 4;
      final innerR = r - 1;
      final rr = i.isEven ? outerR : innerR;
      final x = cx + rr * math.cos(angle);
      final y = cy + rr * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = _c1
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // チョコチップ（不規則な楕円）
    final chips = [
      Offset(cx - r * 0.3, cy - r * 0.2),
      Offset(cx + r * 0.2, cy - r * 0.35),
      Offset(cx + r * 0.3, cy + r * 0.1),
      Offset(cx - r * 0.15, cy + r * 0.3),
      Offset(cx - r * 0.4, cy + r * 0.1),
      Offset(cx + r * 0.05, cy + r * 0.05),
    ];
    for (final o in chips) {
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(0.4);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 5, height: 3.5), chip);
      canvas.restore();
    }

    // 穴（テクスチャ）
    for (final o in [
      Offset(cx + r * 0.1, cy - r * 0.1),
      Offset(cx - r * 0.25, cy - r * 0.05),
    ]) {
      canvas.drawCircle(o, 1.5, dot);
    }

    // ハイライト
    canvas.drawCircle(
        Offset(cx - r * 0.3, cy - r * 0.3),
        r * 0.18,
        Paint()..color = _c3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ショコラ ─────────────────────────────────────────────
class _ChocolatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bw = size.width * 0.55;
    final bh = size.height * 0.55;

    final fill = Paint()..color = _c2;
    final shadow = Paint()..color = _c1;
    final line = Paint()
      ..color = _c1
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final groove = Paint()
      ..color = _c3
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 影（少し右下にずらす）
    final shadowRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx + 3, cy + 3), width: bw, height: bh),
        const Radius.circular(4));
    canvas.drawRRect(shadowRect, shadow);

    // 本体
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh),
        const Radius.circular(4));
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, line);

    // グリッド（3×4分割）
    const cols = 3;
    const rows = 4;
    final left = cx - bw / 2 + 4;
    final top = cy - bh / 2 + 4;
    final right = cx + bw / 2 - 4;
    final bottom = cy + bh / 2 - 4;

    for (int c = 1; c < cols; c++) {
      final x = left + (right - left) * c / cols;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), groove);
    }
    for (int r = 1; r < rows; r++) {
      final y = top + (bottom - top) * r / rows;
      canvas.drawLine(Offset(left, y), Offset(right, y), groove);
    }

    // ハイライト
    final hlRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bw / 2 + 6, cy - bh / 2 + 6, bw * 0.3, bh * 0.15),
        const Radius.circular(3));
    canvas.drawRRect(hlRect, Paint()..color = _c3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ゼリー・プリン ───────────────────────────────────────
class _PuddingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final fill = Paint()..color = _c2;
    final dark = Paint()..color = _c1;
    final light = Paint()..color = _c3;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // カラメル（底）
    final caramel = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * 0.22),
            width: size.width * 0.52,
            height: size.height * 0.14),
        const Radius.circular(4));
    canvas.drawRRect(caramel, dark);

    // プリン本体（ドーム）
    final bodyPath = Path();
    final bw = size.width * 0.46;
    final bh = size.height * 0.55;
    final bodyRect =
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh);

    bodyPath.addArc(bodyRect, math.pi, math.pi); // 上半円
    bodyPath.lineTo(cx + bw / 2, cy + bh * 0.2); // 右側面
    // 底の台形
    bodyPath.lineTo(cx + bw * 0.38, cy + bh * 0.46);
    bodyPath.lineTo(cx - bw * 0.38, cy + bh * 0.46);
    bodyPath.lineTo(cx - bw / 2, cy + bh * 0.2);
    bodyPath.close();

    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, border);

    // 段（プリンの層）
    final lineP = Paint()
      ..color = _c1
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx - bw * 0.45, cy + bh * 0.08),
        Offset(cx + bw * 0.45, cy + bh * 0.08),
        lineP);

    // ハイライト
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - bw * 0.12, cy - bh * 0.15),
            width: bw * 0.22,
            height: bh * 0.12),
        light);

    // てっぺんの小さな丸
    canvas.drawCircle(Offset(cx, cy - bh * 0.5 - 6), 5, fill);
    canvas.drawCircle(Offset(cx, cy - bh * 0.5 - 6), 5, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 和菓子 ───────────────────────────────────────────────
class _WagashiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.28;

    final fill = Paint()..color = _c2;
    final dark = Paint()..color = _c1;
    final light = Paint()..color = _c3;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // 影
    canvas.drawCircle(Offset(cx + 2, cy + 3), r, dark);

    // 本体（まんじゅう形）
    final bodyPath = Path();
    bodyPath.addArc(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
        math.pi,
        math.pi);
    bodyPath.lineTo(cx + r, cy + r * 0.3);
    bodyPath.quadraticBezierTo(cx, cy + r * 0.9, cx - r, cy + r * 0.3);
    bodyPath.close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, border);

    // 底面（台形）
    final basePath = Path();
    basePath.moveTo(cx - r * 0.85, cy + r * 0.28);
    basePath.lineTo(cx + r * 0.85, cy + r * 0.28);
    basePath.lineTo(cx + r * 0.6, cy + r * 0.65);
    basePath.lineTo(cx - r * 0.6, cy + r * 0.65);
    basePath.close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, border);

    // 花の模様（5弁）
    const petals = 5;
    final pr = r * 0.12;
    final flowerCx = cx;
    final flowerCy = cy - r * 0.05;
    for (int i = 0; i < petals; i++) {
      final angle = (2 * math.pi / petals) * i - math.pi / 2;
      final px = flowerCx + r * 0.22 * math.cos(angle);
      final py = flowerCy + r * 0.22 * math.sin(angle);
      canvas.drawCircle(Offset(px, py), pr, dark);
    }
    canvas.drawCircle(Offset(flowerCx, flowerCy), pr * 0.8, light);

    // ハイライト
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.35), r * 0.14, light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 焼き菓子 ─────────────────────────────────────────────
class _BakedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final fill = Paint()..color = _c2;
    final dark = Paint()..color = _c1;
    final light = Paint()..color = _c3;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // マドレーヌのような形
    final bw = size.width * 0.52;
    final bh = size.height * 0.48;

    // 影
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 2, cy + 3), width: bw, height: bh),
        dark);

    // 本体
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh), fill);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh), border);

    // 縦の筋（焼き菓子の型の跡）
    final lineP = Paint()
      ..color = _c1
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const lines = 5;
    for (int i = 0; i < lines; i++) {
      final t = (i + 1) / (lines + 1);
      final lx = cx - bw / 2 + bw * t;
      // 楕円のクリップで縦線を描く
      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCenter(
            center: Offset(cx, cy), width: bw - 2, height: bh - 2)));
      canvas.drawLine(
          Offset(lx, cy - bh / 2), Offset(lx, cy + bh / 2), lineP);
      canvas.restore();
    }

    // 盛り上がり（上部ハイライト）
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - bw * 0.1, cy - bh * 0.1),
            width: bw * 0.45,
            height: bh * 0.28),
        light);

    // 粉糖イメージ（小さな点）
    final dotP = Paint()..color = _c3;
    final rng = [
      Offset(cx - bw * 0.2, cy - bh * 0.25),
      Offset(cx + bw * 0.1, cy - bh * 0.3),
      Offset(cx + bw * 0.25, cy - bh * 0.1),
      Offset(cx - bw * 0.05, cy + bh * 0.15),
    ];
    for (final o in rng) {
      canvas.drawCircle(o, 2, dotP);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── キャンディ ───────────────────────────────────────────
class _CandyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.28;

    final fill = Paint()..color = _c2;
    final dark = Paint()..color = _c1;
    final light = Paint()..color = _c3;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // 棒
    canvas.drawLine(
        Offset(cx + r * 0.7, cy + r * 0.7),
        Offset(cx + r * 1.6, cy + r * 1.6),
        Paint()
          ..color = _c1
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);

    // 飴の本体
    canvas.drawCircle(Offset(cx, cy), r, dark);
    canvas.drawCircle(Offset(cx - 1, cy - 1), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, border);

    // 渦巻き模様
    final spiralPaint = Paint()
      ..color = _c1
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final spiralPath = Path();
    for (int i = 0; i < 100; i++) {
      final t = i / 100.0;
      final angle = t * 3 * math.pi;
      final sr = r * 0.85 * (1 - t * 0.7);
      final sx = cx + sr * math.cos(angle);
      final sy = cy + sr * math.sin(angle);
      if (i == 0) {
        spiralPath.moveTo(sx, sy);
      } else {
        spiralPath.lineTo(sx, sy);
      }
    }
    canvas.save();
    canvas.clipPath(Path()
      ..addCircle(cx, cy, r - 1));
    canvas.drawPath(spiralPath, spiralPaint);
    canvas.restore();

    // ハイライト
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3), r * 0.18, light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ケーキ ───────────────────────────────────────────────
class _CakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final fill = Paint()..color = _c2;
    final dark = Paint()..color = _c1;
    final light = Paint()..color = _c3;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final sw = size.width * 0.48;
    final sh = size.height * 0.52;
    final left = cx - sw / 2;
    final top = cy - sh / 2;

    // ケーキ本体（2層）
    final layer1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top + sh * 0.45, sw, sh * 0.55),
        const Radius.circular(3));
    canvas.drawRRect(layer1, dark);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left - 1, top + sh * 0.44, sw, sh * 0.55),
            const Radius.circular(3)),
        fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left - 1, top + sh * 0.44, sw, sh * 0.55),
            const Radius.circular(3)),
        border);

    final layer2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + sw * 0.05, top + sh * 0.1, sw * 0.9, sh * 0.38),
        const Radius.circular(3));
    canvas.drawRRect(layer2, fill);
    canvas.drawRRect(layer2, border);

    // 層の区切り
    canvas.drawLine(
        Offset(left - 1, top + sh * 0.44),
        Offset(left - 1 + sw, top + sh * 0.44),
        Paint()
          ..color = _c1
          ..strokeWidth = 1.2);

    // クリーム（波形）
    final creamPath = Path();
    final creamY = top + sh * 0.1;
    final creamLeft = left + sw * 0.05;
    final creamRight = left + sw * 0.95;
    creamPath.moveTo(creamLeft, creamY);
    const waves = 4;
    final ww = (creamRight - creamLeft) / waves;
    for (int i = 0; i < waves; i++) {
      final wx = creamLeft + ww * i;
      creamPath.quadraticBezierTo(
          wx + ww / 4, creamY - 8, wx + ww / 2, creamY);
      creamPath.quadraticBezierTo(
          wx + 3 * ww / 4, creamY + 4, wx + ww, creamY);
    }
    creamPath.lineTo(creamRight, creamY + 6);
    creamPath.lineTo(creamLeft, creamY + 6);
    creamPath.close();
    canvas.drawPath(creamPath, light);
    canvas.drawPath(
        creamPath,
        Paint()
          ..color = _c1
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // ろうそく
    const candleW = 5.0;
    const candleH = 16.0;
    final candleX = cx - candleW / 2;
    final candleY = top + sh * 0.1 - candleH;
    canvas.drawRect(
        Rect.fromLTWH(candleX, candleY, candleW, candleH), fill);
    canvas.drawRect(
        Rect.fromLTWH(candleX, candleY, candleW, candleH), border);

    // 炎
    final flamePath = Path();
    flamePath.moveTo(cx, candleY - 2);
    flamePath.quadraticBezierTo(
        cx + 4, candleY - 8, cx, candleY - 12);
    flamePath.quadraticBezierTo(
        cx - 4, candleY - 8, cx, candleY - 2);
    canvas.drawPath(flamePath, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── デフォルト（汎用お菓子） ─────────────────────────────
class _DefaultSweetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final fill = Paint()..color = _c2;
    final dark = Paint()..color = _c1;
    final light = Paint()..color = _c3;
    final border = Paint()
      ..color = _c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // 箱のような形
    final bw = size.width * 0.46;
    final bh = size.height * 0.46;
    final box = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh),
        const Radius.circular(6));

    // 影
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + 3, cy + 3), width: bw, height: bh),
            const Radius.circular(6)),
        dark);
    canvas.drawRRect(box, fill);
    canvas.drawRRect(box, border);

    // リボン（縦）
    canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: 8, height: bh),
        Paint()..color = _c1.withOpacity(0.5));
    // リボン（横）
    canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: 8),
        Paint()..color = _c1.withOpacity(0.5));

    // リボン結び目
    canvas.drawCircle(Offset(cx, cy), 7, dark);
    canvas.drawCircle(Offset(cx, cy), 7, border);

    // リボンの羽（左上・右上）
    for (final sign in [-1.0, 1.0]) {
      final path = Path();
      path.moveTo(cx, cy);
      path.quadraticBezierTo(
          cx + sign * 14, cy - 14, cx + sign * 18, cy - 4);
      path.quadraticBezierTo(cx + sign * 10, cy - 2, cx, cy);
      canvas.drawPath(path, fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = _c1
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }

    // ハイライト
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                cx - bw / 2 + 6, cy - bh / 2 + 6, bw * 0.28, bh * 0.14),
            const Radius.circular(4)),
        light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
