import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/radar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080F08),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const GhostMeshApp(),
    ),
  );
}

class GhostMeshApp extends StatelessWidget {
  const GhostMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghost Mesh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080F08),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF41),
          secondary: Color(0xFF00A828),
          surface: Color(0xFF0A1A0A),
        ),
        fontFamily: 'monospace',
      ),
      home: const _PermissionsGate(),
    );
  }
}

class _PermissionsGate extends StatefulWidget {
  const _PermissionsGate();

  @override
  State<_PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<_PermissionsGate> {
  String _status = 'Requesting permissions…';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    if (!Platform.isAndroid) {
      setState(() {
        _status = 'This app currently runs on Android only.';
      });
      return;
    }

    final perms = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
      Permission.notification,
    ];

    final results = await perms.request();
    final missing = results.entries
        .where((e) =>
            e.value != PermissionStatus.granted &&
            e.value != PermissionStatus.limited)
        .map((e) => e.key.toString().split('.').last)
        .toList();

    if (missing.isNotEmpty) {
      setState(() {
        _status =
            'Missing permissions: ${missing.join(', ')}\nDiscovery may not work.';
      });
      // give the user time to read, then continue anyway
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;
    setState(() => _status = 'Starting mesh…');

    await context.read<AppProvider>().init();

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (_ready && provider.initialized) return const RadarScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF080F08),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '◎',
                style: TextStyle(
                  color: Color(0xFF00FF41),
                  fontSize: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'GHOST MESH',
                style: TextStyle(
                  color: Color(0xFF00FF41),
                  fontFamily: 'monospace',
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'P2P · NO ACCOUNTS · NO SERVERS',
                style: TextStyle(
                  color: Color(0xFF336633),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFF00FF41),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF66CC66),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
