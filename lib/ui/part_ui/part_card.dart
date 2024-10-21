import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/ui/part_ui/part_detail.dart';

import '../../data_bloc_part/part_bloc.dart';
import '../../models/PartFocusRoutine.dart';

class PartCard extends StatelessWidget {
  final Parts part;
  final String userId;
  final VoidCallback? onTap;

  const PartCard({Key? key, required this.part, required this.userId, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      part.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildFavoriteButton(context),
                ],
              ),
              SizedBox(height: 2),
              _buildInfoChip('Body Part', part.bodyPartId.toString()),
              SizedBox(height: 2),
              _buildInfoChip('Set Type', part.setTypeString),
              if (part.additionalNotes.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Text(
                      part.additionalNotes,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              SizedBox(height: 5),
              _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        part.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: part.isFavorite ? Colors.red : null,
      ),
      onPressed: () {
        context.read<PartsBloc>().add(
          TogglePartFavorite(
            userId: userId,
            partId: part.id.toString(),
            isFavorite: !part.isFavorite,
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = part.userProgress ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress: $progress%'),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }
}
