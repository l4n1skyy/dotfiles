import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

// skyymedia: previous / play-pause / next buttons for whatever is playing.
// Talks to the "media" capability (the media service plugin), which follows
// every MPRIS player: Zen's YouTube and YouTube Music tabs, Spotify, mpv...
//
// Previous / play-pause / next plus the track title. Button icons are
// CozetteVector's own glyphs; the title uses the bar font.
// Inline settings (shell.json entry): showTitle (default true),
// maxTitleWidth (default 0 = fill all the free space up to the next module;
// a number caps it), hideWhenIdle (default true).
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

  // Space between where the title starts and the first module of the centre
  // group on this monitor (the clock, or whatever sits before it).
  property real freeWidth: 160
  readonly property real titleGap: Style.space(12)

  function centerEdge() {
    if (!bar) return Infinity
    var win = root.Window.window
    var anchor = bar.centerAnchor
    var ids = [anchor]
    var before = bar.entriesBefore(bar.layoutEntries("center"), anchor)
    for (var i = 0; i < before.length; i++)
      ids.push(typeof before[i] === "string" ? before[i] : before[i].id)
    var edge = Infinity
    for (var k = 0; k < ids.length; k++) {
      var widgets = bar.moduleWidgets(ids[k])
      for (var j = 0; j < widgets.length; j++) {
        var w = widgets[j]
        if (!w || w.Window.window !== win || !w.visible || w.width <= 0) continue
        edge = Math.min(edge, w.mapToItem(null, 0, 0).x)
      }
    }
    return edge
  }

  function measure() {
    var edge = centerEdge()
    if (!isFinite(edge)) return
    var start = titleClip.mapToItem(null, 0, 0).x
    freeWidth = Math.max(0, edge - start - titleGap)
  }

  Timer {
    interval: 500
    repeat: true
    triggeredOnStart: true
    running: root.visible && root.showTitle
    onTriggered: root.measure()
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

    Item {
      id: titleClip
      visible: root.showTitle && root.title !== ""
      width: Math.min(root.maxTitleWidth > 0 ? root.maxTitleWidth : Infinity, root.freeWidth, titleText.implicitWidth)
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
        NumberAnimation on x {
          running: titleText.needsScroll
          loops: Animation.Infinite
          duration: Math.max(6000, titleText.implicitWidth * 25)
          from: titleClip.width
          to: -titleText.implicitWidth
          easing.type: Easing.Linear
        }
      }
    }
  }
}
