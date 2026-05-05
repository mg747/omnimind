import 'package:dio/dio.dart';
import 'dart:async';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://intelligence-for-all-api.onrender.com', // Live Cloud Backend
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Starts or resumes a simulation session
  Future<Map<String, dynamic>> startSimulation({String? initialPrompt}) async {
    try {
      String url = '/simulation/start';
      if (initialPrompt != null && initialPrompt.isNotEmpty) {
        url += '?initial_prompt=${Uri.encodeComponent(initialPrompt)}';
      }
      final response = await _dio.get(url);
      return response.data;
    } catch (e) {
      print('Error starting simulation: $e');
      return {
        'message': 'Simulation Offline: Backend connection failed. You are currently in Mock Mode.',
        'options': ['Retry Connection', 'Continue in Mock Mode'],
        'assets': []
      };
    }
  }

  /// Sends a user action to the backend
  Future<Map<String, dynamic>> performAction(String action, List<String> inventory) async {
    try {
      final response = await _dio.post('/simulation/action', data: {
        'action': action,
        'inventory': inventory,
      });
      return response.data;
    } catch (e) {
      print('Error performing action: $e');
      return {
        'message': 'Action failed: Backend offline. Mock action [$action] executed.',
        'options': ['Retry Connection', 'Continue in Mock Mode'],
        'assets': []
      };
    }
  }

  /// Polls the status of a video generation task
  Stream<String> pollAssetStatus(String taskId) async* {
    while (true) {
      try {
        final response = await _dio.get('/assets/status/$taskId');
        final status = response.data['status'];
        
        if (status == 'SUCCEEDED') {
          yield response.data['output'][0]; // URL
          break;
        } else if (status == 'FAILED') {
          throw Exception('Asset generation failed: ${response.data['error']}');
        }
        
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('Polling error: $e');
        break; 
      }
    }
  }
}
