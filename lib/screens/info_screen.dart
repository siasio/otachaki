import 'package:flutter/material.dart';
import '../services/statistics_manager.dart';
import '../services/custom_dataset_manager.dart';
import '../models/daily_statistics.dart';
import '../models/custom_dataset.dart';
import '../utils/rich_text_formatter.dart';
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
                      'Positions before filling neutral points',
                      'Komi and numbers of prisoners are displayed. '
                      'Use territory scoring. ',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      'Midgame 19x19 Estimation',
                      'Positions at move 150. '
                      'Komi and number of prisoners are displayed. '
                      'Train your quick middle game judgment!',
                    ),
                    const SizedBox(height: 12),
                    _buildDatasetExplanation(
                      'In preparation:',
                      'Dataset of board patches (train your area scoring skills!). '
                      'I think that if I publish this app, it won\'t have this feature... But I want to try it for myself.',
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
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Configuration options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🎯 Task Types',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• By default, you choose the winner (Black/White) or Draw\n'
                      '• Exact score prediction: The app shows three scores (e.g. W+10, W+2, B+6) and you choose the correct one\n'
                      '• Rough lead prediction: Who is leading? Or is the position close? Choose thresholds on your own',
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '⏱️ Timing & Flow',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• To solve a problem, press buttons, or use keyboard arrows (←, ↓, →)\n'
                      '• Even when you have "Auto-advance to next problem" set, you can use the pause button (or ␣ Space Bar) to review the problem\n'
                      '• Adjust time per problem, or disable the timer\n'
                      '• Custom title bar: Use placeholders (%d dataset, %n problems, %a accuracy, ...)',
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🎨 Visual Appearance',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Choose from different color themes. Use E-ink Minimalist for an e-ink device\n'
                      '• Choose layout: Vertical (phones, PC) or Horizontal (tablets)\n'
                      '• Ownership display: get visual feedback during problem review',
                      // '• Timer styles: Smooth progress bar or segmented bar',
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '📱 Position Display',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Move sequences: Show recent moves as numbered sequence to train your visualization skill\n'
                      '• ...or don\'t show the sequence at all and try to imagine it on your own',
                      // '• Game info: Toggle captured stones and komi display\n'
                      // '• Last move marker: Configurable display duration',
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
                    const SizedBox(height: 8),
                    RichTextFormatter.format(
                      '*Otachaki* (Polish: *otaczaki*) is a non-existent Polish word which means *The Surrounding Game*, or *The Game of Go*.',
                      style: const TextStyle(color: Colors.grey),
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
                  '${stats.accuracyPercentage.toStringAsFixed(0)}%',
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
                  // stats.hasSpeedData
                  //     ? '${stats.averagePointsPerSecond.toStringAsFixed(1)} pts/s'
                  //     : 'N/A',
                  '${stats.averagePointsPerSecond.toStringAsFixed(1)} pts/s',
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