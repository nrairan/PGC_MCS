// lib/backend/chatbot_service.dart
//
// Servicio de comunicación con el endpoint /api/chatbot/ de Django.
// Sigue el mismo patrón de HorarioService para mantener consistencia.
//
// Uso:
//   final service = ChatbotService();
//   final reply = await service.sendMessage("¿Cuáles son los horarios del lunes?");

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Representa un turno de conversación (para historial multi-turno).
class ChatTurn {
  final String role;   // 'user' o 'model'
  final String text;

  const ChatTurn({required this.role, required this.text});

  Map<String, String> toJson() => {'role': role, 'text': text};
}

/// Servicio singleton para el chatbot AsistUC.
/// Mantiene el historial de conversación en memoria.
class ChatbotService {
  // ── Singleton ────────────────────────────────────────────
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // ── Configuración ─────────────────────────────────────────
  // Cambia esta URL por la IP/dominio real de tu servidor Django
  static const String _baseUrl = 'http://127.0.0.1:8000/api/chatbot/';

  // ── Estado interno ─────────────────────────────────────────
  final List<ChatTurn> _history = [];

  List<ChatTurn> get history => List.unmodifiable(_history);

  /// Envía un mensaje al chatbot y devuelve la respuesta.
  /// Lanza [Exception] si hay error de red o del servidor.
  Future<String> sendMessage(String userMessage) async {
    final body = jsonEncode({
      'message': userMessage,
      'history': _history.map((t) => t.toJson()).toList(),
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      developer.log(
        'Chatbot response: ${response.statusCode}',
        name: 'ChatbotService',
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['error'] ?? 'Error desconocido del servidor');
      }

      final reply = data['reply'] as String;

      // Guardar turno en historial (máx. 30 turnos = 60 entradas)
      _history.add(ChatTurn(role: 'user', text: userMessage));
      _history.add(ChatTurn(role: 'model', text: reply));
      if (_history.length > 60) {
        _history.removeRange(0, 2);
      }

      return reply;
    } on Exception {
      rethrow;
    }
  }

  /// Limpia el historial de conversación.
  void clearHistory() => _history.clear();
}
