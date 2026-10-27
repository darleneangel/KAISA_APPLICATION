import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kaisa_camera_capture.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _muted = Color(0xFF63786B);

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});
  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final db = Supabase.instance.client;
  final extractedName = TextEditingController();
  final extractedAddress = TextEditingController();
  final form = GlobalKey<FormState>();
  String idType = 'Philippine National ID';
  Uint8List? image;
  String mime = 'image/jpeg';
  bool confirmed = false, busy = false, ocrAvailable = true;
  String? status;
  @override
  void initState() {
    super.initState();
    _status();
  }

  @override
  void dispose() {
    extractedName.dispose();
    extractedAddress.dispose();
    super.dispose();
  }

  Future<void> _status() async {
    try {
      final rows = await db
          .from('kaisa_identity_requests')
          .select('status')
          .eq('user_id', db.auth.currentUser!.id)
          .order('submitted_at', ascending: false)
          .limit(1);
      if (mounted)
        setState(
          () => status = rows.isEmpty ? null : rows.first['status'] as String,
        );
    } catch (_) {
      /* Display application without blocking on status error. */
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 88,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      final contentType = f.mimeType ?? 'image/jpeg';
      if (!['image/jpeg', 'image/png', 'image/webp'].contains(contentType))
        throw Exception('Use a JPG, PNG, or WEBP image.');
      if (bytes.lengthInBytes > 5 * 1024 * 1024)
        throw Exception('ID photo must be under 5 MB.');
      if (mounted)
        setState(() {
          image = bytes;
          mime = contentType;
        });
    } catch (e) {
      _notice('$e');
    }
  }

  void _notice(String s) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _camera() async {
    try {
      final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const KaisaCameraCapture()),
      );
      if (bytes == null) return;
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw Exception('Image exceeds 5 MB; use a smaller image.');
      }
      if (mounted)
        setState(() {
          image = bytes;
          mime = 'image/jpeg';
        });
    } catch (e) {
      _notice('$e');
    }
  }

  Future<void> _submit() async {
    if (image == null || !confirmed || busy || !_validate()) {
      _notice(
        'Add a clear ID photo, review its details, and confirm your consent.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      final uid = db.auth.currentUser!.id;
      final ext = mime == 'image/png'
          ? 'png'
          : mime == 'image/webp'
          ? 'webp'
          : 'jpg';
      final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await db.storage
          .from('kaisa-identity')
          .uploadBinary(
            path,
            image!,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
      final result = await db
          .from('kaisa_identity_requests')
          .insert({
            'user_id': uid,
            'id_type': idType,
            'id_path': path,
            'extracted_name': extractedName.text.trim(),
            'extracted_address': extractedAddress.text.trim(),
          })
          .select('id')
          .single();
      // OCR: Edge Function is OPTIONAL until a private server-side Vision secret is configured.
      // Failed OCR must not silently cancel a successfully saved verification request.
      try {
        await db.functions.invoke(
          'kaisa-id-ocr',
          body: {'request_id': result['id']},
        );
      } catch (_) {
        ocrAvailable = false;
      }
      if (!mounted) return;
      _notice('ID submitted. A KAISA Super Admin will review your request.');
      context.go('/resident/verification-status', extra: {'status': 'Pending'});
    } on PostgrestException catch (e) {
      _notice(
        e.code == '23505'
            ? 'You already have a pending verification request.'
            : e.message,
      );
    } catch (e) {
      _notice('Unable to submit verification: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool _validate() => form.currentState?.validate() ?? false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAF8),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text(
        'Identity verification',
        style: TextStyle(color: _forest, fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Become a Tier 2 Resident',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Submit a clear government-issued ID. Only an authorized KAISA Super Admin can approve Tier 2 access.',
                    style: TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: _green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your ID is stored privately. It will never appear in the community feed.',
                            style: TextStyle(color: _forest),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.hourglass_top, color: _green),
                        title: Text('Verification pending'),
                        subtitle: Text(
                          'Your latest request is awaiting Super Admin review.',
                        ),
                      ),
                    ),
                  ],
                  if (status == 'approved') ...[
                    const SizedBox(height: 12),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.verified, color: _green),
                        title: Text('Tier 2 approved'),
                        subtitle: Text(
                          'Your community publishing access is active.',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: idType,
                    decoration: const InputDecoration(
                      labelText: 'Type of valid ID',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'Philippine National ID',
                              'Driver’s License',
                              'Passport',
                              'UMID',
                              'Postal ID',
                              'Voter’s ID',
                              'Other Government-Issued ID',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => idType = v ?? idType),
                  ),
                  const SizedBox(height: 16),
                  if (image == null)
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFD7E9DC),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 46, color: _green),
                          SizedBox(height: 8),
                          Text(
                            'No ID photo selected',
                            style: TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        image!,
                        height: 230,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload ID image'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _camera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Use camera'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Live capture works with phone cameras and permitted webcams on HTTPS or localhost. Upload is the fallback.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: extractedName,
                    decoration: const InputDecoration(
                      labelText: 'Name as shown on ID',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter the ID name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: extractedAddress,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address shown on ID (if available)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review these details carefully. Automatic text extraction is an optional aid, not proof that an ID is valid.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _forest,
                    title: const Text(
                      'I consent to KAISA processing this ID for identity verification and understand it will be reviewed by authorized LGU personnel.',
                    ),
                    value: confirmed,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => confirmed = v ?? false),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        padding: const EdgeInsets.all(17),
                      ),
                      onPressed:
                          busy || status == 'pending' || status == 'approved'
                          ? null
                          : _submit,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(
                        busy
                            ? 'Submitting securely...'
                            : 'Submit for LGU review',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
