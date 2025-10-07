import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/entry_planner.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/bootstrap/extensions.dart';

class EntryPlannerRow extends StatefulWidget {
  const EntryPlannerRow({super.key, required this.entryPlanner});

  final EntryPlanner entryPlanner;

  @override
  createState() => _EntryPlannerRowState();
}

class _EntryPlannerRowState extends NyState<EntryPlannerRow> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    final feedTimings = widget.entryPlanner.feedTimings ?? const <String>[];

    if (feedTimings.isEmpty) {
      return Container(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("No Feeding Times Added").bodyLarge(),
      ));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: feedTimings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final time = feedTimings[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.color.content.withAlpha((255.0 * 0.3).round()),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Feeding ${index + 1}").bodySmall(
                      color: context.color.content
                          .withAlpha((255.0 * 0.8).round()),
                    ),
                    const SizedBox(height: 4),
                    Text(time).displaySmall(
                      color: context.color.content
                          .withAlpha((255.0 * 0.9).round()),
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
                splashRadius: 20,
                tooltip: "Options",
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {},
                splashRadius: 20,
                tooltip: "Options",
              ),
            ],
          ),
        );
      },
    );
  }
}
