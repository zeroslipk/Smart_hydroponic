import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/sensor_provider.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  String selectedPeriod = '24 Hours';
  late AnimationController _waveController;
  late AnimationController _pulseController;

  final List<String> periods = ['24 Hours', '7 Days', '30 Days', 'Custom'];
  final DatabaseService _databaseService = DatabaseService();
  
  // Cache for chart data futures to prevent constant rebuilding
  final Map<String, Future<List<FlSpot>>> _chartDataCache = {};
  Future<List<TableRow>>? _statsTableCache;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  /// Clear cache when period changes
  void _clearCache() {
    _chartDataCache.clear();
    _statsTableCache = null;
  }

  /// Convert selected period string to hours
  int _getHoursForPeriod(String period) {
    switch (period) {
      case '24 Hours':
        return 24;
      case '7 Days':
        return 7 * 24;
      case '30 Days':
        return 30 * 24;
      case 'Custom':
        return 24; // Default to 24 hours for custom (can be extended)
      default:
        return 24;
    }
  }

  /// Get statistics from SQLite database
  Future<Map<String, double>> _getStats(String sensorId) async {
    final hoursBack = _getHoursForPeriod(selectedPeriod);
    return await _databaseService.getSensorStats(sensorId, hoursBack);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _clearCache(); // Clear cache on manual refresh
                    });
                    await context.read<SensorProvider>().refresh();
                  },
                  color: const Color(0xFF00BCD4),
                  child: Consumer<SensorProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4),
                          ),
                        );
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.refresh(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPeriodSelector(),
                            const SizedBox(height: 24),
                            _buildHealthScore(provider),
                            const SizedBox(height: 24),
                            _buildParameterTrends(provider),
                            const SizedBox(height: 24),
                            _buildStatisticsSummary(provider),
                            const SizedBox(height: 24),
                            _buildExportOptions(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildGlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<SensorProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      'Historical data • ${provider.timeSinceUpdate}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildGlassIconButton(
            icon: Icons.refresh,
            onTap: () {
              setState(() {
                _clearCache(); // Clear cache to force reload
              });
              context.read<SensorProvider>().refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final isSelected = selectedPeriod == periods[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (selectedPeriod != periods[index]) {
                  setState(() {
                    selectedPeriod = periods[index];
                    // Clear cache when period changes to reload data
                    _clearCache();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                        )
                      : null,
                  color: isSelected ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    periods[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthScore(provider) {
    final sensors = provider.getAllSensors();
    if (sensors.isEmpty) {
      return const SizedBox();
    }

    int optimalCount = 0;
    int goodCount = 0;
    final int totalCount = sensors.length;

    for (var sensor in sensors) {
      if (sensor.status == 'optimal') {
        optimalCount++;
      }
      if (sensor.status == 'good') {
        goodCount++;
      }
    }

    final int healthScore = totalCount > 0 
        ? ((optimalCount * 100 + goodCount * 80) / totalCount).round()
        : 0;
    final double healthProgress = healthScore / 100;

    String healthStatus = 'Good';
    if (healthScore >= 90) {
      healthStatus = 'Excellent';
    } else if (healthScore >= 80) {
      healthStatus = 'Very Good';
    } else if (healthScore < 70) {
      healthStatus = 'Fair';
    } else if (healthScore < 50) {
      healthStatus = 'Poor';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Plant Health Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaveCirclePainter(
                      progress: healthProgress,
                      animationValue: _waveController.value,
                      color: const Color(0xFF7CB342),
                    ),
                    size: const Size(180, 180),
                  );
                },
              ),
              Column(
                children: [
                  Text(
                    healthScore.toString(),
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7CB342),
                    ),
                  ),
                  Text(
                    healthStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var sensor in sensors.take(4))
                _buildScoreIndicator(
                  sensor.displayName.split(' ')[0],
                  sensor.progress,
                  sensor.sensorColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, double value, Color color) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 30,
          lineWidth: 6,
          percent: value.clamp(0.0, 1.0),
          center: Text(
            '${(value * 100).toInt()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildParameterTrends(provider) {
    final temperature = provider.temperature;
    final pH = provider.pH;
    final waterLevel = provider.waterLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parameter Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        if (temperature != null)
          _buildTrendChart(
            title: 'Temperature Over Time',
            color: const Color(0xFFFF5252),
            unit: '°C',
            sensorId: 'temperature',
            currentValue: temperature.value,
          ),
        const SizedBox(height: 16),
        if (pH != null)
          _buildTrendChart(
            title: 'pH Level Over Time',
            color: const Color(0xFF9C27B0),
            unit: 'pH',
            sensorId: 'pH',
            currentValue: pH.value,
          ),
        const SizedBox(height: 16),
        if (waterLevel != null)
          _buildTrendChart(
            title: 'Water Level Over Time',
            color: const Color(0xFF00BCD4),
            unit: '%',
            sensorId: 'waterLevel',
            currentValue: waterLevel.value,
          ),
      ],
    );
  }

  Widget _buildTrendChart({
    required String title,
    required Color color,
    required String unit,
    required String sensorId,
    required double currentValue,
  }) {
    // Use cached future or create new one
    final cacheKey = '$sensorId-$selectedPeriod';
    if (!_chartDataCache.containsKey(cacheKey)) {
      _chartDataCache[cacheKey] = _generateSpotsFromSQLite(sensorId);
    }
    
    return FutureBuilder<List<FlSpot>>(
      future: _chartDataCache[cacheKey],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            height: 200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final spots = snapshot.data ?? [];
        
        // Calculate dynamic min/max from actual chart data
        double chartMin = currentValue;
        double chartMax = currentValue;
        if (spots.isNotEmpty) {
          final values = spots.map((s) => s.y).toList();
          chartMin = values.reduce((a, b) => a < b ? a : b);
          chartMax = values.reduce((a, b) => a > b ? a : b);
          // Include current value in range
          if (currentValue < chartMin) chartMin = currentValue;
          if (currentValue > chartMax) chartMax = currentValue;
        }
        final padding = (chartMax - chartMin) * 0.1; // 10% padding
        if (padding == 0) {
          // If all values are the same, add some padding
          chartMin -= 1;
          chartMax += 1;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: spots.isEmpty
                    ? Center(
                        child: Text(
                          'No historical data available',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      )
                    : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        );
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = '00:00';
                            break;
                          case 3:
                            text = '06:00';
                            break;
                          case 6:
                            text = '12:00';
                            break;
                          case 9:
                            text = '18:00';
                            break;
                          case 12:
                            text = '24:00';
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 12,
                minY: chartMin - padding,
                maxY: chartMax + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.5)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  /// Generate chart spots from SQLite historical data
  Future<List<FlSpot>> _generateSpotsFromSQLite(String sensorId) async {
    final hoursBack = _getHoursForPeriod(selectedPeriod);
    final startDate = DateTime.now().subtract(Duration(hours: hoursBack));
    
    // Get historical data from SQLite (limit to reasonable number for chart)
    final activities = await _databaseService.getSensorActivities(
      sensorId: sensorId,
      startDate: startDate,
      limit: 100, // Get up to 100 points for smooth chart
    );

    if (activities.isEmpty) {
      // If no data, return empty spots
      return [];
    }

    // Convert to FlSpot format
    // We need to map timestamps to x-axis positions (0 to 12 for 24h view)
    // For simplicity, we'll evenly distribute points across the x-axis
    final spots = <FlSpot>[];
    final sortedActivities = activities.reversed.toList(); // Oldest first
    
    if (sortedActivities.length <= 13) {
      // If we have 13 or fewer points, use them directly
      for (int i = 0; i < sortedActivities.length; i++) {
        spots.add(FlSpot(i.toDouble(), sortedActivities[i].value));
      }
    } else {
      // If we have more points, sample evenly across 13 positions
      final step = sortedActivities.length / 13;
      for (int i = 0; i < 13; i++) {
        final index = (i * step).floor();
        if (index < sortedActivities.length) {
          spots.add(FlSpot(i.toDouble(), sortedActivities[index].value));
        }
      }
    }

    return spots;
  }

  Widget _buildStatisticsSummary(provider) {
    final sensors = provider.getAllSensors();
    if (sensors.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FutureBuilder<List<TableRow>>(
            future: _statsTableCache ??= _buildAllTableRows(sensors),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final rows = snapshot.data ?? [];
              return Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                children: rows,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build all table rows including header and sensor stats
  Future<List<TableRow>> _buildAllTableRows(List<dynamic> sensors) async {
    final rows = <TableRow>[
      _buildTableRow('Parameter', 'Min', 'Max', 'Avg', isHeader: true),
    ];

    // Load stats for all sensors in parallel
    final futures = sensors.map((sensor) async {
      final stats = await _getStats(sensor.id);
      final isDecimal = sensor.id == 'pH' || sensor.id == 'temperature';
      
      return _buildTableRow(
        sensor.displayName,
        '${stats['min']!.toStringAsFixed(isDecimal ? 1 : 0)}${sensor.unit}',
        '${stats['max']!.toStringAsFixed(isDecimal ? 1 : 0)}${sensor.unit}',
        '${stats['avg']!.toStringAsFixed(isDecimal ? 1 : 0)}${sensor.unit}',
      );
    });

    final sensorRows = await Future.wait(futures);
    rows.addAll(sensorRows);

    return rows;
  }

  TableRow _buildTableRow(String col1, String col2, String col3, String col4,
      {bool isHeader = false}) {
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color,
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF00BCD4).withValues(alpha: 0.1) : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(col1, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(col2, style: textStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(col3, style: textStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(col4, style: textStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export Data',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildExportButton(
          icon: Icons.table_chart,
          label: 'Export as CSV',
          color: const Color(0xFF00BCD4),
          onTap: _exportAsCSV,
        ),
        const SizedBox(height: 12),
        _buildExportButton(
          icon: Icons.picture_as_pdf,
          label: 'Export as PDF Report',
          color: const Color(0xFFFF5252),
          onTap: _exportAsPDF,
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _exportAsCSV() async {
    final provider = context.read<SensorProvider>();
    final sensors = provider.getAllSensors();
    
    if (sensors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating export...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Build CSV content
      final buffer = StringBuffer();
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('HydroPulse Sensor Data Export - $selectedPeriod');
      buffer.writeln('Generated: ${DateTime.now().toString().substring(0, 19)}');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('');
      
      // Current sensor readings
      buffer.writeln('CURRENT SENSOR READINGS');
      buffer.writeln('Sensor,Value,Unit,Status,Min Range,Max Range,Timestamp');
      
      for (final sensor in sensors) {
        buffer.writeln('${sensor.displayName},${sensor.value},${sensor.unit},${sensor.status},${sensor.min},${sensor.max},${DateTime.now().toIso8601String()}');
      }
      
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('STATISTICS SUMMARY ($selectedPeriod)');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('Sensor,Min Value,Max Value,Average Value,Unit');
      
      // Add statistics for each sensor
      for (final sensor in sensors) {
        final stats = await _getStats(sensor.id);
        final isDecimal = sensor.id == 'pH' || sensor.id == 'temperature';
        buffer.writeln('${sensor.displayName},${stats['min']!.toStringAsFixed(isDecimal ? 1 : 0)},${stats['max']!.toStringAsFixed(isDecimal ? 1 : 0)},${stats['avg']!.toStringAsFixed(isDecimal ? 1 : 0)},${sensor.unit}');
      }
      
      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'hydropulse_sensors_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      
      // Write to file
      await file.writeAsString(buffer.toString());
      
      // Share the file (using deprecated but functional API)
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'HydroPulse Sensor Data Export',
        subject: 'Sensor Data CSV',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV file saved: $fileName'),
            backgroundColor: const Color(0xFF7CB342),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _exportAsPDF() async {
    final provider = context.read<SensorProvider>();
    final sensors = provider.getAllSensors();
    
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating report...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Build PDF-like report content (formatted text file)
      final buffer = StringBuffer();
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('           HYDROPULSE SENSOR DATA REPORT');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('');
      buffer.writeln('Generated: ${DateTime.now().toString().substring(0, 19)}');
      buffer.writeln('Period: $selectedPeriod');
      buffer.writeln('Total Sensors: ${sensors.length}');
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('CURRENT SENSOR READINGS');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('');
      
      for (final sensor in sensors) {
        buffer.writeln(sensor.displayName.toUpperCase());
        buffer.writeln('  Current Value: ${sensor.displayValue}${sensor.unit}');
        buffer.writeln('  Status: ${sensor.status.toUpperCase()}');
        buffer.writeln('  Optimal Range: ${sensor.min} - ${sensor.max}${sensor.unit}');
        buffer.writeln('');
      }
      
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('STATISTICS SUMMARY ($selectedPeriod)');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('');
      
      // Add statistics for each sensor
      for (final sensor in sensors) {
        final stats = await _getStats(sensor.id);
        final isDecimal = sensor.id == 'pH' || sensor.id == 'temperature';
        buffer.writeln(sensor.displayName.toUpperCase());
        buffer.writeln('  Minimum: ${stats['min']!.toStringAsFixed(isDecimal ? 1 : 0)}${sensor.unit}');
        buffer.writeln('  Maximum: ${stats['max']!.toStringAsFixed(isDecimal ? 1 : 0)}${sensor.unit}');
        buffer.writeln('  Average: ${stats['avg']!.toStringAsFixed(isDecimal ? 1 : 0)}${sensor.unit}');
        buffer.writeln('');
      }
      
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('END OF REPORT');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      
      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'hydropulse_report_$timestamp.txt';
      final file = File('${directory.path}/$fileName');
      
      // Write to file
      await file.writeAsString(buffer.toString());
      
      // Share the file (using deprecated but functional API)
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'HydroPulse Sensor Report',
        subject: 'Sensor Data Report',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved: $fileName'),
            backgroundColor: const Color(0xFF7CB342),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
}

class WaveCirclePainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;

  WaveCirclePainter({
    required this.progress,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, outerPaint);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 10.0;
    final baseY = size.height * (1 - progress);

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          math.sin((x / size.width) * 4 * math.pi + animationValue * 2 * math.pi) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawPath(path, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WaveCirclePainter oldDelegate) => true;
}
