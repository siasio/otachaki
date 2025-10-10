import 'package:flutter/material.dart';
import '../services/statistics_manager.dart';
import '../services/custom_dataset_manager.dart';
import '../models/daily_statistics.dart';
import '../models/custom_dataset.dart';
import './detailed_statistics_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  StatisticsManager? _statisticsManager;
  CustomDatasetManager? _datasetManager;
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
      _datasetManager = await CustomDatasetManager.getInstance();
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
                          'Training Modes Explained',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDatasetExplanation(
                      'Final Positions (9x9, 13x13, 19x19)',
                      'Komi = 7 points, equal numbers of prisoners. '
                      'Positions are picked so that both area and territory scoring give the same result. '
                      'Your big goal is to count the score on 19x19 within one byo-yomi period!',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      'Final 19x19 Positions',
                      'Komi = 7 points. '
                      'Positions are picked so that both area and territory scoring give the same result. '
                      'Practice until you can count the score within 30s (typical byo-yomi period)!',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      'Midgame 19x19 Estimation',
                      'Positions at move 150. '
                      'Komi and number of prisoners are shown. '
                      'Train your quick middle game judgment!',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      'In preparation:',
                      'Datasets with variations shown by numbers (train like MuZero!). '
                      'Dataset of board patches (train your area scoring skills!).',
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
                      '• Choose from different datasets (9x9, 13x13, 19x19 final positions, 19x19 midgame, partial board)\n'
                      '• Get immediate feedback on your predictions and track your accuracy with built-in scoring',
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
                      '• ↓ Down Arrow: Select Draw/Close\n'
                      '• → Right Arrow: Select Black Wins\n'
                      '• ␣ Space Bar: Pause Auto-Advance to Next Problem',
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
                      '• Customize timer settings and scoring thresholds (especially useful for midgame dataset) for each dataset type\n'
                      '• Choose from different themes and layouts. Horizontal layout is specifically designed for tablets. On e-ink devices, use the e-ink theme and segmented timer',
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
                      'Go Position Evaluation Training App',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Designed by Stanisław Frejlak, 2p. '
                      'Written by ClaudeCode. '
                      'Inspiration taken from antonTobi: https://count.antontobi.com/',
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
    if (_todayStats == null || _datasetManager == null) return [];

    final List<Widget> widgets = [];

    for (final datasetId in _todayStats!.activeDatasetIds) {
      final stats = _todayStats!.getStatsForDatasetId(datasetId);
      final dataset = _datasetManager!.getDatasetById(datasetId);
      if (stats != null && dataset != null) {
        widgets.add(_buildDatasetStatCard(dataset, stats));
        widgets.add(const SizedBox(height: 12));
      }
    }

    // Remove the last SizedBox
    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }

    return widgets;
  }

  Widget _buildDatasetStatCard(CustomDataset dataset, DailyDatasetStatistics stats) {
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
                  dataset.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.analytics_outlined, size: 20),
                onPressed: () => _navigateToDetailedStats(dataset),
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
              Expanded(
                child: _buildMiniStat(
                  'Avg Speed',
                  stats.hasSpeedData
                      ? '${stats.averagePointsPerSecond.toStringAsFixed(1)} pts/s'
                      : 'N/A',
                  Icons.speed_outlined,
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

  Future<void> _navigateToDetailedStats(CustomDataset dataset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedStatisticsScreen(dataset: dataset),
      ),
    );
  }
}