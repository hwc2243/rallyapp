import 'package:flutter_test/flutter_test.dart';

import 'package:rally_lib/rally_lib.dart';

void main() {
  test('calculates a new calibration factor', () {
    expect(
      calculateNewFactor(
        currentFactor: 1.0,
        measuredDistance: 11.0,
        currentAppDistance: 10.0,
      ),
      1.1,
    );
  });
}
