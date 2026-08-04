import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const EcuDashboardApp());
}

class EcuDashboardApp extends StatelessWidget {
  const EcuDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECU Dashboard Supra X 125',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.redAccent,
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variabel Data Sensor ECU
  double rpm = 0.0;
  double ect = 0.0; // Engine Coolant Temp
  double tps = 0.0; // Throttle Position
  double battery = 0.0;
  double speed = 0.0;
  double injDuration = 0.0; // Injection Duration (ms)
  
  Timer? _simulationTimer;
  bool isConnected = true;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  // Fungsi Simulasi Pergerakan Angka Sensor ECU Honda Supra
  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!isConnected) return;

      setState(() {
        _time += 0.2;
        
        // Simulasi Gas Naik Turun secara acak / dinamis
        double wave = (sin(_time * 0.5) + 1) / 2; // nilai antara 0 - 1
        
        tps = wave * 85.0 + (Random().nextDouble() * 2); // TPS 0% - 87%
        if (tps < 0) tps = 0;
        
        rpm = 1400 + (wave * 7000) + (Random().nextInt(150)); // RPM 1400 (Idle) - 8500 RPM
        
        speed = wave * 95.0 + (Random().nextInt(3)); // Speed 0 - 100 km/jam
        
        // ECT naik perlahan dari 35C lalu stabil di sekitar 88C - 92C
        if (ect < 88.0) {
          ect += 0.1;
        } else {
          ect = 89.0 + sin(_time * 0.1) * 2;
        }

        battery = 13.8 + (sin(_time) * 0.2); // Voltase pengisian aki stabil 13.6v - 14.0v
        
        injDuration = 1.8 + (wave * 4.5); // Durasi injeksi 1.8ms - 6.3ms
      });
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HONDA SUPRA X 125 FI', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 5,
        centerTitle: true,
        actions: [
          Icon(
            Icons.circle,
            color: isConnected ? Colors.greenAccent : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Panel Utama: RPM BAR & DIGITAL RPM
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text('ENGINE RPM', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    rpm.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 48, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar untuk RPM RPM Redline di 9000
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (rpm / 10000).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[900],
                      valueColor: AlwaysStoppedAnimation<Color>(rpm > 8000 ? Colors.red : Colors.orangeAccent),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grid Sensor Lainnya
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildSensorCard('VEHICLE SPEED', speed.toStringAsFixed(0), 'Km/h', Icons.speed, Colors.blueAccent),
                  _buildSensorCard('THROTTLE (TPS)', '${tps.toStringAsFixed(1)}%', 'Pos', Icons.shutter_speed, Colors.greenAccent),
                  _buildSensorCard('ENG COOLANT (ECT)', '${ect.toStringAsFixed(1)}°C', 'Temp', Icons.thermostat, Colors.orangeAccent),
                  _buildSensorCard('INJECTOR DURATION', '${injDuration.toStringAsFixed(2)}ms', 'Time', Icons.ev_station, Colors.purpleAccent),
                ],
              ),
            ),

            // Panel Bawah: Voltase Aki & Info Sistem
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[950],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.battery_charging_full, color: Colors.yellowAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('BATTERY VOLTAGE:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        '${battery.toStringAsFixed(1)} V',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const Text(
                    'PROTOKOL: K-LINE KWP2000',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Row(
            alignment: PlaceholderAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
