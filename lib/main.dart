import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara/ui/chat_screen.dart';
import 'package:sara/ui/theme.dart';
import 'package:sara/services/gemma_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(
    const ProviderScope(
      child: SaraApp(),
    ),
  );
}

class SaraApp extends ConsumerWidget {
  const SaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sara Assistant',
      debugShowCheckedModeBanner: false,
      theme: SaraTheme.darkTheme,
      home: const InitializationWrapper(),
    );
  }
}

class InitializationWrapper extends ConsumerStatefulWidget {
  const InitializationWrapper({super.key});

  @override
  ConsumerState<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends ConsumerState<InitializationWrapper> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initGemma();
  }

  Future<void> _initGemma() async {
    try {
      final gemma = ref.read(gemmaServiceProvider);
      
      // In a real app, we would look for the model in the app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDocDir.path}/gemma-4-e2b.litertlm';
      
      // For this demo, we check if it exists, otherwise we show instructions
      final modelFile = File(modelPath);
      if (await modelFile.exists()) {
        await gemma.initialize(modelPath);
      } else {
        // We'll set a mock flag for the UI demo or just show an error instructions
        // For the sake of this plan, we'll assume the user will place the file later
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing SARA Agent...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                Text('Initialization Error', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _isLoading = true;
                    _error = null;
                    _initGemma();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const ChatScreen();
  }
}
