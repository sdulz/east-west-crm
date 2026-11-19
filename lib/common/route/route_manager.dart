import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_crm/app/router.dart';

/// Central Route Manager implementing the route architecture from name_app,
/// configured for the Field CRM project flows.
class RouteManager {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  // Route paths
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String clients = '/clients';
  static const String crm = '/crm';
  static const String tasks = '/tasks';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String changePassword = '/profile/password';
  static const String lock = '/lock';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String pending = '/pending';
  static const String team = '/team';
  static const String dev = '/dev';
  static const String customerNew = '/customers/new';
  static const String opportunityNew = '/opportunities/new';
  static const String pipeline = '/opportunities/pipeline';
  static const String activityNew = '/activity/new';
  static const String quotationsNew = '/quotations/new';
  static const String invoices = '/invoices';

  GoRouter goRouter(WidgetRef ref, [GlobalKey<NavigatorState>? key]) =>
      ref.watch(routerProvider);

  static GoRouter getRouter(WidgetRef ref) => ref.read(routerProvider);
}

