import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc_part/part_bloc.dart';
import 'package:workout/models/PartFocusRoutine.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:logging/logging.dart';

class PartDetailBottomSheet extends StatefulWidget {
  final int partId;
  final String userId;

  const PartDetailBottomSheet({
    Key? key,
    required this.partId,
    required this.userId
  }) : super(key: key);

  @override
  _PartDetailBottomSheetState createState() => _PartDetailBottomSheetState();
}


class _PartDetailBottomSheetState extends State<PartDetailBottomSheet> {

  late PartsBloc _partsBloc;
  final _logger = Logger('PartDetailBottomSheet');




  @override
  void initState() {
    super.initState();
    _partsBloc = context.read<PartsBloc>();
    _logger.info("PartDetailBottomSheet initialized with partId: ${widget.partId}");

    if (widget.partId > 0) {
      _partsBloc.add(FetchPartExercises(partId: widget.partId));
    } else {
      _logger.warning("Invalid partId: ${widget.partId}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz part ID. Lütfen tekrar deneyin.')),
        );
        Navigator.of(context).pop();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final state = _partsBloc.state;
        if (state is PartExercisesLoaded) {
          _partsBloc.add(UpdatePart(state.part));
          _partsBloc.add(FetchParts());
        }
        Navigator.of(context).pop();
      },

      child: BlocListener<PartsBloc, PartsState>(
        listener: (context, state) {
          if (state is PartsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: BlocBuilder<PartsBloc, PartsState>(
                builder: (context, state) {
                  _logger.info('PartDetailBottomSheet state: $state');

                  if (state is PartsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is PartExercisesLoaded) {
                    return _buildLoadedContent(state, controller);
                  }

                  if (state is PartsError) {
                    return Center(child: Text('Hata: ${state.message}'));
                  }

                  return Center(
                    child: Text('Beklenmeyen durum: ${state.runtimeType}'),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(PartExercisesLoaded state, ScrollController controller) {
    return ListView(
      controller: controller,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: PartCard(
            part: state.part,
            userId: widget.userId,
            onTap: () => _partsBloc.add(FetchPartExercises(partId: state.part.id)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Egzersizler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ..._buildExerciseList(state.exerciseListByBodyPart),
      ],
    );
  }

  List<Widget> _buildExerciseList(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...entry.value.map((exercise) => _buildExerciseListTile(exercise)).toList(),
        ],
      );
    }).toList();
  }

  Widget _buildExerciseListTile(Map<String, dynamic> exercise) {
    return ListTile(
      title: Text(exercise['name']),
      subtitle: Text(
        'Set: ${exercise['defaultSets']}, '
            'Tekrar: ${exercise['defaultReps']}, '
            'Ağırlık: ${exercise['defaultWeight']}',
      ),
      trailing: Text(exercise['workoutType']),
    );
  }
}