import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/auth/login_screen.dart';
import 'package:vms_frontend/features/auth/data/auth_service.dart';
import 'package:vms_frontend/features/vehicles/data/vehicle_api_client.dart';
import 'package:vms_frontend/features/vehicles/data/vehicle_repository.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';
import 'package:vms_frontend/features/vehicles/vehicle_form_screen.dart';
import 'package:vms_frontend/features/vehicles/vehicle_list_screen.dart';
import 'package:vms_frontend/shared/widgets/error_view.dart';
import 'package:vms_frontend/shared/widgets/loading_indicator.dart';
import 'package:vms_frontend/shared/widgets/server_request_progress.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final VehicleRepository _vehicleRepository;
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  bool _isDeletingVehicle = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _vehicleRepository = VehicleRepository(
      VehicleApiClient(
        accessTokenProvider: () => widget.authService.accessToken,
      ),
    );
    unawaited(_loadVehicles());
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final vehicles = await _vehicleRepository.listVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({Vehicle? vehicle}) async {
    final result = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute<Vehicle>(
        builder: (_) => VehicleFormScreen(
          vehicle: vehicle,
          onSave: (draft) => vehicle == null
              ? _vehicleRepository.createVehicle(draft)
              : _vehicleRepository.updateVehicle(draft),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _vehicles = [..._vehicles.where((item) => item.id != result.id), result]
        ..sort((a, b) => a.vehicleNumber.compareTo(b.vehicleNumber));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vehicle == null
              ? 'Vehicle registered successfully.'
              : 'Vehicle updated successfully.',
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete vehicle?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove ${vehicle.vehicleNumber} from your fleet?',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This vehicle will be permanently removed from your active register. This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.mutedInk,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete vehicle'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    setState(() => _isDeletingVehicle = true);
    try {
      await _vehicleRepository.deleteVehicle(vehicle.id);
      if (!mounted) return;
      setState(() {
        _vehicles = _vehicles.where((item) => item.id != vehicle.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isDeletingVehicle = false);
    }
  }

  Widget _vehicleContent() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Connecting to fleet register…');
    }
    if (_loadError != null) {
      return ErrorView(
        title: 'Could not load vehicles',
        message: _loadError!,
        onRetry: _loadVehicles,
      );
    }
    return Stack(
      children: [
        VehicleListScreen(
          vehicles: List.unmodifiable(_vehicles),
          onCreate: () => _openForm(),
          onEdit: (vehicle) => _openForm(vehicle: vehicle),
          onDelete: _deleteVehicle,
          onRefresh: _loadVehicles,
        ),
        if (_isDeletingVehicle)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x660F172A),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                  child: const ServerRequestProgress(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _signOut() async {
    try {
      await widget.authService.logout();
    } catch (_) {
      widget.authService.clearSession();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const _AppBrandTitle(),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.navy,
              child: SafeArea(
                child: _SidebarContent(
                  vehicleCount: _vehicles.length,
                  onSignOut: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                ),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 256,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.navy,
                  border: Border(
                    right: BorderSide(color: Color(0xFF1E293B)),
                  ),
                ),
                child: SafeArea(
                  child: _SidebarContent(
                    vehicleCount: _vehicles.length,
                    onSignOut: _signOut,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  _TopNavbar(
                    onRefresh: _loadVehicles,
                    onCreate: () => _openForm(),
                  ),
                Expanded(child: _vehicleContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNavbar extends StatelessWidget {
  const _TopNavbar({
    required this.onRefresh,
    required this.onCreate,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          const Icon(
            Icons.grid_view_rounded,
            size: 16,
            color: AppTheme.mutedInk,
          ),
          const SizedBox(width: 8),
          const Text(
            'Operations',
            style: TextStyle(
              color: AppTheme.mutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '/',
            style: TextStyle(color: AppTheme.subtleInk, fontSize: 13),
          ),
          const SizedBox(width: 6),
          const Text(
            'Fleet Vehicles',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),

          // System Health Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 6),
                Text(
                  'Cloud Sync Active',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.vehicleCount,
    required this.onSignOut,
  });

  final int vehicleCount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF088395)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330EA5E9),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STARK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.4,
                    ),
                  ),
                  Text(
                    'FLEET OS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 16),

        // Navigation Group
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'MANAGEMENT',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Active Vehicle Nav Tab
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
            title: const Text(
              'Vehicles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$vehicleCount',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),

        // User Account Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.tealDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'FA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fleet Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Operations',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: onSignOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AppBrandTitle extends StatelessWidget {
  const _AppBrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_shipping_rounded,
          color: AppTheme.teal,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          'Stark Fleet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
