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
        title: const Text('Delete vehicle?'),
        content: Text('Remove ${vehicle.vehicleNumber} from your fleet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
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
      return const LoadingIndicator(message: 'Loading vehicles…');
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
              color: Color(0x66000000),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: const ServerRequestProgress(),
                  ),
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
    final isWide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Stark Fleet'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    const _SidebarBrand(compact: false),
                    const SizedBox(height: 28),
                    const _SidebarItem(selected: true),
                    const Spacer(),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      onTap: () {
                        Navigator.pop(context);
                        _signOut();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(width: 248, child: _Sidebar(onSignOut: _signOut)),
          Expanded(child: _vehicleContent()),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.navy,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarBrand(compact: true),
          const SizedBox(height: 34),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, 10),
            child: Text(
              'WORKSPACE',
              style: TextStyle(
                color: Color(0xFF91A4B8),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const _SidebarItem(selected: true),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF2D6574),
                  child: Text(
                    'SA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VMS account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Authenticated account',
                        style: TextStyle(
                          color: Color(0xFFB3C6D6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD0DCE6),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, compact ? 22 : 24, 20, 14),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 22,
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
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'FLEET',
              style: TextStyle(
                color: Color(0xFFB3C6D6),
                fontSize: 10,
                letterSpacing: 2.1,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF24445D) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
    ),
    child: ListTile(
      leading: Icon(
        Icons.directions_car_filled_outlined,
        color: selected ? Colors.white : const Color(0xFFB3C6D6),
        size: 20,
      ),
      title: Text(
        'Vehicles',
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFFB3C6D6),
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      dense: true,
    ),
  );
}
