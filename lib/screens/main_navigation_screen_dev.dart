// Dev variant — identical to MainNavigationScreen in the integrated build.
// Kept as a separate class name so splash_screen.dart can still reference it
// without changing existing code.
export 'main_navigation_screen.dart';

// Re-export the class under the dev name via a simple typedef alias.
// Because Dart doesn't allow typedef for classes directly, we re-use the
// production screen. If you need a divergent dev experience, extend here.
