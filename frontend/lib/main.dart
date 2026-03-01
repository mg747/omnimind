import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/simulation_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar'), Locale('bg'), Locale('cs'), Locale('da'), Locale('de'),
        Locale('el'), Locale('en'), Locale('es'), Locale('et'), Locale('fi'),
        Locale('fr'), Locale('he'), Locale('hi'), Locale('hu'), Locale('id'),
        Locale('it'), Locale('ja'), Locale('ko'), Locale('lt'), Locale('lv'),
        Locale('no'), Locale('nl'), Locale('pl'), Locale('pt'), Locale('ro'),
        Locale('ru'), Locale('sk'), Locale('sl'), Locale('sv'), Locale('th'),
        Locale('tr'), Locale('uk'), Locale('vi'), Locale('zh')
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SimulationState()),
        ],
        child: const OmniMindApp(),
      ),
    ),
  );
}

class OmniMindApp extends StatelessWidget {
  const OmniMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniMind',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
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
  
  String _currentMessage = "simulation.init_engine".tr();
  List<String> _options = ["simulation.start".tr()];
  List<String> _inventory = [];
  String? _currentAssetUrl;
  String _currentAssetId = "default_void"; // For caching
  bool _isLoading = false;
  bool _isStream = false;
  bool _hasStarted = false;
  String? _subtitleUrl;

  String get currentMessage => _currentMessage;
  List<String> get options => _options;
  String? get currentAssetUrl => _currentAssetUrl;
  String get currentAssetId => _currentAssetId;
  bool get isLoading => _isLoading;
  bool get isStream => _isStream;
  String? get subtitleUrl => _subtitleUrl;

  Future<void> startSimulation() async {
    _setLoading(true);
    try {
      final data = await _api.startSimulation();
      _updateStateFromResponse(data);
      _options.insert(0, "simulation.watch_movies".tr());
    } catch (e) {
      _currentMessage = "simulation.connection_error".tr(args: [e.toString()]);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitAction(String action) async {
    _setLoading(true);
    _currentMessage = "simulation.processing".tr(); 
    _options = []; 
    notifyListeners();

    try {
      if (!_hasStarted) {
         _hasStarted = true;
         Map<String,dynamic> data;
         if (action.toLowerCase() == "simulation.start".tr().toLowerCase()) {
            data = await _api.startSimulation();
         } else {
            data = await _api.startSimulation(initialPrompt: action);
         }
         _updateStateFromResponse(data);
         _options.insert(0, "simulation.watch_movies".tr());
         return;
      }

      if (action.toLowerCase() == "simulation.watch_movies".tr().toLowerCase()) {
        // Fetch movies list from backend
        // For simplicity, hardcode response structure simulating backend
        _currentMessage = "simulation.select_movie".tr();
        _options = ["simulation.watch_bbb".tr(), "simulation.watch_sintel".tr(), "simulation.return".tr()];
      } else if (action.toLowerCase() == "simulation.watch_bbb".tr().toLowerCase()) {
        _currentMessage = "simulation.streaming_bbb".tr();
        _options = ["simulation.stop_movie".tr()];
        _currentAssetUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
        _currentAssetId = "m1";
        _isStream = true;
        _subtitleUrl = "http://localhost:8000/movies/subtitles/m1";
      } else if (action.toLowerCase() == "simulation.watch_sintel".tr().toLowerCase()) {
        _currentMessage = "simulation.streaming_sintel".tr();
        _options = ["simulation.stop_movie".tr()];
        _currentAssetUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4";
        _currentAssetId = "m2";
        _isStream = true;
        _subtitleUrl = "http://localhost:8000/movies/subtitles/m2";
      } else if (action.toLowerCase() == "simulation.stop_movie".tr().toLowerCase() || action.toLowerCase() == "simulation.return".tr().toLowerCase()) {
        _isStream = false;
        _subtitleUrl = null;
        final data = await _api.startSimulation();
        _updateStateFromResponse(data);
        _options.insert(0, "simulation.watch_movies".tr());
      } else {
        final data = await _api.performAction(action, _inventory);
        _updateStateFromResponse(data);
        _options.insert(0, "simulation.watch_movies".tr());
      }
    } catch (e) {
      _currentMessage = "simulation.error".tr(args: [e.toString()]);
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _updateStateFromResponse(Map<String, dynamic> data) {
    _currentMessage = data['message'] ?? "Unknown state";
    _options = List<String>.from(data['options'] ?? []);
    
    // Handle Assets
    if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
      final asset = data['assets'][0]; // Handle first asset for now
      if (asset['type'] == 'video') {
         if (asset['url'] != null) {
            _currentAssetUrl = asset['url'];
            _currentAssetId = asset['url'].hashCode.toString();
            _isStream = false;
            _subtitleUrl = null;
         } else {
            print("Asset needs generation: ${asset['prompt']}");
         }
      }
    }
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
