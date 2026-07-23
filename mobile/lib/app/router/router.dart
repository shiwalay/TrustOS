import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/onboarding_state.dart';
import '../../features/board/presentation/screens/board_screen.dart';
import '../../features/briefing/presentation/screens/briefing_screen.dart';
import '../../features/campaigns/presentation/screens/campaigns_screen.dart';
import '../../features/communities/presentation/screens/communities_screen.dart';
import '../../features/connectors/presentation/screens/connectors_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/copilot/presentation/screens/copilot_screen.dart';
import '../../features/deals/presentation/screens/deals_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/identity/presentation/screens/identity_screen.dart';
import '../../features/invites/presentation/screens/invites_screen.dart';
import '../../features/knowledge/presentation/screens/knowledge_screen.dart';
import '../../features/leaderboards/presentation/screens/leaderboards_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/neo/presentation/screens/neo_dashboard_screen.dart';
import '../../features/networking/presentation/screens/network_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/referrals/presentation/screens/my_referrals_screen.dart';
import '../../features/relationships/presentation/screens/relationships_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/you_screen.dart';
import '../../features/standing/presentation/screens/standing_screen.dart';
import '../../features/trust/presentation/screens/trust_screen.dart';
import '../shell/action_hub_screen.dart';
import '../shell/app_shell.dart';
import 'routes.dart';

/// Session stub for the auth-guard redirect. Real implementation: OIDC
/// session presence from the secure vault (09 §5.3) + biometric re-lock
/// overlay on resume-after-5-min. Until then, session presence == completed
/// onboarding, so first launch (and "Replay onboarding") lands on /onboarding.
final isAuthenticatedProvider =
    Provider<bool>((ref) => ref.watch(onboardedProvider));

/// GoRouter — 5-tab StatefulShellRoute per 09-mobile-architecture.md §5.1.
/// Deep links received before bootstrap completes are replayed after first
/// frame (cold-start queue — later milestone).
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final inOnboarding = state.matchedLocation.startsWith(Routes.onboarding);
      if (!isAuthenticated && !inOnboarding) return Routes.onboarding;
      if (isAuthenticated && inOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ------------------------------------------------- 5-tab shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.network,
              builder: (context, state) => const NetworkScreen(),
              routes: [
                GoRoute(
                  path: 'contacts',
                  builder: (context, state) => const ContactsScreen(),
                ),
                GoRoute(
                  path: 'relationships',
                  builder: (context, state) => const RelationshipsScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.actionHub,
              builder: (context, state) => const ActionHubScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.communities,
              builder: (context, state) => const CommunitiesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.you,
              builder: (context, state) => const YouScreen(),
              routes: [
                GoRoute(
                  path: 'trust',
                  builder: (context, state) => const TrustProfileScreen(),
                ),
                GoRoute(
                  path: 'rewards',
                  builder: (context, state) => const RewardsScreen(),
                ),
                GoRoute(
                  path: 'deals',
                  builder: (context, state) => const DealsScreen(),
                ),
                GoRoute(
                  path: 'campaigns',
                  builder: (context, state) => const CampaignsScreen(),
                ),
                GoRoute(
                  path: 'leaderboards',
                  builder: (context, state) => const LeaderboardsScreen(),
                ),
                GoRoute(
                  path: 'invites',
                  builder: (context, state) => const InvitesScreen(),
                ),
                GoRoute(
                  path: 'identity',
                  builder: (context, state) => const IdentityScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'standing',
                  builder: (context, state) => const StandingScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ----------------------- pushed over the shell (deep-linkable)
      GoRoute(
        path: '/referrals/campaigns/:cmpId/mine',
        builder: (context, state) => MyReferralsScreen(
          campaignId: state.pathParameters['cmpId']!,
        ),
      ),
      GoRoute(
        path: Routes.copilot,
        builder: (context, state) => const CopilotScreen(),
      ),
      GoRoute(
        path: Routes.marketplace,
        builder: (context, state) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: Routes.knowledge,
        builder: (context, state) => const KnowledgeScreen(),
      ),
      GoRoute(
        path: Routes.briefing,
        builder: (context, state) => const BriefingScreen(),
      ),
      GoRoute(
        path: Routes.board,
        builder: (context, state) => const BoardScreen(),
      ),
      GoRoute(
        path: Routes.connectors,
        builder: (context, state) => const ConnectorsScreen(),
      ),
      GoRoute(
        path: Routes.neo,
        builder: (context, state) => const NeoDashboardScreen(),
      ),
    ],
  );
});
