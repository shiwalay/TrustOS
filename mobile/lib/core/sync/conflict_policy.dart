/// Per-entity-class conflict policies — 09-mobile-architecture.md §4.4.
enum ConflictPolicy {
  /// Computed/authoritative data (DTI, leaderboards, balances): local rows
  /// are pure cache, no local edits exist — server wins, always.
  serverWins,

  /// User-authored content (notes, profile fields, drafts): last-write-wins
  /// with field-level three-way merge against `baseVersionJson`; superseded
  /// edits are preserved locally and surfaced, never silently dropped.
  lwwMerge,

  /// Money / irreversible actions (submit referral, accept intro, orders,
  /// coin spend): NEVER optimistic. Local row is explicitly `pendingSync`;
  /// value renders only from server-confirmed state; terminal rejection
  /// triggers a compensating local write + user notification.
  queueAndConfirm,
}
