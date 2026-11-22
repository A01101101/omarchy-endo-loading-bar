import QtQuick
import "Schemes.js" as Schemes

// Animation state shared by every screen's bar window. One Timer ticks only while
// the bar is showing; each window repaints its Canvas on `frame`.
Item {
  id: root

  // ---- state read by the windows -------------------------------------------
  property bool active: false
  property string mode: "idle"     // idle | demo | progress | done
  property real progress: 0        // displayed fill, 0..1
  property real target: 0          // reported progress, 0..1
  property real barAlpha: 1
  property real now: 0             // seconds
  property real glow: 0            // slow breathing, 0..1
  property var pulses: []          // start times of light waves in flight
  property int barHeight: 2
  property var cur: Schemes.rgbScheme(Schemes.SCHEMES["tokyo-night"])
  property var tgt: Schemes.rgbScheme(Schemes.SCHEMES["tokyo-night"])
  signal frame()

  // ---- tuning ----------------------------------------------------------------
  readonly property real hold: 1.0           // seconds at 100% before fading
  readonly property real fade: 0.6           // fade-out seconds
  readonly property real travel: 6.0         // seconds for a wave to reach the head
  readonly property real travel2: 10.0       // slower second layer
  readonly property real gap: 3.0            // seconds between waves
  readonly property real waveWidth: 0.34     // fraction of the bar
  readonly property real breathHz: 0.12
  readonly property real driftHz: 0.04
  readonly property real ripple: 0.12
  property real demoSeconds: 8

  property real finishedAt: -1
  property real demoStart: 0
  property real lastSpawn: -10
  property real lastTick: 0

  function easeInOut(t) { return t * t * (3 - 2 * t) }

  // Apply a hex scheme object. The first one snaps; later ones crossfade.
  function setScheme(s, snap) {
    tgt = Schemes.rgbScheme(s)
    if (snap) {
      var copy = {}
      for (var i = 0; i < Schemes.KEYS.length; i++) {
        var k = Schemes.KEYS[i]
        copy[k] = tgt[k].slice()
      }
      cur = copy
    }
  }

  function begin(newMode) {
    mode = newMode
    progress = 0
    target = 0
    finishedAt = -1
    pulses = []
    lastSpawn = -10
    demoStart = Date.now() / 1000
    lastTick = demoStart
    barAlpha = 1
    active = true
    ticker.running = true
  }

  function stop() {
    ticker.running = false
    active = false
    mode = "idle"
    progress = 0
    target = 0
    finishedAt = -1
    pulses = []
  }

  function tick() {
    var t = Date.now() / 1000
    var dt = Math.min(0.1, Math.max(0.001, t - lastTick))
    lastTick = t
    now = t

    // Glide the palette toward the active scheme.
    var k = Math.min(1, dt * 2.5)
    for (var i = 0; i < Schemes.KEYS.length; i++) {
      var key = Schemes.KEYS[i]
      for (var c = 0; c < 3; c++) cur[key][c] += (tgt[key][c] - cur[key][c]) * k
    }

    var raw, fadeT
    if (mode === "demo") {
      var cycle = demoSeconds + hold + fade
      var phase = (t - demoStart) % cycle
      raw = Math.min(phase / demoSeconds, 1)
      progress = raw
      fadeT = phase - demoSeconds - hold
    } else {
      var goal = mode === "done" ? 1 : Math.min(target, 0.999)
      var diff = goal - progress
      if (diff > 0) progress += diff * Math.min(1, dt * 1.5)
      if (mode === "done" && 1 - progress < 0.002) {
        progress = 1
        if (finishedAt < 0) finishedAt = t
      }
      raw = progress
      fadeT = finishedAt < 0 ? -1 : t - finishedAt - hold
      if (fadeT >= fade) { stop(); return }
    }

    if (raw > 0.02 && t - lastSpawn >= gap) {
      var next = pulses.slice()
      next.push(t)
      pulses = next
      lastSpawn = t
    }
    if (pulses.length > 0 && t - pulses[0] >= travel) pulses = pulses.filter(function (p) { return t - p < travel })

    glow = 0.5 - 0.5 * Math.cos(2 * Math.PI * breathHz * t)
    barAlpha = fadeT <= 0 ? 1 : 1 - easeInOut(Math.min(fadeT / fade, 1))
    frame()
  }

  Timer {
    id: ticker
    interval: 16
    repeat: true
    running: false
    onTriggered: root.tick()
  }
}
