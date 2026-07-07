import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';

/// Marketplace — services, consulting, jobs with trust-band provenance
/// (marketplace-service). Verified engagements, not review-farm stars.
/// Demo data.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  static const _listings = [
    ('GST cleanup & monthly filings', 'Rao & Co CA · Hyderabad',
        'Silver · 12 verified engagements', '₹15k/mo'),
    ('Brand identity sprint (2 weeks)', 'Meridian Design · Mumbai',
        'Gold · 23 verified engagements', '₹85k'),
    ('D2C growth audit', 'GrowthLab Agency · Delhi',
        'Silver · 9 verified engagements', '₹35k'),
    ('Hiring: senior Flutter engineer', 'CloudPeak SaaS · Bengaluru',
        'Gold · via Rahul Verma', '₹28–35L'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in ['All', 'Services', 'Consulting', 'Jobs',
                  'Partnerships'])
                  Padding(
                    padding: const EdgeInsets.only(right: EmberSpacing.xs),
                    child: FilterChip(
                      label: Text(f),
                      selected: f == 'All',
                      onSelected: (_) {},
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          for (final (title, seller, provenance, price) in _listings)
            Card(
              margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
              child: ListTile(
                title: Text(title),
                subtitle: Text('$seller\n$provenance'),
                isThreeLine: true,
                trailing: Text(
                  price,
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: gold),
                ),
                onTap: () {},
              ),
            ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            '"Verified engagements" are ledger-settled orders — the '
            'marketplace runs on the same outcome truth as your Trust '
            'Index. No review farms.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
