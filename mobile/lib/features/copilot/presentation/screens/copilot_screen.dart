import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';

/// Copilot — context-seeded assistant sheet (10-ux-design.md: a capability,
/// not a tab). Demo: canned grounded replies; production routes through
/// ai-gateway with the grounded-or-silent rule (07 §4).
class CopilotScreen extends StatefulWidget {
  const CopilotScreen({super.key});

  @override
  State<CopilotScreen> createState() => _CopilotScreenState();
}

class _Msg {
  const _Msg(this.fromUser, this.text);
  final bool fromUser;
  final String text;
}

class _CopilotScreenState extends State<CopilotScreen> {
  final _controller = TextEditingController();

  final List<_Msg> _messages = [
    const _Msg(false,
        'Good evening. Two things worth your attention: Rohan Mehta has '
        'been quiet for 44 days, and the clinic campaign closes in 20 '
        'days with one referral still unqualified. Want a hand with '
        'either?'),
    const _Msg(true, 'Draft a follow-up for Rohan'),
    const _Msg(false,
        'Here is a draft — warm, no ask, references your last meeting '
        '(9 Mar, Deshmukh Realty intro):\n\n'
        '"Rohan, saw Mehta Ventures in the news on the Pune fund — '
        'congratulations. It has been a while since our chat about the '
        'realty intro; coffee next week when you are in Bandra?"\n\n'
        'Grounded in: 3 timeline entries, 1 news item. Edit freely — '
        'nothing sends without you.'),
  ];

  static const _suggestions = [
    'Who should I meet this week?',
    'Summarize my pipeline',
    'Prep me for the Nexa call',
  ];

  void _send([String? preset]) {
    final text = preset ?? _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(true, text));
      _messages.add(const _Msg(false,
          'On it — in production this routes through the ai-gateway with '
          'your relationship graph as context. (Demo mode: canned reply.)'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Copilot')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmberSpacing.screenGutter),
              children: [
                for (final m in _messages)
                  Align(
                    alignment: m.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: EmberSpacing.sm),
                      padding: const EdgeInsets.all(EmberSpacing.sm),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: m.fromUser
                            ? gold.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(EmberRadii.card),
                        border: m.fromUser
                            ? Border.all(color: gold.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(m.text, style: theme.textTheme.bodyMedium),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: EmberSpacing.screenGutter),
              children: [
                for (final s in _suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: EmberSpacing.xs),
                    child: ActionChip(
                      label: Text(s),
                      onPressed: () => _send(s),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your network…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: EmberSpacing.xs),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
