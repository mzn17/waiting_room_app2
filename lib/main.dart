import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app2/client_repository.dart';
import 'package:waiting_room_app2/queue_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    // ignore: deprecated_member_use
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Optional anonymous auth (must be enabled in the Supabase dashboard)
  final auth = Supabase.instance.client.auth;
  try {
    if (auth.currentSession == null) {
      final res = await auth.signInAnonymously();
      debugPrint('Signed in anonymously: ${res.user?.id}');
    }
  } catch (e) {
    debugPrint('Anonymous sign-in failed (continuing as anon): $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => QueueProvider(
        SupabaseClientRepository(Supabase.instance.client),
      ),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WaitingRoomScreen(),
    );
  }
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  // Local UI state only (the text field); the queue lives in the provider.
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    context.read<QueueProvider>().addClient(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('nextClientButton'),
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next Client',
            onPressed: () => context.read<QueueProvider>().nextClient(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Client Name'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('addButton'),
                  onPressed: _add,
                  child: const Text('Add'),
                ),
              ],
            ),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(provider.error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            Text('Clients in Queue: ${provider.clients.length}'),
            Expanded(
              child: provider.clients.isEmpty
                  ? const Center(child: Text('No one in queue yet...'))
                  : ListView.builder(
                      itemCount: provider.clients.length,
                      itemBuilder: (context, index) {
                        final client = provider.clients[index];
                        return Card(
                          child: ListTile(
                            title: Text(client.name),
                            subtitle: Text(
                              client.createdAt
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => context
                                  .read<QueueProvider>()
                                  .removeClient(client.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}