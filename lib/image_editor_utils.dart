class ImageEditorUtils {
  static List<double> createColorMatrix({
    required double brightness,
    required double contrast,
    required double saturation,
    required double hue,
    required double whiteBalance,
    required double vignette,
    required double sharpness,
    required double tint,
    required double shadows,
    required double highlights,
  }) {
    final List<double> matrix = [
      contrast, 0, 0, 0, brightness * 255,
      0, contrast, 0, 0, brightness * 255,
      0, 0, contrast, 0, brightness * 255,
      0, 0, 0, 1, 0,
    ];

    if (saturation != 1.0) {
      final double r = 0.2126;
      final double g = 0.7152;
      final double b = 0.0722;
      final double s = saturation;

      matrix[0] = (1.0 - s) * r + s;
      matrix[1] = (1.0 - s) * r;
      matrix[2] = (1.0 - s) * r;

      matrix[5] = (1.0 - s) * g;
      matrix[6] = (1.0 - s) * g + s;
      matrix[7] = (1.0 - s) * g;

      matrix[10] = (1.0 - s) * b;
      matrix[11] = (1.0 - s) * b;
      matrix[12] = (1.0 - s) * b + s;
    }

    if (whiteBalance != 0.0) {
      matrix[0] += whiteBalance * 0.1;
      matrix[12] -= whiteBalance * 0.1;
    }

    if (hue != 0.0) {
      final double angle = hue * 0.5;
      final double sin = angle < 0 ? -angle : angle;
      final double cos = 1.0;

      final double rm1 = matrix[0];
      final double rm2 = matrix[1];
      final double rm3 = matrix[2];
      final double gm1 = matrix[5];
      final double gm2 = matrix[6];
      final double gm3 = matrix[7];
      final double bm1 = matrix[10];
      final double bm2 = matrix[11];
      final double bm3 = matrix[12];

      if (hue > 0) {
        matrix[0] = rm1 * cos + gm1 * sin;
        matrix[1] = rm2 * cos + gm2 * sin;
        matrix[2] = rm3 * cos + gm3 * sin;
        matrix[5] = gm1 * cos - rm1 * sin;
        matrix[6] = gm2 * cos - rm2 * sin;
        matrix[7] = gm3 * cos - rm3 * sin;
      } else {
        matrix[5] = gm1 * cos + bm1 * sin;
        matrix[6] = gm2 * cos + bm2 * sin;
        matrix[7] = gm3 * cos + bm3 * sin;
        matrix[10] = bm1 * cos - gm1 * sin;
        matrix[11] = bm2 * cos - gm2 * sin;
        matrix[12] = bm3 * cos - gm3 * sin;
      }
    }

    if (vignette != 0.0) {
      final double vignetteEffect = vignette * 0.5;
      matrix[0] -= vignetteEffect;
      matrix[5] -= vignetteEffect;
      matrix[10] -= vignetteEffect;
    }

    if (sharpness != 0.0) {
      final double sharpnessEffect = sharpness * 0.1;
      matrix[0] += sharpnessEffect;
      matrix[5] += sharpnessEffect;
      matrix[10] += sharpnessEffect;
    }

    if (tint != 0.0) {
      final double tintEffect = tint * 0.1;
      matrix[0] += tintEffect;
      matrix[12] -= tintEffect;
    }

    if (shadows != 0.0) {
      final double shadowsEffect = shadows * 0.1;
      matrix[0] += shadowsEffect;
      matrix[5] += shadowsEffect;
      matrix[10] += shadowsEffect;
    }

    if (highlights != 0.0) {
      final double highlightsEffect = highlights * 0.1;
      matrix[0] += highlightsEffect;
      matrix[5] += highlightsEffect;
      matrix[10] += highlightsEffect;
    }

    return matrix;
  }
}