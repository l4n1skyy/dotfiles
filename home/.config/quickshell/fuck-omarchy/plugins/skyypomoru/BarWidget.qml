import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// skyypomoru: pomoru's mode and time left, next to the clock.
//
// Display only. It takes no room of its own: it is drawn over the spot where the
// indicators group opens on hover, and the two swap instantly: pomoru is visible only
// while the indicators are NOT open, never both at once. Order in shell.json: clock,
// indicators, skyypomoru.
//
// Colours come from the current theme's palette (colors.toml): focus, break and long
// break each get their own. A soft chime plays when a focus block or a break ends.
// Reads ~/.config/pomoru/status.json and shows only while pomoru is running, unless
// showWhenIdle is set in its shell.json entry. The task you are on (pomoru's current
// task) follows the time; settings: showTask (default true), maxTaskWidth (default 220).
BarWidget {
  id: root
  moduleName: "skyypomoru"

  readonly property string dir: Quickshell.env("HOME") + "/.config/pomoru"
  readonly property bool showWhenIdle: setting("showWhenIdle", false)
  readonly property bool showTask: setting("showTask", true) && !vertical
  readonly property real maxTaskWidth: setting("maxTaskWidth", 220)

  property bool alive: false
  property var status: ({})
  property var prevStatus: null
  property var palette: ({})

  readonly property string mode: String(status.mode || "work")
  readonly property bool running: status.running === true
  readonly property string remaining: String(status.time_remaining || "")
  readonly property string task: status.current_task && status.current_task.title ? String(status.current_task.title) : ""
  readonly property bool isBreak: mode === "break" || mode === "short_break" || mode === "short-break"
  readonly property bool isLongBreak: mode === "long-break" || mode === "long_break"

  function themeColor(names, fallback) {
    for (var i = 0; i < names.length; i++)
      if (palette[names[i]]) return palette[names[i]]
    return fallback
  }

  // Mauve (Catppuccin Mocha cba6f7), as on the boot and login screens. The current
  // theme has no purple of its own, so a theme that defines "purple" wins.
  readonly property color focusColor: themeColor(["purple"], "#cba6f7")
  readonly property color breakColor: themeColor(["green", "bright_green"], Colors.accent)
  readonly property color longBreakColor: themeColor(["blue", "bright_blue"], Colors.foreground)
  readonly property color tint: !alive ? Colors.muted
    : !running ? Qt.darker(modeColor, 1.6) : modeColor
  readonly property color modeColor: isLongBreak ? longBreakColor : isBreak ? breakColor : focusColor

  readonly property string glyph: isLongBreak || isBreak ? "" : ""

  visible: alive || showWhenIdle
  implicitHeight: barSize
  // (Almost) no layout width: the label overlaps the indicators' reveal area instead of
  // pushing things around. 1px, not 0: the bar skips painting zero-width slots.
  implicitWidth: 1

  // The indicators widget on this monitor. Pomoru and the indicators are never on screen
  // together: the moment the indicators open (same condition they use themselves: the
  // centre of the bar is hovered, or the pointer is on the group), pomoru is gone, and it
  // comes straight back the moment they close. No fades, so there is never an overlap.
  property var indicatorsItem: null
  readonly property bool indicatorsOpen: indicatorsItem
    ? indicatorsItem.revealInactiveIndicators === true
    : (bar ? bar.centerSectionRevealHeld === true : false)
  opacity: indicatorsOpen ? 0 : 1

  function findIndicators() {
    if (!bar) return
    var win = root.Window.window
    var items = bar.moduleWidgets("skyyindicators")
    for (var i = 0; i < items.length; i++) {
      if (items[i] && items[i].Window.window === win) { indicatorsItem = items[i]; return }
    }
    indicatorsItem = null
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.findIndicators()
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: Style.space(8)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(8)

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: root.glyph + " " + (root.remaining || "--:--")
      color: root.tint
      font.family: root.bar ? root.bar.fontFamily : ""
      font.pixelSize: Style.font.body
    }

    Text {
      id: taskLabel
      visible: root.showTask && root.task !== ""
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(root.maxTaskWidth, implicitWidth)
      elide: Text.ElideRight
      textFormat: Text.PlainText
      text: root.task
      color: Qt.darker(root.tint, 1.25)
      font.family: root.bar ? root.bar.fontFamily : ""
      font.pixelSize: Style.font.body
    }
  }

  // A session just ended: pomoru flips to the next mode and stops the clock
  function checkTransition(prev, cur) {
    if (!prev || !cur) return
    if (prev.running === true && cur.running !== true && prev.mode !== cur.mode) {
      var kind = String(prev.mode) === "work" ? "focus-done" : "break-done"
      chime.command = ["skyysound-pomoru", kind]
      chime.running = true
    }
  }

  Process { id: chime }

  FileView {
    id: statusFile
    path: root.dir + "/status.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var next = ({})
      try { next = JSON.parse(text()) } catch (e) { next = ({}) }
      root.checkTransition(root.prevStatus, next)
      root.prevStatus = next
      root.status = next
    }
  }

  // The current theme's palette, so the colours follow theme switches
  FileView {
    id: paletteFile
    path: Quickshell.env("HOME") + "/.local/state/fuck-omarchy/current/theme/colors.toml"
    printErrors: false
    onLoaded: {
      var out = ({})
      var lines = text().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var m = lines[i].match(/^\s*([a-z_]+)\s*=\s*"(#[0-9a-fA-F]{6,8})"/)
        if (m) out[m[1]] = m[2]
      }
      root.palette = out
    }
  }
  Connections {
    target: Colors
    function onAccentChanged() { paletteFile.reload() }
    function onForegroundChanged() { paletteFile.reload() }
    function onBackgroundChanged() { paletteFile.reload() }
  }

  // Is the pomoru app still running? instance.pid can outlive it, so check the pid.
  Process {
    id: aliveCheck
    command: ["bash", "-c", "p=$(cat \"$HOME/.config/pomoru/instance.pid\" 2>/dev/null); [[ -n $p ]] && kill -0 \"$p\" 2>/dev/null && echo 1 || echo 0"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.alive = text.trim() === "1"
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      statusFile.reload()
      if (!aliveCheck.running) aliveCheck.running = true
    }
  }
}
