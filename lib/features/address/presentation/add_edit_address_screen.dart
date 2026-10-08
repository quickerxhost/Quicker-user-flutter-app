import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/address_controller.dart';
import '../domain/models/address_model.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's "Add New Address" spec: house number,
/// building, area, landmark, city, state, PIN code, address type
/// (Home/Office/Other), GPS location + map preview.
class AddEditAddressScreen extends ConsumerStatefulWidget {
  const AddEditAddressScreen({super.key, this.existing});
  final AddressModel? existing;

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _houseController;
  late final TextEditingController _buildingController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pinController;
  late AddressType _type;
  late bool _isDefault;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _houseController = TextEditingController(text: e?.houseNumber ?? '');
    _buildingController = TextEditingController(text: e?.building ?? '');
    _areaController = TextEditingController(text: e?.area ?? '');
    _landmarkController = TextEditingController(text: e?.landmark ?? '');
    _cityController = TextEditingController(text: e?.city ?? '');
    _stateController = TextEditingController(text: e?.state ?? '');
    _pinController = TextEditingController(text: e?.pinCode ?? '');
    _type = e?.type ?? AddressType.home;
    _isDefault = e?.isDefault ?? false;
    _lat = e?.latitude;
    _lng = e?.longitude;
  }

  @override
  void dispose() {
    for (final c in [_houseController, _buildingController, _areaController, _landmarkController, _cityController, _stateController, _pinController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final address = AddressModel(
      id: widget.existing?.id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
      houseNumber: _houseController.text.trim(),
      building: _buildingController.text.trim(),
      area: _areaController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pinCode: _pinController.text.trim(),
      type: _type,
      latitude: _lat,
      longitude: _lng,
      isDefault: _isDefault,
    );
    await ref.read(addressListControllerProvider.notifier).addOrUpdate(address);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add New Address' : 'Edit Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_lat != null && _lng != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.base),
                  child: SizedBox(
                    height: 160,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(_lat!, _lng!), zoom: 16),
                      markers: {Marker(markerId: const MarkerId('selected'), position: LatLng(_lat!, _lng!))},
                      zoomControlsEnabled: false,
                      liteModeEnabled: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _houseController, hintText: 'House / Flat No.', validator: (v) => Validators.required(v, field: 'House number'))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppTextField(controller: _buildingController, hintText: 'Building', validator: (v) => Validators.required(v, field: 'Building'))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _areaController, hintText: 'Area / Street', validator: (v) => Validators.required(v, field: 'Area')),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _landmarkController, hintText: 'Landmark (optional)'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _cityController, hintText: 'City', validator: (v) => Validators.required(v, field: 'City'))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppTextField(controller: _stateController, hintText: 'State', validator: (v) => Validators.required(v, field: 'State'))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _pinController,
                hintText: 'PIN Code',
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.length != 6) ? 'Enter a valid 6-digit PIN code' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Address Type', style: AppTypography.labelLg()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AddressType.values.map((type) {
                  final label = switch (type) { AddressType.home => 'Home', AddressType.office => 'Office', AddressType.other => 'Other' };
                  return ChoiceChip(label: Text(label), selected: _type == type, onSelected: (_) => setState(() => _type = type));
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeThumbColor: AppColors.primary,
                title: const Text('Set as default address'),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Save Address', trailingIcon: null, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
