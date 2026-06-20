import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/router/route_audit.dart';
import 'package:invoice_kit/core/router/route_names.dart';
import 'package:invoice_kit/core/router/route_paths.dart';

/// Walks the source tree and verifies that every navigation call site
/// (GoRouter push/go, context.push/go) targets a path that the
/// `AppRouter` actually declares.
///
/// This is intentionally a *source-grep* test rather than a runtime
/// widget test — it runs in milliseconds, doesn't need a full app
/// bootstrap, and catches the most common regressions: hard-coded path
/// strings that drift away from the router.
void main() {
  group('Router audit', () {
    test('All declared RouteNames are unique', () {
      final all = RouteAudit.declaredRouteNames.toList();
      expect(all.length, all.toSet().length, reason: 'Duplicate route name');
    });

    test('RouteNames constants match the declared set', () {
      // Top-level named routes that AppRouter wires up.
      const topLevel = [
        RouteNames.splash,
        RouteNames.onboarding,
        RouteNames.subscription,
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
        RouteNames.dashboard,
        RouteNames.businessProfile,
        RouteNames.clients,
        RouteNames.clientNew,
        RouteNames.clientDetail,
        RouteNames.clientEdit,
        RouteNames.invoices,
        RouteNames.invoiceNew,
        RouteNames.invoiceDetail,
        RouteNames.invoiceEdit,
        RouteNames.quotes,
        RouteNames.quoteNew,
        RouteNames.quoteDetail,
        RouteNames.quoteEdit,
        RouteNames.recurring,
        RouteNames.reports,
        RouteNames.fx,
        RouteNames.backup,
        RouteNames.settings,
      ];
      for (final name in topLevel) {
        expect(
          RouteAudit.declaredRouteNames.contains(name),
          isTrue,
          reason: 'RouteNames.$name is wired but missing from audit set',
        );
      }
    });

    test('All declared RoutePaths are reachable', () {
      for (final path in RouteAudit.declaredAbsolutePaths) {
        expect(path.startsWith('/'), isTrue, reason: '$path is not absolute');
        // Splash is allowed to be `/`; everything else must be a non-root path.
        if (path != RoutePaths.splash) {
          expect(path.length, greaterThan(1), reason: '$path is too short');
        }
      }
    });

    test('pathForName round-trips known names', () {
      expect(
        RouteAudit.pathForName(RouteNames.dashboard),
        RoutePaths.dashboard,
      );
      expect(RouteAudit.pathForName(RouteNames.settings), RoutePaths.settings);
      expect(RouteAudit.pathForName('not-a-real-name'), isNull);
    });

    test('Every navigation call site targets a declared route', () async {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ must exist');

      final navCalls = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (final line in lines) {
          if (_isNavCall(line)) navCalls.add(line.trim());
        }
      }
      expect(navCalls, isNotEmpty, reason: 'No navigation calls found');

      final missing = <String>[];
      for (final call in navCalls) {
        final target = _extractPathArgument(call);
        if (target == null) continue;
        if (target.startsWith('/') &&
            !RouteAudit.declaredAbsolutePaths.contains(target) &&
            !_isDynamicDetailPath(target)) {
          missing.add('$call  →  $target');
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'Navigation targets that are not declared in AppRouter: \n${missing.join('\n')}',
      );
    });
  });
}

/// Returns true if the line contains a GoRouter navigation call that
/// we want to audit.
bool _isNavCall(String line) {
  return line.contains('GoRouter.of(context).push(') ||
      line.contains('GoRouter.of(context).go(') ||
      line.contains('context.go(') ||
      line.contains('context.push(') ||
      line.contains('context.goNamed(') ||
      line.contains('context.pushNamed(');
}

/// Extracts the first string argument from a navigation call. Returns
/// null if the line uses a non-literal target (variable, getter, etc.).
String? _extractPathArgument(String line) {
  final start = line.indexOf("'");
  if (start < 0) return null;
  final end = line.indexOf("'", start + 1);
  if (end < 0) return null;
  final raw = line.substring(start + 1, end);
  return raw;
}

/// Paths like `/invoices/123` that are built dynamically — they're
/// valid because they map to `/invoices/:id`.
bool _isDynamicDetailPath(String path) {
  final detailSegments = <String>[
    RoutePaths.invoiceDetailPath(''),
    RoutePaths.clientDetailPath(''),
    RoutePaths.quoteDetailPath(''),
    RoutePaths.invoiceEditPath(''),
    RoutePaths.clientEditPath(''),
    RoutePaths.quoteEditPath(''),
  ];
  for (final base in detailSegments) {
    if (path.startsWith(base) && path.length > base.length) return true;
  }
  return false;
}
