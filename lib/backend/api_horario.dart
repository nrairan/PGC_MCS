import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class HorarioService {
  final String baseUrl;

  // Constructor mejorado con valor por defecto
  HorarioService([this.baseUrl = 'http://127.0.0.1:8000/api/']);

  Future<List<dynamic>> getHorarios() async {
    try {
      final uri = Uri.parse(baseUrl); // Usa la variable baseUrl
      final response = await http.get(uri);

      developer.log(
        'API Response',
        name: 'HorarioService',
        error: 'Status: ${response.statusCode}\nBody: ${response.body}',
      );

      return _parseResponse(response);
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching horarios',
        name: 'HorarioService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<dynamic> _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw _handleError(response.statusCode, response.body);
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (!decoded.containsKey('horarios')) {
        throw FormatException('Campo "horarios" no encontrado');
      }

      final horarios = decoded['horarios'];

      if (horarios is List) return horarios;
      if (horarios is String) {
        try {
          return jsonDecode(horarios) as List;
        } catch (_) {
          return [horarios];
        }
      }
      throw FormatException('Formato inválido para "horarios"');
    } on FormatException catch (e) {
      developer.log('Parse error', name: 'HorarioService', error: e);
      throw FormatException('Error parsing response: ${e.message}');
    }
  }

  Exception _handleError(int statusCode, String body) {
    try {
      final error = jsonDecode(body)?['error'] ?? body;
      return Exception('Error $statusCode: $error');
    } catch (_) {
      return Exception('Error $statusCode: Invalid response format');
    }
  }
}
