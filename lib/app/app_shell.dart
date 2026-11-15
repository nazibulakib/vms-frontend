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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete vehicle?'),
        content: Text('Remove ${vehicle.vehicleNumber} from your fleet?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDE350B),
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
              color: const Color(0x66000000),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.cardShadow,
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 860;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                'Vehicle List',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
              backgroundColor: AppTheme.starkNavy,
              child: SafeArea(
                child: _SidebarContent(
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
              width: 220,
              child: Container(
                color: AppTheme.starkNavy,
                child: SafeArea(
                  child: _SidebarContent(onSignOut: _signOut),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  _TopHeaderBar(onSignOut: _signOut),
                Expanded(child: _vehicleContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeaderBar extends StatelessWidget {
  const _TopHeaderBar({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.mutedInk),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppTheme.mutedInk,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') onSignOut();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppTheme.mutedInk),
                    SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.starkBlueLight,
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: AppTheme.starkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand "V" Logo matching the guideline mockup
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF172F54),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/images/stark_logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'VMS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),

        // Navigation Items matching the guideline mockup:
        // Dashboard, Vehicle (Active), User, Settings
        _SidebarNavItem(
          icon: Icons.home_outlined,
          label: 'Dashboard',
          isSelected: false,
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _SidebarNavItem(
          icon: Icons.directions_car_outlined,
          label: 'Vehicle',
          isSelected: true,
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _SidebarNavItem(
          icon: Icons.person_outline_rounded,
          label: 'User',
          isSelected: false,
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _SidebarNavItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          isSelected: false,
          onTap: () {},
        ),

        const Spacer(),

        // Sign out button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF98A6C0),
              size: 20,
            ),
            title: const Text(
              'Sign out',
              style: TextStyle(
                color: Color(0xFF98A6C0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onTap: onSignOut,
          ),
        ),
      ],
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.starkBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFFB0BDD6),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFB0BDD6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
