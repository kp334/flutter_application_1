import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'data_table_page.dart';

class GrafikLevelAir extends StatefulWidget {
  final String zoneName;
  
  const GrafikLevelAir({
    Key? key, 
    required this.zoneName,
  }) : super(key: key);

  @override
  State<GrafikLevelAir> createState() => _GrafikLevelAirState();
}

class _GrafikLevelAirState extends State<GrafikLevelAir> {
  // Konfigurasi API
  final String apiUrl = "https://dev.tirtaayu.my.id/api/tekniks/device/LEVEL";
  late DateFormat apiDateFormat;
  late DateFormat displayDateFormat; 
  late DateFormat chartTimeFormat;

  // State management
  bool _isLoading = false;
  String? _errorMessage;
  final List<Map<String, dynamic>> _rawData = [];
  final List<Map<String, dynamic>> _filteredData = [];

  // Filter controls
  DateTime? _startDate;
  DateTime? _endDate;

  // Chart data
  final List<FlSpot> _chartSpots = [];
  final List<String> _xAxisLabels = [];
  bool _usesTimeAxis = true;

  // Bottom navigation bar state
  int _selectedIndex = 1; // Default to home (middle item)

  @override
  void initState() {
    super.initState();
    apiDateFormat = DateFormat('dd-MM-yyyy HH:mm');
    displayDateFormat = DateFormat('dd-MM-yyyy HH:mm');
    chartTimeFormat = DateFormat('HH:mm');
    _initializeDateRange();
    _fetchData();
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59);
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode != 200) {
        throw HttpException('Request failed with status: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final List dataList = (jsonData['data'] ?? []) as List;
      
      _rawData.clear();
      _rawData.addAll(dataList.map<Map<String, dynamic>>(
        (e) => Map<String, dynamic>.from(e))
      );
      
      _applyFilters();
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(dynamic error) {
    setState(() => _errorMessage = error.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${error.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _applyFilters() {
  _filteredData.clear();
  
  // Filter data that has level information and is within date range
  _filteredData.addAll(_rawData.where((data) => 
    data['level'] != null && 
    _isWithinDateRange(data)
  ));
  
  _buildChartData();
  
  if (mounted) setState(() {});
}

  bool _isWithinDateRange(Map<String, dynamic> data) {
  final dateString = data['tanggal'];
  if (dateString == null) return false;

  try {
    final date = apiDateFormat.parse(dateString);
    if (_startDate != null && date.isBefore(_startDate!)) return false;
    if (_endDate != null && date.isAfter(_endDate!)) return false;
    return true;
  } catch (_) {
    return false;
  }
}
  void _buildChartData() {
  _chartSpots.clear();
  _xAxisLabels.clear();
  
  final validTimestamps = <int>{};
  int validCount = 0;

  // Analyze data to determine axis type - only use data with level values
  for (final data in _filteredData) {
    final levelData = data['level'];
    if (levelData is! Map) continue;
    
    final value = _parseDouble(levelData['nilai']);
    if (value == null) continue;

    final dateString = data['tanggal'];
    if (dateString != null) {
      try {
        final date = apiDateFormat.parse(dateString);
        validTimestamps.add(date.millisecondsSinceEpoch);
        validCount++;
      } catch (_) {}
    }
  }

  _usesTimeAxis = validTimestamps.length >= 2 && validCount > 0;

  if (_usesTimeAxis) {
    _buildTimeBasedChart();
  } else {
    _buildCategoryBasedChart();
  }
}

  void _buildTimeBasedChart() {
  final tempSpots = <FlSpot>[];
  
  for (final data in _filteredData) {
    final levelData = data['level'];
    if (levelData is! Map) continue;
    
    final value = _parseDouble(levelData['nilai']);
    if (value == null) continue;

    final dateString = data['tanggal'];
    if (dateString == null) continue;
    
    try {
      final date = apiDateFormat.parse(dateString);
      tempSpots.add(FlSpot(
        date.millisecondsSinceEpoch.toDouble(), 
        value,
      ));
    } catch (_) {}
  }

  tempSpots.sort((a, b) => a.x.compareTo(b.x));
  _chartSpots.addAll(tempSpots);
}
  void _buildCategoryBasedChart() {
    int index = 0;
    
    for (final data in _filteredData) {
      final levelData = data['level'];
      if (levelData is! Map) continue;
      
      final value = _parseDouble(levelData['nilai']);
      if (value == null) continue;

      _chartSpots.add(FlSpot(index.toDouble(), value));
      _xAxisLabels.add(data['nama']?.toString() ?? 'Item ${index + 1}');
      index++;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  double _calculateMinY() {
  final values = _chartSpots.map((spot) => spot.y).toList();
  if (values.isEmpty) return 0;
  
  final minValue = values.reduce((a, b) => a < b ? a : b);
  return minValue * 0.95; // Add some padding
}

double _calculateMaxY() {
  final values = _chartSpots.map((spot) => spot.y).toList();
  if (values.isEmpty) return 5;
  
  final maxValue = values.reduce((a, b) => a > b ? a : b);
  return maxValue * 1.05; // Add some padding
}

  String _formatXAxisLabel(double value) {
    if (_usesTimeAxis) {
      return chartTimeFormat.format(
        DateTime.fromMillisecondsSinceEpoch(value.toInt()),
      );
    }
    
    final index = value.toInt();
    return index >= 0 && index < _xAxisLabels.length 
        ? _xAxisLabels[index] 
        : '';
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    
    if (selectedDate == null || !mounted) return;
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _startDate ?? DateTime.now(),
      ),
    );
    
    if (selectedTime == null || !mounted) return;
    
    setState(() {
      _startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    
    if (selectedDate == null || !mounted) return;
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _endDate ?? DateTime.now(),
      ),
    );
    
    if (selectedTime == null || !mounted) return;
    
    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Map<String, dynamic>? get _latestReading {
  try {
    // Find the latest data for the current zone that has level data
    final zoneData = _rawData.where((d) => 
      d['nama'] == widget.zoneName && 
      d['level'] != null &&
      d['level']['nilai'] != null &&
      d['tanggal'] != null
    ).toList();
    
    if (zoneData.isEmpty) return null;
    
    // Sort by date to get the latest reading
    zoneData.sort((a, b) {
      try {
        final dateA = apiDateFormat.parse(a['tanggal']);
        final dateB = apiDateFormat.parse(b['tanggal']);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });
    
    return zoneData.first;
  } catch (_) {
    return null;
  }
}
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Add navigation logic here if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    final latestValue = _latestReading?['level']?['nilai']?.toString() ?? '0';
    final latestUnit = _latestReading?['level']?['satuan']?.toString() ?? '';
    final latestTime = _latestReading?['tanggal']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.zoneName.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchData,
          ),
        ],
        backgroundColor: const Color(0xFFCFEDEA),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _buildBody(latestValue, latestUnit, latestTime),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody(String value, String unit, String time) {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildValueDisplay(value, unit, time),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 16),
            _buildDateFilters(),
            const SizedBox(height: 16),
            _buildDataTableSection(),
            if (_isLoading) const LinearProgressIndicator(),
            if (_errorMessage != null) _buildErrorDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildValueDisplay(String value, String unit, String time) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value == 'N/A' ? '-' : value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: value == 'N/A' ? Colors.grey : Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            unit == 'N/A' ? '' : unit,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      Text(
        'Update: ${time == 'N/A' ? 'No data' : time}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ],
  );
}
  Widget _buildChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: _chartSpots.isEmpty
          ? const Center(
              child: Text(
                'No data available for chart',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : LineChart(
              LineChartData(
                minY: _calculateMinY(),
                maxY: _calculateMaxY(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _usesTimeAxis ? null : 1,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatXAxisLabel(value),
                          style: TextStyle(
                            fontSize: _usesTimeAxis ? 10 : 8,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateFilters() {
    return Row(
      children: [
        Expanded(
          child: _DateFilterBox(
            label: 'Start Date',
            value: _startDate != null 
                ? displayDateFormat.format(_startDate!) 
                : '-',
            onTap: _selectStartDate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DateFilterBox(
            label: 'End Date',
            value: _endDate != null 
                ? displayDateFormat.format(_endDate!) 
                : '-',
            onTap: _selectEndDate,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _applyFilters,
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }

  // PERBAIKAN BAGIAN TABEL DATA - MULAI DARI SINI
  Widget _buildDataTableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DATA TABLE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 16,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 60,
              headingRowHeight: 50,
              columns: const [
                DataColumn(
                  label: _TableHeader('Date Time'),
                  numeric: false,
                ),
                DataColumn(
                  label: _TableHeader('Level'),
                  numeric: true,
                ),
                DataColumn(
                  label: _TableHeader('Unit'),
                  numeric: false,
                ),
                DataColumn(
                  label: _TableHeader('Min'),
                  numeric: true,
                ),
                DataColumn(
                  label: _TableHeader('Max'),
                  numeric: true,
                ),
              ],
              rows: _filteredData.isEmpty
                  ? [_buildEmptyRow()]
                  : _filteredData.map(_buildDataRow).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_filteredData.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _navigateToFullDataTable,
              child: const Text(
                'View All Data',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  DataRow _buildEmptyRow() {
    return DataRow(
      cells: [
        DataCell(Text('No data available', style: TextStyle(color: Colors.grey))),
        DataCell(Container()),
        DataCell(Container()),
        DataCell(Container()),
        DataCell(Container()),
      ],
    );
  }

DataRow _buildDataRow(Map<String, dynamic> data) {
  final level = data['level'] as Map?;
  final dateTime = data['tanggal']?.toString() ?? '-';
  final value = level?['nilai']?.toString() ?? 'N/A';
  final unit = level?['satuan']?.toString() ?? 'N/A';
  final min = level?['min']?.toString() ?? 'N/A';
  final max = level?['max']?.toString() ?? 'N/A';

  // Handle case where level data might be missing (like device_id: 54)
  final hasLevelData = level != null && level['nilai'] != null;

  return DataRow(
    cells: [
      DataCell(
        SizedBox(
          width: 120,
          child: Text(
            dateTime,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(
        Center(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hasLevelData ? _getValueColor(double.tryParse(value)) : Colors.grey,
            ),
          ),
        ),
      ),
      DataCell(Center(child: Text(unit))),
      DataCell(Center(child: Text(min))),
      DataCell(Center(child: Text(max))),
    ],
  );
}

  Color _getValueColor(double? value) {
    if (value == null) return Colors.black;
    if (value > 80) return Colors.red;
    if (value > 50) return Colors.orange;
    return Colors.green;
  }
  // PERBAIKAN BAGIAN TABEL DATA - SELESAI

  void _navigateToFullDataTable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataTablePage(
          zoneName: widget.zoneName,
          data: _rawData,
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Error: $_errorMessage',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.email),
          label: 'Pesan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Pengaturan',
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }
}

class _DateFilterBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  
  const _DateFilterBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class HttpException implements Exception {
  final String message;
  
  HttpException(this.message);
  
  @override
  String toString() => message;
}