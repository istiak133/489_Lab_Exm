import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/landmark_provider.dart';
import 'screens/map_screen.dart';
import 'screens/landmarks_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/add_landmark_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LandmarkProvider()..loadLandmarks(),
      child: const SmartLandmarksApp(),
    ),
  );
}

class SmartLandmarksApp extends StatelessWidget {
  const SmartLandmarksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Landmarks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

/// Main Screen with Bottom Navigation Bar (4 tabs as required by PDF)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const LandmarksScreen(),
    const ActivityScreen(),
    const AddLandmarkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LandmarkProvider>();

    // Show messages as SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.message!),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        provider.clearMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Landmarks'),
        actions: [
          // Offline indicator
          if (provider.isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text('Offline', style: TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.orange,
                padding: EdgeInsets.zero,
              ),
            ),
          // Pending sync count
          if (provider.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text('${provider.pendingCount} pending',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.red,
                padding: EdgeInsets.zero,
              ),
            ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadLandmarks(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Landmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add/View',
          ),
        ],
      ),
    );
  }
}
