import 'package:go_router/go_router.dart';

class NavigationService {
  static GoRouter? _router;

  static void setRouter(GoRouter router) {
    _router = router;
  }

  static void goToPaymentWall({String? reason}) {
    if (_router == null) return;
    final uri = reason != null
        ? '/payment-wall?reason=${Uri.encodeComponent(reason)}'
        : '/payment-wall';
    _router!.go(uri);
  }
}
