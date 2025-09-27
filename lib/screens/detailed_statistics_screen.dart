import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/dataset_type.dart';
import '../models/daily_statistics.dart';
import '../services/statistics_manager.dart';

class DetailedStatisticsScreen extends StatefulWidget {
  final DatasetType datasetType;

  const DetailedStatisticsScreen({
    super.key,
    required this.datasetType,
  });

  @override
  State<DetailedStatisticsScreen> createState() => _DetailedStatisticsScreenState();
}

enum TimePeriod {
  week(7, 'Last 7 days'),
  month(30, 'Last 30 days'),
  year(365, 'Last year');

  const TimePeriod(this.days, this.label);
  final int days;
  final String label;
}

class _DetailedStatisticsScreenState extends State<DetailedStatisticsScreen> {
  StatisticsManager? _statisticsManager;
  List<DailyDatasetStatistics> _historicalStats = [];
  bool _loading = true;
  TimePeriod _selectedPeriod = TimePeriod.week;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _loading = true;
    });

    try {
      _statisticsManager = await StatisticsManager.getInstance();
      _historicalStats = _statisticsManager!.getHistoricalStats(widget.datasetType, _selectedPeriod.days);
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
        title: Text(_getDatasetDisplayName(widget.datasetType)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<TimePeriod>(
            icon: const Icon(Icons.date_range),
            onSelected: (TimePeriod period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadStatistics();
            },
            itemBuilder: (context) => TimePeriod.values.map((period) =>
              PopupMenuItem(
                value: period,
                child: Text(period.label),
              ),
            ).toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _historicalStats.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildProblemsChart(),
                      const SizedBox(height: 24),
                      _buildAccuracyChart(),
                      const SizedBox(height: 24),
                      _buildAverageTimeChart(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No data available for ${_getDatasetDisplayName(widget.datasetType)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start practicing with this dataset to see your progress!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAttempts = _historicalStats.fold<int>(0, (sum, stat) => sum + stat.totalAttempts);
    final totalCorrect = _historicalStats.fold<int>(0, (sum, stat) => sum + stat.correctAttempts);
    final totalTime = _historicalStats.fold<double>(0, (sum, stat) => sum + stat.totalTimeSeconds);

    final overallAccuracy = totalAttempts > 0 ? (totalCorrect / totalAttempts) * 100 : 0.0;
    final overallAvgTime = totalAttempts > 0 ? totalTime / totalAttempts : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Summary (${_selectedPeriod.label})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Problems',
                    totalAttempts.toString(),
                    Icons.quiz_outlined,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Overall Accuracy',
                    '${overallAccuracy.toStringAsFixed(1)}%',
                    Icons.check_circle_outline,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Avg Time',
                    '${overallAvgTime.toStringAsFixed(1)}s',
                    Icons.timer_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProblemsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Problems Solved Per Day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(_createProblemsLineChart()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accuracy Per Day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(_createAccuracyLineChart()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageTimeChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Time Per Problem',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(_createAverageTimeLineChart()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _createProblemsLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _historicalStats.length; i++) {
      spots.add(FlSpot(i.toDouble(), _historicalStats[i].totalAttempts.toDouble()));
    }

    // Calculate smart interval for y-axis
    final maxValue = _historicalStats.isEmpty ? 10.0 : _historicalStats.map((s) => s.totalAttempts).reduce((a, b) => a > b ? a : b).toDouble();
    final yInterval = _calculateSmartInterval(maxValue, 5); // Target ~5 ticks

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateXAxisInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _historicalStats.length) {
                final date = _historicalStats[index].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatDateForPeriod(date),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      minX: 0,
      maxX: (_historicalStats.length - 1).toDouble(),
      minY: 0,
      maxY: (maxValue * 1.1).ceilToDouble(), // Add 10% padding at top
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  LineChartData _createAccuracyLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _historicalStats.length; i++) {
      spots.add(FlSpot(i.toDouble(), _historicalStats[i].accuracyPercentage));
    }

    // For accuracy, use smart interval but ensure we don't go below 10% steps for readability
    final yInterval = _calculateSmartInterval(100, 5).clamp(10.0, 25.0);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateXAxisInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _historicalStats.length) {
                final date = _historicalStats[index].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatDateForPeriod(date),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      minX: 0,
      maxX: (_historicalStats.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  LineChartData _createAverageTimeLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _historicalStats.length; i++) {
      spots.add(FlSpot(i.toDouble(), _historicalStats[i].averageTimeSeconds));
    }

    // Calculate smart interval for time chart
    final maxValue = _historicalStats.isEmpty ? 15.0 : _historicalStats.map((s) => s.averageTimeSeconds).reduce((a, b) => a > b ? a : b);
    final yInterval = _calculateSmartInterval(maxValue, 5); // Target ~5 ticks

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateXAxisInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _historicalStats.length) {
                final date = _historicalStats[index].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatDateForPeriod(date),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}s',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      minX: 0,
      maxX: (_historicalStats.length - 1).toDouble(),
      minY: 0,
      maxY: (maxValue * 1.1).ceilToDouble(), // Add 10% padding at top
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  /// Calculate appropriate interval for x-axis based on selected time period
  double _calculateXAxisInterval() {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return 1.0; // Show every day for week view
      case TimePeriod.month:
        return 5.0; // Show every 5th day for month view
      case TimePeriod.year:
        return 30.0; // Show approximately every month for year view
    }
  }

  /// Format date labels based on selected time period
  String _formatDateForPeriod(DateTime date) {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return DateFormat('M/d').format(date); // Short format for week
      case TimePeriod.month:
        return DateFormat('M/d').format(date); // Short format for month
      case TimePeriod.year:
        return DateFormat('MMM').format(date); // Month name for year
    }
  }

  /// Calculate a smart interval for axis ticks based on max value and target tick count
  double _calculateSmartInterval(double maxValue, int targetTicks) {
    if (maxValue <= 0) return 1.0;

    // For small integer ranges, use simple integer intervals
    if (maxValue <= targetTicks && maxValue == maxValue.floor()) {
      return 1.0; // Use interval of 1 for small integer ranges
    }

    final roughInterval = maxValue / targetTicks;

    // Find the appropriate "nice" interval
    final magnitude = math.pow(10, (math.log(roughInterval) / math.ln10).floor()).toDouble();
    final normalizedInterval = roughInterval / magnitude;

    // Choose the best "nice" number: 1, 2, 5, or 10
    double niceInterval;
    if (normalizedInterval <= 1) {
      niceInterval = 1;
    } else if (normalizedInterval <= 2) {
      niceInterval = 2;
    } else if (normalizedInterval <= 5) {
      niceInterval = 5;
    } else {
      niceInterval = 10;
    }

    final result = (niceInterval * magnitude).toDouble();

    // Ensure the interval is at least 1 for integer-based charts
    return math.max(1.0, result);
  }

  String _getDatasetDisplayName(DatasetType datasetType) {
    switch (datasetType) {
      case DatasetType.final9x9Area:
        return 'Final 9x9 Positions';
      case DatasetType.final19x19Area:
        return 'Final 19x19 Positions';
      case DatasetType.midgame19x19Estimation:
        return 'Midgame 19x19 Estimation';
      case DatasetType.final9x9AreaVars:
        return 'Final 9x9 with Variations';
      case DatasetType.partialArea:
        return 'Partial Area Analysis';
    }
  }
}