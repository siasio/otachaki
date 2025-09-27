import 'package:flutter/material.dart';
import '../services/position_loader.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _sourceInfo;
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
      final stats = await PositionLoader.getStatistics();
      final source = PositionLoader.getSourceInfo();
      setState(() {
        _statistics = stats;
        _sourceInfo = source;
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
                      '🎯 Final 9x9 Positions',
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

            // Current Dataset Statistics
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_statistics != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Current Dataset Statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Total Positions', _statistics!['total_positions'].toString()),
                      _buildStatRow('Version', _statistics!['version'].toString()),
                      _buildStatRow('Created', _formatDate(_statistics!['created_at'])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_sourceInfo != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Source Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Source Type', _sourceInfo!['source']),
                        _buildStatRow('File', _sourceInfo!['file']),
                        if (_sourceInfo!['path'] != null)
                          _buildStatRow('Path', _sourceInfo!['path']),
                        if (_sourceInfo!['has_bytes'] == true)
                          _buildStatRow('Loaded from', 'Memory (Web)'),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
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

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}