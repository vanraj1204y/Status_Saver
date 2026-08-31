// Generates the StatusNest launcher icon, adaptive icon layers and the
// splash logo. Original branding: a story-style segmented ring with a
// download arrow — WhatsApp-inspired teal, but no WhatsApp logo.
//
// Run with: dart run tool/gen_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

final teal = img.ColorRgba8(0, 191, 165, 255); // #00BFA5
final tealDark = img.ColorRgba8(0, 158, 140, 255); // #009E8C
final white = img.ColorRgba8(255, 255, 255, 255);

void main() {
  Directory('assets/branding').createSync(recursive: true);

  // Adaptive icon background: vertical teal gradient.
  final background = img.Image(width: 1024, height: 1024, numChannels: 4);
  for (var y = 0; y < 1024; y++) {
    final t = y / 1023.0;
    final r = (0 + (0 - 0) * t).round();
    final g = (191 + (158 - 191) * t).round();
    final b = (165 + (140 - 165) * t).round();
    for (var x = 0; x < 1024; x++) {
      background.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  File('assets/branding/icon_background.png')
      .writeAsBytesSync(img.encodePng(background));

  // Adaptive icon foreground: white logo on transparent, inside safe zone.
  final foreground = img.Image(width: 1024, height: 1024, numChannels: 4);
  drawLogo(foreground, color: white, cx: 512, cy: 512, scale: 1.0);
  File('assets/branding/icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  // Full (legacy) launcher icon: gradient background + white logo.
  final full = img.Image.from(background);
  drawLogo(full, color: white, cx: 512, cy: 512, scale: 1.0);
  File('assets/branding/icon_full.png').writeAsBytesSync(img.encodePng(full));

  // Splash logo: teal logo on transparent (works on white and dark splash).
  final splash = img.Image(width: 768, height: 768, numChannels: 4);
  drawLogo(splash, color: teal, cx: 384, cy: 384, scale: 0.75);
  File('assets/branding/splash_logo.png')
      .writeAsBytesSync(img.encodePng(splash));

  stdout.writeln('Branding assets written to assets/branding/');
}

/// Draws the StatusNest mark: a 3-segment story ring with a download
/// arrow dropping onto a tray bar.
void drawLogo(img.Image canvas,
    {required img.Color color, required int cx, required int cy, required double scale}) {
  final ringRadius = 290 * scale;
  final ringThickness = 62 * scale;

  // Three arc segments (like a status story ring), gaps of 24 degrees.
  const segments = 3;
  const gapDeg = 24.0;
  const arcDeg = (360.0 - segments * gapDeg) / segments;
  for (var s = 0; s < segments; s++) {
    final startDeg = -90.0 + gapDeg / 2 + s * (arcDeg + gapDeg);
    for (var d = 0.0; d <= arcDeg; d += 0.75) {
      final a = (startDeg + d) * math.pi / 180.0;
      final x = cx + ringRadius * math.cos(a);
      final y = cy + ringRadius * math.sin(a);
      img.fillCircle(canvas,
          x: x.round(), y: y.round(), radius: (ringThickness / 2).round(), color: color);
    }
  }

  // Arrow shaft with rounded ends.
  final shaftHalf = (30 * scale).round();
  final shaftTop = (cy - 175 * scale).round();
  final shaftBottom = (cy + 15 * scale).round();
  img.fillRect(canvas,
      x1: cx - shaftHalf, y1: shaftTop, x2: cx + shaftHalf, y2: shaftBottom,
      color: color, radius: shaftHalf.toDouble());

  // Arrow head: triangle drawn as horizontal scanlines.
  final headHalf = 118 * scale;
  final headTop = (cy + 5 * scale).round();
  final headBottom = (cy + 140 * scale).round();
  for (var y = headTop; y <= headBottom; y++) {
    final t = (y - headTop) / (headBottom - headTop);
    final half = (headHalf * (1.0 - t)).round();
    if (half < 1) continue;
    img.drawLine(canvas,
        x1: cx - half, y1: y, x2: cx + half, y2: y, color: color);
  }

  // Tray bar under the arrow.
  final trayHalf = (120 * scale).round();
  final trayTop = (cy + 175 * scale).round();
  final trayBottom = (cy + 215 * scale).round();
  img.fillRect(canvas,
      x1: cx - trayHalf, y1: trayTop, x2: cx + trayHalf, y2: trayBottom,
      color: color, radius: (trayBottom - trayTop) / 2);
}
