import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Ask & Offer board — the mouth of the Opportunity Network (docs/15 §7.2).
/// Members post what they need (Ask) or what they can give (Offer); anyone
/// can respond, and crucially anyone can *push it further* — relay it to a
/// contact who fits. The relayer is the connector; if it lands, they earn
/// the credit. This is the async, continuous version of the BNI "asks &
/// offers" round. Demo: in-memory posts; production is networking-service
/// with trust-and-relevance-ranked feeds.
enum PostKind { ask, offer }

class BoardPost {
  BoardPost({
    required this.kind,
    required this.author,
    required this.band,
    required this.city,
    required this.category,
    required this.title,
    required this.body,
    required this.tags,
    this.matchHint,
    this.mine = false,
  });

  final PostKind kind;
  final String author;
  final String band;
  final String city;
  final String category;
  final String title;
  final String body;
  final List<String> tags;
  final String? matchHint;
  final bool mine;

  bool responded = false;
  bool relayed = false;
  String? relayedTo;
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  int _filter = 0; // 0 all · 1 asks · 2 offers

  final List<BoardPost> _posts = [
    BoardPost(
      kind: PostKind.ask,
      author: 'Priya Sharma',
      band: 'Platinum',
      city: 'Mumbai',
      category: 'Introduction',
      title: 'Warm intro to a CFO for a Series-A SaaS',
      body:
          'Raising and need a finance leader who has scaled 1→50 Cr ARR. '
          'Fractional is fine to start.',
      tags: ['Finance', 'SaaS', 'Fundraising'],
      matchHint: 'Rohan Mehta in your network fits this',
    ),
    BoardPost(
      kind: PostKind.offer,
      author: 'Vikram Rao',
      band: 'Gold',
      city: 'Bengaluru',
      category: 'Capacity',
      title: '5,000 sq ft of warehouse space in Bhiwandi',
      body:
          'Spare bonded warehousing, immediate. Great for a D2C brand '
          'scaling fulfilment in the west zone.',
      tags: ['Logistics', 'D2C', 'Warehousing'],
    ),
    BoardPost(
      kind: PostKind.ask,
      author: 'Rakesh Agarwal',
      band: 'Silver',
      city: 'Pune',
      category: 'Referral need',
      title: 'Reliable CA for GST + monthly filings',
      body: '40-person logistics firm, current books are a mess. '
          'Need someone hands-on.',
      tags: ['Accounting', 'GST'],
      matchHint: 'Sneha Rao (Rao & Co CA) is a strong match',
    ),
    BoardPost(
      kind: PostKind.offer,
      author: 'Kavya Nair',
      band: 'Gold',
      city: 'Kochi',
      category: 'Mentorship',
      title: 'Mentoring 2 early D2C founders this quarter',
      body: 'Scaled Bloom to 8 figures. Happy to go deep on retention '
          'and CAC with two founders — no charge.',
      tags: ['D2C', 'Growth', 'Mentorship'],
    ),
    BoardPost(
      kind: PostKind.ask,
      author: 'Rahul Verma',
      band: 'Silver',
      city: 'Bengaluru',
      category: 'Hiring',
      title: 'Senior Flutter engineer, full-time',
      body: 'CloudPeak is hiring. 6+ yrs, offline-first experience a plus. '
          'Referral fee on a successful hire.',
      tags: ['Hiring', 'Flutter', 'SaaS'],
    ),
  ];

  List<BoardPost> get _visible => _posts
      .where((p) =>
          _filter == 0 ||
          (_filter == 1 && p.kind == PostKind.ask) ||
          (_filter == 2 && p.kind == PostKind.offer))
      .toList();

  void _compose() {
    showModalBottomSheet<BoardPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ComposeSheet(),
    ).then((post) {
      if (post != null) setState(() => _posts.insert(0, post));
    });
  }

  void _respond(BoardPost p) {
    setState(() => p.responded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(p.kind == PostKind.ask
            ? 'Offered to help — an intro thread with ${p.author} is open.'
            : 'Requested — ${p.author} will confirm and connect.'),
      ),
    );
  }

  void _push(BoardPost p) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _RelaySheet(),
    ).then((who) {
      if (who == null) return;
      setState(() {
        p.relayed = true;
        p.relayedTo = who;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Pushed to $who — you are the connector. '
              'If it lands, the credit is yours.'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ask & Offer')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
        backgroundColor: theme.colorScheme.tertiary,
        foregroundColor: theme.colorScheme.onTertiary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(EmberSpacing.screenGutter,
                EmberSpacing.sm, EmberSpacing.screenGutter, EmberSpacing.xs),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('All')),
                ButtonSegment(value: 1, label: Text('Asks')),
                ButtonSegment(value: 2, label: Text('Offers')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
              showSelectedIcon: false,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(EmberSpacing.screenGutter, 0,
                  EmberSpacing.screenGutter, 96),
              children: [
                for (final p in _visible)
                  _PostCard(post: p, onRespond: _respond, onPush: _push),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard(
      {required this.post, required this.onRespond, required this.onPush});
  final BoardPost post;
  final void Function(BoardPost) onRespond;
  final void Function(BoardPost) onPush;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gold = theme.colorScheme.tertiary;
    final teal = isDark ? EmberColors.infoDark : EmberColors.infoLight;
    final green = isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final isAsk = post.kind == PostKind.ask;
    final accent = isAsk ? gold : teal;
    final initials = post.author
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: EmberSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(EmberSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: EmberSpacing.xs, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(EmberRadii.chip),
                  ),
                  child: Text(isAsk ? 'ASK' : 'OFFER',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                ),
                const SizedBox(width: EmberSpacing.xs),
                Text(post.category,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: EmberSpacing.xs),
            Text(post.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: EmberSpacing.xxs),
            Text(post.body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: EmberSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: gold.withValues(alpha: 0.15),
                  foregroundColor: gold,
                  child: Text(initials,
                      style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: EmberSpacing.xs),
                Expanded(
                  child: Text('${post.author} · ${post.band} · ${post.city}',
                      style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            if (post.matchHint != null) ...[
              const SizedBox(height: EmberSpacing.xs),
              Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 14, color: gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(post.matchHint!,
                        style: theme.textTheme.bodySmall?.copyWith(color: gold)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: EmberSpacing.sm),
            if (post.relayed)
              Row(children: [
                Icon(Icons.forward_outlined, size: 16, color: green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      'Pushed to ${post.relayedTo} — you’re the connector',
                      style: theme.textTheme.bodySmall?.copyWith(color: green)),
                ),
              ])
            else if (post.responded)
              Row(children: [
                Icon(Icons.check_circle_outline, size: 16, color: green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      isAsk ? 'You offered to help' : 'You asked to connect',
                      style: theme.textTheme.bodySmall?.copyWith(color: green)),
                ),
              ])
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onRespond(post),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40)),
                      child: Text(isAsk ? 'I can help' : 'I want this'),
                    ),
                  ),
                  const SizedBox(width: EmberSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: () => onPush(post),
                    icon: const Icon(Icons.forward_outlined, size: 18),
                    label: const Text('Push'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RelaySheet extends StatelessWidget {
  const _RelaySheet();

  static const _suggested = [
    ('Rohan Mehta', 'Mehta Ventures · strong tie'),
    ('Sneha Rao', 'Rao & Co CA · fits the category'),
    ('Arjun Malhotra', 'GrowthLab Agency · in your network'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EmberSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Push to someone who fits',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: EmberSpacing.xxs),
            Text(
              'Forward this to a contact. If they take it up, you brokered it '
              '— and the connector credit is yours.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: EmberSpacing.sm),
            for (final (name, why) in _suggested)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(name),
                subtitle: Text(why),
                trailing: const Icon(Icons.forward_outlined),
                onTap: () => Navigator.of(context).pop(name),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  PostKind _kind = PostKind.ask;
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: EmberSpacing.lg,
        right: EmberSpacing.lg,
        top: EmberSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + EmberSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Post to the board', style: theme.textTheme.titleMedium),
          const SizedBox(height: EmberSpacing.sm),
          SegmentedButton<PostKind>(
            segments: const [
              ButtonSegment(value: PostKind.ask, label: Text('I need…')),
              ButtonSegment(value: PostKind.offer, label: Text('I can give…')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: EmberSpacing.sm),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'One line',
              hintText: 'Warm intro to a CFO · Spare warehouse space…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          TextField(
            controller: _body,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Details',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Text(
            'Visible to your communities and trusted network first, then more '
            'widely — ranked by fit, never a firehose.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.sm),
          FilledButton(
            onPressed: () {
              final t = _title.text.trim();
              if (t.isEmpty) return;
              Navigator.of(context).pop(BoardPost(
                kind: _kind,
                author: 'You',
                band: 'Gold',
                city: 'Mumbai',
                category: _kind == PostKind.ask ? 'Ask' : 'Offer',
                title: t,
                body: _body.text.trim().isEmpty
                    ? '(no details)'
                    : _body.text.trim(),
                tags: const [],
                mine: true,
              ));
            },
            child: const Text('Post to the board'),
          ),
        ],
      ),
    );
  }
}
