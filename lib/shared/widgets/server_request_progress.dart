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
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE7A0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFB54708),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _waitMessage,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Color(0xFF93370D),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
