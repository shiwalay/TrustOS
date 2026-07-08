/// Typed route table — 09-mobile-architecture.md §5.1.
abstract final class Routes {
  // Tabs (StatefulShellRoute branches).
  static const home = '/home';
  static const network = '/network';
  static const actionHub = '/act'; // center tab: the write verbs
  static const communities = '/communities';
  static const you = '/you';

  // Onboarding (outside the shell; auth guard redirects here).
  static const onboarding = '/onboarding';

  // Network branch.
  static const contacts = '/network/contacts';
  static const relationships = '/network/relationships';
  static String introDetail(String id) => '/network/intros/$id';

  // Communities branch.
  static String communityFeed(String id) => '/communities/$id/feed';

  // You branch.
  static const trustProfile = '/you/trust';
  static const rewards = '/you/rewards';
  static const deals = '/you/deals';
  static const campaigns = '/you/campaigns';
  static const leaderboards = '/you/leaderboards';
  static const identity = '/you/identity';
  static const invites = '/you/invites';
  static const settings = '/you/settings';

  // Referrals (pushed over the shell — deep-linkable from push notifications).
  static String referralDetail(String id) => '/referrals/$id';
  static String campaignDetail(String cmpId) => '/referrals/campaigns/$cmpId';
  static String campaignReferrals(String cmpId) =>
      '/referrals/campaigns/$cmpId/mine';

  // Global overlay destinations.
  static const copilot = '/copilot';
  static const marketplace = '/marketplace';
  static const knowledge = '/knowledge';
  static const briefing = '/briefing';
  static const board = '/board';
  static const neo = '/neo';
  static const standing = '/you/standing';

  /// Seed campaign so the vertical slice is reachable before campaign sync
  /// exists ('cmp_' + UUIDv7 shape per _shared-context.md §1).
  static const demoCampaignId = 'cmp_0190demo0000000000000000000000';

  static String dealDetail(String id) => '/deals/$id';
}
