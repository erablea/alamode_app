import 'dart:math' as math;
import 'package:flutter/material.dart';

class CategoryPlaceholder extends StatelessWidget {
  final String? category;
  final double height;

  const CategoryPlaceholder({super.key, this.category, this.height = 110});

  static const _imageCategories = {
    'クッキー': 'assets/images/cookie.png',
    'ショコラ': 'assets/images/chocolat.png',
    '和菓子':   'assets/images/wagashi.png',
    '焼き菓子': 'assets/images/baked.png',
    'ゼリー・プリン': 'assets/images/pudding.png',
    'その他':   'assets/images/others.png',
  };

  @override
  Widget build(BuildContext context) {
    final imagePath = _imageCategories[category];
    if (imagePath != null) {
      return Container(
        width: double.infinity,
        height: height,
        color: const Color(0xFFF5F5F3),
        child: Image.asset(imagePath, fit: BoxFit.contain),
      );
    }
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFF5F5F3),
      child: CustomPaint(
        painter: _getPainter(category),
      ),
    );
  }

  CustomPainter _getPainter(String? category) {
    switch (category) {
      case 'クッキー':
        return _SablePainter();
      case 'ショコラ':
        return _ChocolatePainter();
      case 'ゼリー・プリン':
        return _CremePainter();
      case '和菓子':
        return _WagashiPainter();
      case '焼き菓子':
        return _FinancierPainter();
      case 'キャンディ':
      case 'キャンデー':
        return _BonbonPainter();
      case 'ケーキ':
        return _EntemetPainter();
      default:
        return _GiftboxPainter();
    }
  }
}

// ─── 共通 ─────────────────────────────────────────────────
const Color _ink   = Color(0xFF9E9E9E); // 主線
const Color _mid   = Color(0xFFBDBDBD); // 中間調
const Color _pale  = Color(0xFFD6D6D6); // 面・淡影
const Color _bg    = Color(0xFFF5F5F3); // 背景同色

Paint _stroke({double w = 0.6, Color c = _ink}) =>
    Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;

Paint _fill(Color c) => Paint()..color = c;

// クロスハッチ（右斜め）
void _hatch(Canvas canvas, Path clip, Rect bounds,
    {double spacing = 5, Color color = _pale, double sw = 0.4}) {
  final p = _stroke(w: sw, c: color);
  canvas.save();
  canvas.clipPath(clip);
  final diag = bounds.width + bounds.height;
  for (double d = -diag; d < diag; d += spacing) {
    canvas.drawLine(
      Offset(bounds.left + d, bounds.top),
      Offset(bounds.left + d + bounds.height, bounds.top + bounds.height),
      p,
    );
  }
  canvas.restore();
}

// ─── サブレ（クッキー） ───────────────────────────────────
class _SablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.30;

    // 薄い落ち影（线）
    canvas.drawCircle(Offset(cx + 1.5, cy + 2), r,
        _stroke(w: 0.4, c: _mid));

    // 面
    canvas.drawCircle(Offset(cx, cy), r, _fill(_pale));

    // ハッチング
    _hatch(canvas, Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        spacing: 4, color: const Color(0xFFC8C8C8), sw: 0.35);

    // 外周ギザギザ（花型）
    const petals = 20;
    final outerPath = Path();
    for (int i = 0; i < petals * 2; i++) {
      final angle = math.pi / petals * i;
      final rr = i.isEven ? r + 3.5 : r - 1;
      final x = cx + rr * math.cos(angle);
      final y = cy + rr * math.sin(angle);
      i == 0 ? outerPath.moveTo(x, y) : outerPath.lineTo(x, y);
    }
    outerPath.close();
    canvas.drawPath(outerPath, _stroke(w: 0.55));

    // 内側の細い円
    canvas.drawCircle(Offset(cx, cy), r * 0.72, _stroke(w: 0.45, c: _mid));

    // 中央の小花（5弁）
    const fp = 5;
    final fr = r * 0.14;
    for (int i = 0; i < fp; i++) {
      final a = 2 * math.pi / fp * i - math.pi / 2;
      canvas.drawCircle(
          Offset(cx + r * 0.26 * math.cos(a), cy + r * 0.26 * math.sin(a)),
          fr, _stroke(w: 0.45, c: _ink));
    }
    canvas.drawCircle(Offset(cx, cy), fr * 0.7, _stroke(w: 0.45, c: _mid));

    // 小さなドット（ランダム風）
    for (final o in [
      Offset(cx + r * 0.45, cy - r * 0.1),
      Offset(cx - r * 0.4, cy + r * 0.3),
      Offset(cx + r * 0.15, cy + r * 0.45),
    ]) {
      canvas.drawCircle(o, 1.2, _fill(_ink));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── タブレット・ショコラ ─────────────────────────────────
class _ChocolatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final bw = size.width * 0.52, bh = size.height * 0.50;

    final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh),
        const Radius.circular(4));

    // 落ち影（線のみ）
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 2, cy + 2.5), width: bw, height: bh),
            const Radius.circular(4)),
        _stroke(w: 0.5, c: _mid));

    // 面
    canvas.drawRRect(rrect, _fill(_pale));

    // ハッチング
    _hatch(canvas, Path()..addRRect(rrect),
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh),
        spacing: 5, color: const Color(0xFFC5C5C5), sw: 0.3);

    // 外枠
    canvas.drawRRect(rrect, _stroke(w: 0.6));

    // グリッド分割線（3×4）
    const cols = 3, rows = 4;
    final l = cx - bw / 2 + 5, t = cy - bh / 2 + 5;
    final r2 = cx + bw / 2 - 5, b = cy + bh / 2 - 5;
    for (int c = 1; c < cols; c++) {
      final x = l + (r2 - l) * c / cols;
      canvas.drawLine(Offset(x, t), Offset(x, b), _stroke(w: 0.5, c: _mid));
    }
    for (int r = 1; r < rows; r++) {
      final y = t + (b - t) * r / rows;
      canvas.drawLine(Offset(l, y), Offset(r2, y), _stroke(w: 0.5, c: _mid));
    }

    // 各ピースの角丸の内線
    final cellW = (r2 - l) / cols, cellH = (b - t) / rows;
    for (int c = 0; c < cols; c++) {
      for (int rr = 0; rr < rows; rr++) {
        final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(l + cellW * c + 1, t + cellH * rr + 1,
                cellW - 2, cellH - 2),
            const Radius.circular(2));
        canvas.drawRRect(rect, _stroke(w: 0.3, c: const Color(0xFFCACACA)));
      }
    }

    // リボン風の帯（包み紙イメージ）
    canvas.drawLine(
        Offset(cx - bw / 2, cy - bh / 2 + 12),
        Offset(cx + bw / 2, cy - bh / 2 + 12),
        _stroke(w: 0.4, c: _mid));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── クレーム・キャラメル ─────────────────────────────────
class _CremePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final bw = size.width * 0.40, bh = size.height * 0.52;

    // 皿
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + bh * 0.55), width: bw * 1.7, height: bh * 0.18),
        _stroke(w: 0.45, c: _mid));

    // カラメルの落ちた跡
    final caramelPath = Path()
      ..moveTo(cx - bw * 0.25, cy + bh * 0.42)
      ..quadraticBezierTo(cx, cy + bh * 0.55, cx + bw * 0.22, cy + bh * 0.44);
    canvas.drawPath(caramelPath, _stroke(w: 0.4, c: _mid));

    // 本体シルエット（ドーム＋台形）
    final bodyPath = Path();
    bodyPath.addArc(
        Rect.fromCenter(center: Offset(cx, cy - bh * 0.05), width: bw, height: bh * 0.9),
        math.pi, math.pi);
    bodyPath.lineTo(cx + bw / 2, cy + bh * 0.28);
    bodyPath.lineTo(cx + bw * 0.38, cy + bh * 0.46);
    bodyPath.lineTo(cx - bw * 0.38, cy + bh * 0.46);
    bodyPath.lineTo(cx - bw / 2, cy + bh * 0.28);
    bodyPath.close();

    canvas.drawPath(bodyPath, _fill(_pale));
    _hatch(canvas, bodyPath,
        Rect.fromLTWH(cx - bw, cy - bh, bw * 2, bh * 2),
        spacing: 4.5, color: const Color(0xFFC6C6C6), sw: 0.3);
    canvas.drawPath(bodyPath, _stroke(w: 0.55));

    // 横の層の線
    canvas.drawLine(
        Offset(cx - bw * 0.42, cy + bh * 0.1),
        Offset(cx + bw * 0.42, cy + bh * 0.1),
        _stroke(w: 0.4, c: _mid));
    canvas.drawLine(
        Offset(cx - bw * 0.38, cy + bh * 0.22),
        Offset(cx + bw * 0.38, cy + bh * 0.22),
        _stroke(w: 0.35, c: _mid));

    // 頂点の小さな膨らみ
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - bh * 0.47), width: 9, height: 6),
        _fill(_pale));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - bh * 0.47), width: 9, height: 6),
        _stroke(w: 0.45));

    // ミントの葉（2枚）
    for (final s in [-1.0, 1.0]) {
      final lp = Path()
        ..moveTo(cx, cy - bh * 0.52)
        ..quadraticBezierTo(
            cx + s * 7, cy - bh * 0.62, cx + s * 10, cy - bh * 0.56)
        ..quadraticBezierTo(
            cx + s * 5, cy - bh * 0.54, cx, cy - bh * 0.52);
      canvas.drawPath(lp, _fill(_pale));
      canvas.drawPath(lp, _stroke(w: 0.4, c: _mid));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── 和菓子（落雁風） ─────────────────────────────────────
class _WagashiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.27;

    // 落ち影（線）
    final shadowPath = _manjiuPath(cx + 1.5, cy + 2, r);
    canvas.drawPath(shadowPath, _stroke(w: 0.4, c: _mid));

    // 本体
    final body = _manjiuPath(cx, cy, r);
    canvas.drawPath(body, _fill(_pale));
    _hatch(canvas, body,
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.5, height: r * 2.5),
        spacing: 4, color: const Color(0xFFC8C8C8), sw: 0.3);
    canvas.drawPath(body, _stroke(w: 0.55));

    // 底の台
    final basePath = Path()
      ..moveTo(cx - r * 0.82, cy + r * 0.30)
      ..lineTo(cx + r * 0.82, cy + r * 0.30)
      ..lineTo(cx + r * 0.58, cy + r * 0.62)
      ..lineTo(cx - r * 0.58, cy + r * 0.62)
      ..close();
    canvas.drawPath(basePath, _fill(_pale));
    canvas.drawPath(basePath, _stroke(w: 0.5));

    // 台の横線
    canvas.drawLine(
        Offset(cx - r * 0.72, cy + r * 0.44),
        Offset(cx + r * 0.72, cy + r * 0.44),
        _stroke(w: 0.35, c: _mid));

    // 桜の花（5弁の細い輪郭）
    const fp = 5;
    final fr = r * 0.10;
    final fcx = cx, fcy = cy - r * 0.06;
    for (int i = 0; i < fp; i++) {
      final a = 2 * math.pi / fp * i - math.pi / 2;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(fcx + r * 0.21 * math.cos(a),
                  fcy + r * 0.21 * math.sin(a)),
              width: fr * 2.2,
              height: fr * 1.6),
          _stroke(w: 0.45, c: _ink));
    }
    // 花の中心小円
    canvas.drawCircle(Offset(fcx, fcy), fr * 0.55, _stroke(w: 0.4, c: _mid));
    // 花芯の細い線
    for (int i = 0; i < fp; i++) {
      final a = 2 * math.pi / fp * i - math.pi / 2;
      canvas.drawLine(
          Offset(fcx, fcy),
          Offset(fcx + fr * 0.45 * math.cos(a), fcy + fr * 0.45 * math.sin(a)),
          _stroke(w: 0.3, c: _mid));
    }
  }

  Path _manjiuPath(double cx, double cy, double r) {
    final p = Path();
    p.addArc(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
        math.pi, math.pi);
    p.lineTo(cx + r, cy + r * 0.28);
    p.quadraticBezierTo(cx, cy + r * 0.85, cx - r, cy + r * 0.28);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── フィナンシェ（焼き菓子） ─────────────────────────────
class _FinancierPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final fw = size.width * 0.54, fh = size.height * 0.38;

    final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: fw, height: fh),
        const Radius.circular(5));

    // 落ち影
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 2, cy + 2.5), width: fw, height: fh),
            const Radius.circular(5)),
        _stroke(w: 0.4, c: _mid));

    // 面
    canvas.drawRRect(rrect, _fill(_pale));
    _hatch(canvas, Path()..addRRect(rrect),
        Rect.fromCenter(center: Offset(cx, cy), width: fw, height: fh),
        spacing: 4, color: const Color(0xFFC5C5C5), sw: 0.3);

    // 外枠
    canvas.drawRRect(rrect, _stroke(w: 0.6));

    // 焦げ色の内線（型の段差）
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: fw - 7, height: fh - 7),
            const Radius.circular(3)),
        _stroke(w: 0.4, c: _mid));

    // 膨らみのハイライト楕円
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - fw * 0.06, cy - fh * 0.12),
            width: fw * 0.5, height: fh * 0.4),
        _stroke(w: 0.3, c: const Color(0xFFCECECE)));

    // アーモンドスライス（3枚）
    final almonds = [
      Offset(cx - fw * 0.15, cy - fh * 0.05),
      Offset(cx + fw * 0.04, cy - fh * 0.08),
      Offset(cx + fw * 0.2, cy + fh * 0.06),
    ];
    for (final o in almonds) {
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(0.3);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
          _fill(_pale));
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
          _stroke(w: 0.45, c: _ink));
      // 中心線
      canvas.drawLine(Offset(-4.5, 0), Offset(4.5, 0), _stroke(w: 0.3, c: _mid));
      canvas.restore();
    }

    // 小さな粉糖の点
    for (final o in [
      Offset(cx - fw * 0.3, cy + fh * 0.28),
      Offset(cx + fw * 0.2, cy + fh * 0.3),
      Offset(cx - fw * 0.05, cy + fh * 0.32),
    ]) {
      canvas.drawCircle(o, 1.0, _fill(_mid));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── ボンボン（キャンディ） ───────────────────────────────
class _BonbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.27;

    // ひねり紙（左）
    _drawTwist(canvas, cx - r - 2, cy, -1);
    // ひねり紙（右）
    _drawTwist(canvas, cx + r + 2, cy, 1);

    // 本体の落ち影
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 1.5, cy + 2), width: r * 2, height: r * 1.5),
        _stroke(w: 0.4, c: _mid));

    // 本体（やや横長の楕円）
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5),
        _fill(_pale));

    // ハッチング
    _hatch(canvas,
        Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5)),
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5),
        spacing: 4, color: const Color(0xFFC5C5C5), sw: 0.3);

    // 斜めのストライプ（キャンディ柄）
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: r * 1.98, height: r * 1.48)));
    for (double d = -r * 2; d < r * 2; d += 8) {
      canvas.drawLine(
          Offset(cx + d, cy - r * 1.5),
          Offset(cx + d + r * 1.5, cy + r),
          _stroke(w: 0.5, c: _mid));
    }
    canvas.restore();

    // 外枠
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5),
        _stroke(w: 0.6));

    // ハイライト（小楕円）
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - r * 0.3, cy - r * 0.28),
            width: r * 0.4, height: r * 0.2),
        _stroke(w: 0.35, c: const Color(0xFFD8D8D8)));
  }

  void _drawTwist(Canvas canvas, double x, double cy, double dir) {
    // ひねり紙：3本の弧線
    for (int i = -1; i <= 1; i++) {
      final p = Path()
        ..moveTo(x, cy + i * 4.0)
        ..quadraticBezierTo(
            x + dir * 8, cy + i * 4.0 - 3,
            x + dir * 14, cy + i * 3.5);
      canvas.drawPath(p, _stroke(w: 0.4, c: _mid));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── アントルメ（ケーキ） ─────────────────────────────────
class _EntemetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final cw = size.width * 0.50, ch = size.height * 0.54;
    final left = cx - cw / 2, top = cy - ch / 2;

    // ─ 本体下層 ─
    final base = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top + ch * 0.44, cw, ch * 0.52),
        const Radius.circular(3));
    canvas.drawRRect(base, _fill(_pale));
    _hatch(canvas, Path()..addRRect(base),
        Rect.fromLTWH(left, top + ch * 0.44, cw, ch * 0.52),
        spacing: 4.5, color: const Color(0xFFC8C8C8), sw: 0.3);
    canvas.drawRRect(base, _stroke(w: 0.55));

    // 側面の細いライン（スポンジ層）
    canvas.drawLine(
        Offset(left + 1, top + ch * 0.58),
        Offset(left + cw - 1, top + ch * 0.58),
        _stroke(w: 0.35, c: _mid));
    canvas.drawLine(
        Offset(left + 1, top + ch * 0.70),
        Offset(left + cw - 1, top + ch * 0.70),
        _stroke(w: 0.35, c: _mid));

    // ─ 上層 ─
    final top2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + cw * 0.06, top + ch * 0.12, cw * 0.88, ch * 0.34),
        const Radius.circular(3));
    canvas.drawRRect(top2, _fill(_pale));
    canvas.drawRRect(top2, _stroke(w: 0.5));

    // ─ クリームの波線 ─
    final creamY = top + ch * 0.12;
    final cl = left + cw * 0.06, cr = left + cw * 0.94;
    final wavePath = Path()..moveTo(cl, creamY);
    const wn = 5;
    final ww = (cr - cl) / wn;
    for (int i = 0; i < wn; i++) {
      final wx = cl + ww * i;
      wavePath.quadraticBezierTo(wx + ww / 4, creamY - 5, wx + ww / 2, creamY);
      wavePath.quadraticBezierTo(wx + 3 * ww / 4, creamY + 3, wx + ww, creamY);
    }
    wavePath.lineTo(cr, creamY + 5);
    wavePath.lineTo(cl, creamY + 5);
    wavePath.close();
    canvas.drawPath(wavePath, _fill(const Color(0xFFE0E0E0)));
    canvas.drawPath(wavePath, _stroke(w: 0.45, c: _mid));

    // ─ 小さな飾り（イチゴ風のシルエット3つ） ─
    final berries = [
      Offset(cx - cw * 0.18, creamY - 10),
      Offset(cx, creamY - 11),
      Offset(cx + cw * 0.18, creamY - 10),
    ];
    for (final b in berries) {
      // 実
      final bp = Path()
        ..moveTo(b.dx, b.dy - 2)
        ..quadraticBezierTo(b.dx + 4, b.dy - 8, b.dx + 4, b.dy - 4)
        ..quadraticBezierTo(b.dx + 4, b.dy + 1, b.dx, b.dy + 3)
        ..quadraticBezierTo(b.dx - 4, b.dy + 1, b.dx - 4, b.dy - 4)
        ..quadraticBezierTo(b.dx - 4, b.dy - 8, b.dx, b.dy - 2)
        ..close();
      canvas.drawPath(bp, _fill(_pale));
      canvas.drawPath(bp, _stroke(w: 0.4, c: _ink));
      // ヘタ（3本）
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(
            Offset(b.dx, b.dy - 2),
            Offset(b.dx + i * 2.5, b.dy - 6),
            _stroke(w: 0.35, c: _mid));
      }
    }

    // ─ ろうそく ─
    final candleX = cx, candleTop = creamY - 22;
    canvas.drawRect(
        Rect.fromLTWH(candleX - 2, candleTop, 4, 13),
        _fill(_pale));
    canvas.drawRect(
        Rect.fromLTWH(candleX - 2, candleTop, 4, 13),
        _stroke(w: 0.45));
    // 溶けた蝋のしずく
    canvas.drawOval(
        Rect.fromCenter(center: Offset(candleX + 1.5, candleTop + 10),
            width: 4, height: 3),
        _stroke(w: 0.3, c: _mid));
    // 炎（二重輪郭）
    final flameO = Path()
      ..moveTo(candleX, candleTop)
      ..quadraticBezierTo(candleX + 4.5, candleTop - 7, candleX, candleTop - 12)
      ..quadraticBezierTo(candleX - 4.5, candleTop - 7, candleX, candleTop);
    canvas.drawPath(flameO, _fill(const Color(0xFFDDDDDD)));
    canvas.drawPath(flameO, _stroke(w: 0.45, c: _mid));
    final flameI = Path()
      ..moveTo(candleX, candleTop - 1)
      ..quadraticBezierTo(candleX + 2.5, candleTop - 5, candleX, candleTop - 8)
      ..quadraticBezierTo(candleX - 2.5, candleTop - 5, candleX, candleTop - 1);
    canvas.drawPath(flameI, _stroke(w: 0.3, c: _ink));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── ギフトボックス（デフォルト） ────────────────────────
class _GiftboxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final bw = size.width * 0.44, bh = size.height * 0.44;

    final boxRect = Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh);
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(4));

    // 落ち影
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 2, cy + 2.5), width: bw, height: bh),
            const Radius.circular(4)),
        _stroke(w: 0.4, c: _mid));

    // 箱の面
    canvas.drawRRect(rrect, _fill(_pale));
    _hatch(canvas, Path()..addRRect(rrect), boxRect,
        spacing: 5, color: const Color(0xFFC8C8C8), sw: 0.3);
    canvas.drawRRect(rrect, _stroke(w: 0.55));

    // 箱のフタの線
    canvas.drawLine(
        Offset(cx - bw / 2, cy - bh * 0.1),
        Offset(cx + bw / 2, cy - bh * 0.1),
        _stroke(w: 0.45, c: _mid));

    // リボン（縦・横の細い線）
    canvas.drawLine(
        Offset(cx, cy - bh / 2),
        Offset(cx, cy + bh / 2),
        _stroke(w: 0.5, c: _ink));
    canvas.drawLine(
        Offset(cx - bw / 2, cy - bh * 0.1),
        Offset(cx + bw / 2, cy - bh * 0.1),
        _stroke(w: 0.5, c: _ink));

    // リボンの結び目（蝶結び）
    final knotY = cy - bh * 0.1;
    for (final s in [-1.0, 1.0]) {
      // 羽（4点ベジェ）
      final bow = Path()
        ..moveTo(cx, knotY)
        ..cubicTo(cx + s * 4, knotY - 10, cx + s * 14, knotY - 8, cx + s * 13, knotY - 2)
        ..cubicTo(cx + s * 12, knotY + 4, cx + s * 4, knotY + 6, cx, knotY);
      canvas.drawPath(bow, _fill(const Color(0xFFE0E0E0)));
      canvas.drawPath(bow, _stroke(w: 0.45, c: _ink));
      // 羽の中の細い筋
      canvas.drawLine(
          Offset(cx + s * 3, knotY - 2),
          Offset(cx + s * 10, knotY - 4),
          _stroke(w: 0.28, c: _mid));
    }
    // 結び目の小円
    canvas.drawCircle(Offset(cx, knotY), 2.8, _fill(_pale));
    canvas.drawCircle(Offset(cx, knotY), 2.8, _stroke(w: 0.4));

    // 花のスタンプ（隅の小さな装飾）
    canvas.drawCircle(Offset(cx + bw * 0.3, cy + bh * 0.28), 3.5,
        _stroke(w: 0.35, c: _mid));
    for (int i = 0; i < 5; i++) {
      final a = 2 * math.pi / 5 * i;
      canvas.drawLine(
          Offset(cx + bw * 0.3, cy + bh * 0.28),
          Offset(cx + bw * 0.3 + 3.5 * math.cos(a),
              cy + bh * 0.28 + 3.5 * math.sin(a)),
          _stroke(w: 0.28, c: _mid));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
