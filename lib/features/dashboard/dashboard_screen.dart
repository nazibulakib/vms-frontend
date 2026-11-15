import 'package:flutter/material.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.vehicles,
    required this.onNavigateToVehicles,
    required this.onCreateVehicle,
    required this.onRefresh,
  });

  final List<Vehicle> vehicles;
  final VoidCallback onNavigateToVehicles;
  final VoidCallback onCreateVehicle;
  final Future<void> Function() onRefresh;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;

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
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 600 ? 16.0 : 28.0;

    final totalCount = widget.vehicles.length;
    final activeCount = widget.vehicles
        .where((v) => v.status.toLowerCase() == 'active')
        .length;
    final maintenanceCount = widget.vehicles
        .where((v) => v.status.toLowerCase().contains('maintenance'))
        .length;
    final inactiveCount = totalCount - activeCount - maintenanceCount;
    final operationalRate =
        totalCount == 0 ? 0.0 : (activeCount / totalCount) * 100;

    // Type distribution
    final typeCounts = <String, int>{};
    for (final v in widget.vehicles) {
      final t = v.type.trim().isEmpty ? 'Unspecified' : v.type.trim();
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Company distribution
    final companyCounts = <String, int>{};
    for (final v in widget.vehicles) {
      final c = v.company.trim().isEmpty ? 'General Fleet' : v.company.trim();
      companyCounts[c] = (companyCounts[c] ?? 0) + 1;
    }
    final sortedCompanies = companyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        // Header Section
        _DashboardHeader(
          onRefresh: _handleRefresh,
          isRefreshing: _isRefreshing,
          onCreateVehicle: widget.onCreateVehicle,
        ),
        const SizedBox(height: 20),

        // Row 1: 4 Key Metric KPI Cards
        _KpiMetricRow(
          totalCount: totalCount,
          activeCount: activeCount,
          maintenanceCount: maintenanceCount,
          inactiveCount: inactiveCount,
          operationalRate: operationalRate,
        ),
        const SizedBox(height: 24),

        // Row 2: Status Donut Chart & Type Classification Breakdown
        if (width >= 960)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _StatusDistributionCard(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  maintenanceCount: maintenanceCount,
                  inactiveCount: inactiveCount,
                  operationalRate: operationalRate,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: _VehicleTypeBreakdownCard(
                  totalCount: totalCount,
                  typeEntries: sortedTypes,
                ),
              ),
            ],
          )
        else ...[
          _StatusDistributionCard(
            totalCount: totalCount,
            activeCount: activeCount,
            maintenanceCount: maintenanceCount,
            inactiveCount: inactiveCount,
            operationalRate: operationalRate,
          ),
          const SizedBox(height: 20),
          _VehicleTypeBreakdownCard(
            totalCount: totalCount,
            typeEntries: sortedTypes,
          ),
        ],
        const SizedBox(height: 24),

        // Row 3: Operating Company Distribution & Quick Telemetry Action Card
        if (width >= 960)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _CompanyAllocationCard(
                  totalCount: totalCount,
                  companies: sortedCompanies,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: _QuickActionCard(
                  totalCount: totalCount,
                  onNavigateToVehicles: widget.onNavigateToVehicles,
                  onCreateVehicle: widget.onCreateVehicle,
                ),
              ),
            ],
          )
        else ...[
          _CompanyAllocationCard(
            totalCount: totalCount,
            companies: sortedCompanies,
          ),
          const SizedBox(height: 20),
          _QuickActionCard(
            totalCount: totalCount,
            onNavigateToVehicles: widget.onNavigateToVehicles,
            onCreateVehicle: widget.onCreateVehicle,
          ),
        ],
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onRefresh,
    required this.isRefreshing,
    required this.onCreateVehicle,
  });

  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final VoidCallback onCreateVehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Real-time overview of fleet operations, status distribution, and metrics.',
                style: TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              tooltip: 'Refresh metrics',
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
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onCreateVehicle,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ New Vehicle'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.starkBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiMetricRow extends StatelessWidget {
  const _KpiMetricRow({
    required this.totalCount,
    required this.activeCount,
    required this.maintenanceCount,
    required this.inactiveCount,
    required this.operationalRate,
  });

  final int totalCount;
  final int activeCount;
  final int maintenanceCount;
  final int inactiveCount;
  final double operationalRate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 640
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiMetricCard(
              width: cardWidth,
              title: 'Active Operations',
              value: '$activeCount',
              subtitle: '${operationalRate.toStringAsFixed(1)}% of fleet',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.statusConnectedText,
              bgColor: AppTheme.statusConnectedBg,
              progress: totalCount == 0 ? 0.0 : activeCount / totalCount,
            ),
            _KpiMetricCard(
              width: cardWidth,
              title: 'In Maintenance',
              value: '$maintenanceCount',
              subtitle: 'Scheduled service',
              icon: Icons.build_circle_outlined,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              progress: totalCount == 0 ? 0.0 : maintenanceCount / totalCount,
            ),
            _KpiMetricCard(
              width: cardWidth,
              title: 'Inactive / Standby',
              value: '$inactiveCount',
              subtitle: 'Available reserve',
              icon: Icons.pause_circle_outline_rounded,
              color: AppTheme.statusDisabledText,
              bgColor: AppTheme.statusDisabledBg,
              progress: totalCount == 0 ? 0.0 : inactiveCount / totalCount,
            ),
            _KpiMetricCard(
              width: cardWidth,
              title: 'Total Fleet',
              value: '$totalCount',
              subtitle: 'Registered units',
              icon: Icons.directions_car_filled_outlined,
              color: AppTheme.starkBlue,
              bgColor: AppTheme.starkBlueLight,
              progress: 1.0,
            ),
          ],
        );
      },
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.progress,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
                title,
                style: const TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDistributionCard extends StatelessWidget {
  const _StatusDistributionCard({
    required this.totalCount,
    required this.activeCount,
    required this.maintenanceCount,
    required this.inactiveCount,
    required this.operationalRate,
  });

  final int totalCount;
  final int activeCount;
  final int maintenanceCount;
  final int inactiveCount;
  final double operationalRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppTheme.starkBlue),
              SizedBox(width: 8),
              Text(
                'Status Distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Vector Donut Chart
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _StatusDonutPainter(
                    total: totalCount,
                    active: activeCount,
                    maintenance: maintenanceCount,
                    inactive: inactiveCount,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${operationalRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const Text(
                          'Ready',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusLegendItem(
                      label: 'Active',
                      count: activeCount,
                      total: totalCount,
                      color: AppTheme.statusConnectedText,
                    ),
                    const SizedBox(height: 10),
                    _StatusLegendItem(
                      label: 'In Maintenance',
                      count: maintenanceCount,
                      total: totalCount,
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(height: 10),
                    _StatusLegendItem(
                      label: 'Inactive',
                      count: inactiveCount,
                      total: totalCount,
                      color: AppTheme.statusDisabledText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  const _StatusLegendItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (count / total) * 100;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
        ),
        Text(
          '$count (${pct.toStringAsFixed(0)}%)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedInk,
          ),
        ),
      ],
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  const _StatusDonutPainter({
    required this.total,
    required this.active,
    required this.maintenance,
    required this.inactive,
  });

  final int total;
  final int active;
  final int maintenance;
  final int inactive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    double startAngle = -1.5707963; // -pi / 2 (top)

    void drawSegment(int count, Color color) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 6.2831853; // 2 * pi
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(active, AppTheme.statusConnectedText);
    drawSegment(maintenance, const Color(0xFFD97706));
    drawSegment(inactive, AppTheme.statusDisabledText);
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter old) =>
      old.total != total ||
      old.active != active ||
      old.maintenance != maintenance ||
      old.inactive != inactive;
}

class _VehicleTypeBreakdownCard extends StatelessWidget {
  const _VehicleTypeBreakdownCard({
    required this.totalCount,
    required this.typeEntries,
  });

  final int totalCount;
  final List<MapEntry<String, int>> typeEntries;

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: AppTheme.starkBlue),
              SizedBox(width: 8),
              Text(
                'Fleet by Vehicle Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (typeEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No vehicle types registered yet.',
                  style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
                ),
              ),
            )
          else
            ...typeEntries.take(5).map((entry) {
              final pct = totalCount == 0 ? 0.0 : entry.value / totalCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconForType(entry.key),
                          size: 16,
                          color: AppTheme.starkBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} unit${entry.value == 1 ? '' : 's'} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.starkBlue,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CompanyAllocationCard extends StatelessWidget {
  const _CompanyAllocationCard({
    required this.totalCount,
    required this.companies,
  });

  final int totalCount;
  final List<MapEntry<String, int>> companies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_rounded, size: 18, color: AppTheme.starkBlue),
              SizedBox(width: 8),
              Text(
                'Operating Companies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (companies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No company data registered.',
                  style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
                ),
              ),
            )
          else
            ...companies.take(4).map((entry) {
              final pct = totalCount == 0 ? 0.0 : entry.value / totalCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.starkBlueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 15,
                          color: AppTheme.starkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          Text(
                            '${entry.value} vehicles allocated',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.totalCount,
    required this.onNavigateToVehicles,
    required this.onCreateVehicle,
  });

  final int totalCount;
  final VoidCallback onNavigateToVehicles;
  final VoidCallback onCreateVehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18, color: AppTheme.starkBlue),
              const SizedBox(width: 8),
              const Text(
                'Fleet Management',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.statusConnectedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 5,
                      color: AppTheme.statusConnectedText,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'SYNC ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusConnectedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Direct access to live vehicle records, asset registration, and fleet telemetry.',
            style: TextStyle(color: AppTheme.mutedInk, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigateToVehicles,
                  icon: const Icon(Icons.directions_car_outlined, size: 16),
                  label: Text('View All ($totalCount)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreateVehicle,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Vehicle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.starkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
