import QtQuick
import Quickshell
import Quickshell.Wayland
import "Schemes.js" as Schemes

// One hairline strip along the bottom edge of a screen. Click-through, above
// everything, and fully transparent except for the bar itself.
PanelWindow {
  id: window

  required property var engine

  color: "transparent"
  visible: engine.active
  WlrLayershell.namespace: "endo-loading-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  mask: Region {}                      // empty input region: clicks pass straight through

  anchors {
    bottom: true
    left: true
    right: true
  }
  implicitHeight: engine.barHeight

  function rgba(c, a) {
    return "rgba(" + Math.round(c[0]) + "," + Math.round(c[1]) + "," + Math.round(c[2]) + "," +
           Math.max(0, Math.min(1, a)).toFixed(3) + ")"
  }
  function lerp(a, b, t) { return a + (b - a) * t }
  function bump(u) {
    if (u < 0.7) return engine.easeInOut(u / 0.7)
    return engine.easeInOut((1 - u) / 0.3)
  }

  Canvas {
    id: canvas
    anchors.fill: parent

    Connections {
      target: window.engine
      function onFrame() { canvas.requestPaint() }
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var e = window.engine
      var W = width
      var H = height
      var w = W * e.progress
      if (w < 1) return

      var op = e.barAlpha
      var cur = e.cur
      var drift = 0.5 - 0.5 * Math.cos(2 * Math.PI * e.driftHz * e.now)
      var mid = Schemes.mix(cur.mid, cur.drift, 0.6 * drift)
      var headC = Schemes.mix(cur.head, Schemes.mix(cur.head, cur.drift, 0.5), drift)

      // Body: gradient with a slow ripple flowing through it, breathing in brightness.
      var breath = 0.82 + 0.18 * e.glow
      var body = ctx.createLinearGradient(0, 0, w, 0)
      var steps = 96
      for (var i = 0; i <= steps; i++) {
        var u = i / steps
        var col, base
        if (u < 0.6) {
          col = Schemes.mix(cur.tail, mid, u / 0.6)
          base = window.lerp(0.67, 1.0, u / 0.6)
        } else {
          col = Schemes.mix(mid, headC, (u - 0.6) / 0.4)
          base = 1.0
        }
        var x = u * w
        var rip = 0.55 * Math.sin(2 * Math.PI * (x / 520 - e.now * 0.07)) +
                  0.45 * Math.sin(2 * Math.PI * (x / 230 + e.now * 0.045))
        body.addColorStop(u, window.rgba(col, base * breath * (1 + e.ripple * rip) * op))
      }
      ctx.fillStyle = body
      ctx.fillRect(0, 0, w, H)

      // Soft glow on the leading edge, swelling with the breath.
      var headLen = 140 + 120 * e.glow
      var hx = Math.max(0, w - headLen)
      var hg = ctx.createLinearGradient(w - headLen, 0, w, 0)
      hg.addColorStop(0, window.rgba(headC, 0))
      hg.addColorStop(1, window.rgba(headC, (0.47 + 0.43 * e.glow) * op))
      ctx.fillStyle = hg
      ctx.fillRect(hx, 0, Math.min(headLen, w), H)

      // Slow waves of light drifting to the head: swell in, glide, dissolve.
      var waveLen = Math.max(120, W * e.waveWidth)
      for (var p = 0; p < e.pulses.length; p++) {
        var f = (e.now - e.pulses[p]) / e.travel
        if (f < 0 || f > 1) continue
        var env = Math.pow(Math.sin(Math.PI * f), 1.5)
        var cx = window.lerp(-waveLen * 0.25, w + waveLen * 0.25, f)
        var left = cx - waveLen * 0.7
        var g = ctx.createLinearGradient(left, 0, left + waveLen, 0)
        for (var j = 0; j <= 20; j++) {
          var uu = j / 20
          g.addColorStop(uu, window.rgba(headC, 0.69 * env * op * window.bump(uu)))
        }
        ctx.fillStyle = g
        var x0 = Math.max(0, left)
        var x1 = Math.min(w, left + waveLen)
        if (x1 > x0) ctx.fillRect(x0, 0, x1 - x0, H)
      }

      // Second, slower layer for depth, tinted by the scheme's layer colour.
      var wave2 = Math.max(200, W * 0.5)
      for (var q = 0; q < 2; q++) {
        var f2 = ((e.now / e.travel2) + q / 2) % 1
        var env2 = Math.pow(Math.sin(Math.PI * f2), 2)
        var cx2 = window.lerp(-wave2 * 0.25, w + wave2 * 0.25, f2)
        var left2 = cx2 - wave2 * 0.65
        var g2 = ctx.createLinearGradient(left2, 0, left2 + wave2, 0)
        for (var m = 0; m <= 20; m++) {
          var u2 = m / 20
          g2.addColorStop(u2, window.rgba(cur.layer, 0.41 * env2 * op * window.bump(u2)))
        }
        ctx.fillStyle = g2
        var a0 = Math.max(0, left2)
        var a1 = Math.min(w, left2 + wave2)
        if (a1 > a0) ctx.fillRect(a0, 0, a1 - a0, H)
      }
    }
  }
}
