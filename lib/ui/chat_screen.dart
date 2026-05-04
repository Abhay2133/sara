import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sara/models/chat_session.dart';
import 'package:sara/models/model_config.dart';
import 'package:sara/services/gemma_service.dart';
import 'package:sara/services/model_config_service.dart';
import 'package:sara/services/session_provider.dart';
import 'package:sara/ui/chat_drawer.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

final isProcessingProvider = StateProvider<bool>((ref) => false);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ModelConfigService _modelConfigService = ModelConfigService();

  ModelConfig? _modelConfig;
  String? _selectedModelId;
  String? _configFolderPath;
  bool _initializing = false;
  bool _downloading = false;
  double? _downloadProgress;
  String? _initializationError;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _loadModelConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _handleToolCall(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'get_battery_level':
        try {
          final battery = Battery();
          final level = await battery.batteryLevel;
          return "$level%";
        } catch (e) {
          return "Failed to get battery level: $e";
        }
      case 'get_current_time':
        return DateTime.now().toString();
      case 'toggle_flashlight':
        try {
          final state = args['state'];
          if (state == 'on') {
            await TorchLight.enableTorch();
            return "Flashlight turned on";
          } else {
            await TorchLight.disableTorch();
            return "Flashlight turned off";
          }
        } catch (e) {
          return "Failed to toggle flashlight: $e";
        }
      default:
        return "Tool not found";
    }
  }

  Future<void> _loadModelConfig() async {
    try {
      final config = await _modelConfigService.loadConfig();
      final configFolder = await _modelConfigService.currentConfigFolder();
      if (!mounted) return;
      setState(() {
        _modelConfig = config;
        _selectedModelId = config.selectedModelId ?? config.models.first.id;
        _configFolderPath = configFolder.path;
      });
    } catch (e) {
      debugPrint('Error loading model config: $e');
    }
  }

  ModelDefinition? get _selectedModelDefinition {
    if (_modelConfig == null || _selectedModelId == null) {
      return null;
    }
    try {
      return _modelConfig!.models.firstWhere((model) => model.id == _selectedModelId);
    } catch (_) {
      return _modelConfig!.models.isNotEmpty ? _modelConfig!.models.first : null;
    }
  }

  Future<void> _saveConfig() async {
    if (_modelConfig == null) return;
    try {
      await _modelConfigService.saveConfig(_modelConfig!);
    } catch (e) {
      debugPrint('Error saving model config: $e');
    }
  }

  Future<void> _downloadSelectedModel() async {
    final selectedModel = _selectedModelDefinition;
    if (selectedModel == null) {
      setState(() {
        _downloadError = 'Select a model first.';
      });
      return;
    }

    setState(() {
      _downloading = true;
      _downloadError = null;
      _downloadProgress = 0;
    });

    try {
      final gemma = ref.read(gemmaServiceProvider);
      final downloaded = await gemma.downloadModel(
        selectedModel.downloadUrl,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
      selectedModel.localPath = downloaded.path;
      await _saveConfig();
    } catch (e) {
      setState(() {
        _downloadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  Future<void> _configureSelectedModelFile() async {
    final selectedModel = _selectedModelDefinition;
    if (selectedModel == null) return;

    final selectedFile = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: 'Model file', extensions: ['litertlm', 'bin', 'task']),
      ],
      confirmButtonText: 'Select model file',
    );

    if (selectedFile == null || selectedFile.path.isEmpty) {
      return;
    }

    selectedModel.localPath = selectedFile.path;
    await _saveConfig();
    if (!mounted) return;
    setState(() {
      _downloadError = null;
    });
  }

  Future<void> _chooseConfigFolder() async {
    final folder = await getDirectoryPath(confirmButtonText: 'Select folder for model_config.json');
    if (folder == null || folder.isEmpty) return;

    _modelConfigService.setConfigFolder(folder);
    await _modelConfigService.saveSettings();
    if (_modelConfig != null) {
      await _modelConfigService.saveConfig(_modelConfig!);
    }

    if (!mounted) return;
    setState(() {
      _configFolderPath = folder;
    });
  }

  Future<void> _resetConfigToDefaults() async {
    final defaults = ModelConfig.defaultConfig();
    await _modelConfigService.saveConfig(defaults);
    final configFolder = await _modelConfigService.currentConfigFolder();
    if (!mounted) return;
    setState(() {
      _modelConfig = defaults;
      _selectedModelId = defaults.selectedModelId;
      _configFolderPath = configFolder.path;
      _initializationError = null;
      _downloadError = null;
    });
  }

  Future<void> _initializeWithSelectedModel() async {
    final selectedModel = _selectedModelDefinition;
    if (selectedModel == null) return;

    final modelPath = selectedModel.localPath ?? '';
    if (modelPath.isEmpty) {
      setState(() {
        _initializationError = 'Please configure a local model file before initializing.';
      });
      return;
    }

    if (!await File(modelPath).exists()) {
      setState(() {
        _initializationError = 'The selected model file was not found at $modelPath';
      });
      return;
    }

    setState(() {
      _initializing = true;
      _initializationError = null;
    });

    try {
      final gemma = ref.read(gemmaServiceProvider);
      await gemma.initialize(modelPath);
      if (!mounted) return;
      setState(() {
        _initializationError = null;
      });
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final gemma = ref.read(gemmaServiceProvider);
    if (!gemma.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initialize Gemma before sending messages.')),
      );
      return;
    }

    // Ensure we have an active session
    ChatSession? activeSession = ref.read(activeSessionProvider);
    ChatSession session;
    if (activeSession == null) {
      session = SessionManager.createNewSession();
      ref.read(gemmaServiceProvider).resetChat();
    } else {
      session = activeSession;
    }
    
    _controller.clear();
    
    // Add user message
    final updatedMessages = [...session.messages, ChatMessage(text: text, isUser: true)];
    
    // Auto-update title if it's the first message
    String newTitle = session.title;
    if (session.messages.isEmpty) {
      newTitle = text.length > 20 ? '${text.substring(0, 20)}...' : text;
    }

    session = session.copyWith(
      messages: updatedMessages,
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    ref.read(activeSessionProvider.notifier).state = session;
    ref.read(historyListProvider.notifier).saveSession(session);

    ref.read(isProcessingProvider.notifier).state = true;
    _scrollToBottom();

    String currentAiResponse = "";
    
    // Add placeholder AI message
    final messagesWithAiPlaceholder = [...session.messages, ChatMessage(text: "", isUser: false)];
    final aiMessageIndex = messagesWithAiPlaceholder.length - 1;
    
    ref.read(activeSessionProvider.notifier).state = session.copyWith(messages: messagesWithAiPlaceholder);

    try {
      final gemma = ref.read(gemmaServiceProvider);
      await for (final chunk in gemma.sendMessage(
        text,
        _handleToolCall,
        onActionChanged: (action) => ref.read(currentActionProvider.notifier).state = action,
      )) {
        currentAiResponse += chunk;

        String displayResponse = currentAiResponse.replaceAll(
          RegExp(r'\{"role":"assistant",\s*"tool_calls":\[\{.*\}\]\}'), 
          ''
        ).trim();

        final currentMessages = [...ref.read(activeSessionProvider)!.messages];
        currentMessages[aiMessageIndex] = ChatMessage(text: displayResponse, isUser: false);
        
        ref.read(activeSessionProvider.notifier).state = ref.read(activeSessionProvider)!.copyWith(messages: currentMessages);
        _scrollToBottom();
      }
      
      // Save final AI response
      final finalSession = ref.read(activeSessionProvider)!;
      ref.read(historyListProvider.notifier).saveSession(finalSession);
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      final errorMessages = [...ref.read(activeSessionProvider)!.messages];
      errorMessages[aiMessageIndex] = ChatMessage(text: 'Error: $e', isUser: false);
      ref.read(activeSessionProvider.notifier).state = ref.read(activeSessionProvider)!.copyWith(messages: errorMessages);
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;
      ref.read(currentActionProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(isProcessingProvider);
    final gemma = ref.read(gemmaServiceProvider);
    final activeSession = ref.watch(activeSessionProvider);
    final messages = activeSession?.messages ?? [];

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          'SARA',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 24,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withAlpha(51)),
          ),
        ),
      ),
      drawer: const ChatDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1A1230),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 4, child: _buildControlPanel(gemma.isInitialized)),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: _buildChatPanel(gemma.isInitialized, messages, isProcessing)),
                        ],
                      )
                    : Column(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.4),
                            child: _buildControlPanel(gemma.isInitialized),
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: _buildChatPanel(gemma.isInitialized, messages, isProcessing)),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel(bool initialized) {
    final selectedModel = _selectedModelDefinition;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Model configuration',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a model and keep its settings in JSON. You can download or configure a local model file.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                _buildModelDropdown(),
                const SizedBox(height: 16),
                if (selectedModel != null) ...[
                  _buildInfoRow('Download URL', selectedModel.downloadUrl),
                  const SizedBox(height: 12),
                  _buildInfoRow('Local model path', selectedModel.localPath ?? 'Not configured'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _downloading || _initializing ? null : _downloadSelectedModel,
                          child: _downloading ? const Text('Downloading...') : const Text('Download model'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _configureSelectedModelFile,
                          child: const Text('Configure file'),
                        ),
                      ),
                    ],
                  ),
                  if (_downloading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        '${((_downloadProgress ?? 0) * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _initializing ? null : _initializeWithSelectedModel,
                    child: _initializing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Initialize selected model'),
                  ),
                ],
                if (_downloadError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _downloadError!,
                    style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                if (_initializationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _initializationError!,
                    style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Config storage',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose the folder where model_config.json will be stored and used.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: _chooseConfigFolder,
                  child: const Text('Choose config folder'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _resetConfigToDefaults,
                  child: const Text('Reset config to defaults'),
                ),
                const SizedBox(height: 12),
                Text(
                  _configFolderPath ?? 'Using app default config location.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(bool initialized, List<ChatMessage> messages, bool isProcessing) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(18),
              itemCount: messages.length,
              itemBuilder: (context, index) => ChatBubble(message: messages[index]),
            ),
          ),
          Consumer(builder: (context, ref, child) {
            final action = ref.watch(currentActionProvider);
            if (action == null && !isProcessing) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (action != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        action == 'thinking' ? 'Sara is thinking...' : 'Sara is $action...',
                        style: GoogleFonts.outfit(
                          color: Colors.cyanAccent.withAlpha(180),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Color(0xFF00E5FF),
                  ),
                ],
              ),
            );
          }),
          _buildInputGroup(initialized),
        ],
      ),
    );
  }

  Widget _buildInputGroup(bool initialized) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Focus(
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                      final bool isControlPressed = HardwareKeyboard.instance.isControlPressed ||
                          HardwareKeyboard.instance.isMetaPressed;
                      if (isControlPressed) {
                        _sendMessage();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    key: const Key('messageInput'),
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: initialized,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: initialized ? 'Talk to Sara... (Ctrl+Enter to send)' : 'Initialize the model first',
                      filled: true,
                      fillColor: Colors.white.withAlpha(13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('sendMessageButton'),
            onPressed: initialized ? _sendMessage : null,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16131F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildModelDropdown() {
    final config = _modelConfig;
    if (config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      key: const Key('selectedModelDropdown'),
      initialValue: _selectedModelId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withAlpha(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      dropdownColor: const Color(0xFF1A1A2C),
      style: GoogleFonts.outfit(color: Colors.white),
      items: config.models.map((model) {
        return DropdownMenuItem(
          value: model.id,
          child: Text(model.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedModelId = value;
          config.selectedModelId = value;
        });
        _saveConfig();
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SelectableText(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(20),
                bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(0),
              ),
              gradient: message.isUser
                  ? const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)])
                  : LinearGradient(colors: [Colors.white.withAlpha(26), Colors.white.withAlpha(13)]),
              border: Border.all(color: Colors.white.withAlpha(26)),
            ),
            child: message.isUser
                ? Text(
                    message.text,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                          code: GoogleFonts.outfit(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                            backgroundColor: Colors.transparent,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (!message.isUser && message.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white54),
                              tooltip: 'Copy to clipboard',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: message.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

