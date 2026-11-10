import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string hintText: "whatchu lookin at go away"
  readonly property int fieldWidth: 400
  readonly property int fieldHeight: 50
  readonly property int outlineThickness: 0
  readonly property int fieldFontSize: 18
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Colors.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Colors.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Same screen as the Plymouth LUKS prompt (/usr/share/plymouth/themes/splash),
  // laid out in physical pixels like the splash: logo in the middle, entry box
  // 40px below, lock icon left of it, 7px bullets inside, flowers either side.
  Rectangle {
    anchors.fill: parent
    color: "#1e1e2e"

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Item {
      id: stage
      readonly property real dpr: Math.max(1, Screen.devicePixelRatio)
      width: Math.round(root.width * dpr)
      height: Math.round(root.height * dpr)
      scale: 1 / dpr
      transformOrigin: Item.TopLeft

      Image {
        source: Qt.resolvedUrl("assets/flower-left.png")
        x: 0
        y: Math.floor(stage.height / 2 - height / 2)
        smooth: false
      }

      Image {
        source: Qt.resolvedUrl("assets/flower-right.png")
        x: stage.width - width
        y: Math.floor(stage.height / 2 - height / 2)
        smooth: false
      }

      Image {
        id: logo
        source: "file:///usr/share/plymouth/themes/splash/logo.png"
        x: Math.floor(stage.width / 2 - width / 2)
        y: Math.floor(stage.height / 2 - height / 2)
        smooth: false
        onStatusChanged: if (status === Image.Error) source = Qt.resolvedUrl("assets/logo.png")
      }

      Image {
        id: entry
        source: Qt.resolvedUrl(root.errorState ? "assets/entry-failed.png" : "assets/entry.png")
        x: Math.floor(stage.width / 2 - width / 2)
        y: logo.y + logo.height + 40
        smooth: false
      }

      Image {
        source: Qt.resolvedUrl(root.errorState ? "assets/lock-failed.png" : "assets/lock.png")
        height: Math.floor(entry.height * 0.8)
        width: Math.floor(84 * height / 96)
        x: entry.x - width - 15
        y: Math.floor(entry.y + entry.height / 2 - height / 2)
      }

      Repeater {
        readonly property int shown: Math.min(passwordInput.text.length, 21)
        model: shown

        Image {
          source: Qt.resolvedUrl("assets/bullet.png")
          width: 7
          height: 7
          x: Math.floor(entry.x + (entry.width - (Math.min(passwordInput.text.length, 21) * 12 - 5)) / 2 + index * 12)
          y: Math.floor(entry.y + entry.height / 2 - 3.5)
        }
      }

      // Fingerprint hint inside the entry's right edge when a sensor is enrolled.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: "#b4befe"
        font.family: Style.font.family
        font.pixelSize: 22
        x: entry.x + entry.width - width - 16
        y: Math.floor(entry.y + entry.height / 2 - height / 2)
      }

      Text {
        textFormat: Text.PlainText
        text: root.authenticatingPassword ? "checking…" : root.hintText
        color: "#cba6f7"
        font.family: "CozetteVector"
        font.pixelSize: 26
        horizontalAlignment: Text.AlignHCenter
        x: Math.floor(stage.width / 2 - width / 2)
        y: entry.y + entry.height + 40
      }

      // Only takes the keystrokes; the bullets above are what you see.
      TextInput {
        id: passwordInput
        x: entry.x
        y: entry.y
        width: entry.width
        height: entry.height
        opacity: 0
        activeFocusOnPress: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        cursorDelegate: Item {}

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) root.wakeRequested()
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }
    }
  }
}
