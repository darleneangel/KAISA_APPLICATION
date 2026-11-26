part of '../feed_page.dart';

class _CreateStoryDialog extends StatefulWidget {
  const _CreateStoryDialog();
  @override
  State<_CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends State<_CreateStoryDialog> {
  final caption = TextEditingController();
  XFile? photo;
  Uint8List? bytes;
  String visibility = 'public';
  bool saving = false;
  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1400,
      );
      if (file == null) return; // Camera/gallery dismissed.
      final value = await file.readAsBytes();
      if (value.lengthInBytes > 2097152) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story image must be under 2 MB')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          photo = file;
          bytes = value;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open camera or photos: $e')),
        );
      }
    }
  }

  Future<void> _captureCamera() async {
    try {
      final captured = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const _StoryCameraScreen()),
      );
      if (captured == null || !mounted) return;
      if (captured.lengthInBytes > 2097152) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story image must be under 2 MB')),
        );
        return;
      }
      setState(() {
        bytes = captured;
        photo = null; // Camera's takePicture() returns JPEG bytes.
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to capture photo: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (caption.text.trim().isEmpty && bytes == null) return;
    setState(() => saving = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    String? path;
    try {
      if (bytes != null) {
        final mime = (photo?.mimeType?.toLowerCase() == 'image/png')
            ? 'image/png'
            : (photo?.mimeType?.toLowerCase() == 'image/webp')
            ? 'image/webp'
            : 'image/jpeg';
        if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime)) {
          throw Exception('Use JPG, PNG or WEBP');
        }
        final ext = mime == 'image/png'
            ? 'png'
            : mime == 'image/webp'
            ? 'webp'
            : 'jpg';
        path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';
        await db.storage
            .from('kaisa-stories')
            .uploadBinary(
              path,
              bytes!,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
      }
      await db.from('kaisa_stories').insert({
        'author_id': uid,
        'caption': caption.text.trim(),
        'visibility': visibility,
        'image_path': path,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (path != null) {
        try {
          await db.storage.from('kaisa-stories').remove([path]);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish story: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Create a story',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            'Visible for 24 hours',
            style: GoogleFonts.inter(textStyle: TextStyle(color: _muted)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: visibility,
            decoration: const InputDecoration(labelText: 'Audience'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'friends', child: Text('Friends')),
              DropdownMenuItem(value: 'private', child: Text('Only me')),
            ],
            onChanged: saving
                ? null
                : (v) => setState(() => visibility = v ?? 'public'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: caption,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write a story...'),
          ),
          if (bytes != null)
            Image.memory(bytes!, height: 180, fit: BoxFit.contain),
          OutlinedButton.icon(
            onPressed: saving ? null : _captureCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take a photo with camera'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Publishing...' : 'Share story'),
          ),
        ],
      ),
    ),
  );
}

/// Uses the same `camera` plugin as KAISA ID verification, on Android and web.
