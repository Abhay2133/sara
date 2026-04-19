import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara/models/tool_definitions.dart';
import 'dart:io';

final gemmaServiceProvider = Provider<GemmaService>((ref) => GemmaService());

class GemmaService {
  InferenceChat? _chat;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String modelPath) async {
    if (_isInitialized) return;

    final file = File(modelPath);
    if (!await file.exists()) {
      throw Exception('Model file not found at $modelPath');
    }

    await FlutterGemma.initialize();

    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    )
        .fromFile(modelPath)
        .install();

    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);

    final tools = availableTools
        .map((t) => Tool(
              name: t.name,
              description: t.description,
              parameters: t.parameters,
            ))
        .toList();

    _chat = await model.createChat(
      tools: tools,
      supportsFunctionCalls: true,
      toolChoice: ToolChoice.auto,
      modelType: ModelType.gemmaIt,
    );

    _isInitialized = true;
  }

  Stream<String> sendMessage(
    String text,
    Future<String> Function(String name, Map<String, dynamic> args) onToolCall,
  ) async* {
    if (_chat == null) {
      throw Exception('Gemma is not initialized');
    }

    await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      } else if (response is FunctionCallResponse) {
        final toolResult = await onToolCall(response.name, response.args);
        await _chat!.addQuery(Message.toolResponse(
          toolName: response.name,
          response: {'result': toolResult},
        ));
        yield* _continueChat();
      } else if (response is ParallelFunctionCallResponse) {
        for (final call in response.calls) {
          final toolResult = await onToolCall(call.name, call.args);
          await _chat!.addQuery(Message.toolResponse(
            toolName: call.name,
            response: {'result': toolResult},
          ));
        }
        yield* _continueChat();
      }
    }
  }

  Stream<String> _continueChat() async* {
    if (_chat == null) return;

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
  }
}
