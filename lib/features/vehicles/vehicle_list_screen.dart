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
          (_statusFilter == null || vehicle.status == _statusFilter!.apiValue);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final padding = constraints.maxWidth < 600 ? 18.0 : 34.0;
        final activeCount = widget.vehicles
            .where((vehicle) => vehicle.status.toLowerCase() == 'active')
            .length;
        final maintenanceCount = widget.vehicles
            .where(
              (vehicle) => vehicle.status.toLowerCase().contains('maintenance'),
            )
            .length;
        final filtered = _filteredVehicles;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(padding, 28, padding, 36),
                children: [
                  _PageHeading(
                    onCreate: widget.onCreate,
                    onRefresh: widget.onRefresh,
                    compact: constraints.maxWidth < 660,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _SummaryCard(
                        label: 'Total vehicles',
                        value: '${widget.vehicles.length}',
                        icon: Icons.directions_car_outlined,
                        tint: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF4F46E5),
                      ),
                      _SummaryCard(
                        label: 'Active',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline_rounded,
                        tint: const Color(0xFFE9F7F0),
                        iconColor: const Color(0xFF168354),
                      ),
                      _SummaryCard(
                        label: 'In maintenance',
                        value: '$maintenanceCount',
                        icon: Icons.build_outlined,
                        tint: const Color(0xFFFFF4E5),
                        iconColor: const Color(0xFFB54708),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        constraints.maxWidth < 600 ? 16 : 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 14,
                            spacing: 18,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicle register',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${widget.vehicles.length} vehicles in your fleet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: constraints.maxWidth < 600
                                        ? constraints.maxWidth - 76
                                        : 260,
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (value) =>
                                          setState(() => _query = value),
                                      decoration: InputDecoration(
                                        hintText: 'Search vehicles',
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          size: 20,
                                        ),
                                        suffixIcon: _query.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip: 'Clear search',
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() => _query = '');
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                ),
                                              ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: constraints.maxWidth < 600
                                        ? constraints.maxWidth - 76
                                        : 176,
                                    child:
                                        DropdownButtonFormField<VehicleStatus?>(
                                          initialValue: _statusFilter,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            prefixIcon: Icon(
                                              Icons.filter_list_rounded,
                                              size: 19,
                                            ),
                                          ),
                                          items: [
                                            const DropdownMenuItem<
                                              VehicleStatus?
                                            >(
                                              value: null,
                                              child: Text('All statuses'),
                                            ),
                                            ...VehicleStatus.values.map(
                                              (status) =>
                                                  DropdownMenuItem<
                                                    VehicleStatus?
                                                  >(
                                                    value: status,
                                                    child: Text(status.label),
                                                  ),
                                            ),
                                          ],
                                          onChanged: (value) => setState(
                                            () => _statusFilter = value,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          if (widget.vehicles.isEmpty)
                            _EmptyState(onCreate: widget.onCreate)
                          else if (filtered.isEmpty)
                            _NoResults(
                              onClear: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                  _statusFilter = null;
                                });
                              },
                            )
                          else if (isDesktop)
                            _VehicleTable(
                              vehicles: filtered,
                              onEdit: widget.onEdit,
                              onDelete: widget.onDelete,
                            )
                          else
                            _VehicleCards(
                              vehicles: filtered,
                              onEdit: widget.onEdit,
                              onDelete: widget.onDelete,
                            ),
                          if (filtered.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Showing ${filtered.length} of ${widget.vehicles.length}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Vehicle data is synced with the VMS server',
                      style: TextStyle(color: AppTheme.mutedInk, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.onCreate,
    required this.onRefresh,
    required this.compact,
  });

  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actions = Wrap(
      spacing: 8,
      children: [
        IconButton.outlined(
          tooltip: 'Refresh vehicles',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Register vehicle'),
        ),
      ],
    );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicles',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              const Text('Manage the vehicles across your companies.'),
              const SizedBox(height: 16),
              actions,
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicles',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text('Manage the vehicles across your companies.'),
                  ],
                ),
              ),
              actions,
            ],
          );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 620 ? (width - 50) / 2 : 220.0;
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 21),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleTable extends StatelessWidget {
  const _VehicleTable({
    required this.vehicles,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 900),
      child: DataTable(
        horizontalMargin: 12,
        columnSpacing: 24,
        headingRowHeight: 48,
        dataRowMinHeight: 68,
        dataRowMaxHeight: 76,
        headingTextStyle: const TextStyle(
          color: AppTheme.mutedInk,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        columns: const [
          DataColumn(label: Text('VEHICLE NUMBER')),
          DataColumn(label: Text('COMPANY')),
          DataColumn(label: Text('TYPE')),
          DataColumn(label: Text('BRAND / MODEL')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: vehicles
            .map(
              (vehicle) => DataRow(
                cells: [
                  DataCell(_VehicleNumber(vehicle: vehicle)),
                  DataCell(Text(vehicle.company)),
                  DataCell(Text(vehicle.type)),
                  DataCell(Text('${vehicle.brand}  ${vehicle.model}')),
                  DataCell(_StatusPill(status: vehicle.status)),
                  DataCell(
                    _RowActions(
                      vehicle: vehicle,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _VehicleCards extends StatelessWidget {
  const _VehicleCards({
    required this.vehicles,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final vehicle in vehicles) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _VehicleNumber(vehicle: vehicle)),
                  const SizedBox(width: 8),
                  _StatusPill(status: vehicle.status),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 26,
                runSpacing: 12,
                children: [
                  _CardDetail(label: 'Company', value: vehicle.company),
                  _CardDetail(label: 'Type', value: vehicle.type),
                  _CardDetail(
                    label: 'Brand / model',
                    value: '${vehicle.brand} ${vehicle.model}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: _RowActions(
                  vehicle: vehicle,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _VehicleNumber extends StatelessWidget {
  const _VehicleNumber({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) => Text(
    vehicle.vehicleNumber,
    style: const TextStyle(
      color: AppTheme.navy,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final (background, foreground, dot) = switch (normalizedStatus) {
      'active' => (
        const Color(0xFFE9F7F0),
        const Color(0xFF067647),
        const Color(0xFF12B76A),
      ),
      'maintenance' || 'in maintenance' => (
        const Color(0xFFFFF4E5),
        const Color(0xFFB54708),
        const Color(0xFFF79009),
      ),
      'inactive' => (
        const Color(0xFFF2F4F7),
        const Color(0xFF475467),
        const Color(0xFF98A2B3),
      ),
      _ => (
        const Color(0xFFEEF2FF),
        const Color(0xFF344054),
        const Color(0xFF667085),
      ),
    };
    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              status,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextButton.icon(
        onPressed: () => onEdit(vehicle),
        icon: const Icon(Icons.edit_outlined, size: 17),
        label: const Text('Edit'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.teal,
          visualDensity: VisualDensity.compact,
        ),
      ),
      IconButton(
        tooltip: 'Delete ${vehicle.vehicleNumber}',
        onPressed: () => onDelete(vehicle),
        icon: const Icon(Icons.delete_outline_rounded, size: 19),
        color: const Color(0xFFB42318),
        visualDensity: VisualDensity.compact,
      ),
    ],
  );
}

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppTheme.ink, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.directions_car_outlined,
            color: AppTheme.teal,
            size: 30,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'Your fleet starts here',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Register your first vehicle to keep your fleet details in one place.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Register a vehicle'),
        ),
      ],
    ),
  );
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
    child: Column(
      children: [
        const Icon(
          Icons.search_off_rounded,
          color: Color(0xFF98A2B3),
          size: 38,
        ),
        const SizedBox(height: 12),
        Text(
          'No vehicles found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        const Text(
          'Try another search term or clear the selected filters.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onClear,
          child: const Text('Clear search and filters'),
        ),
      ],
    ),
  );
}
