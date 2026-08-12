import 'package:flutter_test/flutter_test.dart';
import 'package:status_saver/app/strings.dart';

void main() {
  test('app name is branded', () {
    expect(AppStrings.appName, 'Status Saver');
  });
}
