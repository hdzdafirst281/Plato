import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/navigation/main_scaffold.dart';

void main() {
  test('bottom bar top uses the fallback gap without a safe area', () {
    expect(mainBottomBarVisibleTop(0), 76);
  });

  test('bottom bar top includes the device safe area', () {
    expect(mainBottomBarVisibleTop(34), 102);
  });
}
