// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:workout/ui/part_ui/part_detail.dart';
import 'package:logging/logging.dart';
import 'package:workout/data_bloc_part/part_bloc.dart';
import '../../data_bloc_part/PartRepository.dart';
import '../../models/BodyPart.dart';
import '../../models/Parts.dart';
import '../part_ui/part_card.dart';

class PartsPage extends StatefulWidget {
  final String userId;

  const PartsPage({super.key, required this.userId});

  @override
  _PartsPageState createState() => _PartsPageState();
}

class _PartsPageState extends State<PartsPage> {
  late PartsBloc _partsBloc;
  final _logger = Logger('PartsPage');
  String? _selectedDifficulty;
  List<Map<String, dynamic>> difficultyFilterOptions = [];
  bool _isListView = false;
  int _currentBodyPartIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _setupLogging();
    _partsBloc = BlocProvider.of<PartsBloc>(context);
    _loadAllData();
    _loadFilterOptions();

  }

  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.loggerName}: ${record.level.name}: ${record.message}');
    });
  }

  void _loadAllData() {
    _logger.info('Loading all parts for user: ${widget.userId}');
    _partsBloc.add(FetchParts());
    setState(() {
      _selectedDifficulty = null;
    });
  }


  Future<void> _loadFilterOptions() async {
    List<Parts> allParts = await _partsBloc.repository.getAllParts();
    Set<String> uniqueDifficulties = allParts.map((part) => part.difficulty.toString()).toSet();
    setState(() {
      difficultyFilterOptions = buildDifficultyFilter(uniqueDifficulties.toList())
        ..sort((a, b) => int.parse(a['value']).compareTo(int.parse(b['value'])));
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Vücut Bölümleri', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: BlocBuilder<PartsBloc, PartsState>(
        builder: (context, state) {
          if (state is PartsLoading) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 50,
              ),
            );
          } else if (state is PartsLoaded) {
            return _buildPartsContent(state.parts);
          } else if (state is PartsError) {
            return _buildErrorWidget(state.message);
          } else {
            return _buildUnknownStateWidget();
          }
        },
      ),
    );
  }

  Widget _buildPartsContent(List<Parts> parts) {
    List<Parts> filteredParts = _filterParts(parts);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _partsBloc.repository.getAllBodyParts().then((bodyParts) =>
          bodyParts.map((bp) => bp.toMap()).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata oluştu: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Hiç body part bulunamadı.', style: TextStyle(color: Colors.white)));
        }

        List<Map<String, dynamic>> bodyParts = snapshot.data!;

        return Column(
          children: [
            _buildDifficultyFilter(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: bodyParts.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentBodyPartIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final bodyPart = bodyParts[index];
                  return Column(
                    children: [
                      _buildBodyPartTabs(bodyParts),
                      Expanded(
                        child: _buildBodyPartSection(
                          bodyPart['id'],
                          bodyPart['name'],
                          filteredParts,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyPartTabs(List<Map<String, dynamic>> bodyParts) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: bodyParts.length,
        itemBuilder: (context, index) {
          final bodyPart = bodyParts[index];
          final isSelected = index == _currentBodyPartIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: isSelected ? 6 : 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrangeAccent: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  bodyPart['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSelected ? 16 : 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    // Difficulty'leri sırala
    List<Map<String, dynamic>> sortedDifficulties = List.from(difficultyFilterOptions)
      ..sort((a, b) => int.parse(a['value']).compareTo(int.parse(b['value'])));

    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[850],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: Icon(Icons.all_inbox, color: Colors.white, size: 15),
              selected: _selectedDifficulty == null,
              onSelected: (selected) => setState(() => _selectedDifficulty = null),
            ),
            ...sortedDifficulties.map((difficulty) => _buildFilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color: index < int.parse(difficulty['value']) ? Colors.yellow : Colors.grey,
                    size: 12,
                  );
                }),
              ),
              selected: _selectedDifficulty == difficulty['value'],
              onSelected: (selected) => setState(() => _selectedDifficulty = selected ? difficulty['value'] : null),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartSection(int bodyPartId, String bodyPartName, List<Parts> filteredParts) {
    // Belirtilen bodyPartId'ye göre parçaları filtrele
    final bodyPartParts = filteredParts.where((part) => part.targetedBodyPartIds.contains(bodyPartId)).toList();

    // Eğer filtrelenmiş parça yoksa kullanıcıya bilgi ver
    if (bodyPartParts.isEmpty) {
      return Center(child: Text('Bu bölüm için parça bulunamadı.', style: TextStyle(color: Colors.white)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    bodyPartName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right_alt, color: Colors.white),
                    onPressed: () {
                      // _getBodyParts() metodunu tanımlayın veya mevcut bir metodu çağırın
                      int previousIndex = (_currentBodyPartIndex + 1) % filteredParts.length;
                      _pageController.animateToPage(
                        previousIndex,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Görünümü Değiştir',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(_isListView ? Icons.grid_view : Icons.list, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isListView = !_isListView;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isListView
              ? _buildListView(bodyPartParts)
              : _buildCardView(bodyPartParts),
        ),
      ],
    );
  }

  Widget _buildListView(List<Parts> parts) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            title: Text(
              part.name,
              style: TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Row(
              children: List.generate(5, (i) => Icon(
                i < part.difficulty ? Icons.star : Icons.star_border,
                color: Colors.yellow,
                size: 12,
              )),
            ),
            trailing: Icon(
              part.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: part.isFavorite ? Colors.red : Colors.grey,
              size: 16,
            ),
            onTap: () => _showPartDetailBottomSheet(part.id),
          ),
        );
      },
    );
  }

  Widget _buildCardView(List<Parts> parts) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        return PartCard(
          part: parts[index],
          userId: widget.userId,
          repository: context.read<PartRepository>(),
          onTap: () => _showPartDetailBottomSheet(parts[index].id),
          onFavoriteChanged: (isFavorite) {
            context.read<PartsBloc>().add(
              TogglePartFavorite(
                userId: widget.userId,
                partId: parts[index].id.toString(),
                isFavorite: isFavorite,
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildFilterChip({required Widget label, required bool selected, required Function(bool) onSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.white,
      ),
    );
  }

  List<Map<String, dynamic>> buildDifficultyFilter(List<String> difficulties) {
    return difficulties.map((difficulty) => {'value': difficulty, 'child': 'Difficulty $difficulty'}).toList();
  }

  List<Parts> _filterParts(List<Parts> parts) {
    return parts.where((part) {
      return _selectedDifficulty == null || part.difficulty.toString() == _selectedDifficulty;
    }).toList();
  }

  Future<void> _showPartDetailBottomSheet(int partId) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PartDetailBottomSheet(partId: partId, userId: widget.userId),
      );
      _loadAllData();
    } catch (e, stackTrace) {
      _logger.severe('Error showing part detail bottom sheet', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parça detayları yüklenirken bir hata oluştu')),
      );
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text('Hata: $message', style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAllData, child: Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildUnknownStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
          SizedBox(height: 16),
          Text('Bilinmeyen durum', style: TextStyle(fontSize: 18, color: Colors.white)),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAllData, child: Text('Yenile')),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentBodyPartIndex == index ? Colors.blue : Colors.grey,
            ),
          );
        }),
      ),
    );
  }
}
