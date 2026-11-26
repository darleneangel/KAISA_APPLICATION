import 'package:flutter/material.dart';

import 'kaisa_events_repository.dart';

const _dark = Color(0xFF00301B);
const _green = Color(0xFF00492C);
const _canvas = Color(0xFFF9F9FF);
const _panel = Color(0xFFF0F3FF);
const _ink = Color(0xFF151C27);
const _gold = Color(0xFFFDBC19);
const _red = Color(0xFFBA1A1A);

class EventDetailsModal extends StatelessWidget {
  const EventDetailsModal({
    super.key,
    required this.title,
    required this.coverAsset,
    required this.event,
    required this.info,
    required this.feedback,
    required this.loading,
    required this.error,
    required this.retry,
    required this.registrationLabel,
    required this.register,
    this.openOrganizer,
  });

  final String title;
  final String? coverAsset;
  final KaisaEvent? event;
  final Map<String, dynamic>? info;
  final List<Map<String, dynamic>>? feedback;
  final bool loading;
  final String? error;
  final VoidCallback retry;
  final String registrationLabel;
  final VoidCallback? register;
  final VoidCallback? openOrganizer;

  @override
  Widget build(BuildContext context) {
    final data = event;
    final strings = MaterialLocalizations.of(context);
    DateTime manila(DateTime timestamp) =>
        timestamp.toUtc().add(const Duration(hours: 8));
    String time(DateTime timestamp) =>
        strings.formatTimeOfDay(TimeOfDay.fromDateTime(manila(timestamp)));
    final briefing = _parseBriefing(info?['instructions'] as String?);
    final contact = [
      info?['contact_name'] as String?,
      info?['contact_email'] as String?,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join('\n');
    return Scaffold(
      backgroundColor: _canvas,
      body: Stack(
        children: [
          ListView(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _dark,
                  image: coverAsset == null
                      ? null
                      : DecorationImage(
                          image: AssetImage(coverAsset!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x5500301B), _dark],
                    ),
                  ),
                  alignment: AlignmentDirectional.bottomStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data != null)
                        Text(
                          data.category,
                          style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.white, fontSize: 25),
                      ),
                    ],
                  ),
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null || data == null)
                ListTile(
                  title: Text(error ?? 'This event is no longer available.'),
                  trailing: TextButton(
                    onPressed: retry,
                    child: const Text('Retry'),
                  ),
                )
              else ...[
                Material(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.groups_outlined, color: _green),
                    title: Text(
                      data.organization,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _green,
                        decoration: openOrganizer == null
                            ? null
                            : TextDecoration.underline,
                      ),
                    ),
                    subtitle: const Text('Organized by'),
                    trailing: openOrganizer == null
                        ? null
                        : const Icon(Icons.chevron_right, color: _green),
                    onTap: openOrganizer,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ModalPanel(
                        title: 'Date, schedule & assembly venue',
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth >= 650
                                  ? (constraints.maxWidth - 24) / 3
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  for (final item in [
                                    (
                                      Icons.calendar_today_outlined,
                                      'Date',
                                      strings.formatFullDate(
                                        manila(data.startsAt),
                                      ),
                                    ),
                                    (
                                      Icons.schedule_outlined,
                                      'Schedule',
                                      '${time(data.startsAt)} – ${time(data.endsAt)} PHT',
                                    ),
                                    (
                                      Icons.place_outlined,
                                      'Assembly venue',
                                      briefing['Assembly venue'] ??
                                          data.location,
                                    ),
                                  ])
                                    SizedBox(
                                      width: width,
                                      child: Material(
                                        color: _panel,
                                        borderRadius: BorderRadius.circular(8),
                                        child: ListTile(
                                          leading: Icon(item.$1, color: _green),
                                          title: Text(item.$2),
                                          subtitle: Text(item.$3),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FeedbackPanel(
                        feedback: feedback,
                        sampleRatings: eventSampleRatings(
                          data,
                          info?['instructions'] as String?,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final briefingPanel = _ModalPanel(
                            title: 'Event description & Bayanihan objectives',
                            children: [
                              Text(
                                data.description.isEmpty
                                    ? 'No description provided.'
                                    : data.description,
                              ),
                              for (final section in [
                                ('Goals', Icons.flag_outlined),
                                ('Intended participants', Icons.people_outline),
                                (
                                  'Required attire or items to bring',
                                  Icons.checkroom_outlined,
                                ),
                                ('Important instructions', Icons.info_outline),
                              ]) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Icon(section.$2, size: 17, color: _green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        section.$1,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  briefing[section.$1] ??
                                      'No information provided.',
                                ),
                              ],
                            ],
                          );
                          final actions = _ModalPanel(
                            title: 'Event participation',
                            children: [
                              for (final section in [
                                (
                                  'Registration requirements',
                                  Icons.how_to_reg_outlined,
                                ),
                                (
                                  'Attendance requirements',
                                  Icons.fact_check_outlined,
                                ),
                              ])
                                if (briefing[section.$1]
                                    case final requirement?)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3D7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            section.$2,
                                            size: 18,
                                            color: const Color(0xFF7B5900),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${section.$1}\n$requirement',
                                              style: const TextStyle(
                                                color: Color(0xFF5D4200),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              Text(
                                '${data.registeredCount} of ${data.capacity} registered',
                              ),
                              LinearProgressIndicator(
                                value: data.capacity > 0
                                    ? (data.registeredCount / data.capacity)
                                          .clamp(0.0, 1.0)
                                    : 0,
                                color: _green,
                                backgroundColor: _panel,
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _dark,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: register,
                                child: Text(registrationLabel),
                              ),
                              if (contact.isNotEmpty) ...[
                                const Divider(),
                                Text(
                                  'Event coordinator',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                SelectableText(contact),
                              ],
                              const Divider(),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.flag_outlined),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _red,
                                ),
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _PrivateReportDialog(
                                    event: data,
                                    available: feedback != null,
                                  ),
                                ),
                                label: const Text('Submit private report'),
                              ),
                            ],
                          );
                          if (constraints.maxWidth < 690) {
                            return Column(
                              children: [
                                briefingPanel,
                                const SizedBox(height: 16),
                                actions,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: briefingPanel),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: actions),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
              ),
              tooltip: 'Close event details',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, String> _parseBriefing(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return {};
  final sections = RegExp(
    r'^(Assembly venue|Goals|Intended participants|Required attire or items to bring|Important instructions|Sample ratings|Registration requirements|Attendance requirements):[ \t]*',
    multiLine: true,
  ).allMatches(text).toList();
  if (sections.isEmpty) return {'Important instructions': text};
  return {
    if (sections.first.start > 0)
      'Important instructions': text.substring(0, sections.first.start).trim(),
    for (var i = 0; i < sections.length; i++)
      sections[i].group(1)!: text
          .substring(
            sections[i].end,
            i + 1 < sections.length ? sections[i + 1].start : text.length,
          )
          .trim(),
  };
}

class _ModalPanel extends StatelessWidget {
  const _ModalPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE2F3)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _ink),
        ),
        ...children,
      ],
    ),
  );
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.feedback, required this.sampleRatings});

  final List<Map<String, dynamic>>? feedback;
  final List<int> sampleRatings;

  @override
  Widget build(BuildContext context) {
    final reviews = feedback ?? const <Map<String, dynamic>>[];
    final scores = reviews.map((review) => review['rating'] as num).toList();
    final useSample = scores.isEmpty && sampleRatings.isNotEmpty;
    if (useSample) scores.addAll(sampleRatings);
    final average = scores.isEmpty
        ? 0.0
        : scores.fold<num>(0, (total, score) => total + score) / scores.length;
    return _ModalPanel(
      title: 'Event ratings & verified participant feedback',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RatingStars(rating: average),
            if (scores.isNotEmpty)
              Text(
                '${average.toStringAsFixed(1)} / 5 · ${scores.length} ${useSample ? 'sample ratings' : 'verified'}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        if (reviews.isEmpty)
          Text(
            feedback == null
                ? 'Verified feedback is currently unavailable.'
                : 'No verified feedback yet.',
          )
        else ...[
          for (final review in reviews) ...[
            const Divider(),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                _RatingStars(rating: (review['rating'] as num).toDouble()),
                const Icon(Icons.verified_outlined, color: _green, size: 15),
                const Text('Verified participant'),
              ],
            ),
            Text(review['feedback'] as String),
          ],
        ],
      ],
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${rating.toStringAsFixed(1)} out of 5 stars',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var position = 1; position <= 5; position++)
            Icon(
              rating >= position
                  ? Icons.star_rounded
                  : rating >= position - .5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              color: const Color(0xFF946900),
              size: 17,
            ),
        ],
      ),
    ),
  );
}

class _PrivateReportDialog extends StatefulWidget {
  const _PrivateReportDialog({required this.event, required this.available});

  final KaisaEvent event;
  final bool available;

  @override
  State<_PrivateReportDialog> createState() => _PrivateReportDialogState();
}

class _PrivateReportDialogState extends State<_PrivateReportDialog> {
  final _description = TextEditingController();
  String? _category;
  String? _error;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _category;
    final explanation = _description.text.trim();
    if (category == null || explanation.length < 10) {
      setState(
        () => _error = 'Choose a category and enter at least 10 characters.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await KaisaEventsRepository.instance.submitPrivateReport(
        widget.event.id,
        category,
        explanation,
      );
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not submit the report. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _canvas,
    icon: const Icon(Icons.flag_outlined, color: _red),
    title: const Text('Submit private report'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(widget.event.title),
            if (_sent)
              const Text('Your report was submitted for private review.')
            else if (!widget.available)
              const Text('Private reporting is currently unavailable.')
            else ...[
              const Text('Your report is sent privately to KAISA Operations.'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Report category'),
                items: [
                  for (final category in const [
                    'Misleading information',
                    'Inappropriate content',
                    'Fraudulent or suspicious activity',
                    'Unauthorized activity',
                    'Harassment or discrimination',
                    'Safety concerns',
                    'Other',
                  ])
                    DropdownMenuItem(
                      value: category,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _category = value),
              ),
              TextField(
                controller: _description,
                enabled: !_busy,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Explanation'),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: _red)),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: Text(_sent || !widget.available ? 'Close' : 'Cancel'),
      ),
      if (widget.available && !_sent)
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Submitting…' : 'File private report'),
        ),
    ],
  );
}
