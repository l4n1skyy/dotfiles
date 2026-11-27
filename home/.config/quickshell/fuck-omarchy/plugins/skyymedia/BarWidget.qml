import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// skyymedia: previous / play-pause / next buttons for whatever is playing.
// Talks to the "media" capability (the media service plugin), which follows
// every MPRIS player: Zen's YouTube and YouTube Music tabs, Spotify, mpv...
//
// Previous / play-pause / next plus the track title. Button icons are
// CozetteVector's own glyphs; the title uses the bar font.
// Inline settings (shell.json entry): showTitle (default true),
// maxTitleWidth (default 0 = fill all the free space up to the next module
// group, wherever the module sits; a number caps it), hideWhenIdle (default true).
BarWidget {
  id: root
  moduleName: "skyymedia"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("media")
  readonly property var player: mediaService ? mediaService.activePlayer : null
  readonly property bool hasMedia: player !== null && (player.trackTitle || player.trackArtist)
  readonly property string iconFont: "CozetteVector"
  readonly property string title: player ? (player.trackTitle || "") : ""
  readonly property string artist: player ? (player.trackArtist || "") : ""
  readonly property bool showTitle: setting("showTitle", true) && !vertical
  readonly property real maxTitleWidth: setting("maxTitleWidth", 0)

  // How wide the title may get: its current width plus the empty bar space it
  // can still grow into before its module group runs into the next one on
  // this monitor. Works in any region (left, either side of the centre
  // anchor, right), since each grows a different way.
  property real freeWidth: 160
  readonly property real titleGap: Style.space(12)

  // Left / right edge (window x) of each region's visible modules on this
  // bar surface, this one included.
  function regionExtents() {
    var win = root.Window.window
    var ext = { left: null, center: null, right: null }
    var slots = bar && bar.moduleSlots ? bar.moduleSlots : []
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      var w = s ? s.activeItem : null
      if (!w || !(s.region in ext) || w.Window.window !== win || !w.visible || w.width <= 0) continue
      var x = w.mapToItem(null, 0, 0).x
      var e = ext[s.region] || (ext[s.region] = { min: Infinity, max: -Infinity })
      e.min = Math.min(e.min, x)
      e.max = Math.max(e.max, x + w.width)
    }
    return ext
  }

  function ownRegion() {
    var slots = bar && bar.moduleSlots ? bar.moduleSlots : []
    for (var i = 0; i < slots.length; i++)
      if (slots[i] && slots[i].activeItem === root) return slots[i].region
    return ""
  }

  // Empty space the title can still take (negative = it already overlaps).
  // The left group grows rightwards, the right group leftwards; in the centre
  // the modules before the anchor grow leftwards, those after it rightwards,
  // and with no anchor the whole group grows both ways (half each side).
  function slack() {
    var region = ownRegion()
    var ext = regionExtents()
    var winWidth = root.Window.window ? root.Window.window.width : Infinity
    var leftEnd = ext.left ? ext.left.max : 0
    var rightStart = ext.right ? ext.right.min : winWidth
    var gap = titleGap
    if (region === "left")
      return (ext.center ? ext.center.min : rightStart) - ext.left.max - gap
    if (region === "right")
      return ext.right.min - (ext.center ? ext.center.max : leftEnd) - gap
    if (region !== "center" || !ext.center) return NaN
    var entries = bar.layoutEntries("center")
    var anchorIdx = bar.entryIndex(entries, bar.centerAnchor)
    var ownIdx = bar.entryIndex(entries, root.moduleName)
    if (anchorIdx === -1)
      return 2 * Math.min(ext.center.min - leftEnd - gap, rightStart - ext.center.max - gap)
    return ownIdx < anchorIdx ? ext.center.min - leftEnd - gap
                              : rightStart - ext.center.max - gap
  }

  // While this module is being dragged, its title keeps a fixed width so the
  // ghost and the drop marker do not jump around; it re-measures on drop.
  readonly property bool beingDragged: bar !== null && bar !== undefined
    && bar.barDragSource !== null && bar.barDragSource !== undefined
    && bar.barDragSource.activeItem === root
  readonly property real dragWidth: Style.space(160)

  function measure() {
    if (beingDragged || !bar) return
    var room = slack()
    if (!isFinite(room)) return
    freeWidth = Math.max(0, titleClip.width + room)
  }

  Timer {
    interval: 500
    repeat: true
    triggeredOnStart: true
    running: root.visible && root.showTitle && !root.beingDragged
    onTriggered: root.measure()
  }
  // YouTube Music like button: only for Pear Desktop's player (MPRIS name
  // org.mpris.MediaPlayer2.YoutubeMusic, from Pear's shortcuts plugin), the one
  // skyyytlike can like through Pear's API server. The video id comes from its
  // MPRIS url. (Old Zen window: ~/.local/bin/hypr/skyyytmusic-zen/README.md.)
  readonly property bool isPear: player !== null && String(player.dbusName || "").indexOf("YoutubeMusic") !== -1
  readonly property string trackUrl: player && player.metadata ? (player.metadata["xesam:url"] || "") : ""
  readonly property string videoId: {
    if (!isPear) return ""
    var m = /^https:\/\/music\.youtube\.com\/watch\?(?:.*&)?v=([\w-]{11})/.exec(trackUrl)
    return m ? m[1] : ""
  }
  property bool liked: false
  property bool likeBusy: false
  readonly property string likeBin: Quickshell.env("HOME") + "/.local/bin/hypr/skyyytlike"
  onVideoIdChanged: { liked = false; if (videoId !== "") likeProc.run("status") }

  // Re-check every few seconds so likes made in the browser show up too.
  Timer {
    interval: 3000
    repeat: true
    running: root.visible && root.videoId !== "" && !root.likeBusy
    onTriggered: likeProc.run("status")
  }

  Process {
    id: likeProc
    property string mode: "status"
    property string forId: ""
    property bool pendingToggle: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (likeProc.forId === root.videoId) root.liked = text.trim() === "LIKE"
        if (likeProc.pendingToggle) {
          likeProc.pendingToggle = false
          likeProc.run("toggle")
        } else {
          root.likeBusy = false
        }
      }
    }
    function run(m) {
      if (running) { if (m === "toggle") pendingToggle = true; return }
      mode = m
      forId = root.videoId
      command = [root.likeBin, m, root.videoId]
      running = true
    }
  }
  readonly property bool playing: player !== null && player.isPlaying === true
  readonly property bool hideWhenIdle: setting("hideWhenIdle", true)

  visible: !hideWhenIdle || hasMedia
  implicitHeight: barSize
  implicitWidth: visible ? row.implicitWidth + Style.space(14) : 0


  function act(name) {
    if (mediaService) mediaService.runAction(name, false, mediaService.playerKey(player))
  }

  component Btn: Item {
    id: btn
    property string glyph: ""
    property bool enabledBtn: true
    property bool big: false
    signal pressed()
    width: Style.space(big ? 24 : 20)
    height: root.barSize

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: btn.glyph
      font.family: root.iconFont
      font.pixelSize: Style.font.body + (btn.big ? 2 : 0)
      color: !btn.enabledBtn ? Qt.darker(root.bar.barForeground, 2.2)
        : hit.containsMouse ? Qt.lighter(root.bar.barForeground, 1.3) : root.bar.barForeground
    }
    MouseArea {
      id: hit
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: btn.enabledBtn ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (btn.enabledBtn) btn.pressed()
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(2)

    Btn {
      glyph: ""
      enabledBtn: root.player ? root.player.canGoPrevious !== false : false
      onPressed: root.act("previous")
    }
    Btn {
      big: true
      glyph: root.playing ? "" : ""
      enabledBtn: root.player !== null
      onPressed: root.act("playPause")
    }
    Btn {
      glyph: ""
      enabledBtn: root.player ? root.player.canGoNext !== false : false
      onPressed: root.act("next")
    }

    Btn {
      visible: root.videoId !== ""
      glyph: root.liked ? "♥" : "♡"
      enabledBtn: !root.likeBusy
      onPressed: { root.likeBusy = true; root.liked = !root.liked; likeProc.run("toggle") }
    }

    Item {
      id: titleClip
      visible: root.showTitle && root.title !== ""
      width: Math.min(root.maxTitleWidth > 0 ? root.maxTitleWidth : Infinity, root.beingDragged ? root.dragWidth : root.freeWidth, titleText.implicitWidth)
      height: root.barSize
      clip: true

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Jump to the YouTube Music window on workspace 8 (opens it if it is closed)
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/hypr/skyyytmusic", "focus"])
      }

      Text {
        id: titleText
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.title + (root.artist ? "  ·  " + root.artist : "")
        color: root.bar ? root.bar.barForeground : "white"
        font.family: root.bar ? root.bar.fontFamily : ""
        font.pixelSize: Style.font.body
        property bool needsScroll: implicitWidth > titleClip.width
        // The marquee animates scrollX; x is bound so it snaps back to 0
        // whenever the text fits or the track changes (an Animation on x
        // leaves x stranded wherever it stopped).
        property real scrollX: 0
        x: needsScroll ? scrollX : 0
        NumberAnimation on scrollX {
          id: marquee
          running: titleText.needsScroll
          loops: Animation.Infinite
          duration: Math.max(6000, titleText.implicitWidth * 25)
          from: titleClip.width
          to: -titleText.implicitWidth
          easing.type: Easing.Linear
        }
        onTextChanged: if (marquee.running) { marquee.restart() }
      }
    }
  }
}
