import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PgPage(
      children: const [
        PgHeader(),
        PgTitle(
          title: 'Activity',
          subtitle: 'Protection, restore, sync, and connection events in one place.',
        ),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PgSectionHeader(title: 'Recent activity'),
              SizedBox(height: 20),
              PgEmptyState(
                icon: Icons.monitor_heart_outlined,
                title: 'Nothing to show yet',
                body: 'Your local protection events will appear here as activity persistence is added.',
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        PgCard(
          backgroundColor: Color(0xFFF3F7FF),
          child: Row(
            children: [
              PgIconBox(icon: Icons.privacy_tip_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The current build does not send activity telemetry to a server.',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
