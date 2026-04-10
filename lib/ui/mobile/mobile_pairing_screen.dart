import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/core/providers.dart';

class MobilePairingScreen extends ConsumerStatefulWidget {
  const MobilePairingScreen({super.key});

  @override
  ConsumerState<MobilePairingScreen> createState() =>
      _MobilePairingScreenState();
}

class _MobilePairingScreenState extends ConsumerState<MobilePairingScreen> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final _codeController = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    final service = ref.read(pairingServiceProvider);
    final success = await service.connectToDesktop(
      address: _addressController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 0,
      code: _codeController.text.trim(),
    );

    if (mounted) {
      setState(() => _connecting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paired with desktop!')),
        );
      } else {
        setState(() => _error = 'Could not connect. Check IP, port, and code.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(pairingServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pair with Desktop')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.isPaired) ...[
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Connected to desktop'),
                  trailing: TextButton(
                    onPressed: () async {
                      await service.unpair();
                      setState(() {});
                    },
                    child: const Text('Unpair'),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Connect to your desktop',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Open Blink on your desktop and go to Settings > Pairing '
                'to find your IP address, port, and pairing code.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Desktop IP Address',
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8080',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Pairing Code',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _connecting ? null : _connect,
                  child: _connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
