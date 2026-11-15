import 'package:flutter/material.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({
    super.key,
    required this.vehicles,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<Vehicle> vehicles;
  final VoidCallback onCreate;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;
  final Future<void> Function() onRefresh;

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  VehicleStatus? _statusFilter;
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Vehicle> get _filteredVehicles {
    final query = _query.trim().toLowerCase();
    return widget.vehicles.where((vehicle) {
      final matchesQuery =
          query.isEmpty ||
          [
            vehicle.vehicleNumber,
            vehicle.company,
            vehicle.type,
            vehicle.brand,
            vehicle.model,
          ].any((value) => value.toLowerCase().contains(query));
      return matchesQuery &&
          (_statusFilter == null ||
              vehicle.status.toLowerCase() ==
                  _statusFilter!.apiValue.toLowerCase());
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;
        final padding = width < 600 ? 16.0 : 28.0;

        final filtered = _filteredVehicles;
        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            // Top Row: "Vehicle List" heading + "+ New List" (or "+ New Vehicle") button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Vehicle List',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onCreate,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('New Vehicle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.starkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Main Card matching Stark Guideline
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search and status filters apply as soon as they change.
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Search input
                        SizedBox(
                          width: width < 600 ? width - 64 : 240,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _query = val),
                            decoration: InputDecoration(
                              hintText: 'Search vehicles...',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              suffixIcon: const Icon(
                                Icons.search,
                                size: 18,
                                color: AppTheme.mutedInk,
                              ),
                            ),
                          ),
                        ),

                        // Status Dropdown
                        SizedBox(
                          width: width < 600 ? width - 64 : 160,
                          child: DropdownButtonFormField<VehicleStatus?>(
                            initialValue: _statusFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Filter',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<VehicleStatus?>(
                                value: null,
                                child: Text('All Statuses'),
                              ),
                              ...VehicleStatus.values.map(
                                (s) => DropdownMenuItem<VehicleStatus?>(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _statusFilter = val),
                          ),
                        ),

                        IconButton.outlined(
                          tooltip: 'Refresh vehicles',
                          onPressed: _isRefreshing ? null : _refresh,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                        ),

                        if (_query.isNotEmpty || _statusFilter != null)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _statusFilter = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.border),

                  // Data Content
                  if (widget.vehicles.isEmpty)
                    _EmptyView(onCreate: widget.onCreate)
                  else if (filtered.isEmpty)
                    _NoMatchesView(
                      onReset: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _statusFilter = null;
                        });
                      },
                    )
                  else if (isDesktop)
                    _DesktopTableView(
                      vehicles: filtered,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _MobileCardListView(
                        vehicles: filtered,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      ),
                    ),

                  // Show the number of matches without suggesting pagination.
                  if (filtered.isNotEmpty) ...[
                    const Divider(color: AppTheme.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} ${filtered.length == 1 ? 'vehicle' : 'vehicles'}',
                            style: const TextStyle(
                              color: AppTheme.mutedInk,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopTableView extends StatelessWidget {
  const _DesktopTableView({
    required this.vehicles,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 860),
        child: DataTable(
          horizontalMargin: 16,
          columnSpacing: 24,
          headingRowHeight: 42,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
          headingTextStyle: const TextStyle(
            color: AppTheme.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          columns: [
            const DataColumn(label: Text('Vehicle Number')),
            const DataColumn(label: Text('Brand')),
            const DataColumn(label: Text('Model')),
            const DataColumn(label: Text('Company')),
            const DataColumn(label: Text('Type')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Actions')),
          ],
          rows: vehicles.map((vehicle) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    vehicle.vehicleNumber,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    vehicle.brand,
                    style: const TextStyle(color: AppTheme.ink, fontSize: 13),
                  ),
                ),
                DataCell(
                  Text(
                    vehicle.model,
                    style: const TextStyle(color: AppTheme.ink, fontSize: 13),
                  ),
                ),
                DataCell(
                  Text(
                    vehicle.company,
                    style: const TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    vehicle.type,
                    style: const TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(_StatusBadge(status: vehicle.status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.starkBlue,
                        ),
                        onPressed: () => onEdit(vehicle),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.statusDisconnectedText,
                        ),
                        onPressed: () => onDelete(vehicle),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MobileCardListView extends StatelessWidget {
  const _MobileCardListView({
    required this.vehicles,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final vehicle in vehicles) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.vehicleNumber,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _StatusBadge(status: vehicle.status),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.brand} ${vehicle.model} • ${vehicle.type}',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.company,
                        style: const TextStyle(
                          color: AppTheme.mutedInk,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => onEdit(vehicle),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.starkBlue,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(color: AppTheme.starkBlue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => onDelete(vehicle),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppTheme.statusDisconnectedText,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: AppTheme.statusDisconnectedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final (bg, text) = switch (lower) {
      'active' ||
      'connected' => (AppTheme.statusConnectedBg, AppTheme.statusConnectedText),
      'in maintenance' ||
      'maintenance' => (AppTheme.statusWarningBg, AppTheme.statusWarningText),
      'disconnected' => (
        AppTheme.statusDisconnectedBg,
        AppTheme.statusDisconnectedText,
      ),
      _ => (AppTheme.statusDisabledBg, AppTheme.statusDisabledText),
    };

    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 40,
            color: AppTheme.mutedInk,
          ),
          const SizedBox(height: 12),
          const Text(
            'No vehicles in register',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first vehicle to the list.',
            style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.starkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            label: const Text('New Vehicle'),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesView extends StatelessWidget {
  const _NoMatchesView({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: AppTheme.subtleInk,
          ),
          const SizedBox(height: 12),
          const Text(
            'No vehicles found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or status filter.',
            style: TextStyle(color: AppTheme.mutedInk, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onReset, child: const Text('Reset filter')),
        ],
      ),
    );
  }
}
