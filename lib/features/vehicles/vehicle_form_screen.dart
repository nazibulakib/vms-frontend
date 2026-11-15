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
    final isDesktop = width >= 860;
    final twoColumns = width >= 640;

    final formContent = ListView(
      padding: EdgeInsets.all(width < 600 ? 16 : 28),
      children: [
        // Page Title matching Stark Guideline Right Mockup
        Row(
          children: [
            IconButton(
              tooltip: 'Back to vehicle list',
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            Text(
              _isEditing ? 'Update Vehicle' : 'Register / Update Vehicle',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Main Card
        Container(
          padding: EdgeInsets.all(width < 600 ? 18 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Number
                _FieldLabel(
                  label: 'Vehicle Number',
                  child: TextFormField(
                    controller: _numberController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Enter vehicle number.',
                    ),
                    validator: (val) => _required(val, 'vehicle number'),
                  ),
                ),
                const SizedBox(height: 18),

                // Row with Type and Brand
                if (twoColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _FieldLabel(
                          label: 'Type',
                          child: DropdownButtonFormField<String>(
                            initialValue: _typeController.text.isNotEmpty
                                ? _typeController.text
                                : null,
                            isExpanded: true,
                            hint: const Text('Select type'),
                            items: [
                              'Truck',
                              'Van',
                              'Sedan',
                              'SUV',
                              'Bus',
                              'Motorcycle',
                              'Pickup',
                            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _typeController.text = val);
                              }
                            },
                            validator: (_) => _required(_typeController.text, 'vehicle type'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FieldLabel(
                          label: 'Brand',
                          child: TextFormField(
                            controller: _brandController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Brand 1 / Toyota',
                            ),
                            validator: (val) => _required(val, 'brand'),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _FieldLabel(
                    label: 'Type',
                    child: DropdownButtonFormField<String>(
                      initialValue: _typeController.text.isNotEmpty
                          ? _typeController.text
                          : null,
                      isExpanded: true,
                      hint: const Text('Select type'),
                      items: [
                        'Truck',
                        'Van',
                        'Sedan',
                        'SUV',
                        'Bus',
                        'Motorcycle',
                        'Pickup',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _typeController.text = val);
                        }
                      },
                      validator: (_) => _required(_typeController.text, 'vehicle type'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(
                    label: 'Brand',
                    child: TextFormField(
                      controller: _brandController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Brand 1 / Toyota',
                      ),
                      validator: (val) => _required(val, 'brand'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Row with Model and Assigned To / Company
                if (twoColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _FieldLabel(
                          label: 'Model',
                          child: TextFormField(
                            controller: _modelController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Model X / Hiace',
                            ),
                            validator: (val) => _required(val, 'model'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FieldLabel(
                          label: 'Assigned To / Company',
                          child: TextFormField(
                            controller: _companyController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Stark Logistics Ltd.',
                            ),
                            validator: (val) => _required(val, 'company'),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _FieldLabel(
                    label: 'Model',
                    child: TextFormField(
                      controller: _modelController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Model X / Hiace',
                      ),
                      validator: (val) => _required(val, 'model'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(
                    label: 'Assigned To / Company',
                    child: TextFormField(
                      controller: _companyController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Stark Logistics Ltd.',
                      ),
                      validator: (val) => _required(val, 'company'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Status
                _FieldLabel(
                  label: 'Status',
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    items: {
                      ...VehicleStatus.values.map((s) => s.label),
                      _status,
                    }
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message if failed
                if (_saveError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBE6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFBDAD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _saveError!,
                          style: const TextStyle(
                            color: Color(0xFFBF2600),
                            fontSize: 12,
                          ),
                        ),
                        if (_saveTimedOut) ...[
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _isSaving ? null : _save,
                            child: const Text('Try again'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (_isSaving) ...[
                  const ServerRequestProgress(),
                  const SizedBox(height: 16),
                ],

                // Bottom Full-Width "Save" Button matching the guideline
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.starkBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.canvas,
        appBar: AppBar(
          title: Text(_isEditing ? 'Update Vehicle' : 'Register Vehicle'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: formContent,
      );
    }

    // On Desktop: Render the identical persistent sidebar and top bar matching the guideline right mockup
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 220,
            child: Container(
              color: AppTheme.starkNavy,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    _SidebarStaticItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      isSelected: false,
                    ),
                    const SizedBox(height: 6),
                    _SidebarStaticItem(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicles',
                      isSelected: true,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Main Workspace with Header and Form
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: AppTheme.mutedInk),
                      SizedBox(width: 12),
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: AppTheme.mutedInk,
                      ),
                      SizedBox(width: 16),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.starkBlueLight,
                        child: Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppTheme.starkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: formContent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SidebarStaticItem extends StatelessWidget {
  const _SidebarStaticItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final bool isSelected;

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
      ),
    );
  }
}
