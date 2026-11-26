import 'package:field_crm/app/dev_menu.dart';
import 'package:field_crm/app/shell.dart';
import 'package:field_crm/common/constant/key_constant.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/activity_form_screen.dart';
import 'package:field_crm/features/activities/presentation/follow_ups_screen.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/auth/presentation/forgot_password_screen.dart';
import 'package:field_crm/features/auth/presentation/lock_screen.dart';
import 'package:field_crm/features/auth/presentation/login_screen.dart';
import 'package:field_crm/features/auth/presentation/splash_screen.dart';
import 'package:field_crm/features/customers/presentation/customer_detail_screen.dart';
import 'package:field_crm/features/customers/presentation/customer_form_screen.dart';
import 'package:field_crm/features/customers/presentation/customer_list_screen.dart';
import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:field_crm/features/history/presentation/history_timeline.dart';
import 'package:field_crm/features/notifications/presentation/notifications_screen.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_detail_screen.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_form_screen.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_list_screen.dart';
import 'package:field_crm/features/pending/presentation/pending_center_screen.dart';
import 'package:field_crm/features/pipeline/presentation/pipeline_screen.dart';
import 'package:field_crm/features/profile/presentation/change_password_screen.dart';
import 'package:field_crm/features/profile/presentation/profile_edit_screen.dart';
import 'package:field_crm/features/profile/presentation/profile_screen.dart';
import 'package:field_crm/features/quotations/presentation/quotation_detail_screen.dart';
import 'package:field_crm/features/quotations/presentation/quotation_form_screen.dart';
import 'package:field_crm/features/quotations/presentation/quotation_widgets.dart';
import 'package:field_crm/features/search/presentation/search_screen.dart';
import 'package:field_crm/features/team/presentation/team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// Top-level
// ---------------------------------------------------------------------------

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SplashScreen();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}

@TypedGoRoute<ForgotPasswordRoute>(path: '/forgot-password')
class ForgotPasswordRoute extends GoRouteData with $ForgotPasswordRoute {
  const ForgotPasswordRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ForgotPasswordScreen();
}

@TypedGoRoute<ProfileEditRoute>(path: '/profile/edit')
class ProfileEditRoute extends GoRouteData with $ProfileEditRoute {
  const ProfileEditRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileEditScreen();
}

@TypedGoRoute<ChangePasswordRoute>(path: '/profile/password')
class ChangePasswordRoute extends GoRouteData with $ChangePasswordRoute {
  const ChangePasswordRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ChangePasswordScreen();
}

@TypedGoRoute<QuotationNewRoute>(path: '/quotations/new')
class QuotationNewRoute extends GoRouteData with $QuotationNewRoute {
  const QuotationNewRoute({this.customerId, this.opportunityId});
  final String? customerId;
  final String? opportunityId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      QuotationFormScreen(customerId: customerId, opportunityId: opportunityId);
}

@TypedGoRoute<QuotationDetailRoute>(path: '/quotations/:id')
class QuotationDetailRoute extends GoRouteData with $QuotationDetailRoute {
  const QuotationDetailRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      QuotationDetailScreen(id: id);
}

@TypedGoRoute<PendingInvoicesRoute>(path: '/invoices')
class PendingInvoicesRoute extends GoRouteData with $PendingInvoicesRoute {
  const PendingInvoicesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PendingInvoicesScreen();
}

@TypedGoRoute<LockRoute>(path: '/lock')
class LockRoute extends GoRouteData with $LockRoute {
  const LockRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const LockScreen();
}

@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SearchScreen();
}

@TypedGoRoute<NotificationsRoute>(path: '/notifications')
class NotificationsRoute extends GoRouteData with $NotificationsRoute {
  const NotificationsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationsScreen();
}

@TypedGoRoute<PendingRoute>(path: '/pending')
class PendingRoute extends GoRouteData with $PendingRoute {
  const PendingRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PendingCenterScreen();
}

@TypedGoRoute<TeamRoute>(path: '/team')
class TeamRoute extends GoRouteData with $TeamRoute {
  const TeamRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const TeamScreen();
}

@TypedGoRoute<DevMenuRoute>(path: '/dev')
class DevMenuRoute extends GoRouteData with $DevMenuRoute {
  const DevMenuRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DevMenuScreen();
}

@TypedGoRoute<ActivityFormRoute>(path: '/activity/new')
class ActivityFormRoute extends GoRouteData with $ActivityFormRoute {
  const ActivityFormRoute({this.type, this.relatedType, this.relatedId});
  final String? type;
  final String? relatedType;
  final String? relatedId;

  @override
  Widget build(BuildContext context, GoRouterState state) => ActivityFormScreen(
    type: ActivityType.values.asNameMap()[type],
    relatedType: RelatedType.values.asNameMap()[relatedType],
    relatedId: relatedId,
  );
}

@TypedGoRoute<HistoryRoute>(path: '/history/:type/:id')
class HistoryRoute extends GoRouteData with $HistoryRoute {
  const HistoryRoute({required this.type, required this.id});
  final String type;
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) => HistoryScreen(
    type: RelatedType.values.asNameMap()[type] ?? RelatedType.customer,
    id: id,
  );
}

@TypedGoRoute<CustomerNewRoute>(path: '/customers/new')
class CustomerNewRoute extends GoRouteData with $CustomerNewRoute {
  const CustomerNewRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerFormScreen();
}

@TypedGoRoute<CustomerDetailRoute>(
  path: '/customers/:id',
  routes: [TypedGoRoute<CustomerEditRoute>(path: 'edit')],
)
class CustomerDetailRoute extends GoRouteData with $CustomerDetailRoute {
  const CustomerDetailRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerDetailScreen(id: id);
}

class CustomerEditRoute extends GoRouteData with $CustomerEditRoute {
  const CustomerEditRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerFormScreen(id: id);
}

@TypedGoRoute<OpportunityNewRoute>(path: '/opportunities/new')
class OpportunityNewRoute extends GoRouteData with $OpportunityNewRoute {
  const OpportunityNewRoute({this.customerId});
  final String? customerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OpportunityFormScreen(customerId: customerId);
}

@TypedGoRoute<OpportunityListRoute>(path: '/opportunities/list')
class OpportunityListRoute extends GoRouteData with $OpportunityListRoute {
  const OpportunityListRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OpportunityListScreen();
}

@TypedGoRoute<PipelineRoute>(path: '/opportunities/pipeline')
class PipelineRoute extends GoRouteData with $PipelineRoute {
  const PipelineRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PipelineScreen();
}

@TypedGoRoute<OpportunityDetailRoute>(
  path: '/opportunities/:id',
  routes: [TypedGoRoute<OpportunityEditRoute>(path: 'edit')],
)
class OpportunityDetailRoute extends GoRouteData with $OpportunityDetailRoute {
  const OpportunityDetailRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OpportunityDetailScreen(id: id);
}

class OpportunityEditRoute extends GoRouteData with $OpportunityEditRoute {
  const OpportunityEditRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OpportunityFormScreen(id: id);
}

// ---------------------------------------------------------------------------
// Bottom-nav shell: Home | Clients | CRM | Tasks | Profile
// ---------------------------------------------------------------------------

@TypedStatefulShellRoute<MainShellRoute>(
  branches: [
    TypedStatefulShellBranch<HomeBranch>(
      routes: [TypedGoRoute<HomeRoute>(path: '/home')],
    ),
    TypedStatefulShellBranch<ClientsBranch>(
      routes: [TypedGoRoute<ClientsRoute>(path: '/clients')],
    ),
    TypedStatefulShellBranch<CrmBranch>(
      routes: [TypedGoRoute<CrmRoute>(path: '/crm')],
    ),
    TypedStatefulShellBranch<TasksBranch>(
      routes: [TypedGoRoute<TasksRoute>(path: '/tasks')],
    ),
    TypedStatefulShellBranch<ProfileBranch>(
      routes: [TypedGoRoute<ProfileRoute>(path: '/profile')],
    ),
  ],
)
class MainShellRoute extends StatefulShellRouteData {
  const MainShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(navigationShell: navigationShell);
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
}

class ClientsBranch extends StatefulShellBranchData {
  const ClientsBranch();
}

class CrmBranch extends StatefulShellBranchData {
  const CrmBranch();
}

class TasksBranch extends StatefulShellBranchData {
  const TasksBranch();
}

class ProfileBranch extends StatefulShellBranchData {
  const ProfileBranch();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class ClientsRoute extends GoRouteData with $ClientsRoute {
  const ClientsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerListScreen();
}

class CrmRoute extends GoRouteData with $CrmRoute {
  const CrmRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PipelineScreen();
}

class TasksRoute extends GoRouteData with $TasksRoute {
  const TasksRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const FollowUpsScreen();
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileScreen();
}

// ---------------------------------------------------------------------------
// Router with auth / lock redirects
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..listen(appLockProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: CommonConstants.navKey,
    routes: $appRoutes,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final locked = ref.read(appLockProvider);
      final at = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) {
        return at == '/splash' ? null : '/splash';
      }
      final loggedIn = auth.valueOrNull != null;
      if (!loggedIn) {
        return at == '/login' || at == '/forgot-password' ? null : '/login';
      }
      if (locked) return at == '/lock' ? null : '/lock';
      if (at == '/login' || at == '/splash' || at == '/lock') return '/home';
      return null;
    },
  );
});
