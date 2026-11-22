import 'dart:convert';
import 'dart:async';
import 'certificate_leave_guard_stub.dart' if (dart.library.html) 'certificate_leave_guard_web.dart' as leave_guard;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.color = const Color(0xFF173F2E),
    this.bold = false,
  }) : font = 'Sans',
     align = TextAlign.center;

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
  }) : y = .12,
     width = .14;
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
  double _layerWidth(_TextLayer e) => e.id.startsWith('signer_') ? .34 : .78;

  static const double _layerWidthFraction = 0.78;
  

  late final List<_TextLayer> _layers = [
    _TextLayer(
      'org',
      'Organization',
      TextEditingController(text: 'KAISA Community Organization'),
      x: .5,
      y: .16,
      size: 20,
      bold: true,
    ),
    _TextLayer(
      'title',
      'Title',
      TextEditingController(text: 'CERTIFICATE OF PARTICIPATION'),
      x: .5,
      y: .27,
      size: 30,
      bold: true,
    ),
    _TextLayer(
      'intro',
      'Presented to',
      TextEditingController(text: 'This certificate is presented to'),
      x: .5,
      y: .38,
      size: 15,
      color: const Color(0xFF34473D),
    ),
    _TextLayer(
      'recipient',
      'Recipient name',
      TextEditingController(text: '{recipient}'),
      x: .5,
      y: .46,
      size: 37,
      bold: true,
    ),
    _TextLayer(
      'description',
      'Description',
      TextEditingController(
        text: 'In grateful recognition of your valuable participation, dedication, and meaningful contribution to the success of this community initiative. Your commitment to service and collaboration is sincerely appreciated.',
      ),
      x: .5,
      y: .59,
      size: 14,
      color: const Color(0xFF34473D),
    ),
    _TextLayer(
      'event',
      'Event',
      TextEditingController(text: 'Community Volunteer Program'),
      x: .5,
      y: .72,
      size: 17,
      bold: true,
    ),
    _TextLayer(
      'date',
      'Date',
      TextEditingController(text: 'November 20, 2026'),
      x: .5,
      y: .79,
      size: 14,
    ),
   _TextLayer(
  'signer_left',
  'Left signatory name',
  TextEditingController(text: 'Darlene Raven'),
  x: 0.27,
  y: 0.855,
  size: 15,
  bold: true,
),
_TextLayer(
  'signer_left_position',
  'Left signatory position',
  TextEditingController(text: 'Organization Representative'),
  x: 0.27,
  y: 0.895,
  size: 11,
),
_TextLayer(
  'signer_right',
  'Right signatory name',
  TextEditingController(text: 'Darlene Raven'),
  x: 0.73,
  y: 0.855,
  size: 15,
  bold: true,
),
_TextLayer(
  'signer_right_position',
  'Right signatory position',
  TextEditingController(text: 'Authorized LGU Representative'),
  x: 0.73,
  y: 0.895,
  size: 11,
),
  ];

  final List<_LogoLayer> _logos = [];
  // Bottom-to-top stacking order. The list is also used by the PDF renderer.
  late final List<String> _zOrder = [
    'kaisa_default',
    ..._layers.map((layer) => layer.id),
  ];

  void _reorderLayer(int oldIndex, int newIndex) {
    final displayOrder = _zOrder.reversed.toList();
    if (newIndex > oldIndex) newIndex--;
    if (newIndex == oldIndex) return;
    _checkpoint();
    setState(() {
      final moved = displayOrder.removeAt(oldIndex);
      displayOrder.insert(newIndex, moved);
      _zOrder
        ..clear()
        ..addAll(displayOrder.reversed);
    });
  }

  _TextLayer? _textFor(String id) {
    for (final layer in _layers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  _LogoLayer? _imageFor(String id) {
    for (final logo in _logos) {
      if (logo.id == id) return logo;
    }
    return null;
  }

  Uint8List? _kaisaLogoBytes;
  bool _showKaisaLogo = true;
  bool _showKaisaBorder = true;
  double _kaisaLogoX = .065, _kaisaLogoY = .07, _kaisaLogoWidth = .105;
  String? _editingId;
  final FocusNode _editorFocus = FocusNode();
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  final Map<String, String> _lastTextValues = {};
  bool _restoring = false;

  // Browser-persistent, organization-scoped template library.
  List<Map<String, dynamic>> _savedTemplates = [];
  bool _templatesLoading = false;
  bool _templatesBusy = false;
  String? _activeTemplateId;
  String? _savedFingerprint;
  bool _libraryReady = false;
  Timer? _draftTimer;
  String? _observedFingerprint;
  String? _baselineFingerprint;
  bool _loadingDesign = false;
  bool _allowRouteExit = false;
  String _draftStatus = 'Draft protection ready';

  String? get _draftStorageKey => _templateStorageKey == null
      ? null : '${_templateStorageKey!}_draft_v1';

  bool get _hasUncommittedEdits => _libraryReady &&
      _currentFingerprint != (_savedFingerprint ?? _baselineFingerprint);

  void _scheduleDraftIfChanged() {
    if (!_libraryReady || _loadingDesign || _templateStorageKey == null) return;
    final fingerprint = _currentFingerprint;
    if (_observedFingerprint == fingerprint) return;
    _observedFingerprint = fingerprint;
    _draftTimer?.cancel();
    leave_guard.setUnsaved(_hasUncommittedEdits);
    _draftTimer = Timer(const Duration(seconds: 2), _writeDraft);
  }

  Future<void> _writeDraft() async {
    final key = _draftStorageKey;
    if (key == null || !_libraryReady || _loadingDesign) return;
    final fingerprint = _currentFingerprint;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_hasUncommittedEdits) {
        await prefs.remove(key);
        if (mounted) setState(() => _draftStatus = 'All changes saved');
        return;
      }
      final ok = await prefs.setString(key, jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'activeTemplateId': _activeTemplateId,
        'savedFingerprint': _savedFingerprint,
        'design': _serializeDesign(),
      }));
      if (!ok) throw StateError('Browser storage rejected the draft');
      if (mounted) setState(() => _draftStatus =
          fingerprint == _currentFingerprint ? 'Draft auto-saved' : 'Saving newer edits…');
    } catch (e) {
      if (mounted) setState(() => _draftStatus = 'Auto-save failed: $e');
    }
  }

  Future<void> _recoverDraft() async {
    final key = _draftStorageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || !mounted) return;
    Map<String, dynamic> record;
    try {
      record = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) { return; }
    final recover = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Recover your certificate draft?'),
        content: Text('KAISA found an auto-saved design from '
            '${record['savedAt'] ?? 'a previous session'}. Restore it?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Discard draft')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore draft')),
        ],
      ),
    );
    if (!mounted || key != _draftStorageKey) return;
    if (recover != true) {
      await prefs.remove(key);
      return;
    }
    try {
      _loadingDesign = true;
      await _applySavedDesign(Map<String, dynamic>.from(record['design'] as Map));
      if (!mounted) return;
      _activeTemplateId = record['activeTemplateId'] as String?;
      if (!_savedTemplates.any((e) => e['id'] == _activeTemplateId)) {
        _activeTemplateId = null;
      }
      _savedFingerprint = record['savedFingerprint'] as String?;
      _observedFingerprint = _currentFingerprint;
      leave_guard.setUnsaved(_hasUncommittedEdits);
      setState(() => _draftStatus = 'Recovered auto-saved draft');
    } catch (e) {
      if (mounted) setState(() => _message = 'Draft recovery failed: $e');
    } finally {
      _loadingDesign = false;
    }
  }

  Future<void> _confirmRouteExit() async {
    if (!await _confirmDiscardChanges()) return;
    if (!mounted) return;
    _allowRouteExit = true;
    Navigator.of(context).pop();
  }


  String? get _templateStorageKey {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _organizationId == null) return null;
    return 'kaisa_cert_templates_v1_${userId}_${_organizationId!}';
  }

  Map<String, dynamic> _serializeDesign() {
    final snapshot = _snapshot();
    return {
      'version': 1,
      'zOrder': snapshot['zOrder'],
      'design': snapshot['design'],
      'background': _background == null ? null : base64Encode(_background!),
      'backgroundName': _backgroundName,
      'showLogo': _showKaisaLogo,
      'showBorder': _showKaisaBorder,
      'logoX': _kaisaLogoX,
      'logoY': _kaisaLogoY,
      'logoWidth': _kaisaLogoWidth,
      'layers': _layers.map((e) => {
        'id': e.id, 'label': e.label, 'text': e.text.text,
        'x': e.x, 'y': e.y, 'size': e.size, 'font': e.font,
        'color': e.color.toARGB32(), 'bold': e.bold,
        'visible': e.visible, 'align': e.align.name,
      }).toList(),
      'logos': _logos.map((e) => {
        'id': e.id, 'name': e.name, 'bytes': base64Encode(e.bytes),
        'visible': e.visible, 'x': e.x, 'y': e.y, 'width': e.width,
      }).toList(),
      'customFontBytes': _customFontBytes == null ? null : base64Encode(_customFontBytes!),
      'customFontName': _customFontName,
      'namedFontBytes': {
        for (final entry in _namedFontBytes.entries)
          if (!_bundledFonts.containsKey(entry.key)) entry.key: base64Encode(entry.value),
      },
    };
  }

  Future<void> _applySavedDesign(Map<String, dynamic> design) async {
    if (design['version'] != 1) throw const FormatException('Unsupported template version');
    final layers = (design['layers'] as List).map((item) {
      final v = Map<String, dynamic>.from(item as Map);
      return <String, dynamic>{
        'id': v['id'] as String, 'label': v['label'] as String,
        'text': v['text'] as String,
        'x': (v['x'] as num).toDouble(), 'y': (v['y'] as num).toDouble(),
        'size': (v['size'] as num).toDouble(),
        'font': v['font'] as String, 'color': Color(v['color'] as int),
        'bold': v['bold'] as bool, 'visible': v['visible'] as bool,
        'align': TextAlign.values.byName(v['align'] as String),
      };
    }).toList();
    if (layers.isEmpty) throw const FormatException('Template contains no text layers');
    final logos = (design['logos'] as List).map((item) {
      final v = Map<String, dynamic>.from(item as Map);
      return <String, dynamic>{
        'id': v['id'] as String, 'name': v['name'] as String,
        'bytes': base64Decode(v['bytes'] as String),
        'visible': v['visible'] as bool,
        'x': (v['x'] as num).toDouble(), 'y': (v['y'] as num).toDouble(),
        'width': (v['width'] as num).toDouble(),
      };
    }).toList();
    final custom = design['customFontBytes'] as String?;
    final restoredNamed = <String, Uint8List>{};
    for (final entry in (design['namedFontBytes'] as Map? ?? {}).entries) {
      restoredNamed[entry.key.toString()] = base64Decode(entry.value as String);
    }
    // Restore font registrations before rendering layers.
    String? customFamily;
    if (custom != null) {
      customFamily = 'KAISARecoveredCustom_${DateTime.now().microsecondsSinceEpoch}';
      final loader = FontLoader(customFamily)
        ..addFont(Future.value(ByteData.sublistView(base64Decode(custom))));
      await loader.load();
    }
    final restoredFamilies = <String, String>{};
    for (final entry in restoredNamed.entries) {
      final family = 'KAISARecovered_${restoredFamilies.length}_${DateTime.now().microsecondsSinceEpoch}';
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(entry.value)));
      await loader.load();
      restoredFamilies[entry.key] = family;
    }
    if (!mounted) return;
    _checkpoint();
    _restore({
      'zOrder': (design['zOrder'] as List).cast<String>(),
      'design': design['design'] as int,
      'background': design['background'] == null ? null : base64Decode(design['background'] as String),
      'backgroundName': design['backgroundName'],
      'selectedId': layers.first['id'], 'selectedImageId': null,
      'showLogo': design['showLogo'] as bool,
      'showBorder': design['showBorder'] as bool,
      'logoX': (design['logoX'] as num).toDouble(),
      'logoY': (design['logoY'] as num).toDouble(),
      'logoWidth': (design['logoWidth'] as num).toDouble(),
      'layers': layers, 'logos': logos,
    });
    _customFontBytes = custom == null ? null : base64Decode(custom);
    _customFontName = design['customFontName'] as String?;
    _customFontFamily = customFamily;
    _namedFontBytes..clear()..addAll(restoredNamed);
    _namedFontFamilies..clear()..addAll(restoredFamilies);
    _nextLayerId = 1 + _layers.where((e) => e.id.startsWith('extra_'))
      .map((e) => int.tryParse(e.id.substring(6)) ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    _nextLogoId = 1 + _logos.where((e) => e.id.startsWith('logo_'))
      .map((e) => int.tryParse(e.id.substring(5)) ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    _undoStack.clear();
    _redoStack.clear();
    setState(() {});
  }

  String get _currentFingerprint => jsonEncode(_serializeDesign());
  bool get _hasUnsavedTemplateChanges => _hasUncommittedEdits;

  Future<void> _loadTemplateLibrary() async {
    final key = _templateStorageKey;
    setState(() { _templatesLoading = true; _libraryReady = false; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = key == null ? null : prefs.getString(key);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
      if (!mounted || key != _templateStorageKey) return;
      setState(() {
        _savedTemplates = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _activeTemplateId = null;
        _savedFingerprint = null;
        _libraryReady = true;
        _baselineFingerprint = _currentFingerprint;
        _observedFingerprint = _currentFingerprint;
      });
      await _recoverDraft();
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not load My Templates: $e');
    } finally {
      if (mounted) setState(() => _templatesLoading = false);
    }
  }

  Future<void> _persistTemplates() async {
    final key = _templateStorageKey;
    if (key == null) throw StateError('Select an authorized organization first.');
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(key, jsonEncode(_savedTemplates));
    if (!ok) throw StateError('Browser storage rejected the save.');
  }

  Future<String?> _askTemplateName({String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(initial == null ? 'Save certificate template' : 'Template name'),
          content: TextField(
            controller: controller, autofocus: true, maxLength: 80,
            decoration: const InputDecoration(labelText: 'Template name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) Navigator.pop(ctx, name);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUncommittedEdits) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('Your edits have not been saved as a named template. An auto-saved draft may be recoverable on this browser.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard changes')),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveTemplate({bool saveAs = false}) async {
    if (_templatesBusy || !_libraryReady || _templateStorageKey == null) return;
    final existingIndex = _savedTemplates.indexWhere((e) => e['id'] == _activeTemplateId);
    String? name;
    if (saveAs || existingIndex < 0) {
      name = await _askTemplateName(initial: saveAs && existingIndex >= 0
        ? '${_savedTemplates[existingIndex]['name']} copy' : null);
      if (name == null) return;
    }
    setState(() => _templatesBusy = true);
    final previous = List<Map<String, dynamic>>.from(_savedTemplates);
    try {
      final id = (!saveAs && existingIndex >= 0)
        ? _activeTemplateId!
        : DateTime.now().microsecondsSinceEpoch.toString();
      final record = <String, dynamic>{
        'id': id,
        'name': name ?? _savedTemplates[existingIndex]['name'],
        'updatedAt': DateTime.now().toIso8601String(),
        'design': _serializeDesign(),
      };
      if (!saveAs && existingIndex >= 0) {
        _savedTemplates[existingIndex] = record;
      } else {
        _savedTemplates.insert(0, record);
      }
      await _persistTemplates();
      if (!mounted) return;
      setState(() {
        _activeTemplateId = id;
        _savedFingerprint = _currentFingerprint;
        _baselineFingerprint = _currentFingerprint;
        _observedFingerprint = _currentFingerprint;
        leave_guard.setUnsaved(false);
        _draftTimer?.cancel();
        _draftStatus = 'All changes saved';
        _message = 'Template saved in this browser.';
      });
      final draftKey = _draftStorageKey;
      if (draftKey != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(draftKey);
      }
    } catch (e) {
      _savedTemplates = previous;
      if (mounted) setState(() => _message = 'Template save failed (browser storage may be full): $e');
    } finally {
      if (mounted) setState(() => _templatesBusy = false);
    }
  }

  Future<void> _openTemplate(Map<String, dynamic> template) async {
    if (_templatesBusy || !await _confirmDiscardChanges()) return;
    setState(() => _templatesBusy = true);
    try {
      _loadingDesign = true;
      await _applySavedDesign(Map<String, dynamic>.from(template['design'] as Map));
      if (!mounted) return;
      setState(() {
        _activeTemplateId = template['id'] as String;
        _savedFingerprint = _currentFingerprint;
        _baselineFingerprint = _currentFingerprint;
        _observedFingerprint = _currentFingerprint;
        _draftTimer?.cancel();
        leave_guard.setUnsaved(false);
        _draftStatus = 'All changes saved';
        _message = 'Opened ${template['name']}.';
      });
      final draftKey = _draftStorageKey;
      if (draftKey != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(draftKey);
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'Unable to open template: $e');
    } finally {
      _loadingDesign = false;
      if (mounted) setState(() => _templatesBusy = false);
    }
  }

  Future<void> _renameTemplate(Map<String, dynamic> template) async {
    final name = await _askTemplateName(initial: template['name'] as String);
    if (name == null) return;
    final previous = template['name'];
    template['name'] = name;
    try {
      await _persistTemplates();
      if (mounted) setState(() {});
    } catch (e) {
      template['name'] = previous;
      if (mounted) setState(() => _message = 'Rename failed: $e');
    }
  }

  Future<void> _duplicateTemplate(Map<String, dynamic> template) async {
    final duplicate = <String, dynamic>{
      ...template,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': '${template['name']} (copy)',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _savedTemplates.insert(0, duplicate);
    try {
      await _persistTemplates();
      if (mounted) setState(() {});
    } catch (e) {
      _savedTemplates.remove(duplicate);
      if (mounted) setState(() => _message = 'Duplicate failed: $e');
    }
  }

  Future<void> _deleteTemplate(Map<String, dynamic> template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "${template['name']}" from this browser?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    final previous = List<Map<String, dynamic>>.from(_savedTemplates);
    _savedTemplates.removeWhere((e) => e['id'] == template['id']);
    try {
      await _persistTemplates();
      if (!mounted) return;
      setState(() {
        if (_activeTemplateId == template['id']) {
          _activeTemplateId = null;
          _savedFingerprint = null;
        }
      });
    } catch (e) {
      _savedTemplates = previous;
      if (mounted) setState(() => _message = 'Delete failed: $e');
    }
  }

  Widget _myTemplatesPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.folder_copy_outlined, color: _forest),
            const SizedBox(width: 8),
            const Expanded(child: Text('My Templates', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            if (_templatesLoading || _templatesBusy)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 6),
          const Text('Templates and recovery drafts are stored in this browser for the selected organization. Not synced across devices.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: _libraryReady && !_templatesBusy ? () => _saveTemplate() : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(_activeTemplateId == null ? 'Save template' : 'Save changes'),
            ),
            OutlinedButton.icon(
              onPressed: _libraryReady && !_templatesBusy ? () => _saveTemplate(saveAs: true) : null,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Save as new'),
            ),
          ]),
          if (_libraryReady) ...[
            const SizedBox(height: 8),
            Text(_hasUnsavedTemplateChanges ? '● Unsaved edits — $_draftStatus' : '✓ $_draftStatus',
              style: TextStyle(fontSize: 12, color: _hasUnsavedTemplateChanges ? Colors.deepOrange : _forest)),
          ],
          const Divider(height: 24),
          if (_savedTemplates.isEmpty)
            const Text('No saved templates yet. Design a certificate, then select Save template.')
          else
            ..._savedTemplates.map((template) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(template['id'] == _activeTemplateId ? Icons.description : Icons.article_outlined, color: _forest),
              title: Text(template['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('Updated ${((template['updatedAt'] as String?) ?? '').replaceFirst('T', ' ').split('.').first}'),
              onTap: _templatesBusy ? null : () => _openTemplate(template),
              trailing: PopupMenuButton<String>(
                enabled: !_templatesBusy,
                tooltip: 'Template actions',
                onSelected: (action) {
                  switch (action) {
                    case 'open': _openTemplate(template);
                    case 'rename': _renameTemplate(template);
                    case 'duplicate': _duplicateTemplate(template);
                    case 'delete': _deleteTemplate(template);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'open', child: Text('Open')),
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            )),
        ]),
      ),
    );
  }

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
  String? _selectedImageId;
  bool _layersExpanded = false;
  bool _templateExpanded = false;
  bool _formatExpanded = false;
  Map<String, dynamic>? _copiedObject;
  int _pasteCount = 0;
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
    for (final layer in _layers) { _lastTextValues[layer.id] = layer.text.text; }
    _loadKaisaLogo();
    _loadOrganizations();
  }

  Future<void> _loadKaisaLogo() async {
    try {
      final data = await rootBundle.load('assets/images/kaisa_logo.png');
      if (mounted) setState(() => _kaisaLogoBytes = data.buffer.asUint8List());
    } catch (_) {
      if (mounted) {
        setState(() => _message =
          'KAISA logo asset missing. Add kaisa_logo.png to assets/images/.');
      }
    }
  }

  Map<String, dynamic> _snapshot() => {
    'zOrder': List<String>.from(_zOrder),
    'design': _design, 'background': _background,
    'backgroundName': _backgroundName, 'selectedId': _selectedId,
    'selectedImageId': _selectedImageId,
    'showLogo': _showKaisaLogo, 'showBorder': _showKaisaBorder,
    'logoX': _kaisaLogoX, 'logoY': _kaisaLogoY,
    'logoWidth': _kaisaLogoWidth,
    'layers': _layers.map((e) => {
      'id': e.id, 'label': e.label, 'text': e.text.text,
      'x': e.x, 'y': e.y, 'size': e.size, 'font': e.font,
      'color': e.color, 'bold': e.bold, 'visible': e.visible,
      'align': e.align,
    }).toList(),
    'logos': _logos.map((e) => {
      'id': e.id, 'name': e.name, 'bytes': e.bytes,
      'visible': e.visible, 'x': e.x, 'y': e.y, 'width': e.width,
    }).toList(),
  };

  void _checkpoint() {
    if (_restoring) return;
    _undoStack.add(_snapshot());
    if (_undoStack.length > 80) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _restore(Map<String, dynamic> data) {
    _restoring = true;
    for (final layer in _layers) {
      layer.text.removeListener(_refresh);
      layer.text.dispose();
    }
    _layers.clear();
    for (final item in (data['layers'] as List)) {
      final v = Map<String, dynamic>.from(item as Map);
      final layer = _TextLayer(
        v['id'] as String, v['label'] as String,
        TextEditingController(text: v['text'] as String),
        x: v['x'] as double, y: v['y'] as double,
        size: v['size'] as double, color: v['color'] as Color,
        bold: v['bold'] as bool,
      );
      layer.font = v['font'] as String;
      layer.visible = v['visible'] as bool;
      layer.align = v['align'] as TextAlign;
      layer.text.addListener(_refresh);
      _layers.add(layer);
    }
    _logos.clear();
    for (final item in (data['logos'] as List)) {
      final v = Map<String, dynamic>.from(item as Map);
      final logo = _LogoLayer(
        id: v['id'] as String, name: v['name'] as String,
        bytes: v['bytes'] as Uint8List, x: v['x'] as double,
      );
      logo.y = v['y'] as double;
      logo.width = v['width'] as double;
      logo.visible = v['visible'] as bool;
      _logos.add(logo);
    }
    _zOrder..clear()..addAll((data['zOrder'] as List?)?.cast<String>() ?? ['kaisa_default', ..._layers.map((e) => e.id), ..._logos.map((e) => e.id)]);
    _design = data['design'] as int;
    _background = data['background'] as Uint8List?;
    _backgroundName = data['backgroundName'] as String?;
    _showKaisaLogo = data['showLogo'] as bool;
    _showKaisaBorder = data['showBorder'] as bool;
    _kaisaLogoX = data['logoX'] as double;
    _kaisaLogoY = data['logoY'] as double;
    _kaisaLogoWidth = (data['logoWidth'] as num)
    .toDouble()
    .clamp(0.05, 0.40)
    .toDouble();
    final selected = data['selectedId'] as String;
        _selectedId = _layers.any((e) => e.id == selected)
        ? selected : _layers.first.id;
    final imageId = data['selectedImageId'] as String?;
    _selectedImageId = imageId != null &&
        (imageId == 'kaisa_default' || _logos.any((e) => e.id == imageId))
        ? imageId : null;
    _lastTextValues..clear()..addEntries(
      _layers.map((e) => MapEntry(e.id, e.text.text)));
    _editingId = null;
    _restoring = false;
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_snapshot());
    _restore(previous);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_snapshot());
    _restore(next);
  }

  void _refresh() {
    if (_restoring) return;
    for (final layer in _layers) {
      final old = _lastTextValues[layer.id];
      if (old != null && old != layer.text.text) {
        final previous = _snapshot();
        final items = previous['layers'] as List;
        final entry = items.cast<Map<String, dynamic>>()
            .firstWhere((e) => e['id'] == layer.id);
        entry['text'] = old;
        _undoStack.add(previous);
        if (_undoStack.length > 80) _undoStack.removeAt(0);
        _redoStack.clear();
      }
      _lastTextValues[layer.id] = layer.text.text;
    }
    if (mounted) setState(() {});
  }

  String _longDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May',
      'June', 'July', 'August', 'September', 'October',
      'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      if (selected != null) {
        await _loadTemplateLibrary();
        await _loadEvents();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingOrganizations = false;
          _dataError = 'Unable to load managed organizations: $error';
        });
      }
    }
  }

  Future<void> _changeOrganization(String? id) async {
    if (id == null || id == _organizationId) return;
    if (!await _confirmDiscardChanges()) return;
    _draftTimer?.cancel();
    leave_guard.setUnsaved(false);
    _libraryReady = false;
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
    await _loadTemplateLibrary();
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
      if (mounted && _organizationId == orgId) {
        setState(() {
          _loadingEvents = false;
          _dataError = 'Unable to load organization events: $error';
        });
      }
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
              _longDate(date);
        }
        _updateSelectedNames();
      });
    } catch (error) {
      if (mounted && _eventId == eventId) {
        setState(() {
          _loadingAttendees = false;
          _dataError = 'Unable to load verified event attendance: $error';
        });
      }
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
    _draftTimer?.cancel();
    leave_guard.setUnsaved(false);
    _names.removeListener(_onNamesChange);
    _names.dispose();
    for (final layer in _layers) {
      layer.text.removeListener(_refresh);
      layer.text.dispose();
    }
    _editorFocus.dispose();
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
      _checkpoint();
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
      _checkpoint();
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
        if (mounted) {
          setState(() => _message = 'Choose a .ttf font under 3 MB.');
        }
        return false;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > _maxFont) {
        if (mounted) {
          setState(() => _message = 'Choose a .ttf font under 3 MB.');
        }
        return false;
      }
      if (bytes.length < 4 ||
          bytes[0] != 0 ||
          bytes[1] != 1 ||
          bytes[2] != 0 ||
          bytes[3] != 0) {
        if (mounted) {
          setState(
            () => _message =
                'Use a TrueType .ttf font; OpenType .otf files are not supported here.',
          );
        }
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

  static const Map<String, String> _bundledFonts = {
    'Great Vibes': 'assets/fonts/GreatVibes-Regular.ttf',
    'Times New Roman': 'assets/fonts/times.ttf',
    'Montserrat Black': 'assets/fonts/Montserrat-Black.ttf',
    'Montserrat Thin': 'assets/fonts/Montserrat-Thin.ttf',
    'Montserrat Thin Italic': 'assets/fonts/Montserrat-ThinItalic.ttf',
  };

  static const Map<String, String> _bundledFamilies = {
    'Great Vibes': 'GreatVibes',
    'Times New Roman': 'TimesNewRoman',
    'Montserrat Black': 'MontserratBlack',
    'Montserrat Thin': 'MontserratThin',
    'Montserrat Thin Italic': 'MontserratThinItalic',
  };

  

  Future<bool> _loadBundledFont(String name) async {
    if (_namedFontBytes.containsKey(name)) return true;
    final path = _bundledFonts[name];
    if (path == null) return false;
    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (!mounted) return false;
      setState(() {
        _namedFontBytes[name] = bytes;
        _namedFontFamilies[name] = _bundledFamilies[name]!;
        _message = null;
      });
      return true;
    } catch (error) {
      if (mounted) setState(() => _message = 'Missing bundled font $path: $error');
      return false;
    }
  }

  Future<void> _selectFont(String fontName) async {
  if (_bundledFonts.containsKey(fontName)) {
    final loaded = await _loadBundledFont(fontName);

    if (!loaded || !mounted) return;
  }

  _checkpoint();

  setState(() {
    _selected.font = fontName;
    _selected.bold = false;
    _message = null;
  });
}

  Future<void> _toggleSelectedBold() async {
    final layer = _selected;
    if (_bundledFonts.containsKey(layer.font)) {
      setState(() => _message = 'This bundled font uses its own fixed weight.');
      return;
    }
    if (layer.font == 'TeX Gyre Termes' && !layer.bold) {
      final ok = await _loadNamedFont('TeX Gyre Termes', boldFace: true);
      if (!ok || !mounted) return;
    }
    _checkpoint();
    if (mounted) setState(() => layer.bold = !layer.bold);
  }

  TextStyle _previewStyle(_TextLayer e, double scale) {
  final String? family = switch (e.font) {
    'Great Vibes' => 'GreatVibes',
    'Times New Roman' => 'TimesNewRoman',
    'Serif' || 'Serif Italic' => 'serif',
    'Mono' || 'Mono Bold' => 'monospace',
    'Custom' => _customFontFamily,
    _ => null,
  };

  return TextStyle(
    fontFamily: family,
    fontSize: e.size * scale,
    fontWeight: e.bold ||
            e.font == 'Sans Bold' ||
            e.font == 'Mono Bold'
        ? FontWeight.bold
        : FontWeight.normal,
    fontStyle: e.font == 'Serif Italic'
        ? FontStyle.italic
        : FontStyle.normal,
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
  if (_bundledFonts.containsKey(e.font)) {
    return named[e.font] ?? pw.Font.helvetica();
  }

  if (e.font == 'Custom' && custom != null) {
    return custom;
  }

  if (e.font == 'Serif' || e.font == 'Serif Italic') {
    if (e.font == 'Serif Italic') {
      return bold
          ? pw.Font.timesBoldItalic()
          : pw.Font.timesItalic();
    }

    return bold ? pw.Font.timesBold() : pw.Font.times();
  }

  if (e.font == 'Mono' || e.font == 'Mono Bold') {
    return bold || e.font == 'Mono Bold'
        ? pw.Font.courierBold()
        : pw.Font.courier();
  }

  if (e.font == 'Sans Bold') {
    return pw.Font.helveticaBold();
  }

  return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
}

    // Object clipboard is separate from native clipboard inside editable text fields.
  // TextField / EditableText keeps its own Ctrl+C / Ctrl+V behavior.
  bool get _editingTextField {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null && context.findAncestorStateOfType<EditableTextState>() != null;
  }

  void _selectTextLayer(String id) {
    setState(() {
      _selectedId = id;
      _selectedImageId = null;
    });
  }

  void _selectImageLayer(String id) {
    setState(() {
      _selectedImageId = id;
      _editingId = null;
      _layersExpanded = true;
    });
  }

  void _copySelectedObject() {
    if (_editingTextField) return;
    if (_selectedImageId == 'kaisa_default') {
      if (_kaisaLogoBytes == null) return;
      _copiedObject = {
        'type': 'image', 'name': 'KAISA logo', 'bytes': _kaisaLogoBytes!,
        'x': _kaisaLogoX, 'y': _kaisaLogoY, 'width': _kaisaLogoWidth,
      };
    } else if (_selectedImageId != null) {
      final matches = _logos.where((e) => e.id == _selectedImageId);
      if (matches.isEmpty) return;
      final logo = matches.first;
      _copiedObject = {
        'type': 'image', 'name': logo.name, 'bytes': logo.bytes,
        'x': logo.x, 'y': logo.y, 'width': logo.width,
      };
    } else {
      final matches = _layers.where((e) => e.id == _selectedId);
      if (matches.isEmpty) return;
      final layer = matches.first;
      _copiedObject = {
        'type': 'text', 'label': layer.label, 'text': layer.text.text,
        'x': layer.x, 'y': layer.y, 'size': layer.size,
        'font': layer.font, 'color': layer.color, 'bold': layer.bold,
        'align': layer.align,
      };
    }
    _pasteCount = 0;
  }

  void _pasteCopiedObject() {
    if (_editingTextField || _copiedObject == null) return;
    _checkpoint();
    final copied = _copiedObject!;
    _pasteCount++;
    final offset = .025 * ((_pasteCount - 1) % 5 + 1);
    if (copied['type'] == 'image') {
      final width = copied['width'] as double;
      final logo = _LogoLayer(
        id: 'logo_${_nextLogoId++}',
        name: '${copied['name']} (copy)',
        bytes: copied['bytes'] as Uint8List,
        x: ((copied['x'] as double) + offset).clamp(0.0, 1.0 - width),
      );
      logo.y = ((copied['y'] as double) + offset).clamp(0.0, .95);
      logo.width = width;
      setState(() {
        _logos.add(logo);
        _zOrder.add(logo.id);
        _selectedImageId = logo.id;
        _layersExpanded = true;
      });
    } else {
      final id = 'extra_${_nextLayerId++}';
      final layer = _TextLayer(
        id, '${copied['label']} (copy)',
        TextEditingController(text: copied['text'] as String),
        x: ((copied['x'] as double) + offset).clamp(.17, .83),
        y: ((copied['y'] as double) + offset).clamp(0.0, .96),
        size: copied['size'] as double,
        color: copied['color'] as Color,
        bold: copied['bold'] as bool,
      );
      layer.font = copied['font'] as String;
      layer.align = copied['align'] as TextAlign;
      layer.text.addListener(_refresh);
      _lastTextValues[id] = layer.text.text;
      setState(() {
        _layers.add(layer);
        _zOrder.add(layer.id);
        _selectedId = id;
        _selectedImageId = null;
        _layersExpanded = true;
      });
    }
  }

  void _removeSelectedObject() {
    if (_selectedImageId == 'kaisa_default') {
      _checkpoint();
      setState(() { _showKaisaLogo = false; _selectedImageId = null; });
    } else if (_selectedImageId != null) {
      _checkpoint();
      setState(() {
        _logos.removeWhere((e) => e.id == _selectedImageId);
        _zOrder.remove(_selectedImageId);
        _selectedImageId = null;
      });
    } else {
      _removeSelectedLayer();
    }
  }

  Widget _layerNavigator() {
  return Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      
      initiallyExpanded: _layersExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _layersExpanded = expanded;
        });
      },
      leading: const Icon(Icons.layers_outlined),
      title: const Text(
        'Layers',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_layers.length} text · '
        '${_logos.length + (_showKaisaLogo ? 1 : 0)} images',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addTextLayer,
                  icon: const Icon(Icons.add),
                  label: const Text('Add text'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addLogo,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add image'),
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Drag the handle to change stacking order '
            '(top = in front).',
          ),
        ),

        const SizedBox(height: 8),

        // Custom drag/drop avoids the ReorderableListView runtime type error.
        SizedBox(
          height: (_zOrder.length * 56.0).clamp(56.0, 320.0).toDouble(),
          child: ListView.builder(
            itemCount: _zOrder.length,
            itemBuilder: (context, index) {
              final id = _zOrder[_zOrder.length - 1 - index];
              final textLayer = _textFor(id);
              final imageLayer = _imageFor(id);
              final isText = textLayer != null;
              final label = textLayer?.label ??
                  (imageLayer?.name ?? 'KAISA Logo');
              final selected = isText
                  ? _selectedImageId == null && _selectedId == id
                  : _selectedImageId == id;

              void selectLayer() {
                if (isText) {
                  _selectTextLayer(id);
                } else {
                  _selectImageLayer(id);
                }
              }

              return DragTarget<String>(
                onWillAcceptWithDetails: (details) => details.data != id,
                onAcceptWithDetails: (details) {
                  final oldIndex = _zOrder.reversed.toList().indexOf(details.data);
                  if (oldIndex < 0 || oldIndex == index) return;
                  // _reorderLayer expects Flutter's insertion index semantics.
                  _reorderLayer(oldIndex, oldIndex < index ? index + 1 : index);
                },
                builder: (context, candidates, rejected) {
                  return Container(
                    key: ValueKey(id),
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? _forest.withValues(alpha: 0.10)
                          : null,
                      border: candidates.isNotEmpty
                          ? Border.all(color: _forest)
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      selected: selected,
                      onTap: selectLayer,
                      leading: Draggable<String>(
                        data: id,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.drag_indicator),
                              const SizedBox(width: 8),
                              Text(label),
                            ]),
                          ),
                        ),
                        childWhenDragging: const Icon(
                          Icons.drag_indicator, color: Colors.grey),
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(Icons.drag_indicator),
                        ),
                      ),
                      title: Text(label,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Icon(isText
                          ? Icons.text_fields : Icons.image_outlined),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeSelectedObject,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove selected'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy selected',
                onPressed: _copySelectedObject,
                icon: const Icon(Icons.copy_outlined),
              ),
              IconButton(
                tooltip: 'Paste object',
                onPressed: _copiedObject == null
                    ? null
                    : _pasteCopiedObject,
                icon: const Icon(Icons.content_paste_outlined),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  void _addTextLayer() {
    _checkpoint();
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
    _lastTextValues[id] = layer.text.text;
    setState(() {
      _layers.add(layer);
      _zOrder.add(id);
            _selectedId = id;
      _selectedImageId = null;
      _layersExpanded = true;
    });
  }

  void _removeSelectedLayer() {
    final index = _layers.indexWhere((layer) => layer.id == _selectedId);
    if (index < 0 || _layers.length <= 1) return;
    _checkpoint();
    final layer = _layers.removeAt(index);
    _zOrder.remove(layer.id);
    layer.text.removeListener(_refresh);
    layer.text.dispose();
    _lastTextValues.remove(layer.id);
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
      if (mounted) {
        _checkpoint();
        setState(
                    () {
            final id = 'logo_${_nextLogoId++}';
            _zOrder.add(id);
            _logos.add(_LogoLayer(
              id: id,
              name: file.name,
              bytes: bytes,
                            x: .12 + (_logos.length % 3) * .2,
            ));
            _selectedImageId = id;
            _layersExpanded = true;
          },
        );
      }
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
              _checkpoint();
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
    _checkpoint();
    setState(() {
      _design = design;
      _background = null;
      _backgroundName = null;
    });
  }

  pw.Widget _pdfDecoration() {
    if (!_showKaisaBorder) return pw.Container(color: PdfColors.white);
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

    for (final fontName in _layers.map((layer) => layer.font).toSet()) {
      if (_bundledFonts.containsKey(fontName)) {
        if (!await _loadBundledFont(fontName)) {
          throw StateError('Unable to load bundled font: $fontName');
        }
      }
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
              // Background image or built-in template, then optional KAISA frame.
              if (bg != null)
                pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.fill))
              else
                pw.Positioned.fill(child: _pdfDecoration()),
              if (_showKaisaBorder) ...[
                pw.Positioned(
                  left: 22, right: 22, top: 22, bottom: 22,
                  child: pw.Container(decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#176B43'), width: 4),
                  )),
                ),
                pw.Positioned(
                  left: 31, right: 31, top: 31, bottom: 31,
                  child: pw.Container(decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#E4B746'), width: 1.5),
                  )),
                ),
              ],
              for (final id in _zOrder) ...[
                if (id == 'kaisa_default' && _showKaisaLogo && _kaisaLogoBytes != null)
                  pw.Positioned(
                    left: _kaisaLogoX * _pageWidth,
                    top: _kaisaLogoY * _pageHeight,
                    child: pw.SizedBox(
                      width: _kaisaLogoWidth * _pageWidth,
                      child: pw.Image(pw.MemoryImage(_kaisaLogoBytes!), fit: pw.BoxFit.contain),
                    ),
                  ),
                if (_imageFor(id) case final logo? when logo.visible)
                  pw.Positioned(
                    left: logo.x * _pageWidth,
                    top: logo.y * _pageHeight,
                    child: pw.SizedBox(
                      width: logo.width * _pageWidth,
                      child: pw.Image(pw.MemoryImage(logo.bytes), fit: pw.BoxFit.contain),
                    ),
                  ),
                if (_textFor(id) case final layer? when layer.visible)
                  pw.Positioned(
                    left: layer.x * _pageWidth - _pageWidth * _layerWidth(layer) / 2,
                    top: layer.y * _pageHeight,
                    child: pw.SizedBox(
                      width: _pageWidth * _layerWidth(layer),
                      child: pw.Text(
                        _displayText(layer, name),
                        maxLines: layer.id == 'description' ? 5 : 3,
                        textAlign: switch (layer.align) {
                          TextAlign.left => pw.TextAlign.left,
                          TextAlign.right => pw.TextAlign.right,
                          _ => pw.TextAlign.center,
                        },
                        style: pw.TextStyle(
                          font: _pdfFont(layer, bold: layer.bold, custom: customFont, named: namedPdfFonts),
                          fontSize: layer.size,
                          color: _pdfColor(layer.color),
                          lineSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
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

  void _editOnCanvas(_TextLayer layer) {
        setState(() { _selectedId = layer.id; _selectedImageId = null; _editingId = layer.id; });
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
                   decoration: BoxDecoration(
                     color: Colors.white,
                     image: _background == null ? null : DecorationImage(
                       image: MemoryImage(_background!), fit: BoxFit.fill),
                   ),
                   child: _showKaisaBorder ? Stack(children: [
                     Positioned.fill(child: Container(
                       margin: EdgeInsets.all(22 * scale),
                       decoration: BoxDecoration(border: Border.all(
                         color: _forest, width: 4 * scale)),
                     )),
                     Positioned.fill(child: Container(
                       margin: EdgeInsets.all(31 * scale),
                       decoration: BoxDecoration(border: Border.all(
                         color: _gold, width: 1.5 * scale)),
                     )),
                   ]) : null,
                 ),
               ),
              for (final id in _zOrder) ...[
               if (id == 'kaisa_default' && _showKaisaLogo && _kaisaLogoBytes != null)
                 Positioned(
                   left: _kaisaLogoX * w, top: _kaisaLogoY * h,
                   width: _kaisaLogoWidth * w,
                   child: GestureDetector(
                                           onTap: () => _selectImageLayer('kaisa_default'),
                      onPanStart: (_) { _checkpoint(); _selectImageLayer('kaisa_default'); },
                      onPanUpdate: (details) => setState(() {
                        _kaisaLogoX = (_kaisaLogoX + details.delta.dx / w)
                           .clamp(0.0, 1 - _kaisaLogoWidth);
                       _kaisaLogoY = (_kaisaLogoY + details.delta.dy / h)
                           .clamp(0.0, .95);
                     }),
                                           child: Container(
                        decoration: BoxDecoration(border: _selectedImageId == 'kaisa_default'
                          ? Border.all(color: _forest, width: 2) : null),
                        child: Image.memory(_kaisaLogoBytes!, fit: BoxFit.contain),
                      ),
                   ),
                 ),
// Uploaded image layers sit above the template, below text.
              if (_imageFor(id) case final logo? when logo.visible)
  Positioned(
                  left: logo.x * w,
                  top: logo.y * h,
                  width: logo.width * w,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                                         onTap: () => _selectImageLayer(logo.id),
                     onPanStart: (_) { _checkpoint(); _selectImageLayer(logo.id); },
                     onPanUpdate: (details) => setState(() {
                       logo.x = (logo.x + details.delta.dx / w).clamp(
                        0.0,
                        1.0 - logo.width,
                      );
                      logo.y = (logo.y + details.delta.dy / h).clamp(0.0, 0.95);
                    }),
                                         child: Container(
                       decoration: BoxDecoration(border: _selectedImageId == logo.id
                         ? Border.all(color: _forest, width: 2) : null),
                       child: Image.memory(
                         logo.bytes,
                         fit: BoxFit.contain,
                         gaplessPlayback: true,
                       ),
                     ),
                  ),
                ),
                if (_textFor(id) case final layer? when layer.visible)
  Positioned(
                  left: (layer.x - _layerWidth(layer) / 2) * w,
                  top: layer.y * h,
                  width: _layerWidth(layer) * w,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectTextLayer(layer.id),
                    onPanStart: (_) { _checkpoint(); _selectTextLayer(layer.id); },
                    onDoubleTap: () => _editOnCanvas(layer),
                    onPanUpdate: (details) => setState(() {
                      layer.x = (layer.x + details.delta.dx / w).clamp(
                        _layerWidth(layer) / 2,
                        1 - _layerWidth(layer) / 2,
                      );
                      layer.y = (layer.y + details.delta.dy / h).clamp(0, .96);
                    }),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 3 * scale),
                      decoration: BoxDecoration(
  color: Colors.transparent,
  border: _selectedImageId == null && layer.id == _selectedId
      ? Border.all(
          color: _forest.withValues(alpha: 0.65),
          width: 1,
        )
      : null,
),
                      child: _editingId == layer.id
                          ? TextField(
                              controller: layer.text, autofocus: true,
                              minLines: 1, maxLines: layer.id == 'description' ? 5 : 3,
                              textAlign: layer.align,
                              style: _previewStyle(layer, scale),
                              decoration: const InputDecoration(
                                isDense: true, border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(4)),
                              onSubmitted: (_) => setState(() => _editingId = null),
                              onTapOutside: (_) => setState(() => _editingId = null),
                            )
                          : Text(
                        _displayText(layer, _sampleName),
                        textAlign: layer.align,
                        maxLines: layer.id == 'description' ? 5 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: _previewStyle(layer, scale),
                      ),
                    ),
                  ),
                ),
              ],
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
  'Times New Roman',
  if (_customFontBytes != null) 'Custom',
];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: const PageStorageKey('certificate_template'),
            initiallyExpanded: _templateExpanded,
            onExpansionChanged: (value) => _templateExpanded = value,
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: const Text('Template', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Design, border, logo and background'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
         SwitchListTile.adaptive(
           title: const Text('Show default KAISA logo'),
           value: _showKaisaLogo,
           onChanged: (value) { _checkpoint(); setState(() => _showKaisaLogo = value); },
         ),
         SwitchListTile.adaptive(
           title: const Text('Show KAISA green-and-gold border'),
           value: _showKaisaBorder,
           onChanged: (value) { _checkpoint(); setState(() => _showKaisaBorder = value); },
         ),
         if (_showKaisaLogo) ...[
           const Text('KAISA logo size'),
           Slider(
  value: _kaisaLogoWidth.clamp(0.05, 0.40).toDouble(),
  min: 0.05,
  max: 0.40,
  onChangeStart: (_) => _checkpoint(),
  onChanged: (value) {
    setState(() {
      _kaisaLogoWidth = value;
      _kaisaLogoX = _kaisaLogoX
          .clamp(0.0, 1.0 - value)
          .toDouble();
    });
  },
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
            onPressed: () { _checkpoint(); setState(() {
              _background = null;
              _backgroundName = null;
            }); },
            child: const Text('Use simple built-in border'),
          ),
                                   ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
         _layerNavigator(),
         const SizedBox(height: 12),
         if (_selectedImageId != null) ...[
           Text('Selected image', style: Theme.of(context).textTheme.titleMedium),
           const SizedBox(height: 8),
           const Text('Drag the image on the canvas to move it. Use Layers to hide or remove it.'),
           const SizedBox(height: 10),
           const Text('Image size'),
           Slider(
  value: (_selectedImageId == 'kaisa_default'
          ? _kaisaLogoWidth
          : _logos.firstWhere(
              (logo) => logo.id == _selectedImageId,
            ).width)
      .clamp(0.05, 0.40)
      .toDouble(),
  min: 0.05,
  max: 0.40,
  onChangeStart: (_) => _checkpoint(),
  onChanged: (value) {
    setState(() {
      if (_selectedImageId == 'kaisa_default') {
        _kaisaLogoWidth = value;
        _kaisaLogoX = _kaisaLogoX
            .clamp(0.0, 1.0 - value)
            .toDouble();
      } else {
        final logo = _logos.firstWhere(
          (logo) => logo.id == _selectedImageId,
        );

        logo.width = value;
        logo.x = logo.x
            .clamp(0.0, 1.0 - value)
            .toDouble();
      }
    });
  },
),
         ] else ...[
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('label_${e.id}'),
          initialValue: e.label,
          decoration: const InputDecoration(labelText: 'Layer name'),
          onChanged: (value) { _checkpoint(); setState(() => e.label = value); },
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
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: const PageStorageKey('certificate_format'),
            initiallyExpanded: _formatExpanded,
            onExpansionChanged: (value) => _formatExpanded = value,
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Text formatting & position',
              style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${e.font} · ${e.size.toStringAsFixed(0)} pt'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
        Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    DropdownButtonFormField<String>(
      key: ValueKey('font_${e.id}_${e.font}'),
      initialValue: e.font,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Font',
        border: OutlineInputBorder(),
      ),
      items: availableFonts.map((f) {
        return DropdownMenuItem<String>(
          value: f,
          child: Text(
            f == 'Custom' ? 'Uploaded font' : f,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (f) {
        if (f != null) _selectFont(f);
      },
    ),

    const SizedBox(height: 10),

    OutlinedButton.icon(
      onPressed: _pickFont,
      icon: const Icon(Icons.font_download_outlined),
      label: const Text('Upload .ttf'),
    ),
  ],
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
              onPressed: _bundledFonts.containsKey(e.font) ? null : _toggleSelectedBold,
              tooltip: _bundledFonts.containsKey(e.font)
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
          onChangeStart: (_) => _checkpoint(),
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
          onSelectionChanged: (value) { _checkpoint(); setState(() => e.align = value.first); },
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
                onTap: () { _checkpoint(); setState(() => e.color = c); },
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
                value: e.x.clamp(0.0, 1.0).toDouble(),
                min: 0.0,
                max: 1.0,
                onChangeStart: (_) => _checkpoint(),
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
                onChangeStart: (_) => _checkpoint(),
                 onChanged: (v) => setState(() => e.y = v),
              ),
            ),
          ], // Row children
        ), // Vertical slider Row
              ], // Formatting Column children
            ), // Formatting Column
          ), // Padding
        ], // ExpansionTile children
        ), // ExpansionTile
        ), // Card
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
         ], // Text controls else spread
      ], // Control panel Column children
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
                     IconButton(
             tooltip: 'Undo (Ctrl+Z)',
             onPressed: _undoStack.isEmpty ? null : _undo,
             icon: const Icon(Icons.undo),
           ),
           IconButton(
             tooltip: 'Redo (Ctrl+Y / Ctrl+Shift+Z)',
             onPressed: _redoStack.isEmpty ? null : _redo,
             icon: const Icon(Icons.redo),
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
        'Click to select, double-click to edit text on the canvas, or drag to move. Ctrl+C: copy layer; Ctrl+V: paste layer; Ctrl+Z: undo; Ctrl+Y: redo.',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleDraftIfChanged();
    });
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    return PopScope(
      canPop: _allowRouteExit || !_hasUncommittedEdits,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmRouteExit();
      },
      child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
                 const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _redo,
         const SingleActivator(LogicalKeyboardKey.keyC, control: true): _copySelectedObject,
         const SingleActivator(LogicalKeyboardKey.keyV, control: true): _pasteCopiedObject,
      },
      child: Focus(
      focusNode: _editorFocus,
      autofocus: true,
      child: Scaffold(
      // No app bar: the Organization Admin shell owns the shared header.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1700),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KAISA · ORGANIZATION TOOLS · VERIFIED ATTENDANCE',
                      style: TextStyle(color: _forest, fontSize: 12,
                        fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Make it yours.',
                      style: TextStyle(color: Color(0xFF173F2E), fontSize: 29,
                        fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Upload a design, drag text, choose fonts, and print certificates for every attendee.',
                      style: TextStyle(color: Color(0xFF5E7869))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _supabasePanel(),
              const SizedBox(height: 16),
              _myTemplatesPanel(),
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
      ),
      ),
      ),
    );
  }
}
