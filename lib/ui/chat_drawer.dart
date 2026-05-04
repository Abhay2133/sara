import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sara/services/gemma_service.dart';
import 'package:sara/services/session_provider.dart';
import 'package:intl/intl.dart';

class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyListProvider);
    final activeSession = ref.watch(activeSessionProvider);

    return Drawer(
      backgroundColor: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF673AB7), Color(0xFF1A1230)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Chat History',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: () {
                final newSession = SessionManager.createNewSession();
                ref.read(activeSessionProvider.notifier).state = newSession;
                ref.read(gemmaServiceProvider).resetChat();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final session = history[index];
                final isSelected = activeSession?.id == session.id;

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.white.withAlpha(15),
                  leading: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                  title: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, HH:mm').format(session.updatedAt),
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () {
                    ref.read(activeSessionProvider.notifier).state = session;
                    ref.read(gemmaServiceProvider).resetChat();
                    Navigator.pop(context);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      ref.read(historyListProvider.notifier).deleteSession(session.id);
                      if (isSelected) {
                        ref.read(activeSessionProvider.notifier).state = null;
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
