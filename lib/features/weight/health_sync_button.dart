import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'health_service.dart';
import 'weight_provider.dart';

class HealthSyncButton extends StatefulWidget {
  const HealthSyncButton({super.key});

  @override
  State<HealthSyncButton> createState() => _HealthSyncButtonState();
}

class _HealthSyncButtonState extends State<HealthSyncButton> {
  bool _busy = false;

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<WeightProvider>();
    setState(() => _busy = true);

    void say(String msg) => messenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)));

    try {
      final service = HealthService();
      final ok = await service.authorize();
      if (!ok) {
        say('Autorisation refusée ou Health Connect indisponible.');
        return;
      }
      final entries = await service.importWeights();
      if (entries.isEmpty) {
        say('Aucune pesée trouvée dans Health Connect.');
        return;
      }
      final n = await provider.importEntries(entries);
      say('$n pesée(s) importée(s).');
    } catch (e) {
      say('Échec de la synchronisation : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _busy
        ? const Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2)),
    )
        : IconButton(
      tooltip: 'Importer depuis Health Connect',
      icon: const Icon(Icons.sync),
      onPressed: _sync,
    );
  }
}