import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/simulation_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SimulationState()),
      ],
      child: const OmniMindApp(),
    ),
  );
}

class OmniMindApp extends StatelessWidget {
  const OmniMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniMind',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        fontFamily: 'Roboto', // Assume Roboto is available or use Google Fonts
      ),
      home: const SimulationScreen(),
    );
  }
}

class SimulationState extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  String _currentMessage = "Initializing Director Engine...";
  List<String> _options = ["Start Simulation"];
  List<String> _inventory = [];
  String? _currentAssetUrl;
  String _currentAssetId = "default_void"; // For caching
  bool _isLoading = false;

  String get currentMessage => _currentMessage;
  List<String> get options => _options;
  String? get currentAssetUrl => _currentAssetUrl;
  String get currentAssetId => _currentAssetId;
  bool get isLoading => _isLoading;

  Future<void> startSimulation() async {
    _setLoading(true);
    try {
      final data = await _api.startSimulation();
      _updateStateFromResponse(data);
    } catch (e) {
      _currentMessage = "Connection Error: $e";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitAction(String action) async {
    _setLoading(true);
    // Optimistic update
    _currentMessage = "Processing..."; 
    _options = []; 
    notifyListeners();

    try {
      final data = await _api.performAction(action, _inventory);
      _updateStateFromResponse(data);
    } catch (e) {
      _currentMessage = "Error: $e";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _updateStateFromResponse(Map<String, dynamic> data) {
    _currentMessage = data['message'] ?? "Unknown state";
    _options = List<String>.from(data['options'] ?? []);
    
    // Handle Assets
    if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
      final asset = data['assets'][0]; // Handle first asset for now
      if (asset['type'] == 'video') {
         // In a real app, we would check if URL is provided or if we need to generate
         // For this MVP with the provided backend, we might assume prompt is passed
         // and we need to trigger generation if URL is missing.
         // However, the backend simulation_generator integration with asset_pipeline 
         // isn't fully automatic yet. 
         // Let's assume for now we might get a prompt and we'd trigger it, 
         // OR we just display a placeholder loop if it's missing.
         
         // If `url` is present, use it.
         if (asset['url'] != null) {
            _currentAssetUrl = asset['url'];
            _currentAssetId = asset['url'].hashCode.toString();
         } else {
            // Trigger generation (stub for MVP flow)
            // In a full implementation, we'd call _api.generateAsset(asset['prompt'])
            print("Asset needs generation: ${asset['prompt']}");
         }
      }
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Placeholder for hardware integration
  void unlockDevice() {
    print("Sending Bluetooth signal to unlock device...");
  }
}
