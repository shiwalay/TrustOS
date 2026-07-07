import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';

/// Knowledge hub — playbooks, templates, prompts (knowledge-service).
/// Endorsements, not likes: contribution feeds the knowledge component
/// of trust. Demo data.
class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  static const _items = [
    ('Playbook', 'The warm-intro message that gets replies',
        'Priya Sharma · 48 endorsements', Icons.menu_book_outlined),
    ('Template', 'Referral follow-up sequence (3 touches)',
        'Arjun Malhotra · 31 endorsements', Icons.copy_all_outlined),
    ('SOP', 'Qualifying a clinic lead in one call',
        'Meddo Health · 27 endorsements', Icons.checklist_outlined),
    ('Prompt', 'Meeting-prep brief from a LinkedIn profile',
        'Rahul Verma · 19 endorsements', Icons.auto_awesome_outlined),
    ('Case study', 'How Mumbai Founders Circle settled ₹4.6L in Q2',
        'Community team · 12 endorsements', Icons.insights_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search playbooks, templates, prompts…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EmberRadii.card),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          for (final (kind, title, meta, icon) in _items)
            Card(
              margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
              child: ListTile(
                leading: Icon(icon, color: gold),
                title: Text(title),
                subtitle: Text('$kind · $meta'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Endorsed contributions feed the knowledge component of your '
            'Trust Index — and the copilot cites this library when it '
            'coaches you.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
