import 'package:flutter/material.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';

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
    });
    try {
      final saved = await widget.onSave(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final twoColumns = width >= 680;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(_isEditing ? 'Edit vehicle' : 'Register vehicle'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      width < 600 ? 18 : 32,
                      28,
                      width < 600 ? 18 : 32,
                      30,
                    ),
                    children: [
                      Text(
                        _isEditing
                            ? 'Update vehicle details'
                            : 'Add a vehicle to your fleet',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing
                            ? 'Keep your fleet information accurate and up to date.'
                            : 'Enter the key details below. You can change them at any time.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 26),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(width < 600 ? 20 : 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionHeading(
                                icon: Icons.directions_car_outlined,
                                title: 'Vehicle information',
                                subtitle: 'Identity and classification',
                              ),
                              const SizedBox(height: 25),
                              _ResponsiveFields(
                                twoColumns: twoColumns,
                                children: [
                                  _LabeledField(
                                    label: 'Vehicle number',
                                    requiredField: true,
                                    child: TextFormField(
                                      controller: _numberController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. DHAKA-METRO-GA-11-4821',
                                      ),
                                      validator: (value) =>
                                          _required(value, 'vehicle number'),
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Company',
                                    requiredField: true,
                                    child: TextFormField(
                                      controller: _companyController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Stark Logistics',
                                      ),
                                      validator: (value) =>
                                          _required(value, 'company'),
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Vehicle type',
                                    requiredField: true,
                                    child: TextFormField(
                                      controller: _typeController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Truck',
                                      ),
                                      validator: (value) =>
                                          _required(value, 'vehicle type'),
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Brand',
                                    requiredField: true,
                                    child: TextFormField(
                                      controller: _brandController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Toyota',
                                      ),
                                      validator: (value) =>
                                          _required(value, 'brand'),
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Model',
                                    requiredField: true,
                                    child: TextFormField(
                                      controller: _modelController,
                                      textInputAction: TextInputAction.done,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Hiace 2022',
                                      ),
                                      validator: (value) =>
                                          _required(value, 'model'),
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Status',
                                    requiredField: true,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _status,
                                      decoration: const InputDecoration(),
                                      items:
                                          {
                                                ...VehicleStatus.values.map(
                                                  (status) => status.label,
                                                ),
                                                _status,
                                              }
                                              .map(
                                                (status) => DropdownMenuItem(
                                                  value: status,
                                                  child: Text(status),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) => setState(
                                        () => _status = value ?? _status,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (_saveError != null) ...[
                                const SizedBox(height: 16),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _saveError!,
                                    style: const TextStyle(
                                      color: Color(0xFFB42318),
                                    ),
                                  ),
                                ),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: AppTheme.teal,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Changes are saved to the VMS server.',
                                      style: TextStyle(
                                        color: AppTheme.mutedInk,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 600 ? 18 : 32,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.twoColumns, required this.children});

  final bool twoColumns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!twoColumns) {
      return Column(
        children: [
          for (final child in children) ...[child, const SizedBox(height: 20)],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 22,
        runSpacing: 20,
        children: [
          for (final child in children)
            SizedBox(width: (constraints.maxWidth - 22) / 2, child: child),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.requiredField = false,
  });

  final String label;
  final Widget child;
  final bool requiredField;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFB42318),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5F5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppTheme.teal, size: 21),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}
