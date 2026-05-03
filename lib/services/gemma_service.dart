import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sara/models/tool_definitions.dart';
import 'dart:io';

final gemmaServiceProvider = Provider<GemmaService>((ref) => GemmaService());

final currentActionProvider = StateProvider<String?>((ref) => null);

class GemmaService {
  InferenceChat? _chat;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String modelPath) async {
    final file = File(modelPath);
    if (!await file.exists()) {
      throw Exception('Model file not found at $modelPath');
    }

    await FlutterGemma.initialize();

    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
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
      modelType: ModelType.gemma4,
    );

    _isInitialized = true;
  }

  Future<Directory> getModelsDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final modelsDirectory = Directory('${directory.path}${Platform.pathSeparator}models');
    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(recursive: true);
    }
    return modelsDirectory;
  }

  Future<List<File>> listModelFiles() async {
    final modelsDirectory = await getModelsDirectory();
    final files = <File>[];
    await for (final entity in modelsDirectory.list()) {
      if (entity is File &&
          (entity.path.endsWith('.litertlm') || entity.path.endsWith('.task') || entity.path.endsWith('.bin')) ) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<File> downloadModel(String url, {void Function(double)? onProgress}) async {
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'gemma_model.litertlm';
    final destination = File('${(await getModelsDirectory()).path}${Platform.pathSeparator}$filename');

    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Model download failed with status ${response.statusCode}');
    }

    final contentLength = response.contentLength;
    int downloaded = 0;

    final sink = destination.openWrite();
    await for (final chunk in response) {
      downloaded += chunk.length;
      sink.add(chunk);
      if (onProgress != null && contentLength > 0) {
        onProgress(downloaded / contentLength);
      }
    }
    await sink.close();

    return destination;
  }

  Stream<String> sendMessage(
    String text,
    Future<String> Function(String name, Map<String, dynamic> args) onToolCall, {
    void Function(String?)? onActionChanged,
  }) async* {
    if (_chat == null) {
      throw Exception('Gemma is not initialized');
    }

    onActionChanged?.call('thinking');
    await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        // Filter out raw tool call JSON if it leaks into text responses
        if (response.token.contains('"tool_calls"') || response.token.contains('"role":"assistant"')) {
          continue;
        }
        yield response.token;
      } else if (response is FunctionCallResponse) {
        onActionChanged?.call('calling tool: ${response.name}');
        final toolResult = await onToolCall(response.name, response.args);
        await _chat!.addQuery(Message.toolResponse(
          toolName: response.name,
          response: {'result': toolResult},
        ));
        onActionChanged?.call('thinking');
        yield* _continueChat();
      } else if (response is ParallelFunctionCallResponse) {
        for (final call in response.calls) {
          onActionChanged?.call('calling tool: ${call.name}');
          final toolResult = await onToolCall(call.name, call.args);
          await _chat!.addQuery(Message.toolResponse(
            toolName: call.name,
            response: {'result': toolResult},
          ));
        }
        onActionChanged?.call('thinking');
        yield* _continueChat();
      }
    }
    onActionChanged?.call(null);
  }

  Stream<String> _continueChat() async* {
    if (_chat == null) return;

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        if (response.token.contains('"tool_calls"') || response.token.contains('"role":"assistant"')) {
          continue;
        }
        yield response.token;
      }
    }
  }
}

