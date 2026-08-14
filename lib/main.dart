import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:local_auth/local_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'database_helper.dart';
import 'alrajhi_parser.dart';
import 'export_helper.dart';
import 'backup_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MasareefiApp());
}

class MasareefiApp extends StatefulWidget {
  const MasareefiApp({super.key});

  @override
  State<MasareefiApp> meState() => _MasareefiAppState();

  static _MasareefiAppState meState() => _MasareefiAppState();
}

class _MasareefiAppState extends State<MasareefiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ù…ØµØ§Ø±ÙŠÙÙŠ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Ø§Ù„Ø±Ø¬Ø§Ø¡ Ø§Ù„ØªØ¨ØµÙŠÙ… Ù„ÙØªØ­ ØªØ·Ø¨ÙŠÙ‚ Ù…ØµØ§Ø±ÙŠÙÙŠ',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      setState(() { _authenticated = authenticated; });
    } catch (e) {
      setState(() { _authenticated = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return const HomeScreen();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text('ØªØ·Ø¨ÙŠÙ‚ Ù…ØµØ§Ø±ÙŠÙÙŠ Ù…ØºÙ„Ù‚', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ù‚ÙÙ„'),
            )
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String _selectedCategory = 'Ø§Ù„ÙƒÙ„';
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  final Telephony telephony = Telephony.instance;

  final List<String> _categories = [
    'Ø§Ù„ÙƒÙ„', 'Ù…Ø·Ø§Ø¹Ù…', 'Ù‚Ù‡ÙˆØ©', 'Ø¨Ù†Ø²ÙŠÙ†', 'Ø³ÙˆØ¨Ø± Ù…Ø§Ø±ÙƒØª', 'ØªØ³ÙˆÙ‚', 'ØªØ­ÙˆÙŠÙ„Ø§Øª', 'ÙÙˆØ§ØªÙŠØ±', 'Ø£Ø®Ø±Ù‰'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _requestSMSPermissions();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.getAllExpenses();
    setState(() {
      _expenses = data;
      _applyFilters();
      _isLoading = false;
    });
  }

  Future<void> _requestSMSPermissions() async {
    var status = await Permission.sms.request();
    if (status.isGranted) _syncSMS();
  }

  Future<void> _syncSMS() async {
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    int newAdded = 0;
    for (var msg in messages) {
      if (msg.body != null) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(msg.date ?? DateTime.now().millisecondsSinceEpoch);
        var parsed = AlRajhiParser.parseSMS(msg.body!, date);
        if (parsed != null) {
          Expense exp = Expense(
            amount: parsed.amount,
            merchant: parsed.merchant,
            date: parsed.date,
            cardLast4: parsed.cardLast4,
            type: parsed.type,
            category: parsed.category,
            smsHash: parsed.smsHash,
          );
          bool inserted = await DatabaseHelper.instance.insertExpense(exp);
          if (inserted) newAdded++;
        }
      }
    }

    if (newAdded > 0) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ØªÙ… Ø§Ø³ØªÙŠØ±Ø§Ø¯  Ø¹Ù…Ù„ÙŠØ© Ø¬Ø¯ÙŠØ¯Ø©')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _expenses.where((e) {
        bool matchesSearch = e.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.category.contains(_searchQuery);
        bool matchesCategory = _selectedCategory == 'Ø§Ù„ÙƒÙ„' || e.category == _selectedCategory;
        bool matchesDate = _selectedDateRange == null ||
            (e.date.isAfter(_selectedDateRange!.start) && e.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesCategory && matchesDate;
      }).toList();
    });
  }

  double get _todayExpense {
    DateTime now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _monthExpense {
    DateTime now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _totalExpense => _expenses.fold(0.0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ù…ØµØ§Ø±ÙŠÙÙŠ'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: _syncSMS, tooltip: 'Ù…Ø²Ø§Ù…Ù†Ø©'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'export_excel') {
                String path = await ExportHelper.exportToExcel(_filteredExpenses);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ØªÙ… Ø§Ù„ØªØµØ¯ÙŠØ± Ù„Ù€ Excel ÙÙŠ: ')));
              } else if (value == 'export_pdf') {
                await ExportHelper.exportToPdf(_filteredExpenses);
              } else if (value == 'backup') {
                String path = await BackupHelper.createBackup();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ù†Ø³Ø®Ø© Ø§Ù„Ø§Ø­ØªÙŠØ§Ø·ÙŠØ©: ')));
              } else if (value == 'theme') {
                MasareefiApp.meState().toggleTheme();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export_excel', child: Row(children: [Icon(Icons.table_chart), SizedBox(width: 8), Text('ØªØµØ¯ÙŠØ± Excel')])),
              const PopupMenuItem(value: 'export_pdf', child: Row(children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Text('Ø·Ø¨Ø§Ø¹Ø© / ØªØµØ¯ÙŠØ± PDF')])),
              const PopupMenuItem(value: 'backup', child: Row(children: [Icon(Icons.backup), SizedBox(width: 8), Text('Ù†Ø³Ø® Ø§Ø­ØªÙŠØ§Ø·ÙŠ Ù…Ø­Ù„ÙŠ')])),
              const PopupMenuItem(value: 'theme', child: Row(children: [Icon(Icons.brightness_6), SizedBox(width: 8), Text('ØªØºÙŠÙŠØ± Ø§Ù„Ù…Ø¸Ù‡Ø±')])),
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _buildStatCard('Ø§Ù„ÙŠÙˆÙ…', ' SAR', Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatCard('Ø§Ù„Ø´Ù‡Ø±', ' SAR', Colors.teal),
                      const SizedBox(width: 8),
                      _buildStatCard('Ø§Ù„Ø¥Ø¬Ù…Ø§Ù„ÙŠ', ' SAR', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Ø¨Ø­Ø« Ø¨Ø§Ø³Ù… Ø§Ù„ØªØ§Ø¬Ø± Ø£Ùˆ Ø§Ù„ØªØµÙ†ÙŠÙ...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() { _selectedDateRange = picked; });
                            _applyFilters();
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() { _selectedCategory = cat; });
                                _applyFilters();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ø§Ù„Ø¹Ù…Ù„ÙŠØ§Øª', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(' Ø¹Ù…Ù„ÙŠØ©', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ..._filteredExpenses.map((item) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(item.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(' â€¢ '),
                          trailing: Text(' SAR', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15)),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            FittedBox(child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
          ],
        ),
      ),
    );
  }
}