import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';

/// Gradient header showing the signed-in user, a live clock and the factory
/// name from the business settings.
class WelcomeHeaderWidget extends StatefulWidget {
  const WelcomeHeaderWidget({
    super.key,
    this.factoryName = '',
    this.onRefresh,
  });

  final String factoryName;
  final VoidCallback? onRefresh;

  @override
  State<WelcomeHeaderWidget> createState() => _WelcomeHeaderWidgetState();
}

class _WelcomeHeaderWidgetState extends State<WelcomeHeaderWidget> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF155EEF), Color(0xFF4938C2)],
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final identity = _identity(user);
            final clock = _clock(compact);
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identity, const SizedBox(height: 16), clock],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 12),
                clock,
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh dashboard',
                  icon: const Icon(Icons.refresh),
                  onPressed: widget.onRefresh,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _identity(UserEntity? user) => Row(
    children: [
      _avatar(_initials(user)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.displayLabel ?? 'User'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _roleBadge(user?.role ?? 'viewer'),
                if (widget.factoryName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.factoryName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDDE8FF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _clock(bool compact) => Column(
    crossAxisAlignment: compact
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end,
    children: [
      Text(
        DateFormat('hh:mm:ss a').format(_now),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        DateFormat('EEE, dd MMM yyyy').format(_now),
        style: const TextStyle(fontSize: 12, color: Color(0xFFDDE8FF)),
      ),
    ],
  );

  Widget _avatar(String initials) => Container(
    width: 52,
    height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      shape: BoxShape.circle,
    ),
    child: Text(
      initials,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _roleBadge(String role) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      role.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );

  /// Up to two initials from the display name, falling back to the email.
  static String _initials(UserEntity? user) {
    final source = user?.displayLabel ?? '';
    final parts = source
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
