// Web-only browser close/refresh warning. Browsers display their own message.
import 'dart:html' as html;

bool _installed = false;
bool _unsaved = false;

void setUnsaved(bool unsaved) {
  _unsaved = unsaved;
  if (_installed) return;
  _installed = true;
  html.window.onBeforeUnload.listen((event) {
    if (!_unsaved) return;
    event.preventDefault();
    (event as html.BeforeUnloadEvent).returnValue = '';
  });
}
