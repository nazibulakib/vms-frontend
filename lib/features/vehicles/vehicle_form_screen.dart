import 'package:flutter/material.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';
import 'package:vms_frontend/features/vehicles/data/vehicle_api_exception.dart';
import 'package:vms_frontend/shared/widgets/server_request_progress.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle, required this.onSave});

  final Vehicle? vehicle;
  final Future<Vehicle> Function(Vehicle vehicle) onSave;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _companyController;
  late final TextEditingController _typeController;
  late String _status;
  bool _isSaving = false;
  String? _saveError;
  bool _saveTimedOut = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _numberController = TextEditingController(
      text: vehicle?.vehicleNumber ?? '',
    );
    _companyController = TextEditingController(text: vehicle?.company ?? '');
    _typeController = TextEditingController(text: vehicle?.type ?? '');
    _brandController = TextEditingController(text: vehicle?.brand ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _status = vehicle?.status ?? VehicleStatus.active.label;

    _numberController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _companyController.dispose();
    _typeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter the $label.';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final original = widget.vehicle;
    final draft = Vehicle(
      id: original?.id ?? '',
      vehicleNumber: _numberController.text.trim().toUpperCase(),
      company: _companyController.text.trim(),
      type: _typeController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      status: _status,
    );
    setState(() {
      _isSaving = true;
      _saveError = null;
      _saveTimedOut = false;
    });
    try {
      final saved = await widget.onSave(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = error.toString();
          _saveTimedOut = error is VehicleApiException && error.timedOut;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 768;
    final plateNumber = _numberController.text.trim().toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to vehicles',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Vehicle' : 'Register Vehicle',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    widget.vehicle!.vehicleNumber,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: ['monospace', 'Courier'],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: width < 600 ? 16 : 32,
                      vertical: 24,
                    ),
                    children: [
                      // Header & Live Plate Preview
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.tealLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppTheme.teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing
                                        ? 'Update Asset Record'
                                        : 'New Fleet Vehicle',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.ink,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Asset identifiers, technical specifications, and operating status.',
                                    style: TextStyle(
                                      color: AppTheme.mutedInk,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (plateNumber.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
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
                                    const SizedBox(width: 6),
                                    Text(
                                      plateNumber,
                                      style: const TextStyle(
                                        color: AppTheme.navy,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        fontFamilyFallback: [
                                          'monospace',
                                          'Courier',
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Card 1: Identity & Entity
                      _FormCard(
                        title: 'Identification',
                        icon: Icons.badge_outlined,
                        child: Column(
                          children: [
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _FormFieldContainer(
                                      label: 'Vehicle number',
                                      requiredField: true,
                                      child: TextFormField(
                                        controller: _numberController,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. DHAKA-METRO-GA-11-4821',
                                          prefixIcon: Icon(
                                            Icons.pin_rounded,
                                            size: 18,
                                            color: AppTheme.mutedInk,
                                          ),
                                        ),
                                        validator: (value) =>
                                            _required(value, 'vehicle number'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _FormFieldContainer(
                                      label: 'Company',
                                      requiredField: true,
                                      child: TextFormField(
                                        controller: _companyController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. Stark Logistics Ltd.',
                                          prefixIcon: Icon(
                                            Icons.business_rounded,
                                            size: 18,
                                            color: AppTheme.mutedInk,
                                          ),
                                        ),
                                        validator: (value) =>
                                            _required(value, 'company'),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _FormFieldContainer(
                                label: 'Vehicle number',
                                requiredField: true,
                                child: TextFormField(
                                  controller: _numberController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. DHAKA-METRO-GA-11-4821',
                                    prefixIcon: Icon(
                                      Icons.pin_rounded,
                                      size: 18,
                                      color: AppTheme.mutedInk,
                                    ),
                                  ),
                                  validator: (value) =>
                                      _required(value, 'vehicle number'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FormFieldContainer(
                                label: 'Company',
                                requiredField: true,
                                child: TextFormField(
                                  controller: _companyController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Stark Logistics Ltd.',
                                    prefixIcon: Icon(
                                      Icons.business_rounded,
                                      size: 18,
                                      color: AppTheme.mutedInk,
                                    ),
                                  ),
                                  validator: (value) =>
                                      _required(value, 'company'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Card 2: Vehicle Specs
                      _FormCard(
                        title: 'Specifications',
                        icon: Icons.tune_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormFieldContainer(
                              label: 'Vehicle type',
                              requiredField: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _typeController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Truck, Van, Sedan, Bus',
                                      prefixIcon: Icon(
                                        Icons.local_shipping_outlined,
                                        size: 18,
                                        color: AppTheme.mutedInk,
                                      ),
                                    ),
                                    validator: (value) =>
                                        _required(value, 'vehicle type'),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      'Truck',
                                      'Van',
                                      'Sedan',
                                      'SUV',
                                      'Bus',
                                      'Motorcycle',
                                    ].map((preset) {
                                      return InkWell(
                                        onTap: () {
                                          _typeController.text = preset;
                                          setState(() {});
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceAlt,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppTheme.border,
                                            ),
                                          ),
                                          child: Text(
                                            preset,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.mutedInk,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _FormFieldContainer(
                                      label: 'Brand',
                                      requiredField: true,
                                      child: TextFormField(
                                        controller: _brandController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. Toyota, Volvo, Ford',
                                          prefixIcon: Icon(
                                            Icons.branding_watermark_outlined,
                                            size: 18,
                                            color: AppTheme.mutedInk,
                                          ),
                                        ),
                                        validator: (value) =>
                                            _required(value, 'brand'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _FormFieldContainer(
                                      label: 'Model',
                                      requiredField: true,
                                      child: TextFormField(
                                        controller: _modelController,
                                        textInputAction: TextInputAction.done,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. Hiace 2024, FH16',
                                          prefixIcon: Icon(
                                            Icons.directions_car_outlined,
                                            size: 18,
                                            color: AppTheme.mutedInk,
                                          ),
                                        ),
                                        validator: (value) =>
                                            _required(value, 'model'),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _FormFieldContainer(
                                label: 'Brand',
                                requiredField: true,
                                child: TextFormField(
                                  controller: _brandController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Toyota, Volvo, Ford',
                                    prefixIcon: Icon(
                                      Icons.branding_watermark_outlined,
                                      size: 18,
                                      color: AppTheme.mutedInk,
                                    ),
                                  ),
                                  validator: (value) =>
                                      _required(value, 'brand'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FormFieldContainer(
                                label: 'Model',
                                requiredField: true,
                                child: TextFormField(
                                  controller: _modelController,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Hiace 2024, FH16',
                                    prefixIcon: Icon(
                                      Icons.directions_car_outlined,
                                      size: 18,
                                      color: AppTheme.mutedInk,
                                    ),
                                  ),
                                  validator: (value) =>
                                      _required(value, 'model'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Card 3: Operational Status
                      _FormCard(
                        title: 'Operational Status',
                        icon: Icons.traffic_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set the current deployment and operational readiness of this asset.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWideCards = constraints.maxWidth >= 600;
                                final cardWidth = isWideCards
                                    ? (constraints.maxWidth - 20) / 3
                                    : double.infinity;

                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _StatusChoiceCard(
                                      width: cardWidth,
                                      title: 'Active',
                                      subtitle: 'Available for dispatch',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF059669),
                                      bgColor: const Color(0xFFECFDF5),
                                      borderColor: const Color(0xFFA7F3D0),
                                      isSelected: _status.toLowerCase() == 'active',
                                      onTap: () => setState(
                                        () => _status = VehicleStatus.active.label,
                                      ),
                                    ),
                                    _StatusChoiceCard(
                                      width: cardWidth,
                                      title: 'In maintenance',
                                      subtitle: 'Service / repairs',
                                      icon: Icons.build_circle_rounded,
                                      color: const Color(0xFFD97706),
                                      bgColor: const Color(0xFFFFFBEB),
                                      borderColor: const Color(0xFFFDE68A),
                                      isSelected: _status.toLowerCase().contains('maintenance'),
                                      onTap: () => setState(
                                        () => _status = VehicleStatus.maintenance.label,
                                      ),
                                    ),
                                    _StatusChoiceCard(
                                      width: cardWidth,
                                      title: 'Inactive',
                                      subtitle: 'Standby / decommissioned',
                                      icon: Icons.pause_circle_filled_rounded,
                                      color: const Color(0xFF64748B),
                                      bgColor: const Color(0xFFF1F5F9),
                                      borderColor: const Color(0xFFCBD5E1),
                                      isSelected: _status.toLowerCase() == 'inactive',
                                      onTap: () => setState(
                                        () => _status = VehicleStatus.inactive.label,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Error message if save failed
                      if (_saveError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _saveError!,
                                      style: const TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_saveTimedOut) ...[
                                      const SizedBox(height: 6),
                                      TextButton.icon(
                                        onPressed: _isSaving ? null : _save,
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Try save again'),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),

                // Sticky Command Bottom Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 600 ? 16 : 32,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSaving) ...[
                        const ServerRequestProgress(),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              _isSaving
                                  ? 'Saving…'
                                  : _isEditing
                                  ? 'Save changes'
                                  : 'Register vehicle',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FormFieldContainer extends StatelessWidget {
  const _FormFieldContainer({
    required this.label,
    required this.child,
    this.requiredField = false,
  });

  final String label;
  final Widget child;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (requiredField) ...[
                const SizedBox(width: 3),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        Semantics(
          container: true,
          label: requiredField ? '$label, required' : label,
          child: child,
        ),
      ],
    );
  }
}

class _StatusChoiceCard extends StatelessWidget {
  const _StatusChoiceCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.isSelected,
    required this.onTap,
  });

  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? borderColor : AppTheme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : AppTheme.mutedInk,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : AppTheme.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
