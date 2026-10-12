import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:field_crm/features/team/domain/team.dart';

/// The whole in-memory "server". Serialisable so the mock survives restarts.
class MockState {
  MockState({
    required this.users,
    required this.passwords,
    required this.teams,
    required this.stages,
    required this.activityTypes,
    required this.customers,
    required this.opportunities,
    required this.activities,
    required this.history,
    Map<String, String>? sessions,
    Map<String, String>? passwordResets,
    List<Quotation>? quotations,
    List<Invoice>? invoices,
    List<Product>? products,
    List<AppNotification>? notifications,
  }) : sessions = sessions ?? {},
       passwordResets = passwordResets ?? {},
       quotations = quotations ?? [],
       invoices = invoices ?? [],
       products = products ?? [],
       notifications = notifications ?? [];

  factory MockState.fromJson(Map<String, dynamic> j) => MockState(
    users: listFromJson(j['users'], AppUser.fromJson),
    passwords: Map<String, String>.from(j['passwords'] as Map),
    teams: listFromJson(j['teams'], Team.fromJson),
    stages: listFromJson(j['stages'], PipelineStage.fromJson),
    activityTypes: listFromJson(j['activityTypes'], ActivityTypeDef.fromJson),
    customers: listFromJson(j['customers'], Customer.fromJson),
    opportunities: listFromJson(j['opportunities'], Opportunity.fromJson),
    activities: listFromJson(j['activities'], Activity.fromJson),
    history: (j['history'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, listFromJson(v, HistoryEntry.fromJson)),
    ),
    sessions: Map<String, String>.from(j['sessions'] as Map? ?? {}),
    passwordResets: Map<String, String>.from(j['passwordResets'] as Map? ?? {}),
    quotations: listFromJson(j['quotations'], Quotation.fromJson),
    invoices: listFromJson(j['invoices'], Invoice.fromJson),
    products: listFromJson(j['products'], Product.fromJson),
    notifications: listFromJson(j['notifications'], AppNotification.fromJson),
  );

  final List<AppUser> users;
  final Map<String, String> passwords;
  final List<Team> teams;
  final List<PipelineStage> stages;
  final List<ActivityTypeDef> activityTypes;
  final List<Customer> customers;
  final List<Opportunity> opportunities;
  final List<Activity> activities;

  /// Keyed by `"$relatedType:$relatedId"`.
  final Map<String, List<HistoryEntry>> history;

  /// token -> userId
  final Map<String, String> sessions;

  /// email -> one-time reset code
  final Map<String, String> passwordResets;
  final List<Quotation> quotations;
  final List<Invoice> invoices;
  final List<Product> products;
  final List<AppNotification> notifications;

  Map<String, dynamic> toJson() => {
    'users': users.map((e) => e.toJson()).toList(),
    'passwords': passwords,
    'teams': teams.map((e) => e.toJson()).toList(),
    'stages': stages.map((e) => e.toJson()).toList(),
    'activityTypes': activityTypes.map((e) => e.toJson()).toList(),
    'customers': customers.map((e) => e.toJson()).toList(),
    'opportunities': opportunities.map((e) => e.toJson()).toList(),
    'activities': activities.map((e) => e.toJson()).toList(),
    'history': history.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    ),
    'sessions': sessions,
    'passwordResets': passwordResets,
    'quotations': quotations.map((e) => e.toJson()).toList(),
    'invoices': invoices.map((e) => e.toJson()).toList(),
    'products': products.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
  };

  static List<T> listFromJson<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) => (raw as List? ?? const [])
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();

  static String historyKey(RelatedType type, String id) => '${type.name}:$id';
}
