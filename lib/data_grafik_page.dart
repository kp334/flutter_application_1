// ignore_for_file: use_build_context_synchronously

/*
  data_grafik_page.dart (FINAL, panjang) - DIPERBAIKI
  - Ditambahkan logging komprehensif untuk debugging
  - Diperbaiki error handling
  - Ditambahkan validasi data yang lebih robust
*/

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'data_table_page.dart';

/// ============================================================================
/// SECTION: Model & Utilities
/// ============================================================================

/// Model generik satu titik data grafik
class GaugePoint {
  final DateTime time;
  final double value;

  GaugePoint(this.time, this.value);

  Map<String, dynamic> toMap() => {
        'datetime': time.toIso8601String(),
        'value': value,
      };

  @override
  String toString() => 'GaugePoint(${DateFormat('dd-MM-yyyy HH:mm').format(time)}, $value)';
}

/// Hasil parsing keseluruhan
class ChartSeriesBundle {
  final List<GaugePoint> flow;
  final List<GaugePoint> pressure;
  final List<GaugePoint> totalizer;

  ChartSeriesBundle({
    required this.flow,
    required this.pressure,
    required this.totalizer,
  });

  bool get isEmpty => flow.isEmpty && pressure.isEmpty && totalizer.isEmpty;

  @override
  String toString() => 'ChartSeriesBundle(flow: ${flow.length}, pressure: ${pressure.length}, totalizer: ${totalizer.length})';
}

/// Statistik sederhana
class BasicStats {
  final double min;
  final double max;
  final double avg;

  const BasicStats({required this.min, required this.max, required this.avg});

  static const zero = BasicStats(min: 0, max: 0, avg: 0);

  @override
  String toString() => 'Stats(min: $min, max: $max, avg: $avg)';
}

/// Util untuk statistik
BasicStats computeStats(List<double> values) {
  if (values.isEmpty) return BasicStats.zero;
  double minV = values.first;
  double maxV = values.first;
  double sum = 0;
  for (final v in values) {
    minV = math.min(minV, v);
    maxV = math.max(maxV, v);
    sum += v;
  }
  return BasicStats(min: minV, max: maxV, avg: sum / values.length);
}

/// Normalisasi date string dari server
class ServerDateParser {
  static final List<DateFormat> _candidates = [
    DateFormat('dd-MM-yyyy HH:mm'),
    DateFormat('dd-MM-yyyy HH:mm:ss'),
    DateFormat('yyyy-MM-dd HH:mm'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
  ];

  static DateTime? parseAny(String raw) {
    if (raw.isEmpty) {
      print("⚠️  Date string is empty");
      return null;
    }

    print("🕐 Trying to parse date: '$raw'");

    // Coba parse sebagai timestamp Unix (dalam miliseconds atau seconds)
    try {
      final timestamp = int.tryParse(raw);
      if (timestamp != null) {
        if (timestamp > 1000000000000) { // Miliseconds
          final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          print("✅ Parsed as Unix timestamp (ms): $dt");
          return dt;
        } else if (timestamp > 1000000000) { // Seconds
          final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          print("✅ Parsed as Unix timestamp (s): $dt");
          return dt;
        }
      }
    } catch (e) {
      print("❌ Unix timestamp parsing failed: $e");
    }

    // ISO 8601 langsung
    try {
      if (raw.contains('T')) {
        final result = DateTime.parse(raw);
        print("✅ Parsed as ISO 8601: $result");
        return result;
      }
    } catch (e) {
      print("❌ ISO 8601 parsing failed: $e");
    }

    // Coba semua format kandidat
    for (final f in _candidates) {
      try {
        final result = f.parseStrict(raw);
        print("✅ Parsed with ${f.pattern}: $result");
        return result;
      } catch (e) {
        // Skip error untuk format yang tidak cocok
      }
    }

    // Normalisasi dd-MM-yyyy HH:mm(:ss)? -> yyyy-MM-ddTHH:mm(:ss)?
    try {
      if (raw.contains(' ')) {
        final parts = raw.split(' ');
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          final normalized = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}T${parts[1]}';
          final result = DateTime.parse(normalized);
          print("✅ Parsed with normalization: $result");
          return result;
        }
      }
    } catch (e) {
      print("❌ Normalization parsing failed: $e");
    }

    // Fallback parse
    try {
      final result = DateTime.parse(raw);
      print("✅ Parsed with fallback: $result");
      return result;
    } catch (e) {
      print("❌ All parsing attempts failed for: '$raw'");
    }

    return null;
  }
}

/// ============================================================================
/// SECTION: API Service (support 2 pola API)
/// ============================================================================

class GrafikApiService {
  GrafikApiService._();

  /// Token default
  static const _defaultToken = "Bearer 8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111";

  /// Pola A (endpoint device per zone)
  static Uri endpointA(String zoneName) => Uri.parse(
      "https://dev.tirtaayu.my.id/api/tekniks/device/zone_id=$zoneName");

  /// Pola B (detail with serial + awal/akhir)
  static Uri endpointB({
    required String serialOrZone,
    required DateTime start,
    required DateTime end,
  }) {
    final df = DateFormat("dd-MM-yyyy HH:mm");
    final awal = Uri.encodeQueryComponent(df.format(start));
    final akhir = Uri.encodeQueryComponent(df.format(end));
    return Uri.parse(
        "https://dev.tirtaayu.my.id/api/tekniks/detail/$serialOrZone?awal=$awal&akhir=$akhir");
  }

  /// Try fetch dgn Pola B dulu; jika gagal atau tidak cocok → fallback Pola A
  static Future<ChartSeriesBundle> fetchFlexible({
    required String zoneName,
    required DateTime start,
    required DateTime end,
    String? token,
  }) async {
    final usedToken = token ?? _defaultToken;
    print("🔑 Using token: $usedToken");
    print("🌐 Fetching data for zone: $zoneName");
    print("📅 Range: ${DateFormat('dd-MM-yyyy HH:mm').format(start)} to ${DateFormat('dd-MM-yyyy HH:mm').format(end)}");

    // 1) Try Pola B
    try {
      print("🔄 Trying Pola B...");
      final bundle = await _fetchPolaB(
        zoneOrSerial: zoneName,
        start: start,
        end: end,
        token: usedToken,
      );
      print("📊 Pola B result: $bundle");
      
      if (!bundle.isEmpty) {
        print("✅ Using Pola B data");
        return bundle;
      } else {
        print("⚠️  Pola B returned empty data");
      }
    } catch (e, stackTrace) {
      print("❌ Pola B failed: $e");
      print("📋 Stack trace: $stackTrace");
    }

    // 2) fallback Pola A
    try {
      print("🔄 Trying Pola A...");
      final bundle = await _fetchPolaA(zoneName: zoneName, token: usedToken);
      print("📊 Pola A result: $bundle");
      
      final filteredBundle = _filterByRange(bundle, start, end);
      print("📊 After filtering: $filteredBundle");
      
      return filteredBundle;
    } catch (e, stackTrace) {
      print("❌ Pola A failed: $e");
      print("📋 Stack trace: $stackTrace");
      rethrow;
    }
  }

  /// Parser Pola A (data list dengan field tanggal + flow/pressure/totalizer objek)
  static Future<ChartSeriesBundle> _fetchPolaA({
    required String zoneName,
    required String token,
  }) async {
    final uri = endpointA(zoneName);
    print("🌐 Pola A URL: $uri");

    final resp = await http.get(uri, headers: {"Authorization": token});

    print("📨 Pola A Response: ${resp.statusCode}");
    print("📄 Pola A Body: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception("API Pola A gagal (${resp.statusCode}) - ${resp.body}");
    }

    final body = json.decode(resp.body);
    print("📋 Parsed Body: ${body.runtimeType}");

    final List<dynamic> list = body["data"] ?? [];
    print("📊 Data list length: ${list.length}");

    final flow = <GaugePoint>[];
    final pressure = <GaugePoint>[];
    final totalizer = <GaugePoint>[];

    for (final item in list) {
      print("📦 Processing item: $item");
      
      final dtRaw = item["tanggal"]?.toString() ?? "";
      final dt = ServerDateParser.parseAny(dtRaw);
      
      if (dt == null) {
        print("⚠️  Skipping item due to invalid date: $dtRaw");
        continue;
      }

      // Handle berbagai format data
      dynamic flowVal = item["flow"];
      dynamic pressureVal = item["pressure"];
      dynamic totalizerVal = item["totalizer"];

      // Jika flow adalah object dengan property 'nilai'
      if (flowVal is Map && flowVal.containsKey("nilai")) {
        flowVal = flowVal["nilai"];
      }
      
      if (pressureVal is Map && pressureVal.containsKey("nilai")) {
        pressureVal = pressureVal["nilai"];
      }
      
      if (totalizerVal is Map && totalizerVal.containsKey("nilai")) {
        totalizerVal = totalizerVal["nilai"];
      }

      // Convert ke double
      final flowDouble = (flowVal is num) ? flowVal.toDouble() : 
                        (flowVal is String) ? double.tryParse(flowVal) ?? 0.0 : 0.0;
      
      final pressureDouble = (pressureVal is num) ? pressureVal.toDouble() : 
                            (pressureVal is String) ? double.tryParse(pressureVal) ?? 0.0 : 0.0;
      
      final totalizerDouble = (totalizerVal is num) ? totalizerVal.toDouble() : 
                             (totalizerVal is String) ? double.tryParse(totalizerVal) ?? 0.0 : 0.0;

      flow.add(GaugePoint(dt, flowDouble));
      pressure.add(GaugePoint(dt, pressureDouble));
      totalizer.add(GaugePoint(dt, totalizerDouble));
    }

    return ChartSeriesBundle(flow: flow, pressure: pressure, totalizer: totalizer);
  }

  /// Parser Pola B (endpoint detail serial dengan array flow/pressure/totalizer)
  static Future<ChartSeriesBundle> _fetchPolaB({
    required String zoneOrSerial,
    required DateTime start,
    required DateTime end,
    required String token,
  }) async {
    final uri = endpointB(serialOrZone: zoneOrSerial, start: start, end: end);
    print("🌐 Pola B URL: $uri");

    final resp = await http.get(uri, headers: {"Authorization": token});

    print("📨 Pola B Response: ${resp.statusCode}");
    print("📄 Pola B Body: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception("API Pola B gagal (${resp.statusCode}) - ${resp.body}");
    }

    final body = json.decode(resp.body);
    print("📋 Parsed Body: $body");

    final List<dynamic> flowRaw = body["flow"] ?? [];
    final List<dynamic> pressureRaw = body["pressure"] ?? [];
    final List<dynamic> totalizerRaw = body["totalizer"] ?? [];

    print("📊 Flow data: ${flowRaw.length}, Pressure: ${pressureRaw.length}, Totalizer: ${totalizerRaw.length}");

    final flow = <GaugePoint>[];
    final pressure = <GaugePoint>[];
    final totalizer = <GaugePoint>[];

    DateTime fromUnix(dynamic v) {
      final int s = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: false);
    }

    for (final e in flowRaw) {
      final t = fromUnix(e["unix"]);
      final val = (e["nilai"] is num) ? (e["nilai"] as num).toDouble() : 0.0;
      flow.add(GaugePoint(t, val));
    }
    
    for (final e in pressureRaw) {
      final t = fromUnix(e["unix"]);
      final val = (e["nilai"] is num) ? (e["nilai"] as num).toDouble() : 0.0;
      pressure.add(GaugePoint(t, val));
    }
    
    for (final e in totalizerRaw) {
      final t = fromUnix(e["unix"]);
      final val = (e["nilai"] is num) ? (e["nilai"] as num).toDouble() : 0.0;
      totalizer.add(GaugePoint(t, val));
    }

    return ChartSeriesBundle(flow: flow, pressure: pressure, totalizer: totalizer);
  }

  /// Filter by user range jika datang dari Pola A (atau data sangat besar)
  static ChartSeriesBundle _filterByRange(
      ChartSeriesBundle src, DateTime start, DateTime end) {
    bool inRange(DateTime t) => !t.isBefore(start) && !t.isAfter(end);
    return ChartSeriesBundle(
      flow: src.flow.where((p) => inRange(p.time)).toList(),
      pressure: src.pressure.where((p) => inRange(p.time)).toList(),
      totalizer: src.totalizer.where((p) => inRange(p.time)).toList(),
    );
  }
}

/// ============================================================================
/// SECTION: In-Memory Cache (sederhana)
/// ============================================================================

class _ChartCacheEntry {
  final DateTime start;
  final DateTime end;
  final ChartSeriesBundle bundle;
  final DateTime createdAt;

  _ChartCacheEntry(this.start, this.end, this.bundle)
      : createdAt = DateTime.now();

  bool isFresh([Duration ttl = const Duration(minutes: 2)]) =>
      DateTime.now().difference(createdAt) <= ttl;

  bool sameRange(DateTime a, DateTime b) =>
      start.isAtSameMomentAs(a) && end.isAtSameMomentAs(b);
}

class ChartMemoryCache {
  ChartMemoryCache._();

  static final Map<String, _ChartCacheEntry> _map = {};

  static String _key(String zone) => "zone::$zone";

  static void put(String zone, DateTime start, DateTime end, ChartSeriesBundle b) {
    _map[_key(zone)] = _ChartCacheEntry(start, end, b);
  }

  static _ChartCacheEntry? get(String zone) => _map[_key(zone)];

  static void clear() => _map.clear();
}

/// ============================================================================
/// SECTION: Main Page
/// ============================================================================

class GrafikPage extends StatefulWidget {
  final String zoneName;

  const GrafikPage({
    super.key,
    required this.zoneName,
  });

  @override
  State<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends State<GrafikPage> {
  // Data
  ChartSeriesBundle _bundle =
      ChartSeriesBundle(flow: [], pressure: [], totalizer: []);

  // UI State
  bool _isLoading = false;
  String? _error;

  // View options
  bool _showFlow = true;
  bool _showPressure = true;
  bool _showTotalizer = true;
  bool _curved = true;
  bool _showDots = false;

  // Filter time
  final DateFormat inputFormat = DateFormat("dd-MM-yyyy HH:mm");
  DateTime _start = DateTime.now().subtract(Duration(hours: 24));
  DateTime _end = DateTime.now();

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  // Auto-refresh
  Timer? _timer;
  _AutoRefreshInterval _selectedInterval = _AutoRefreshInterval.off;

  // Latest values
  String _latestFlow = "0.00";
  String _latestPressure = "0.00";
  String _latestTime = "";

  // totalizer scale
  static const double _totalizerScale = 100000.0;

  // spots
  List<FlSpot> _flowSpots = [];
  List<FlSpot> _pressureSpots = [];
  List<FlSpot> _totalizerSpots = [];

  @override
  void initState() {
    super.initState();
    print("🚀 Initializing GrafikPage for zone: ${widget.zoneName}");
    
    // Set range default: 24 jam terakhir
    _start = DateTime.now().subtract(Duration(hours: 24));
    _end = DateTime.now();
    
    startController.text = inputFormat.format(_start);
    endController.text = inputFormat.format(_end);

    final entry = ChartMemoryCache.get(widget.zoneName);
    if (entry != null && entry.isFresh() && entry.sameRange(_start, _end)) {
      print("💾 Using cached data");
      _bundle = entry.bundle;
      _computeSpotsAndLatest();
      setState(() {});
    } else {
      print("🔄 Fetching new data");
      _fetch();
    }
    _applyAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    print("🔄 Starting fetch...");
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print("📡 Fetching data for ${widget.zoneName} from ${_start} to ${_end}");

      final data = await GrafikApiService.fetchFlexible(
        zoneName: widget.zoneName,
        start: _start,
        end: _end,
      );

      print("✅ Fetch successful - Data points: Flow: ${data.flow.length}, Pressure: ${data.pressure.length}, Totalizer: ${data.totalizer.length}");

      if (data.isEmpty) {
        print("⚠️  No data received from API");
        setState(() {
          _isLoading = false;
          _error = "Tidak ada data yang ditemukan untuk zona ${widget.zoneName} pada rentang waktu ini.";
        });
        return;
      }

      ChartMemoryCache.put(widget.zoneName, _start, _end, data);

      _bundle = data;
      _computeSpotsAndLatest();
      setState(() => _isLoading = false);
      
    } catch (e, stackTrace) {
      print("❌ Fetch error: $e");
      print("📋 Stack trace: $stackTrace");
      
      setState(() {
        _isLoading = false;
        _error = "Gagal memuat data.\nError: ${e.toString()}\n\nPastikan:\n• Koneksi internet tersedia\n• Zone name '${widget.zoneName}' valid\n• Server API sedang online";
      });
    }
  }

  void _computeSpotsAndLatest() {
    print("📊 Computing spots and latest values...");
    
    List<GaugePoint> flow = _bundle.flow;
    List<GaugePoint> pressure = _bundle.pressure;
    List<GaugePoint> totalizer = _bundle.totalizer;

    int cmp(GaugePoint a, GaugePoint b) => a.time.compareTo(b.time);
    flow.sort(cmp);
    pressure.sort(cmp);
    totalizer.sort(cmp);

    print("📈 Sorted data - Flow: ${flow.length}, Pressure: ${pressure.length}, Totalizer: ${totalizer.length}");

    _flowSpots = [];
    _pressureSpots = [];
    _totalizerSpots = [];
    
    for (var i = 0; i < flow.length; i++) {
      _flowSpots.add(FlSpot(i.toDouble(), flow[i].value));
    }
    for (var i = 0; i < pressure.length; i++) {
      _pressureSpots.add(FlSpot(i.toDouble(), pressure[i].value));
    }
    for (var i = 0; i < totalizer.length; i++) {
      _totalizerSpots
          .add(FlSpot(i.toDouble(), totalizer[i].value / _totalizerScale));
    }

    _latestFlow =
        _flowSpots.isNotEmpty ? _flowSpots.last.y.toStringAsFixed(2) : "0.00";
    _latestPressure = pressure.isNotEmpty
        ? pressure.last.value.toStringAsFixed(2)
        : "0.00";
    
    DateTime? lastTime;
    if (flow.isNotEmpty) lastTime = flow.last.time;
    if (pressure.isNotEmpty) {
      if (lastTime == null || pressure.last.time.isAfter(lastTime)) {
        lastTime = pressure.last.time;
      }
    }
    if (totalizer.isNotEmpty) {
      if (lastTime == null || totalizer.last.time.isAfter(lastTime)) {
        lastTime = totalizer.last.time;
      }
    }
    _latestTime = lastTime != null ? inputFormat.format(lastTime) : "";

    print("📊 Latest values - Flow: $_latestFlow, Pressure: $_latestPressure, Time: $_latestTime");
  }

  Future<void> _pickDateTime(TextEditingController controller, bool isStart) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    controller.text = inputFormat.format(dt);
    setState(() {
      if (isStart) {
        _start = dt;
      } else {
        _end = dt;
      }
    });
  }

  void _applyFilter() {
    try {
      final s = inputFormat.parseStrict(startController.text);
      final e = inputFormat.parseStrict(endController.text);
      if (e.isBefore(s)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tanggal akhir tidak boleh sebelum awal")),
        );
        return;
      }
      setState(() {
        _start = s;
        _end = e;
      });
      _fetch();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format tanggal salah. Gunakan dd-MM-yyyy HH:mm")),
      );
    }
  }

  void _useQuickRange(_QuickRange r) {
    final now = DateTime.now();
    late DateTime s, e;
    switch (r) {
      case _QuickRange.today:
        s = DateTime(now.year, now.month, now.day, 0);
        e = DateTime(now.year, now.month, now.day, 23, 59);
        break;
      case _QuickRange.yesterday:
        final y = now.subtract(const Duration(days: 1));
        s = DateTime(y.year, y.month, y.day, 0);
        e = DateTime(y.year, y.month, y.day, 23, 59);
        break;
      case _QuickRange.last7Days:
        s = now.subtract(const Duration(days: 7));
        e = now;
        break;
      case _QuickRange.last30Days:
        s = now.subtract(const Duration(days: 30));
        e = now;
        break;
    }
    startController.text = inputFormat.format(s);
    endController.text = inputFormat.format(e);
    setState(() {
      _start = s;
      _end = e;
    });
    _fetch();
  }

  void _applyAutoRefresh() {
    _timer?.cancel();
    final dur = _selectedInterval.toDuration();
    if (dur == null) return;
    _timer = Timer.periodic(dur, (_) => _fetch());
  }

  Future<void> _copyCsv() async {
    final rows = <List<String>>[];
    rows.add(["DateTime", "Flow(L/s)", "Pressure(Bar)", "Totalizer"]);

    final int len = [
      _bundle.flow.length,
      _bundle.pressure.length,
      _bundle.totalizer.length
    ].reduce((a, b) => math.max(a, b));

    String fmt(DateTime t) => inputFormat.format(t);
    String dv(double? v) => v == null ? "" : v.toString();

    for (int i = 0; i < len; i++) {
      final dt = _bundle.flow.length > i
          ? _bundle.flow[i].time
          : _bundle.pressure.length > i
              ? _bundle.pressure[i].time
              : _bundle.totalizer.length > i
                  ? _bundle.totalizer[i].time
                  : null;

      final flowVal = _bundle.flow.length > i ? _bundle.flow[i].value : null;
      final pressureVal =
          _bundle.pressure.length > i ? _bundle.pressure[i].value : null;
      final totalizerVal =
          _bundle.totalizer.length > i ? _bundle.totalizer[i].value : null;

      rows.add([
        dt != null ? fmt(dt) : "",
        dv(flowVal),
        dv(pressureVal),
        dv(totalizerVal),
      ]);
    }

    final buffer = StringBuffer();
    for (final r in rows) {
      buffer.writeln(r.map((e) => '"${e.replaceAll('"', '""')}"').join(","));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("CSV tersalin ke clipboard")),
    );
  }

  _AxisCalc _calcAxis() {
    final allY = <double>[];
    if (_showFlow) allY.addAll(_flowSpots.map((e) => e.y));
    if (_showPressure) allY.addAll(_pressureSpots.map((e) => e.y));
    if (_showTotalizer) allY.addAll(_totalizerSpots.map((e) => e.y));

    if (allY.isEmpty) {
      return _AxisCalc(minY: 0, maxY: 1, maxX: 1, xInterval: 1.0);
    }

    double minY = allY.reduce(math.min);
    double maxY = allY.reduce(math.max);

    if (minY == maxY) {
      minY = math.max(0, minY - 1);
      maxY = maxY + 1;
    } else {
      final pad = (maxY - minY) * 0.1;
      minY -= pad;
      maxY += pad;
      if (minY < 0) minY = 0;
    }

    final length =
        [_flowSpots.length, _pressureSpots.length, _totalizerSpots.length]
            .reduce(math.max);
    final maxX = math.max(0, length - 1).toDouble();
    final xInterval =
        (length <= 6) ? 1.0 : (length / 6.0).clamp(1.0, 12.0).toDouble();

    return _AxisCalc(minY: minY, maxY: maxY, maxX: maxX, xInterval: xInterval);
  }

  @override
  Widget build(BuildContext context) {
    final axis = _calcAxis();

    final statsFlow = computeStats(_bundle.flow.map((e) => e.value).toList());
    final statsPressure =
        computeStats(_bundle.pressure.map((e) => e.value).toList());
    final statsTotalizer =
        computeStats(_bundle.totalizer.map((e) => e.value).toList());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ZONA ${widget.zoneName}".toUpperCase(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          PopupMenuButton<_AutoRefreshInterval>(
            icon: const Icon(Icons.schedule, color: Colors.black),
            initialValue: _selectedInterval,
            onSelected: (v) {
              setState(() => _selectedInterval = v);
              _applyAutoRefresh();
            },
            itemBuilder: (ctx) => _AutoRefreshInterval.values
                .map((e) => PopupMenuItem(
                      value: e,
                      child: Text(e.label),
                    ))
                .toList(),
          ),
          IconButton(
            tooltip: 'Copy CSV',
            onPressed: _bundle.isEmpty ? null : _copyCsv,
            icon: const Icon(Icons.copy_all, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const _LoadingSkeleton()
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: _fetch,
                )
              : _bundle.isEmpty
                  ? const _EmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header latest
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _latestFlow,
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    const _BadgeUnit(text: "L/s"),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _latestPressure,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    const _BadgeUnit(text: "Bar"),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Update $_latestTime",
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Control panel
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _ChartControlPanel(
                              showFlow: _showFlow,
                              showPressure: _showPressure,
                              showTotalizer: _showTotalizer,
                              curved: _curved,
                              showDots: _showDots,
                              onChanged: (c) {
                                setState(() {
                                  _showFlow = c.showFlow;
                                  _showPressure = c.showPressure;
                                  _showTotalizer = c.showTotalizer;
                                  _curved = c.curved;
                                  _showDots = c.showDots;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Chart
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: LineChart(
                                LineChartData(
                                  minX: 0.0,
                                  maxX: axis.maxX,
                                  minY: axis.minY,
                                  maxY: axis.maxY,
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      axisNameWidget: const Text('Value'),
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 44,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: axis.xInterval,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          final dt = _resolveTimeFromIndex(idx);
                                          if (dt == null) {
                                            return const SizedBox.shrink();
                                          }
                                          final rangeDays =
                                              _end.difference(_start).inDays;
                                          final lab = (rangeDays >= 1)
                                              ? DateFormat("dd/MM HH:mm").format(dt)
                                              : DateFormat("HH:mm").format(dt);
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              lab,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    if (_showFlow)
                                      LineChartBarData(
                                        spots: _flowSpots,
                                        isCurved: _curved,
                                        color: Colors.blue,
                                        barWidth: 2,
                                        dotData: FlDotData(show: _showDots),
                                      ),
                                    if (_showTotalizer)
                                      LineChartBarData(
                                        spots: _totalizerSpots,
                                        isCurved: _curved,
                                        color: Colors.purple,
                                        barWidth: 2,
                                        dotData: FlDotData(show: _showDots),
                                      ),
                                    if (_showPressure)
                                      LineChartBarData(
                                        spots: _pressureSpots,
                                        isCurved: _curved,
                                        color: Colors.red,
                                        barWidth: 2,
                                        dotData: FlDotData(show: _showDots),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              LegendItem(color: Colors.blue, text: 'Flow'),
                              SizedBox(width: 16),
                              LegendItem(color: Colors.purple, text: 'Totalizer / 100k'),
                              SizedBox(width: 16),
                              LegendItem(color: Colors.red, text: 'Pressure'),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Date filter
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _DateFilterPanel(
                              startController: startController,
                              endController: endController,
                              onPickStart: () => _pickDateTime(startController, true),
                              onPickEnd: () => _pickDateTime(endController, false),
                              onApply: _applyFilter,
                              onQuick: _useQuickRange,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _StatsPanel(
                              statsFlow: statsFlow,
                              statsPressure: statsPressure,
                              statsTotalizer: statsTotalizer,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Mini table + Nav to full table
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "DATA GRAFIK (ringkas)",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _MiniTable(
                              bundle: _bundle,
                              dateFormat: inputFormat,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final rows = _composeDataForTablePage(_bundle);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DataTablePage(
                                      zoneName: widget.zoneName,
                                      data: rows,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Tampilkan Semua"),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  DateTime? _resolveTimeFromIndex(int idx) {
    if (_bundle.flow.length > idx) return _bundle.flow[idx].time;
    if (_bundle.pressure.length > idx) return _bundle.pressure[idx].time;
    if (_bundle.totalizer.length > idx) return _bundle.totalizer[idx].time;
    return null;
  }

  List<Map<String, dynamic>> _composeDataForTablePage(ChartSeriesBundle b) {
    final int len = [b.flow.length, b.pressure.length, b.totalizer.length]
        .reduce((a, c) => math.max(a, c));

    String fmt(DateTime t) => inputFormat.format(t);

    final List<Map<String, dynamic>> out = [];
    for (int i = 0; i < len; i++) {
      final DateTime? t = (b.flow.length > i)
          ? b.flow[i].time
          : (b.pressure.length > i)
              ? b.pressure[i].time
              : (b.totalizer.length > i)
                  ? b.totalizer[i].time
                  : null;

      out.add({
        'datetime': t != null ? fmt(t) : '-',
        'flow': (b.flow.length > i) ? (b.flow[i].value) : 0.0,
        'pressure':
            (b.pressure.length > i) ? (b.pressure[i].value) : 0.0,
        'totalizer':
            (b.totalizer.length > i) ? (b.totalizer[i].value) : 0.0,
      });
    }
    return out;
  }
}

/// ============================================================================
/// SECTION: Small Widgets
/// ============================================================================

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.show_chart, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BadgeUnit extends StatelessWidget {
  final String text;
  const _BadgeUnit({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar({double h = 18, double w = 120}) => Container(
          height: h,
          width: w,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          bar(h: 28, w: 180),
          bar(w: 140),
          const SizedBox(height: 12),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          bar(w: double.infinity),
          bar(w: double.infinity),
          bar(w: double.infinity),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.insights, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "Tidak ada data pada rentang waktu ini.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Coba gunakan rentang waktu yang berbeda.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel filter tanggal + quick range
class _DateFilterPanel extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onApply;
  final void Function(_QuickRange range) onQuick;

  const _DateFilterPanel({
    required this.startController,
    required this.endController,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onApply,
    required this.onQuick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: Text("Tanggal Awal")),
            Expanded(child: Text("Tanggal Akhir")),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onPickStart,
                child: AbsorbPointer(
                  child: TextField(
                    controller: startController,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onPickEnd,
                child: AbsorbPointer(
                  child: TextField(
                    controller: endController,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickChip(
              label: "Hari Ini",
              onTap: () => onQuick(_QuickRange.today),
            ),
            _QuickChip(
              label: "Kemarin",
              onTap: () => onQuick(_QuickRange.yesterday),
            ),
            _QuickChip(
              label: "7 Hari",
              onTap: () => onQuick(_QuickRange.last7Days),
            ),
            _QuickChip(
              label: "30 Hari",
              onTap: () => onQuick(_QuickRange.last30Days),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.filter_alt),
            label: const Text("Filter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Panel pengaturan chart (show/hide series, curved, dots)
class _ChartControlPanel extends StatelessWidget {
  final bool showFlow;
  final bool showPressure;
  final bool showTotalizer;
  final bool curved;
  final bool showDots;
  final void Function(_ChartControlChanged change) onChanged;

  const _ChartControlPanel({
    required this.showFlow,
    required this.showPressure,
    required this.showTotalizer,
    required this.curved,
    required this.showDots,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    void update({
      bool? sFlow,
      bool? sPressure,
      bool? sTotalizer,
      bool? sCurved,
      bool? sDots,
    }) {
      onChanged(_ChartControlChanged(
        showFlow: sFlow ?? showFlow,
        showPressure: sPressure ?? showPressure,
        showTotalizer: sTotalizer ?? showTotalizer,
        curved: sCurved ?? curved,
        showDots: sDots ?? showDots,
      ));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Flow", style: TextStyle(fontSize: 12)),
                value: showFlow,
                activeColor: Colors.blue,
                onChanged: (v) => update(sFlow: v ?? true),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title:
                    const Text("Pressure", style: TextStyle(fontSize: 12)),
                value: showPressure,
                activeColor: Colors.red,
                onChanged: (v) => update(sPressure: v ?? true),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Totalizer", style: TextStyle(fontSize: 12)),
                value: showTotalizer,
                activeColor: Colors.purple,
                onChanged: (v) => update(sTotalizer: v ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: curved,
                      onChanged: (v) => update(sCurved: v),
                    ),
                    const Text("Curved"),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: showDots,
                      onChanged: (v) => update(sDots: v),
                    ),
                    const Text("Dot"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartControlChanged {
  final bool showFlow;
  final bool showPressure;
  final bool showTotalizer;
  final bool curved;
  final bool showDots;

  _ChartControlChanged({
    required this.showFlow,
    required this.showPressure,
    required this.showTotalizer,
    required this.curved,
    required this.showDots,
  });
}

/// Mini table ringkas menampilkan data gabungan (3 kolom)
class _MiniTable extends StatelessWidget {
  final ChartSeriesBundle bundle;
  final DateFormat dateFormat;
  const _MiniTable({required this.bundle, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final len = [
      bundle.flow.length,
      bundle.pressure.length,
      bundle.totalizer.length
    ].reduce(math.max);

    if (len == 0) {
      return const _EmptyState();
    }

    final int limit = math.min(10, len);

    String fmt(DateTime t) => dateFormat.format(t);

    return Table(
      border: TableBorder.all(color: Colors.black54, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE0F2F1)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "DateTime",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Flow",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Pressure",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Totalizer",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        for (int i = 0; i < limit; i++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (bundle.flow.length > i)
                      ? fmt(bundle.flow[i].time)
                      : (bundle.pressure.length > i)
                          ? fmt(bundle.pressure[i].time)
                          : (bundle.totalizer.length > i)
                              ? fmt(bundle.totalizer[i].time)
                              : "-",
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (bundle.flow.length > i) ? bundle.flow[i].value.toStringAsFixed(2) : "-",
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (bundle.pressure.length > i) ? bundle.pressure[i].value.toStringAsFixed(2) : "-",
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (bundle.totalizer.length > i) ? bundle.totalizer[i].value.toStringAsFixed(2) : "-",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Panel statistik
class _StatsPanel extends StatelessWidget {
  final BasicStats statsFlow;
  final BasicStats statsPressure;
  final BasicStats statsTotalizer;

  const _StatsPanel({
    required this.statsFlow,
    required this.statsPressure,
    required this.statsTotalizer,
  });

  Widget _item({
    required String title,
    required BasicStats stats,
    required Color color,
    String? unit,
  }) {
    String f(double v) => v.toStringAsFixed(2);
    final u = unit ?? "";
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, color: color),
                    const SizedBox(width: 6),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Min: "),
                    Text("${f(stats.min)} $u"),
                  ],
                ),
                Row(
                  children: [
                    const Text("Max: "),
                    Text("${f(stats.max)} $u"),
                  ],
                ),
                Row(
                  children: [
                    const Text("Avg: "),
                    Text("${f(stats.avg)} $u"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(title: "Flow", stats: statsFlow, color: Colors.blue, unit: "L/s"),
        _item(title: "Pressure", stats: statsPressure, color: Colors.red, unit: "Bar"),
        _item(title: "Totalizer", stats: statsTotalizer, color: Colors.purple),
      ],
    );
  }
}

/// ============================================================================
/// SECTION: Helpers
/// ============================================================================

class _AxisCalc {
  final double minY;
  final double maxY;
  final double maxX;
  final double xInterval;
  _AxisCalc({
    required this.minY,
    required this.maxY,
    required this.maxX,
    required this.xInterval,
  });
}

enum _QuickRange { today, yesterday, last7Days, last30Days }

enum _AutoRefreshInterval { off, s15, s30, s60, m5 }

extension on _AutoRefreshInterval {
  String get label => {
        _AutoRefreshInterval.off: "Auto: Mati",
        _AutoRefreshInterval.s15: "Auto: 15s",
        _AutoRefreshInterval.s30: "Auto: 30s",
        _AutoRefreshInterval.s60: "Auto: 60s",
        _AutoRefreshInterval.m5: "Auto: 5m",
      }[this]!;

  Duration? toDuration() => {
        _AutoRefreshInterval.off: null,
        _AutoRefreshInterval.s15: const Duration(seconds: 15),
        _AutoRefreshInterval.s30: const Duration(seconds: 30),
        _AutoRefreshInterval.s60: const Duration(seconds: 60),
        _AutoRefreshInterval.m5: const Duration(minutes: 5),
      }[this];
}