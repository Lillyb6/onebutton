import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneButton',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DownloadScreen(),
    );
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key, this.client});

  final http.Client? client;

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  late final http.Client _client = widget.client ?? http.Client();
  List<String> _items = [];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  Future<void> _downloadItems() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client
          .get(Uri.parse('https://api.restful-api.dev/objects'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Request failed: ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('Expected a list of items.');
      }
      final names = decoded.map<String>((item) {
        if (item is! Map<String, dynamic> || item['name'] is! String) {
          throw const FormatException('Expected an item name.');
        }
        return item['name'] as String;
      }).toList();

      if (!mounted || requestId != _requestId) return;
      setState(() => _items = names);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'Could not load items. Please try again.';
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearItems() {
    // Ignore any response still arriving after the user clears the list.
    ++_requestId;
    setState(() {
      _items = [];
      _error = null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('OneButton')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _downloadItems,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_loading ? 'Loading...' : 'Download items'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: _clearItems,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _loading ? 'Fetching items...' : 'No items yet.\nPress Download items to load the list.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              ListTile(title: Text(_items[index])),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
