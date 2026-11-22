import QtQuick
import Quickshell
import Quickshell.Io
import "Schemes.js" as Schemes

// Endo Loading Bar: a hairline progress strip on the bottom edge of every screen.
//
// Control it from a terminal or script (target `endo-loading-bar`):
//   omarchy-shell endo-loading-bar set 40      show the bar at 40%
//   omarchy-shell endo-loading-bar done        finish, hold, fade out
//   omarchy-shell endo-loading-bar demo        looping demo
//   omarchy-shell endo-loading-bar hide        hide immediately
//   omarchy-shell endo-loading-bar scheme nord force a scheme ("auto" follows the theme)
//   omarchy-shell endo-loading-bar height 3    bar height in px
//   omarchy-shell endo-loading-bar status
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/current"
  property string themeSlug: ""
  property string forcedScheme: ""
  property string colorsText: ""
  property string activeName: ""

  Engine { id: eng }

  // ---- theme following -------------------------------------------------------
  function applyScheme(snap) {
    var key = forcedScheme !== "" ? forcedScheme : themeSlug
    var s = Schemes.SCHEMES[key]
    if (s) {
      activeName = s.name
    } else if (colorsText !== "") {
      s = Schemes.deriveScheme(Schemes.parseColors(colorsText))
      activeName = "Derived from " + (themeSlug || "theme")
    } else {
      s = Schemes.SCHEMES["tokyo-night"]
      activeName = "Tokyo Night (fallback)"
    }
    eng.setScheme(s, snap)
  }

  function refreshTheme() {
    nameFile.reload()
    colorsFile.reload()
  }

  FileView {
    id: nameFile
    path: root.stateDir + "/theme.name"
    watchChanges: false
    printErrors: false
    onLoaded: {
      root.themeSlug = Schemes.slug(text())
      root.applyScheme(false)
    }
  }
  FileView {
    id: colorsFile
    path: root.stateDir + "/theme/colors.toml"
    watchChanges: false
    printErrors: false
    onLoaded: {
      root.colorsText = text()
      root.applyScheme(false)
    }
  }
  // Omarchy bumps theme.generation on every theme change; watch it to follow along.
  FileView {
    id: generationFile
    path: root.stateDir + "/theme.generation"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshTheme()
  }
  FileView {
    id: nameWatch
    path: root.stateDir + "/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshTheme()
  }

  Component.onCompleted: {
    eng.setScheme(Schemes.SCHEMES["tokyo-night"], true)
    refreshTheme()
  }

  // ---- one strip per screen -----------------------------------------------------
  Variants {
    model: Quickshell.screens
    delegate: Component {
      BarWindow {
        required property var modelData
        screen: modelData
        engine: eng
      }
    }
  }

  // ---- control surface ------------------------------------------------------------
  IpcHandler {
    target: "endo-loading-bar"

    function set(percent: real): void {
      var v = Math.max(0, Math.min(100, percent)) / 100
      if (eng.mode !== "progress") eng.begin("progress")
      eng.target = v
    }
    function done(): void {
      if (eng.mode === "idle") eng.begin("progress")
      eng.mode = "done"
    }
    function demo(): void { eng.begin("demo") }
    function hide(): void { eng.stop() }
    function scheme(name: string): void {
      root.forcedScheme = (name === "auto" || name === "") ? "" : Schemes.slug(name)
      root.applyScheme(false)
    }
    function height(px: int): void { eng.barHeight = Math.max(1, Math.min(12, px)) }
    function schemes(): string { return Object.keys(Schemes.SCHEMES).join(" ") }
    function status(): string {
      return eng.mode + " " + Math.round(eng.progress * 100) + "% · scheme: " + root.activeName +
             (root.forcedScheme !== "" ? " (forced)" : "")
    }
  }
}
