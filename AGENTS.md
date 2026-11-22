# Agent instructions

To install or modify this plugin, follow [AI-INSTALL.md](AI-INSTALL.md).

Rules for changes to this repo:

- `Schemes.js` and `docs/themes.*` are generated. Edit `schemes.json`, then run `python3 tools/gen.py`.
- Do not name a QML property `opacity`, `visible`, `scale`, `width`, `height`, or any other
  `Item` property in `Engine.qml`; it fails with "Cannot override FINAL property".
- Keep the IPC target `endo-loading-bar` and the plugin id `endo-loading-bar` in sync with
  `manifest.json`, `bin/endo-bar` and the docs.
- Run `omarchy plugin validate .` before committing.
- The shell caches plugin QML by path: after a QML fix, `omarchy restart shell` before retesting.
