import 'package:invoice_kit/app/app.dart';
import 'package:invoice_kit/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
