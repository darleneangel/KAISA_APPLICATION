part of '../feed_page.dart';

class _FeedPreferencesDialog extends StatefulWidget {
  const _FeedPreferencesDialog({required this.interests, required this.skills});
  final List<String> interests;
  final List<String> skills;

  @override
  State<_FeedPreferencesDialog> createState() => _FeedPreferencesDialogState();
}

class _FeedPreferencesDialogState extends State<_FeedPreferencesDialog> {
  late final Set<String> selectedInterests = {...widget.interests};
  late final Set<String> selectedSkills = {...widget.skills};

  Widget _choices(List<String> choices, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final value in choices)
        FilterChip(
          selected: selected.contains(value),
          label: Text(
            value,
            style: GoogleFonts.inter(textStyle: TextStyle(fontSize: 12)),
          ),
          selectedColor: const Color(0xFFDDEFE3),
          checkmarkColor: _forest,
          side: BorderSide(color: selected.contains(value) ? _green : _line),
          onSelected: (checked) => setState(() {
            if (checked) {
              selected.add(value);
            } else {
              selected.remove(value);
            }
          }),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 570),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.interests_rounded, color: _forest),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Personalize your feed',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: _forest,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Choose the same interests and skills used in KAISA Profile Setup. '
              'These help order posts that you already have permission to view.',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMMUNITY INTERESTS',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _green,
                          letterSpacing: 1,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _choices(_kaisaInterests, selectedInterests),
                    const SizedBox(height: 18),
                    Text(
                      'YOUR SKILLS',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _green,
                          letterSpacing: 1,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _choices(_kaisaSkills, selectedSkills),
                  ],
                ),
              ),
            ),
            const Divider(height: 23),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    selectedInterests.clear();
                    selectedSkills.clear();
                  }),
                  child: const Text('Clear all'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _forest),
                  onPressed: () => Navigator.pop(context, (
                    interests: selectedInterests.toList(),
                    skills: selectedSkills.toList(),
                  )),
                  child: const Text('Save preferences'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Facebook-like discovery modal, intentionally limited to posts and authors
/// returned by kaisa_feed_stream. No public user directory is queried.
