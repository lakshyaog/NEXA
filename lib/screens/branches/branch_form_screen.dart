import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/validators.dart';
import '../../models/branch.dart';
import '../../services/location_service.dart';
import '../../state/attendance_providers.dart';
import '../../state/employee_providers.dart';
import '../../widgets/geofence_map.dart';

class BranchFormScreen extends ConsumerStatefulWidget {
  const BranchFormScreen({super.key, this.branch});
  final Branch? branch;

  bool get isEdit => branch != null;

  @override
  ConsumerState<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends ConsumerState<BranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  late final _name = TextEditingController(text: widget.branch?.name);
  late final _lat = TextEditingController(
      text: widget.branch?.latitude.toStringAsFixed(6) ?? '');
  late final _lng = TextEditingController(
      text: widget.branch?.longitude.toStringAsFixed(6) ?? '');

  late double _radius = widget.branch?.radiusMeters ?? 100;
  bool _saving = false;
  bool _locating = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  LatLng get _center => LatLng(
        double.tryParse(_lat.text) ?? 19.0760,
        double.tryParse(_lng.text) ?? 72.8777,
      );

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (!mounted) return;
      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lng.text = pos.longitude.toStringAsFixed(6);
      });
      _mapController.move(_center, 16);
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final branch = Branch(
        id: widget.branch?.id ?? '',
        name: _name.text.trim(),
        latitude: double.parse(_lat.text),
        longitude: double.parse(_lng.text),
        radiusMeters: _radius,
      );
      final service = ref.read(branchServiceProvider);
      if (widget.isEdit) {
        await service.update(widget.branch!.id, branch);
      } else {
        await service.create(branch);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save branch. $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateCoordinate(String? v, {required double max, required String label}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final parsed = double.tryParse(v.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < -max || parsed > max) return '$label must be between -$max and $max';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit branch' : 'Add branch'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 240,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GeofenceMap(
                    mapController: _mapController,
                    center: _center,
                    radiusMeters: _radius,
                    onTap: (point) => setState(() {
                      _lat.text = point.latitude.toStringAsFixed(6);
                      _lng.text = point.longitude.toStringAsFixed(6);
                    }),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tap the map to move the branch pin, or use your current location.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: const Text('Use my current location'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Branch name'),
                validator: (v) => Validators.required(v, 'Branch name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          _validateCoordinate(v, max: 90, label: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          _validateCoordinate(v, max: 180, label: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Geofence radius',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${_radius.round()} m'),
                ],
              ),
              Slider(
                value: _radius,
                min: 25,
                max: 1000,
                divisions: 39,
                label: '${_radius.round()} m',
                onChanged: (v) => setState(() => _radius = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEdit ? 'Save changes' : 'Add branch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
