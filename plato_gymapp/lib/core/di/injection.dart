import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: false,
)
// SỬA Ở ĐÂY: Đổi từ void thành Future<void> và thêm async / await
Future<void> configureDependencies() async {
  await init(getIt);
}