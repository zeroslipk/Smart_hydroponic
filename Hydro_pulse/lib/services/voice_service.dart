import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/sensor_reading.dart';
import '../models/alert_model.dart';

/// Voice command types
enum VoiceCommand {
  status,
  temperature,
  waterLevel,
  pH,
  tds,
  light,
  alerts,
  pumpOn,
  pumpOff,
  lightsOn,
  lightsOff,
  fanOn,
  fanOff,
  unknown,
}

/// Callback for actuator commands
typedef ActuatorCallback = void Function(String actuatorId, bool turnOn);

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';
  
  // Callbacks
  Function(String)? onWordsRecognized;
  Function(VoiceCommand, String)? onCommandRecognized;
  Function(bool)? onListeningChanged;
  ActuatorCallback? onActuatorCommand;

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;

  /// Initialize TTS and Speech
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize TTS
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Slightly slower for clarity
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      // Set TTS callbacks
      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      // Initialize Speech Recognition
      final speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('VoiceService: Speech error: ${error.errorMsg}');
          _isListening = false;
          onListeningChanged?.call(false);
        },
        onStatus: (status) {
          debugPrint('VoiceService: Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningChanged?.call(false);
          }
        },
      );

      _isInitialized = speechAvailable;
      debugPrint('VoiceService: Initialized. Speech available: $speechAvailable');
      return speechAvailable;
    } catch (e) {
      debugPrint('VoiceService: Initialization error: $e');
      return false;
    }
  }

  // ============== TEXT-TO-SPEECH ==============

  /// Speak text with optional priority (stops current speech)
  Future<void> speak(String text, {bool priority = false}) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint('VoiceService: Cannot speak - initialization failed');
          return;
        }
      }
      
      if (priority && _isSpeaking) {
        await _tts.stop();
      }
      
      debugPrint('VoiceService: Speaking: $text');
      await _tts.speak(text).catchError((e) {
        debugPrint('VoiceService: Error speaking: $e');
      });
    } catch (e) {
      debugPrint('VoiceService: Exception in speak(): $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Read system status from sensors
  Future<void> speakSystemStatus(List<SensorReading> sensors) async {
    if (sensors.isEmpty) {
      await speak('No sensor data available');
      return;
    }

    final buffer = StringBuffer('System status. ');
    
    for (final sensor in sensors) {
      final status = sensor.status == 'optimal' || sensor.status == 'good' 
          ? 'normal' 
          : sensor.status;
      buffer.write('${sensor.displayName}: ${sensor.displayValue} ${_getUnitSpoken(sensor.unit)}, $status. ');
    }
    
    await speak(buffer.toString());
  }

  /// Read single sensor
  Future<void> speakSensor(SensorReading sensor) async {
    final status = sensor.status == 'optimal' || sensor.status == 'good' 
        ? 'within normal range' 
        : 'at ${sensor.status} level';
    
    await speak(
      '${sensor.displayName} is ${sensor.displayValue} ${_getUnitSpoken(sensor.unit)}, $status',
    );
  }

  /// Read alert
  Future<void> speakAlert(AlertModel alert) async {
    await speak(
      '${alert.severityLabel} alert: ${alert.title}. ${alert.message}',
    );
  }

  /// Read multiple alerts summary
  Future<void> speakAlertsSummary(List<AlertModel> alerts) async {
    final unread = alerts.where((a) => !a.isAcknowledged).length;
    final critical = alerts.where((a) => a.severity == AlertSeverity.critical && !a.isAcknowledged).length;
    
    if (unread == 0) {
      await speak('You have no unread alerts. All systems normal.');
    } else if (critical > 0) {
      await speak('Warning! You have $unread unread alerts, including $critical critical. Please check immediately.');
    } else {
      await speak('You have $unread unread alerts.');
    }
  }

  /// Get spoken version of unit
  String _getUnitSpoken(String unit) {
    switch (unit) {
      case '°C':
        return 'degrees celsius';
      case '°F':
        return 'degrees fahrenheit';
      case '%':
        return 'percent';
      case 'ppm':
        return 'parts per million';
      case 'lux':
        return 'lux';
      case 'pH':
        return '';
      default:
        return unit;
    }
  }

  // ============== SPEECH RECOGNITION ==============

  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        debugPrint('VoiceService: Cannot start listening - not initialized');
        return;
      }
    }

    if (_isListening) return;
    
    // Stop any ongoing speech
    if (_isSpeaking) {
      await stopSpeaking();
    }

    _isListening = true;
    _lastWords = '';
    onListeningChanged?.call(true);

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speech.stop();
    _isListening = false;
    onListeningChanged?.call(false);
  }

  /// Toggle listening state
  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Handle speech recognition result
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords.toLowerCase();
    onWordsRecognized?.call(_lastWords);
    
    debugPrint('VoiceService: Recognized: $_lastWords (final: ${result.finalResult})');
    
    if (result.finalResult && _lastWords.isNotEmpty) {
      final command = _parseCommand(_lastWords);
      debugPrint('VoiceService: Command: $command');
      onCommandRecognized?.call(command, _lastWords);
      _executeCommand(command);
    }
  }

  /// Parse voice command from text
  VoiceCommand _parseCommand(String text) {
    final lower = text.toLowerCase().trim();
    
    // Status commands
    if (lower.contains('status') || lower.contains('how is') || lower.contains('system')) {
      return VoiceCommand.status;
    }
    
    // Sensor commands
    if (lower.contains('temperature') || lower.contains('temp')) {
      return VoiceCommand.temperature;
    }
    if (lower.contains('water level') || lower.contains('water')) {
      return VoiceCommand.waterLevel;
    }
    if (lower.contains('ph') || lower.contains('acidity')) {
      return VoiceCommand.pH;
    }
    if (lower.contains('tds') || lower.contains('nutrient')) {
      return VoiceCommand.tds;
    }
    if (lower.contains('light') || lower.contains('brightness')) {
      return VoiceCommand.light;
    }
    
    // Alert commands
    if (lower.contains('alert') || lower.contains('warning') || lower.contains('notification')) {
      return VoiceCommand.alerts;
    }
    
    // Actuator commands - Pump
    if ((lower.contains('pump') || lower.contains('water')) && 
        (lower.contains('on') || lower.contains('start') || lower.contains('activate'))) {
      return VoiceCommand.pumpOn;
    }
    if ((lower.contains('pump') || lower.contains('water')) && 
        (lower.contains('off') || lower.contains('stop') || lower.contains('deactivate'))) {
      return VoiceCommand.pumpOff;
    }
    
    // Actuator commands - Lights
    if (lower.contains('light') && 
        (lower.contains('on') || lower.contains('start') || lower.contains('activate'))) {
      return VoiceCommand.lightsOn;
    }
    if (lower.contains('light') && 
        (lower.contains('off') || lower.contains('stop') || lower.contains('deactivate'))) {
      return VoiceCommand.lightsOff;
    }
    
    // Actuator commands - Fan
    if (lower.contains('fan') && 
        (lower.contains('on') || lower.contains('start') || lower.contains('activate'))) {
      return VoiceCommand.fanOn;
    }
    if (lower.contains('fan') && 
        (lower.contains('off') || lower.contains('stop') || lower.contains('deactivate'))) {
      return VoiceCommand.fanOff;
    }
    
    return VoiceCommand.unknown;
  }

  /// Execute actuator commands
  void _executeCommand(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.pumpOn:
        onActuatorCommand?.call('pump', true);
        speak('Turning pump on');
        break;
      case VoiceCommand.pumpOff:
        onActuatorCommand?.call('pump', false);
        speak('Turning pump off');
        break;
      case VoiceCommand.lightsOn:
        onActuatorCommand?.call('lights', true);
        speak('Turning lights on');
        break;
      case VoiceCommand.lightsOff:
        onActuatorCommand?.call('lights', false);
        speak('Turning lights off');
        break;
      case VoiceCommand.fanOn:
        onActuatorCommand?.call('fan', true);
        speak('Turning fan on');
        break;
      case VoiceCommand.fanOff:
        onActuatorCommand?.call('fan', false);
        speak('Turning fan off');
        break;
      case VoiceCommand.unknown:
        speak("Sorry, I didn't understand that command");
        break;
      default:
        // Other commands are handled by the UI
        break;
    }
  }

  /// Dispose resources
  void dispose() {
    _tts.stop();
    _speech.stop();
  }
}
