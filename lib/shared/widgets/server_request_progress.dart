import 'dart:async';

import 'package:flutter/material.dart';

/// Accessible progress state for requests that may be delayed by a cold start.
class ServerRequestProgress extends StatefulWidget {
  const ServerRequestProgress({super.key});

  @override
  State<ServerRequestProgress> createState() => _ServerRequestProgressState();
}

class _ServerRequestProgressState extends State<ServerRequestProgress> {
  static const _waitMessage =
      'The server may be waking from inactivity. Startup can take about a minute. Keep this page open while it responds.';

  Timer? _waitTimer;
  bool _showWaitMessage = false;

  @override
  void initState() {
    super.initState();
    _waitTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showWaitMessage = true);
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _showWaitMessage
          ? 'Request in progress. $_waitMessage'
          : 'Request in progress. Please wait.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            semanticsLabel: 'Request in progress',
          ),
          if (_showWaitMessage) ...[
            const SizedBox(height: 12),
            Text(_waitMessage, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
