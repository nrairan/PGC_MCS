// lib/frontend/barraLateral/chat.dart
//
// Pantalla del Chatbot AsistUC — integrada en PGC_MCS.
// Reemplaza el archivo chat.dart vacío que ya existe en el proyecto.
//
// Integración:
//   • Se accede desde MenuLateral con el botón "Asistente IA"
//   • También puede abrirse como FloatingActionButton desde cualquier pantalla

import 'package:flutter/material.dart';
import 'package:mcs/backend/chatbot_service.dart';

// ─────────────────────────────────────────────────────────
// MODELOS DE MENSAJE (UI)
// ─────────────────────────────────────────────────────────

enum MessageRole { user, bot }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Paleta institucional
  static const Color _green700 = Color(0xFF2D6A4F);
  static const Color _green500 = Color(0xFF40916C);
  static const Color _green100 = Color(0xFFD8F3DC);
  static const Color _green50  = Color(0xFFF0FAF2);

  final ChatbotService     _service    = ChatbotService();
  final TextEditingController _ctrl    = TextEditingController();
  final ScrollController   _scroll     = ScrollController();
  final FocusNode          _focus      = FocusNode();

  final List<ChatMessage>  _messages   = [];
  bool                     _loading    = false;

  // Preguntas rápidas contextuales
  static const List<String> _quickQuestions = [
    '¿Qué programas hay?',
    '¿Cómo consulto mi horario?',
    '¿Cuáles son los roles del sistema?',
    '¿Qué es PGC_MCS?',
    '¿Qué salones hay disponibles?',
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      '¡Hola! Soy **AsistUC** 🎓\n\n'
      'Soy el asistente virtual del sistema PGC_MCS de la '
      'Universidad de Cundinamarca — Seccional Ubaté.\n\n'
      '¿En qué te puedo ayudar hoy?',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, role: MessageRole.bot));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, role: MessageRole.user));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Envío de mensaje ───────────────────────────────────

  Future<void> _handleSend([String? overrideText]) async {
    final text = (overrideText ?? _ctrl.text).trim();
    if (text.isEmpty || _loading) return;

    _ctrl.clear();
    _addUserMessage(text);

    setState(() => _loading = true);

    try {
      final reply = await _service.sendMessage(text);
      _addBotMessage(reply);
    } catch (e) {
      _addBotMessage(
        '⚠️ Ocurrió un error al conectar con el asistente.\n'
        'Verifica tu conexión e intenta de nuevo.\n\n'
        '_Detalle: ${e}_',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        // Pequeño delay para que Flutter complete el rebuild antes de pedir foco
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _focus.requestFocus();
        });
      }
    }
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar conversación'),
        content: const Text('¿Deseas iniciar una nueva conversación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green500),
            onPressed: () {
              Navigator.pop(context);
              _service.clearHistory();
              setState(() => _messages.clear());
              _addBotMessage(
                '¡Conversación reiniciada! ¿En qué te puedo ayudar? 😊',
              );
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _green50,
      appBar: AppBar(
        backgroundColor: _green700,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _green500,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('AsistUC',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Asistente PGC_MCS',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Nueva conversación',
            onPressed: _clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de mensajes ──────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                  ),
          ),

          // ── Indicador de carga ─────────────────────────
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _green100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _green500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AsistUC está pensando...',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Preguntas rápidas ──────────────────────────
          if (_messages.length <= 2 && !_loading) _buildQuickQuestions(),

          // ── Input area ─────────────────────────────────
          _buildInputArea(),
        ],
      ),
    );
  }

  // ── Widgets auxiliares ──────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Inicia la conversación',
              style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    final time = '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
        '${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _green700,
              child: const Icon(Icons.smart_toy,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? _green500 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: isUser
                        ? null
                        : Border.all(color: _green100),
                  ),
                  child: _buildMessageText(msg.text, isUser),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 14,
              backgroundColor: _green100,
              child: Icon(Icons.person, size: 14, color: _green700),
            ),
          ],
        ],
      ),
    );
  }

  /// Renderiza texto con soporte básico de Markdown (**negrita**, *itálica*)
  Widget _buildMessageText(String text, bool isUser) {
    // Parseo simple de **negrita** y *itálica*
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|([^*`]+)');
    for (final m in pattern.allMatches(text)) {
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.white : _green700,
          ),
        ));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(
          text: m.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: isUser ? Colors.white70 : Colors.black87,
          ),
        ));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
          text: m.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            backgroundColor: isUser
                ? Colors.white.withOpacity(.15)
                : _green100,
            color: isUser ? Colors.white : _green700,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: m.group(4),
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.5,
          ),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          Text(
            'Preguntas frecuentes:',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600),
          ),
          ..._quickQuestions.map(
            (q) => ActionChip(
              label: Text(q, style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.white,
              side: BorderSide(color: _green500.withOpacity(.5)),
              labelStyle: TextStyle(color: _green700),
              onPressed: () => _handleSend(q),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              readOnly: _loading,   // readOnly evita estado bloqueado vs enabled
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF0FAF2),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      BorderSide(color: _green500, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton.small(
              onPressed: _loading ? null : () => _handleSend(),
              backgroundColor: _loading ? Colors.grey.shade300 : _green700,
              elevation: 1,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}