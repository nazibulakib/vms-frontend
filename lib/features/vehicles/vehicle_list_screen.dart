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
      final matchesQuery = query.isEmpty ||
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

  Future<void> _handleRefresh() async {
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
        final isDesktop = width >= 1000;
        final horizontalPadding = width < 600 ? 16.0 : 32.0;

        final totalCount = widget.vehicles.length;
        final activeCount = widget.vehicles
            .where((v) => v.status.toLowerCase() == 'active')
            .length;
        final maintenanceCount = widget.vehicles
            .where((v) => v.status.toLowerCase().contains('maintenance'))
            .length;
        final inactiveCount = totalCount - activeCount - maintenanceCount;

        final filtered = _filteredVehicles;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            36,
          ),
          children: [
            // Header Bar
            _HeaderSection(
              totalCount: totalCount,
              isRefreshing: _isRefreshing,
              onRefresh: _handleRefresh,
              onCreate: widget.onCreate,
              compact: width < 680,
            ),
            const SizedBox(height: 20),

            // 4 Executive KPI Metric Cards
            _MetricSummaryGrid(
              totalCount: totalCount,
              activeCount: activeCount,
              maintenanceCount: maintenanceCount,
              inactiveCount: inactiveCount,
            ),
            const SizedBox(height: 24),

            // Main Registry Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter & Search Control Toolbar
                  Padding(
                    padding: EdgeInsets.all(width < 600 ? 16 : 20),
                    child: _ControlToolbar(
                      searchController: _searchController,
                      query: _query,
                      onQueryChanged: (val) => setState(() => _query = val),
                      onClearQuery: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      statusFilter: _statusFilter,
                      onStatusFilterChanged: (status) =>
                          setState(() => _statusFilter = status),
                      totalCount: totalCount,
                      activeCount: activeCount,
                      maintenanceCount: maintenanceCount,
                      inactiveCount: inactiveCount,
                      isNarrow: width < 860,
                    ),
                  ),
                  const Divider(color: AppTheme.border),

                  // Data Area (Table on Desktop, Cards on Mobile/Tablet)
                  if (widget.vehicles.isEmpty)
                    _EmptyFleetView(onCreate: widget.onCreate)
                  else if (filtered.isEmpty)
                    _NoSearchResultsView(
                      onClear: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _statusFilter = null;
                        });
                      },
                    )
                  else if (isDesktop)
                    _VehicleTableView(
                      vehicles: filtered,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _VehicleCardListView(
                        vehicles: filtered,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      ),
                    ),

                  // Footer Stats Bar
                  if (filtered.isNotEmpty) ...[
                    const Divider(color: AppTheme.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${filtered.length} of $totalCount units',
                            style: const TextStyle(
                              color: AppTheme.mutedInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Row(
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Synced with server',
                                style: TextStyle(
                                  color: AppTheme.subtleInk,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.totalCount,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onCreate,
    required this.compact,
  });

  final int totalCount;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Refresh vehicles',
          onPressed: isRefreshing ? null : onRefresh,
          icon: isRefreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          style: IconButton.styleFrom(
            side: const BorderSide(color: AppTheme.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Register vehicle'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicles',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              actions,
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Central fleet registry and vehicle operational status.',
            style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicles',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Central fleet registry and vehicle operational status.',
                style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
              ),
            ],
          ),
        ),
        actions,
      ],
    );
  }
}

class _MetricSummaryGrid extends StatelessWidget {
  const _MetricSummaryGrid({
    required this.totalCount,
    required this.activeCount,
    required this.maintenanceCount,
    required this.inactiveCount,
  });

  final int totalCount;
  final int activeCount;
  final int maintenanceCount;
  final int inactiveCount;

  @override
  Widget build(BuildContext context) {
    final activePercent =
        totalCount == 0 ? 0 : ((activeCount / totalCount) * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 640
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              width: cardWidth,
              label: 'Total Fleet',
              value: '$totalCount',
              badgeText: 'All units',
              icon: Icons.directions_car_filled_rounded,
              accentColor: const Color(0xFF0EA5E9),
              bgColor: const Color(0xFFF0F9FF),
            ),
            _MetricCard(
              width: cardWidth,
              label: 'Active',
              value: '$activeCount',
              badgeText: '$activePercent% operational',
              icon: Icons.check_circle_rounded,
              accentColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
            ),
            _MetricCard(
              width: cardWidth,
              label: 'In Maintenance',
              value: '$maintenanceCount',
              badgeText: 'Requires attention',
              icon: Icons.build_circle_rounded,
              accentColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
            ),
            _MetricCard(
              width: cardWidth,
              label: 'Inactive',
              value: '$inactiveCount',
              badgeText: 'Standby / offline',
              icon: Icons.pause_circle_filled_rounded,
              accentColor: const Color(0xFF64748B),
              bgColor: const Color(0xFFF1F5F9),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  final double width;
  final String label;
  final String value;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlToolbar extends StatelessWidget {
  const _ControlToolbar({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.totalCount,
    required this.activeCount,
    required this.maintenanceCount,
    required this.inactiveCount,
    required this.isNarrow,
  });

  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final VehicleStatus? statusFilter;
  final ValueChanged<VehicleStatus?> onStatusFilterChanged;
  final int totalCount;
  final int activeCount;
  final int maintenanceCount;
  final int inactiveCount;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final searchField = SizedBox(
      width: isNarrow ? double.infinity : 280,
      child: TextField(
        controller: searchController,
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search vehicles',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 19,
            color: AppTheme.mutedInk,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClearQuery,
                  icon: const Icon(Icons.close_rounded, size: 17),
                ),
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          DropdownButtonFormField<VehicleStatus?>(
            initialValue: statusFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              prefixIcon: Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: AppTheme.mutedInk,
              ),
            ),
            items: [
              DropdownMenuItem<VehicleStatus?>(
                value: null,
                child: Text('All statuses ($totalCount)'),
              ),
              DropdownMenuItem<VehicleStatus?>(
                value: VehicleStatus.active,
                child: Text('Active ($activeCount)'),
              ),
              DropdownMenuItem<VehicleStatus?>(
                value: VehicleStatus.maintenance,
                child: Text('In maintenance ($maintenanceCount)'),
              ),
              DropdownMenuItem<VehicleStatus?>(
                value: VehicleStatus.inactive,
                child: Text('Inactive ($inactiveCount)'),
              ),
            ],
            onChanged: onStatusFilterChanged,
          ),
        ],
      );
    }

    return Row(
      children: [
        searchField,
        const SizedBox(width: 16),
        // Filter Segment Tabs
        _FilterChip(
          label: 'All',
          count: totalCount,
          isSelected: statusFilter == null,
          onTap: () => onStatusFilterChanged(null),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Active',
          count: activeCount,
          isSelected: statusFilter == VehicleStatus.active,
          onTap: () => onStatusFilterChanged(VehicleStatus.active),
          badgeColor: const Color(0xFF059669),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'In maintenance',
          count: maintenanceCount,
          isSelected: statusFilter == VehicleStatus.maintenance,
          onTap: () => onStatusFilterChanged(VehicleStatus.maintenance),
          badgeColor: const Color(0xFFD97706),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Inactive',
          count: inactiveCount,
          isSelected: statusFilter == VehicleStatus.inactive,
          onTap: () => onStatusFilterChanged(VehicleStatus.inactive),
          badgeColor: const Color(0xFF64748B),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.badgeColor,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.navy : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.ink,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.mutedInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTableView extends StatelessWidget {
  const _VehicleTableView({
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
        constraints: const BoxConstraints(minWidth: 920),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 28,
          headingRowHeight: 44,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(
            color: AppTheme.mutedInk,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
          columns: const [
            DataColumn(label: Text('ASSET / NUMBER')),
            DataColumn(label: Text('COMPANY')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('BRAND & MODEL')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: vehicles.map((vehicle) {
            return DataRow(
              cells: [
                DataCell(_LicensePlateBadge(vehicleNumber: vehicle.vehicleNumber)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.business_rounded,
                        size: 15,
                        color: AppTheme.subtleInk,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        vehicle.company,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  _VehicleTypeBadge(type: vehicle.type),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vehicle.brand,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        vehicle.model,
                        style: const TextStyle(
                          color: AppTheme.mutedInk,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(_StatusBadge(status: vehicle.status)),
                DataCell(
                  _TableActionButtons(
                    vehicle: vehicle,
                    onEdit: onEdit,
                    onDelete: onDelete,
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

class _VehicleCardListView extends StatelessWidget {
  const _VehicleCardListView({
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LicensePlateBadge(vehicleNumber: vehicle.vehicleNumber),
                    _StatusBadge(status: vehicle.status),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  children: [
                    _CardMetaItem(
                      icon: Icons.business_rounded,
                      label: 'Company',
                      value: vehicle.company,
                    ),
                    _CardMetaItem(
                      icon: Icons.directions_car_outlined,
                      label: 'Classification',
                      value: vehicle.type,
                    ),
                    _CardMetaItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Make / Model',
                      value: '${vehicle.brand} ${vehicle.model}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TableActionButtons(
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
}

class _LicensePlateBadge extends StatelessWidget {
  const _LicensePlateBadge({required this.vehicleNumber});

  final String vehicleNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            vehicleNumber,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontFamilyFallback: ['monospace', 'Courier', 'Menlo'],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTypeBadge extends StatelessWidget {
  const _VehicleTypeBadge({required this.type});

  final String type;

  IconData _iconForType(String val) {
    final lower = val.toLowerCase();
    if (lower.contains('truck') || lower.contains('lorry')) {
      return Icons.local_shipping_rounded;
    }
    if (lower.contains('van') || lower.contains('hiace') || lower.contains('micro')) {
      return Icons.airport_shuttle_rounded;
    }
    if (lower.contains('bus')) {
      return Icons.directions_bus_rounded;
    }
    if (lower.contains('bike') || lower.contains('motor')) {
      return Icons.two_wheeler_rounded;
    }
    return Icons.directions_car_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _iconForType(type),
          size: 16,
          color: AppTheme.mutedInk,
        ),
        const SizedBox(width: 7),
        Text(
          type,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
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
    final (bg, border, text, dot) = switch (lower) {
      'active' => (
        const Color(0xFFECFDF5),
        const Color(0xFFA7F3D0),
        const Color(0xFF065F46),
        const Color(0xFF10B981),
      ),
      'in maintenance' || 'maintenance' => (
        const Color(0xFFFFFBEB),
        const Color(0xFFFDE68A),
        const Color(0xFF92400E),
        const Color(0xFFF59E0B),
      ),
      _ => (
        const Color(0xFFF1F5F9),
        const Color(0xFFCBD5E1),
        const Color(0xFF475467),
        const Color(0xFF94A3B8),
      ),
    };

    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableActionButtons extends StatelessWidget {
  const _TableActionButtons({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => onEdit(vehicle),
          icon: const Icon(Icons.edit_outlined, size: 14),
          label: const Text('Edit'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.ink,
            side: const BorderSide(color: AppTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Delete ${vehicle.vehicleNumber}',
          onPressed: () => onDelete(vehicle),
          icon: const Icon(Icons.delete_outline_rounded, size: 17),
          color: const Color(0xFFDC2626),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(7),
            minimumSize: const Size(32, 32),
          ),
        ),
      ],
    );
  }
}

class _CardMetaItem extends StatelessWidget {
  const _CardMetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.subtleInk),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.subtleInk, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyFleetView extends StatelessWidget {
  const _EmptyFleetView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.tealLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppTheme.teal,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No vehicles registered yet',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: const Text(
              'Add your first vehicle to start tracking telemetry, models, and operational status.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Register vehicle'),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResultsView extends StatelessWidget {
  const _NoSearchResultsView({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppTheme.mutedInk,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No matching vehicles found',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check your search query or clear the active status filter.',
            style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onClear,
            child: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }
}
