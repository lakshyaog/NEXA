import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/validators.dart';
import '../../models/employee.dart';
import '../../state/employee_providers.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.employee});
  final Employee? employee;

  bool get isEdit => employee != null;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.employee?.name);
  late final _mobile = TextEditingController(text: widget.employee?.mobile);
  late final _email = TextEditingController(text: widget.employee?.email);
  late final _designation =
      TextEditingController(text: widget.employee?.designation);

  String? _branchId;
  String? _branchName;
  File? _pickedPhoto;
  String? _existingPhotoUrl;
  double? _uploadProgress;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _branchId = widget.employee?.branchId.isNotEmpty == true
        ? widget.employee!.branchId
        : null;
    _branchName = widget.employee?.branchName;
    _existingPhotoUrl = widget.employee?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _designation.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (xfile != null) setState(() => _pickedPhoto = File(xfile.path));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _uploadProgress = null;
    });

    try {
      String? photoUrl = _existingPhotoUrl;
      if (_pickedPhoto != null) {
        final empId = widget.employee?.id ??
            DateTime.now().microsecondsSinceEpoch.toString();
        photoUrl = await ref.read(fileStorageProvider).upload(
              path: 'employees/$empId/profile.jpg',
              file: _pickedPhoto!,
              onProgress: (p) {
                if (mounted) setState(() => _uploadProgress = p);
              },
            );
      }

      final employee = Employee(
        id: widget.employee?.id ?? '',
        name: _name.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        designation: _designation.text.trim(),
        branchId: _branchId ?? '',
        branchName: _branchName ?? '',
        status: widget.employee?.status ?? EmployeeStatus.active,
        photoUrl: photoUrl,
      );

      final service = ref.read(employeeServiceProvider);
      if (widget.isEdit) {
        await service.update(widget.employee!.id, employee);
      } else {
        await service.create(employee);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleStatus() async {
    final e = widget.employee!;
    final next =
        e.isActive ? EmployeeStatus.inactive : EmployeeStatus.active;
    await ref.read(employeeServiceProvider).setStatus(e.id, e.name, next);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit employee' : 'Add employee'),
        actions: [
          if (widget.isEdit)
            IconButton(
              tooltip: widget.employee!.isActive ? 'Deactivate' : 'Activate',
              icon: Icon(widget.employee!.isActive
                  ? Icons.block
                  : Icons.check_circle_outline),
              onPressed: _toggleStatus,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.lavender,
                        backgroundImage: _pickedPhoto != null
                            ? FileImage(_pickedPhoto!)
                            : (_existingPhotoUrl != null
                                ? NetworkImage(_existingPhotoUrl!)
                                : null) as ImageProvider?,
                        child: _pickedPhoto == null && _existingPhotoUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_uploadProgress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text('Uploading photo... ${(_uploadProgress! * 100).round()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                validator: Validators.mobile,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _designation,
                decoration: const InputDecoration(labelText: 'Designation'),
                validator: (v) => Validators.required(v, 'Designation'),
              ),
              const SizedBox(height: 12),
              branches.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text(
                    'Could not load branches. You can assign one later.'),
                data: (list) {
                  if (list.isEmpty) {
                    return const Text(
                        'No branches yet. You can assign one later once branches are set up.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _branchId,
                    decoration: const InputDecoration(
                        labelText: 'Branch (optional)'),
                    items: [
                      for (final b in list)
                        DropdownMenuItem(value: b.id, child: Text(b.name)),
                    ],
                    onChanged: (id) => setState(() {
                      _branchId = id;
                      _branchName = list.firstWhere((b) => b.id == id).name;
                    }),
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.isEdit ? 'Save changes' : 'Add employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
