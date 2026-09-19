import 'core/bootstrap/bootstrap.dart';
import 'res/assets_res.dart';

/// نقطة دخول Flutter Web.
///
/// `bootstrap` يتعامل تلقائياً مع تخطي Firebase على الويب
/// عبر فحص `kIsWeb`.
void main() => bootstrap(envFile: AssetsRes.ENV);