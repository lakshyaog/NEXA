import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/status_colors.dart';
import '../../models/customer.dart';
import '../../state/customer_providers.dart';
import '../../state/employee_providers.dart';
import '../../widgets/status_chip.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});
  final Customer customer;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  File? _preview;
  double? _progress;
  bool _uploading = false;
  String? _error;

  Future<void> _pick() async {
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
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _preview = File(file.path);
        _error = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_preview == null || _uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
      _progress = 0;
    });
    try {
      final name = 'id_proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await ref.read(fileStorageProvider).upload(
            path: 'customers/${widget.customer.id}/$name',
            file: _preview!,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      await ref.read(customerServiceProvider).addDocument(
            customerId: widget.customer.id,
            customerName: widget.customer.name,
            type: 'ID Proof',
            fileUrl: url,
            fileName: name,
          );
      if (mounted) {
        setState(() {
          _preview = null;
          _progress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final docs = ref.watch(customerDocumentsProvider(c.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CustomerFormScreen(customer: c),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    StatusChip(
                        label: c.status, color: leadStatusColor(c.status)),
                  ],
                ),
                const SizedBox(height: 12),
                _Row(icon: Icons.phone_outlined, value: c.mobile),
                if (c.email.isNotEmpty)
                  _Row(icon: Icons.email_outlined, value: c.email),
                if (c.address.isNotEmpty)
                  _Row(icon: Icons.location_on_outlined, value: c.address),
                if (c.createdAt != null)
                  _Row(
                    icon: Icons.schedule,
                    value:
                        'Added ${DateFormat('d MMM yyyy').format(c.createdAt!)}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ID Proof',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          if (_preview != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_preview!, height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            if (_progress != null) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text('Uploading... ${((_progress ?? 0) * 100).round()}%',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _uploading ? null : () => setState(() => _preview = null),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _uploading ? null : _upload,
                    child: Text(_uploading
                        ? 'Uploading...'
                        : (_error != null ? 'Retry upload' : 'Upload')),
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select ID proof'),
            ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],

          const SizedBox(height: 16),
          docs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Could not load documents.'),
            data: (list) {
              if (list.isEmpty) {
                return const Text('No documents uploaded yet.',
                    style: TextStyle(color: Colors.black54));
              }
              return Column(
                children: [
                  for (final d in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              d.fileUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : const SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        ),
                            ),
                          ),
                          title: Text(d.type),
                          subtitle: Text(
                            d.uploadedAt == null
                                ? d.fileName
                                : DateFormat('d MMM yyyy, h:mm a')
                                    .format(d.uploadedAt!),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black45),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
}
