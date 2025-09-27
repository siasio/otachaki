import 'package:flutter/material.dart';
import '../services/statistics_manager.dart';
import '../models/dataset_type.dart';
import '../models/daily_statistics.dart';
import './detailed_statistics_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  StatisticsManager? _statisticsManager;
  DailyStatistics? _todayStats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _loading = true;
    });

    try {
      _statisticsManager = await StatisticsManager.getInstance();
      _todayStats = _statisticsManager!.getTodayStatistics();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Information'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dataset Types Explained
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.library_books, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Dataset Types Explained',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDatasetExplanation(
                      'Final 9x9 Positions',
                      'Game-ending positions on 9x9 boards analyzed with KataGo\'s AI ownership maps. '
                      'These positions show clear territorial outcomes where stones are mostly settled. '
                      'Good for beginners to learn basic territory evaluation.',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      '🏟️ Final 19x19 Positions',
                      'Game-ending positions on full 19x19 boards with AI-based territory analysis. '
                      'More complex than 9x9 with larger-scale territorial judgments. '
                      'Ideal for intermediate players.',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      '⚡ Midgame 19x19 Estimation',
                      'Mid-game positions where the outcome is not yet decided. '
                      'Requires evaluating potential territory, influence, and fighting outcomes. '
                      'Challenging positions for advanced players to test territorial intuition.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // How to Use the App
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'How to Use the App',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🎯 App Functionality',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• View Go positions from actual games and predict the winner\n'
                      '• Choose from different datasets (9x9 final, 19x19 midgame, etc.)\n'
                      '• Get immediate feedback on your predictions\n'
                      '• Track your accuracy with built-in scoring',
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '⌨️ Keyboard Shortcuts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ← Left Arrow: Select White Wins\n'
                      '• ↓ Down Arrow: Select Draw\n'
                      '• → Right Arrow: Select Black Wins\n'
                      '• Look for arrow icons on the buttons for quick reference',
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '⚙️ Configuration Options',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Use the gear icon in the training screen to access settings\n'
                      '• Customize scoring thresholds for each dataset type\n'
                      '• Adjust timer settings and display preferences\n'
                      '• Choose from different themes and layouts',
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Statistics
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.today, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Today\'s Statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_todayStats == null || !_todayStats!.hasAttempts)
                        const Text(
                          'No practice sessions yet today. Start training to see your statistics!',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        )
                      else
                        ..._buildTodayStatsContent(),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // About Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Go Territory Counting Training App',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This app helps you practice predicting game outcomes from Go positions. '
                      'You can load different datasets containing positions from actual games '
                      'and test your ability to determine who is winning.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatasetExplanation(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTodayStatsContent() {
    if (_todayStats == null) return [];

    final List<Widget> widgets = [];

    for (final datasetType in _todayStats!.activeDatasetTypes) {
      final stats = _todayStats!.getStatsForDataset(datasetType);
      if (stats != null) {
        widgets.add(_buildDatasetStatCard(datasetType, stats));
        widgets.add(const SizedBox(height: 12));
      }
    }

    // Remove the last SizedBox
    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }

    return widgets;
  }

  Widget _buildDatasetStatCard(DatasetType datasetType, DailyDatasetStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getDatasetDisplayName(datasetType),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.analytics_outlined, size: 20),
                onPressed: () => _navigateToDetailedStats(datasetType),
                tooltip: 'View detailed statistics',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Accuracy',
                  '${stats.accuracyPercentage.toStringAsFixed(1)}%',
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Problems',
                  '${stats.totalAttempts}',
                  Icons.quiz_outlined,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Avg Time',
                  '${stats.averageTimeSeconds.toStringAsFixed(1)}s',
                  Icons.timer_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getDatasetDisplayName(DatasetType datasetType) {
    switch (datasetType) {
      case DatasetType.final9x9Area:
        return 'Final 9x9 Positions';
      case DatasetType.final19x19Area:
        return '🏟️ Final 19x19 Positions';
      case DatasetType.midgame19x19Estimation:
        return '⚡ Midgame 19x19 Estimation';
      case DatasetType.final9x9AreaVars:
        return 'Final 9x9 with Variations';
      case DatasetType.partialArea:
        return 'Partial Area Analysis';
    }
  }

  Future<void> _navigateToDetailedStats(DatasetType datasetType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedStatisticsScreen(datasetType: datasetType),
      ),
    );
  }
}