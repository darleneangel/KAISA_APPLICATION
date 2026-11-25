part of '../feed_page.dart';

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  String visibility = 'public';
  final text = TextEditingController();
  String category = 'Community';
  final selectedInterests = <String>{};
  final selectedSkills = <String>{};
  final images = <({Uint8List bytes, String name, String mime})>[];
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (images.length >= 2) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose image'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo (supported devices)'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';
      if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime)) {
        throw Exception('Please use JPG, PNG or WEBP.');
      }
      if (bytes.lengthInBytes > 204800) {
        throw Exception('Image is over 200 KB. Reduce its size and retry.');
      }
      if (mounted) {
        setState(
          () => images.add((bytes: bytes, name: picked.name, mime: mime)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _submit() async {
    final body = text.text.trim();
    if (busy || body.isEmpty || body.length > 2000) return;
    if (selectedInterests.isEmpty || selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one interest and one skill.'),
        ),
      );
      return;
    }
    if (visibility != 'public' && images.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos are currently supported on Public posts only.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    String? postId;
    try {
      final p = await db
          .from('kaisa_feed_posts')
          .insert({
            'author_id': uid,
            'body': body,
            'category': category,
            'interest_tags': selectedInterests.toList(),
            'skill_tags': selectedSkills.toList(),
            'visibility': visibility,
          })
          .select('id')
          .single();
      postId = p['id'] as String;
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final ext = image.mime == 'image/png'
            ? 'png'
            : image.mime == 'image/webp'
            ? 'webp'
            : 'jpg';
        final path = '$uid/${postId}_${i + 1}.$ext';
        await db.storage
            .from('kaisa-feed')
            .uploadBinary(
              path,
              image.bytes,
              fileOptions: FileOptions(contentType: image.mime, upsert: false),
            );
        await db.from('kaisa_feed_images').insert({
          'post_id': postId,
          'owner_id': uid,
          'storage_path': path,
          'position': i + 1,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // A partial post is removed on error, but uploaded orphan media may require scheduled cleanup.
      if (postId != null) {
        try {
          await db.from('kaisa_feed_posts').delete().eq('id', postId);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _tagPicker(String title, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            textStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _forest,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${selected.length} selected • Choose at least one',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                selectedColor: _soft,
                checkmarkColor: _forest,
                labelStyle: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: selected.contains(option) ? _forest : _muted,
                  ),
                ),
                onSelected: busy
                    ? null
                    : (value) => setState(() {
                        if (value) {
                          selected.add(option);
                        } else {
                          selected.remove(option);
                        }
                      }),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 24,
                    color: _forest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEW COMMUNITY POST',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            color: _green,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Share an update',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close without posting',
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, color: _ink),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Keep your neighbors informed, connected, and inspired.',
              style: GoogleFonts.inter(
                textStyle: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'CATEGORY',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  color: _forest,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: InputDecoration(
                prefixIcon: Icon(_categoryIcon(category), color: _green),
                labelText: 'Post category',
                filled: true,
                fillColor: _soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
              items:
                  const ['Community', 'Announcement', 'Event', 'Organization']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: busy
                  ? null
                  : (value) => setState(() => category = value ?? category),
            ),
            const SizedBox(height: 15),
            Text(
              'WHO CAN SEE THIS?',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  color: _forest,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: visibility,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  visibility == 'private'
                      ? Icons.lock_outline_rounded
                      : visibility == 'friends'
                      ? Icons.people_outline_rounded
                      : Icons.public_rounded,
                  color: _green,
                ),
                labelText: 'Audience',
                filled: true,
                fillColor: _soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'public',
                  child: Text('Public · Everyone'),
                ),
                DropdownMenuItem(value: 'friends', child: Text('Friends only')),
                DropdownMenuItem(value: 'private', child: Text('Only me')),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() {
                      visibility = value ?? 'public';
                      if (visibility != 'public') images.clear();
                    }),
            ),
            if (visibility != 'public')
              Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  'Photos are currently available for public posts only.',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(fontSize: 12, color: _muted),
                  ),
                ),
              ),
            const SizedBox(height: 17),
            Text(
              'YOUR MESSAGE',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  color: _forest,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: text,
              onChanged: (_) => setState(() {}),
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'What would you like to share with your community?',
                hintStyle: GoogleFonts.inter(
                  textStyle: TextStyle(color: _muted, fontSize: 14),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Help residents discover your post by choosing relevant topics and skills.',
              style: GoogleFonts.inter(
                textStyle: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            _tagPicker('Interests *', _kaisaInterests, selectedInterests),
            const SizedBox(height: 16),
            _tagPicker('Skills *', _kaisaSkills, selectedSkills),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final img in images)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          img.bytes,
                          width: 112,
                          height: 108,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: IconButton.filledTonal(
                          iconSize: 18,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Remove photo',
                          onPressed: busy
                              ? null
                              : () => setState(() => images.remove(img)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy || images.length >= 2 || visibility != 'public'
                  ? null
                  : _add,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Add photo (${images.length}/2 · 200 KB each)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                side: const BorderSide(color: _line),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: _forest,
                      side: const BorderSide(color: _line),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed:
                        busy ||
                            text.text.trim().isEmpty ||
                            selectedInterests.isEmpty ||
                            selectedSkills.isEmpty
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: Icon(
                      busy ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                      size: 18,
                    ),
                    label: Text(busy ? 'Publishing…' : 'Publish post'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
