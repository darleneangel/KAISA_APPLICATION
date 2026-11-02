import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Organization-scoped E-Certificate Studio backed by verified KAISA attendance.
class ECertificateStudioPage extends StatefulWidget {
  const ECertificateStudioPage({super.key, this.organizationId});

  /// Optional organization ID from account switcher; authorization is checked by SQL RPC.
  final String? organizationId;

  @override
  State<ECertificateStudioPage> createState() => _CertificateStudioPageState();
}

class _TextLayer {
  _TextLayer(
    this.id,
    this.label,
    this.text, {
    required this.x,
    required this.y,
    required this.size,
    this.font = 'Sans',
    this.color = const Color(0xFF173F2E),
    this.bold = false,
    this.align = TextAlign.center,
  });

  final String id;
  String label;
  final TextEditingController text;
  double x; // 0..1 center point of the text area
  double y; // 0..1 top point of the text area
  double size; // PDF points at full A4 landscape size
  String font;
  Color color;
  bool bold;
  bool visible = true;
  TextAlign align;
}

class _LogoLayer {
  _LogoLayer({
    required this.id,
    required this.name,
    required this.bytes,
    this.x = .13,
    this.y = .12,
    this.width = .14,
  });
  final String id;
  String name;
  final Uint8List bytes;
  bool visible = true;
  double x;
  double y;
  double width; // fraction of page width
}

class _CertificateStudioPageState extends State<ECertificateStudioPage> {
  static const _forest = Color(0xFF176B43);
  static const _gold = Color(0xFFE4B746);
  static const _maxImage = 5 * 1024 * 1024;
  static const _maxFont = 3 * 1024 * 1024;
  // All layers are placed relative to the A4 landscape page.
  static const _pageWidth = 841.89;
  static const _pageHeight = 595.28;
  static const _layerWidthFraction = .78;

  late final List<_TextLayer> _layers = [
    _TextLayer(
      'org',
      'Organization',
      TextEditingController(text: 'KAISA Community Organization'),
      x: .5,
      y: .14,
      size: 20,
      bold: true,
    ),
    _TextLayer(
      'title',
      'Title',
      TextEditingController(text: 'CERTIFICATE OF PARTICIPATION'),
      x: .5,
      y: .27,
      size: 32,
      bold: true,
    ),
    _TextLayer(
      'intro',
      'Presented to',
      TextEditingController(text: 'This certificate is presented to'),
      x: .5,
      y: .39,
      size: 15,
      color: const Color(0xFF34473D),
    ),
    _TextLayer(
      'recipient',
      'Recipient name',
      TextEditingController(text: '{recipient}'),
      x: .5,
      y: .47,
      size: 37,
      bold: true,
    ),
    _TextLayer(
      'description',
      'Description',
      TextEditingController(
        text: 'For actively participating in the community activity',
      ),
      x: .5,
      y: .60,
      size: 16,
      color: const Color(0xFF34473D),
    ),
    _TextLayer(
      'event',
      'Event',
      TextEditingController(text: 'Community Volunteer Program'),
      x: .5,
      y: .68,
      size: 20,
      bold: true,
    ),
    _TextLayer(
      'date',
      'Date',
      TextEditingController(text: 'October 29, 2026'),
      x: .5,
      y: .76,
      size: 14,
    ),
    _TextLayer(
      'signer',
      'Signatory',
      TextEditingController(text: 'Organization Representative'),
      x: .5,
      y: .87,
      size: 15,
    ),
  ];

  final List<_LogoLayer> _logos = [];
  int _nextLayerId = 1;
  int _nextLogoId = 1;
  int _design = 0; // Simple, Classic, Modern

  final _names = TextEditingController();

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _organizations = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _attendees = [];
  final Set<String> _selectedUsers = {};
  String? _organizationId;
  String? _eventId;
  bool _loadingOrganizations = true;
  bool _loadingEvents = false;
  bool _loadingAttendees = false;
  String? _dataError;
  bool _hasLoadedAttendees = false;

  Uint8List? _background;
  String? _backgroundName;
  Uint8List? _customFontBytes;
  String? _customFontName;
  String? _customFontFamily;
  // Font files are loaded only in memory, never uploaded to Supabase.
  final Map<String, Uint8List> _namedFontBytes = {};
  final Map<String, String> _namedFontFamilies = {};
  String _selectedId = 'recipient';
  int _recipientIndex = 0;
  bool _exporting = false;
  String? _message;

  _TextLayer get _selected => _layers.firstWhere((e) => e.id == _selectedId);

  List<String> get _recipients {
    final seen = <String>{};
    for (final line in _names.text.split(RegExp(r'\r?\n'))) {
      if (line.trim().isNotEmpty) seen.add(line.trim());
    }
    return seen.toList();
  }

  String get _sampleName {
    final recipients = _recipients;
    return recipients.isEmpty
        ? 'Recipient Name'
        : recipients[_recipientIndex.clamp(0, recipients.length - 1)];
  }

  String _displayText(_TextLayer e, String recipient) =>
      e.text.text.replaceAll('{recipient}', recipient);

  @override
  void initState() {
    super.initState();
    for (final layer in _layers) {
      layer.text.addListener(_refresh);
    }
    _names.addListener(_onNamesChange);
    _loadOrganizations();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onNamesChange() {
    if (mounted) setState(() => _recipientIndex = 0);
  }

  List<Map<String, dynamic>> _asMaps(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> _loadOrganizations() async {
    try {
      final raw = await _supabase.rpc('kaisa_admin_my_organizations');
      if (!mounted) return;
      final orgs = _asMaps(raw);
      final requested = widget.organizationId;
      final selected = orgs.any((o) => o['id'].toString() == requested)
          ? requested
          : (requested == null && orgs.isNotEmpty
                ? orgs.first['id'].toString()
                : null);
      setState(() {
        _organizations = orgs;
        _organizationId = selected;
        _loadingOrganizations = false;
        _dataError = selected == null
            ? 'No authorized Organization Admin membership for the selected organization.'
            : null;
      });
      if (selected != null) await _loadEvents();
    } catch (error) {
      if (mounted)
        setState(() {
          _loadingOrganizations = false;
          _dataError = 'Unable to load managed organizations: $error';
        });
    }
  }

  Future<void> _changeOrganization(String? id) async {
    if (id == null) return;
    setState(() {
      _organizationId = id;
      _eventId = null;
      _events = [];
      _attendees = [];
      _selectedUsers.clear();
      _hasLoadedAttendees = false;
      _names.clear();
      _dataError = null;
    });
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    final orgId = _organizationId;
    if (orgId == null) return;
    setState(() {
      _loadingEvents = true;
      _dataError = null;
    });
    try {
      final raw = await _supabase.rpc(
        'kaisa_certificate_events',
        params: {'p_organization_id': orgId},
      );
      if (!mounted || _organizationId != orgId) return;
      setState(() {
        _events = _asMaps(raw);
        _loadingEvents = false;
      });
    } catch (error) {
      if (mounted && _organizationId == orgId)
        setState(() {
          _loadingEvents = false;
          _dataError = 'Unable to load organization events: $error';
        });
    }
  }

  Future<void> _loadAttendees(String? eventId) async {
    final orgId = _organizationId;
    if (orgId == null || eventId == null) return;
    setState(() {
      _eventId = eventId;
      _loadingAttendees = true;
      _attendees = [];
      _selectedUsers.clear();
      _names.clear();
      _hasLoadedAttendees = false;
      _dataError = null;
    });
    try {
      final raw = await _supabase.rpc(
        'kaisa_certificate_attendees',
        params: {'p_organization_id': orgId, 'p_event_id': eventId},
      );
      if (!mounted || _organizationId != orgId || _eventId != eventId) return;
      final people = _asMaps(raw);
      final event = _events.firstWhere((e) => e['id'].toString() == eventId);
      final organization = _organizations.firstWhere(
        (o) => o['id'].toString() == orgId,
      );
      setState(() {
        _attendees = people;
        _selectedUsers.addAll(people.map((p) => p['user_id'].toString()));
        _loadingAttendees = false;
        _hasLoadedAttendees = true;
        _layers.firstWhere((l) => l.id == 'org').text.text =
            organization['name'].toString();
        _layers.firstWhere((l) => l.id == 'event').text.text = event['title']
            .toString();
        final start = DateTime.tryParse(event['starts_at']?.toString() ?? '');
        if (start != null) {
          final date = start.toLocal();
          _layers.firstWhere((l) => l.id == 'date').text.text =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
        _updateSelectedNames();
      });
    } catch (error) {
      if (mounted && _eventId == eventId)
        setState(() {
          _loadingAttendees = false;
          _dataError = 'Unable to load verified event attendance: $error';
        });
    }
  }

  void _updateSelectedNames() {
    _names.text = _attendees
        .where((a) => _selectedUsers.contains(a['user_id'].toString()))
        .map((a) => a['name'].toString().trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .join('\n');
    _recipientIndex = 0;
  }

  Widget _supabasePanel() {
    final canUse = !_loadingOrganizations && _organizationId != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verified attendees from KAISA',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Only published events assigned to your organization and checked-in Tier 2 residents are eligible.',
            ),
            if (_loadingOrganizations || _loadingEvents || _loadingAttendees)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
            if (_dataError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _dataError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('organization_$_organizationId'),
              initialValue: _organizationId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Authorized organization',
                border: OutlineInputBorder(),
              ),
              items: _organizations
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o['id'].toString(),
                      child: Text(
                        o['name'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.organizationId != null
                  ? null
                  : _changeOrganization,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('event_$_organizationId-$_eventId'),
              initialValue: _eventId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Organization event',
                border: OutlineInputBorder(),
              ),
              items: _events
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e['id'].toString(),
                      child: Text(
                        e['title'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: canUse && !_loadingEvents ? _loadAttendees : null,
            ),
            if (canUse && !_loadingEvents && _events.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'No published events with an attendance-session assignment for this organization.',
                ),
              ),
            if (_hasLoadedAttendees) ...[
              const SizedBox(height: 12),
              Text(
                '${_selectedUsers.length} selected of ${_attendees.length} verified, checked-in attendees',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (_attendees.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No verified check-ins found. Complete QR check-in and Tier 2 verification first.',
                  ),
                ),
              if (_attendees.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedUsers.addAll(
                          _attendees.map((p) => p['user_id'].toString()),
                        );
                        _updateSelectedNames();
                      }),
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedUsers.clear();
                        _updateSelectedNames();
                      }),
                      child: const Text('Clear selection'),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final a in _attendees)
                        CheckboxListTile(
                          dense: true,
                          title: Text(a['name'].toString()),
                          subtitle: Text(
                            'Checked in: ${a['checked_in_at'] ?? '-'}',
                          ),
                          value: _selectedUsers.contains(
                            a['user_id'].toString(),
                          ),
                          onChanged: (checked) => setState(() {
                            final uid = a['user_id'].toString();
                            if (checked == true) {
                              _selectedUsers.add(uid);
                            } else {
                              _selectedUsers.remove(uid);
                            }
                            _updateSelectedNames();
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _names.removeListener(_onNamesChange);
    _names.dispose();
    for (final layer in _layers) {
      layer.text.removeListener(_refresh);
      layer.text.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBackground() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (result.isEmpty) return;
      final file = result.first;
      final length = file.lengthSync() ?? await file.length();
      if (length == null || length == 0 || length > _maxImage) {
        setState(() => _message = 'Use a PNG or JPEG under 5 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > _maxImage) {
        setState(() => _message = 'Use a PNG or JPEG under 5 MB.');
        return;
      }
      final png =
          bytes.length > 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final jpg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (!png && !jpg) {
        setState(() => _message = 'The selected file is not a valid PNG/JPEG.');
        return;
      }
      setState(() {
        _background = bytes;
        _backgroundName = file.name;
        _message = null;
      });
    } catch (e) {
      setState(() => _message = 'Unable to load background: $e');
    }
  }

  Future<void> _pickFont() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf'],
      );
      if (result.isEmpty) return;
      final file = result.first;
      final length = file.lengthSync() ?? await file.length();
      if (length == null || length == 0 || length > _maxFont) {
        setState(() => _message = 'Choose a .ttf font smaller than 3 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > _maxFont) {
        setState(() => _message = 'Choose a .ttf font smaller than 3 MB.');
        return;
      }
      // Reject files that are not TrueType/OpenType-flavored SFNT TTF files.
      final truetype =
          bytes.length > 4 &&
          bytes[0] == 0 &&
          bytes[1] == 1 &&
          bytes[2] == 0 &&
          bytes[3] == 0;
      final opentype =
          bytes.length > 4 &&
          bytes[0] == 79 &&
          bytes[1] == 84 &&
          bytes[2] == 84 &&
          bytes[3] == 79;
      if (!truetype && !opentype) {
        setState(() => _message = 'Choose a valid .ttf font file.');
        return;
      }
      final family =
          'KAISAUploadedFont_${DateTime.now().microsecondsSinceEpoch}';
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      if (!mounted) return;
      setState(() {
        _customFontBytes = bytes;
        _customFontName = file.name;
        _customFontFamily = family;
        _selected.font = 'Custom';
        _message = null;
      });
    } catch (e) {
      if (mounted) setState(() => _message = 'Unable to load font: $e');
    }
  }

  // A named font is picked once, then available to every text layer.
  // Only TrueType .ttf fonts are supported by the local PDF exporter.
  Future<bool> _loadNamedFont(String name, {bool boldFace = false}) async {
    final key = boldFace ? '$name:bold' : name;
    if (_namedFontBytes.containsKey(key)) return true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf'],
      );
      if (result.isEmpty) return false;
      final file = result.first;
      final length = file.lengthSync() ?? await file.length();
      if (length == null || length == 0 || length > _maxFont) {
        if (mounted)
          setState(() => _message = 'Choose a .ttf font under 3 MB.');
        return false;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > _maxFont) {
        if (mounted)
          setState(() => _message = 'Choose a .ttf font under 3 MB.');
        return false;
      }
      if (bytes.length < 4 ||
          bytes[0] != 0 ||
          bytes[1] != 1 ||
          bytes[2] != 0 ||
          bytes[3] != 0) {
        if (mounted)
          setState(
            () => _message =
                'Use a TrueType .ttf font; OpenType .otf files are not supported here.',
          );
        return false;
      }
      final family =
          'KAISA_${name.replaceAll(' ', '_')}_${boldFace ? 'Bold' : 'Regular'}';
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      if (!mounted) return false;
      setState(() {
        _namedFontBytes[key] = bytes;
        _namedFontFamilies[key] = family;
        _message = null;
      });
      return true;
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not load font: $error');
      return false;
    }
  }

  Future<void> _selectFont(String fontName) async {
    if (fontName == 'Great Vibes' || fontName == 'TeX Gyre Termes') {
      final ok = await _loadNamedFont(fontName);
      if (!ok || !mounted) return;
    }
    setState(() {
      _selected.font = fontName;
      if (fontName == 'Great Vibes') _selected.bold = false;
      if (fontName == 'TeX Gyre Termes') _selected.bold = false;
    });
  }

  Future<void> _toggleSelectedBold() async {
    final layer = _selected;
    if (layer.font == 'Great Vibes') {
      setState(() => _message = 'Great Vibes has no native bold face.');
      return;
    }
    if (layer.font == 'TeX Gyre Termes' && !layer.bold) {
      final ok = await _loadNamedFont('TeX Gyre Termes', boldFace: true);
      if (!ok || !mounted) return;
    }
    if (mounted) setState(() => layer.bold = !layer.bold);
  }

  TextStyle _previewStyle(_TextLayer e, double scale) {
    final isTermesBold =
        e.font == 'TeX Gyre Termes' &&
        e.bold &&
        _namedFontFamilies.containsKey('TeX Gyre Termes:bold');
    final family = switch (e.font) {
      'Great Vibes' => _namedFontFamilies['Great Vibes'],
      'TeX Gyre Termes' =>
        _namedFontFamilies[isTermesBold
            ? 'TeX Gyre Termes:bold'
            : 'TeX Gyre Termes'],
      'Serif' || 'Serif Italic' => 'serif',
      'Mono' || 'Mono Bold' => 'monospace',
      'Custom' => _customFontFamily,
      _ => null,
    };
    return TextStyle(
      fontFamily: family,
      fontSize: e.size * scale,
      // Bold font files already carry their own weight.
      fontWeight: e.font == 'Great Vibes' || e.font == 'TeX Gyre Termes'
          ? FontWeight.normal
          : (e.bold || e.font == 'Sans Bold' || e.font == 'Mono Bold')
          ? FontWeight.bold
          : FontWeight.normal,
      fontStyle: e.font == 'Serif Italic' ? FontStyle.italic : FontStyle.normal,
      color: e.color,
      height: 1.1,
    );
  }

  PdfColor _pdfColor(Color color) =>
      PdfColor(color.r, color.g, color.b, color.a);

  pw.Font _pdfFont(
    _TextLayer e, {
    required bool bold,
    pw.Font? custom,
    required Map<String, pw.Font> named,
  }) {
    if (e.font == 'Great Vibes')
      return named['Great Vibes'] ?? pw.Font.timesItalic();
    if (e.font == 'TeX Gyre Termes') {
      return named[bold ? 'TeX Gyre Termes:bold' : 'TeX Gyre Termes'] ??
          named['TeX Gyre Termes'] ??
          pw.Font.times();
    }
    if (e.font == 'Custom' && custom != null) return custom;
    if (e.font == 'Serif' || e.font == 'Serif Italic') {
      if (e.font == 'Serif Italic') {
        return bold ? pw.Font.timesBoldItalic() : pw.Font.timesItalic();
      }
      return bold ? pw.Font.timesBold() : pw.Font.times();
    }
    if (e.font == 'Mono' || e.font == 'Mono Bold') {
      return (bold || e.font == 'Mono Bold')
          ? pw.Font.courierBold()
          : pw.Font.courier();
    }
    if (e.font == 'Sans Bold') return pw.Font.helveticaBold();
    return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
  }

  void _addTextLayer() {
    final id = 'extra_${_nextLayerId++}';
    final layer = _TextLayer(
      id,
      'Custom ${_nextLayerId - 1}',
      TextEditingController(text: 'Your text here'),
      x: .5,
      y: .53,
      size: 18,
    );
    layer.text.addListener(_refresh);
    setState(() {
      _layers.add(layer);
      _selectedId = id;
    });
  }

  void _removeSelectedLayer() {
    final index = _layers.indexWhere((layer) => layer.id == _selectedId);
    if (index < 0 || _layers.length <= 1) return;
    final layer = _layers.removeAt(index);
    layer.text.removeListener(_refresh);
    layer.text.dispose();
    setState(() => _selectedId = _layers.first.id);
  }

  Future<void> _addLogo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (result.isEmpty) return;
      final file = result.first;
      final length = file.lengthSync() ?? await file.length();
      if (length == null || length == 0 || length > _maxImage) {
        if (mounted) setState(() => _message = 'Choose an image under 5 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > _maxImage) {
        if (mounted) setState(() => _message = 'Choose an image under 5 MB.');
        return;
      }
      if (mounted)
        setState(
          () => _logos.add(
            _LogoLayer(
              id: 'logo_${_nextLogoId++}',
              name: file.name,
              bytes: bytes,
              x: .12 + (_logos.length % 3) * .2,
            ),
          ),
        );
    } catch (e) {
      if (mounted) setState(() => _message = 'Unable to load logo: $e');
    }
  }

  void _showColorPicker() {
    Color draft = _selected.color;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose text color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: draft,
            onColorChanged: (value) => draft = value,
            enableAlpha: false,
            displayThumbColor: true,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _selected.color = draft);
              Navigator.pop(dialogContext);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _applyDesign(int design) {
    setState(() {
      _design = design;
      _background = null;
      _backgroundName = null;
    });
  }

  pw.Widget _pdfDecoration() {
    if (_design == 1) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColor.fromHex('#B79543'), width: 12),
        ),
      );
    }
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(
          color: PdfColor.fromHex(_design == 2 ? '#176B43' : '#176B43'),
          width: _design == 2 ? 11 : 4,
        ),
      ),
    );
  }

  Future<Uint8List> _makePdf() async {
    final recipients = _recipients;

    if (recipients.isEmpty) {
      throw StateError('Enter at least one recipient name.');
    }

    if (recipients.length > 200) {
      throw StateError('Maximum 200 recipients per batch.');
    }

    final document = pw.Document(compress: true);

    final bg = _background == null ? null : pw.MemoryImage(_background!);

    final customFont = _customFontBytes == null
        ? null
        : pw.Font.ttf(ByteData.sublistView(_customFontBytes!));
    final namedPdfFonts = <String, pw.Font>{
      for (final entry in _namedFontBytes.entries)
        entry.key: pw.Font.ttf(ByteData.sublistView(entry.value)),
    };

    for (final name in recipients) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              // Certificate background
              if (bg != null)
                pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.fill))
              else ...[
                pw.Positioned.fill(child: _pdfDecoration()),

                pw.Positioned(
                  left: 22,
                  right: 22,
                  top: 22,
                  bottom: 22,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#176B43'),
                        width: 4,
                      ),
                    ),
                  ),
                ),

                pw.Positioned(
                  left: 31,
                  right: 31,
                  top: 31,
                  bottom: 31,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#E4B746'),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],

              // Uploadable logos are embedded once into the PDF document.
              for (final logo in _logos.where((item) => item.visible))
                pw.Positioned(
                  left: logo.x * _pageWidth,
                  top: logo.y * _pageHeight,
                  child: pw.SizedBox(
                    width: logo.width * _pageWidth,
                    child: pw.Image(
                      pw.MemoryImage(logo.bytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),

              // Editable certificate text layers
              for (final layer in _layers.where((e) => e.visible))
                pw.Positioned(
                  left:
                      layer.x * _pageWidth -
                      _pageWidth * _layerWidthFraction / 2,
                  top: layer.y * _pageHeight,

                  // Width is now inside SizedBox
                  child: pw.SizedBox(
                    width: _pageWidth * _layerWidthFraction,
                    child: pw.Text(
                      _displayText(layer, name),
                      maxLines: 3,
                      textAlign: switch (layer.align) {
                        TextAlign.left => pw.TextAlign.left,
                        TextAlign.right => pw.TextAlign.right,
                        _ => pw.TextAlign.center,
                      },
                      style: pw.TextStyle(
                        font: _pdfFont(
                          layer,
                          bold: layer.bold,
                          custom: customFont,
                          named: namedPdfFonts,
                        ),
                        fontSize: layer.size,
                        color: _pdfColor(layer.color),
                        lineSpacing: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return document.save();
  }

  Future<void> _export({required bool print}) async {
    if (_exporting) return;
    if (!_hasLoadedAttendees || _selectedUsers.isEmpty || _eventId == null) {
      setState(
        () => _message =
            'Select an organization event and at least one verified checked-in attendee before exporting.',
      );
      return;
    }
    setState(() {
      _exporting = true;
      _message = null;
    });
    try {
      final bytes = await _makePdf();
      if (print) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'KAISA Certificates',
        );
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'kaisa_certificates.pdf',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _certificateCanvas() => LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = w * _pageHeight / _pageWidth;
      final scale = w / _pageWidth;
      return SizedBox(
        height: h,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: _background == null
                      ? BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _forest, width: 4 * scale),
                        )
                      : BoxDecoration(
                          color: Colors.white,
                          image: DecorationImage(
                            image: MemoryImage(_background!),
                            fit: BoxFit.fill,
                          ),
                        ),
                  child: _background == null
                      ? Padding(
                          padding: EdgeInsets.all(10 * scale),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _gold,
                                width: 2 * scale,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              // Uploaded image layers sit above the template, below text.
              for (final logo in _logos.where((item) => item.visible))
                Positioned(
                  left: logo.x * w,
                  top: logo.y * h,
                  width: logo.width * w,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) => setState(() {
                      logo.x = (logo.x + details.delta.dx / w).clamp(
                        0.0,
                        1.0 - logo.width,
                      );
                      logo.y = (logo.y + details.delta.dy / h).clamp(0.0, 0.95);
                    }),
                    child: Image.memory(
                      logo.bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              for (final layer in _layers.where((item) => item.visible))
                Positioned(
                  left: (layer.x - _layerWidthFraction / 2) * w,
                  top: layer.y * h,
                  width: _layerWidthFraction * w,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedId = layer.id),
                    onPanStart: (_) => setState(() => _selectedId = layer.id),
                    onPanUpdate: (details) => setState(() {
                      layer.x = (layer.x + details.delta.dx / w).clamp(
                        _layerWidthFraction / 2,
                        1 - _layerWidthFraction / 2,
                      );
                      layer.y = (layer.y + details.delta.dy / h).clamp(0, .96);
                    }),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 3 * scale),
                      decoration: BoxDecoration(
                        color: layer.id == _selectedId
                            ? const Color(0x14176B43)
                            : Colors.transparent,
                        border: layer.id == _selectedId
                            ? Border.all(color: _forest, width: 1.4)
                            : null,
                      ),
                      child: Text(
                        _displayText(layer, _sampleName),
                        textAlign: layer.align,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _previewStyle(layer, scale),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _controlPanel() {
    final e = _selected;
    final availableFonts = [
      'Sans',
      'Sans Bold',
      'Serif',
      'Serif Italic',
      'Mono',
      'Mono Bold',
      'Great Vibes',
      'TeX Gyre Termes',
      if (_customFontBytes != null) 'Custom',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Template',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 10),
        const Text('Starter designs (or upload your own background)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final preset in [
              (0, 'Simple'),
              (1, 'Classic Gold'),
              (2, 'Modern Green'),
            ])
              ChoiceChip(
                label: Text(preset.$2),
                selected: _design == preset.$1 && _background == null,
                onSelected: (_) => _applyDesign(preset.$1),
              ),
          ],
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: _addLogo,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add logo/image layer'),
        ),
        if (_logos.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final logo in _logos)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Image: ${logo.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: logo.visible ? 'Hide image' : 'Show image',
                      icon: Icon(
                        logo.visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => logo.visible = !logo.visible),
                    ),
                    IconButton(
                      tooltip: 'Remove image',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _logos.remove(logo)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('X'),
                    Expanded(
                      child: Slider(
                        value: logo.x.clamp(0.0, 1.0 - logo.width),
                        min: 0,
                        max: 1.0 - logo.width,
                        onChanged: (v) => setState(() => logo.x = v),
                      ),
                    ),
                    const Text('Y'),
                    Expanded(
                      child: Slider(
                        value: logo.y.clamp(0.0, 0.95),
                        min: 0,
                        max: 0.95,
                        onChanged: (v) => setState(() => logo.y = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Size'),
                    Expanded(
                      child: Slider(
                        value: logo.width,
                        min: .05,
                        max: .4,
                        onChanged: (value) => setState(() {
                          logo.width = value;
                          logo.x = logo.x.clamp(0, 1 - value);
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickBackground,
          icon: const Icon(Icons.upload_file),
          label: Text(
            _backgroundName == null
                ? 'Upload PNG/JPG background'
                : 'Background: $_backgroundName',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_background != null)
          TextButton(
            onPressed: () => setState(() {
              _background = null;
              _backgroundName = null;
            }),
            child: const Text('Use simple built-in border'),
          ),
        const SizedBox(height: 20),
        const Text(
          'Text layers',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _addTextLayer,
              icon: const Icon(Icons.add),
              label: const Text('Add text'),
            ),
            OutlinedButton.icon(
              onPressed: _layers.length <= 1 ? null : _removeSelectedLayer,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove selected'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          dense: true,
          title: const Text('Show selected text layer'),
          value: e.visible,
          onChanged: (v) => setState(() => e.visible = v),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            for (final layer in _layers)
              ChoiceChip(
                label: Text(layer.label),
                selected: _selectedId == layer.id,
                onSelected: (_) => setState(() => _selectedId = layer.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('label_${e.id}'),
          initialValue: e.label,
          decoration: const InputDecoration(labelText: 'Layer name'),
          onChanged: (value) => setState(() => e.label = value),
        ),
        const SizedBox(height: 10),
        TextField(
          key: ValueKey(e.id),
          controller: e.text,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Edit ${e.label}',
            helperText: e.id == 'recipient'
                ? 'Use {recipient} to insert each attendee name.'
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('font_${e.id}_${e.font}'),
                initialValue: e.font,
                decoration: const InputDecoration(labelText: 'Font'),
                items: availableFonts
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f == 'Custom' ? 'Uploaded font' : f),
                      ),
                    )
                    .toList(),
                onChanged: (f) {
                  if (f != null) _selectFont(f);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFont,
                icon: const Icon(Icons.font_download_outlined),
                label: const Text('Upload .ttf'),
              ),
            ),
          ],
        ),
        if (e.font == 'Great Vibes' || e.font == 'TeX Gyre Termes')
          const Text(
            'The file dialog is expected: choose an extracted .ttf (not a ZIP or .otf). This font is loaded only for the current preview session.',
            style: TextStyle(fontSize: 12),
          ),
        if (_customFontName != null)
          Text(
            'Loaded: $_customFontName (local preview only)',
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Size: ${e.size.toStringAsFixed(0)} pt',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              onPressed: e.font == 'Great Vibes' ? null : _toggleSelectedBold,
              tooltip: e.font == 'Great Vibes'
                  ? 'Great Vibes has no native bold face'
                  : 'Bold',
              icon: Icon(
                Icons.format_bold,
                color: e.bold ? _forest : Colors.grey,
              ),
            ),
          ],
        ),
        Slider(
          value: e.size,
          min: 9,
          max: 64,
          divisions: 55,
          onChanged: (v) => setState(() => e.size = v),
        ),
        const SizedBox(height: 4),
        const Text('Alignment'),
        SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
              value: TextAlign.left,
              icon: Icon(Icons.format_align_left),
            ),
            ButtonSegment(
              value: TextAlign.center,
              icon: Icon(Icons.format_align_center),
            ),
            ButtonSegment(
              value: TextAlign.right,
              icon: Icon(Icons.format_align_right),
            ),
          ],
          selected: {e.align},
          onSelectionChanged: (value) => setState(() => e.align = value.first),
        ),
        const SizedBox(height: 15),
        const Text('Text color'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final c in [
              const Color(0xFF173F2E),
              Colors.black,
              Colors.white,
              const Color(0xFF654321),
              const Color(0xFF9B7524),
              const Color(0xFF1C5496),
            ])
              InkWell(
                onTap: () => setState(() => e.color = c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: e.color == c ? _gold : Colors.grey.shade300,
                      width: e.color == c ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _showColorPicker,
          icon: const Icon(Icons.color_lens_outlined),
          label: const Text('Custom color wheel / HEX'),
        ),
        const SizedBox(height: 14),
        const Text(
          'Fine-tune position',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        Row(
          children: [
            const Text('Horizontal'),
            Expanded(
              child: Slider(
                value: e.x,
                min: _layerWidthFraction / 2,
                max: 1 - _layerWidthFraction / 2,
                onChanged: (v) => setState(() => e.x = v),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Vertical'),
            Expanded(
              child: Slider(
                value: e.y,
                min: 0,
                max: .96,
                onChanged: (v) => setState(() => e.y = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Recipients · one name per line',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _names,
          maxLines: 5,
          readOnly: true,
          decoration: const InputDecoration(
            hintText:
                'Choose verified attendees above; names are loaded securely from Supabase.',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_recipients.length} unique recipient(s)',
          style: const TextStyle(color: _forest, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _previewPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Certificate canvas',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
          if (_recipients.length > 1) ...[
            IconButton(
              onPressed: _recipientIndex <= 0
                  ? null
                  : () => setState(() => _recipientIndex--),
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${_recipientIndex + 1} / ${_recipients.length}'),
            IconButton(
              onPressed: _recipientIndex >= _recipients.length - 1
                  ? null
                  : () => setState(() => _recipientIndex++),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Click a text layer to select it, then drag to move. Sizes are based on landscape A4 PDF.',
        style: TextStyle(color: Color(0xFF5E7869), fontSize: 12),
      ),
      const SizedBox(height: 12),
      _certificateCanvas(),
      const SizedBox(height: 17),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: _exporting ? null : () => _export(print: false),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export batch PDF'),
          ),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export(print: true),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
      if (_message != null) ...[
        const SizedBox(height: 10),
        Text(_message!, style: const TextStyle(color: Colors.red)),
      ],
      const SizedBox(height: 9),
      const Text(
        'Verified attendees and event details are read from Supabase. PDF export is local; issuance records and resident download delivery are not yet implemented.',
        style: TextStyle(fontSize: 12, color: Color(0xFF5E7869)),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      // No app bar: the Organization Admin shell owns the shared header.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1450),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _forest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KAISA · ORGANIZATION TOOLS · VERIFIED ATTENDANCE',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Make it yours.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Upload a design, drag text, choose fonts, and print certificates for every attendee.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _supabasePanel(),
              const SizedBox(height: 16),
              if (desktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: _controlPanel(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: _previewPanel(),
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _previewPanel(),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _controlPanel(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
