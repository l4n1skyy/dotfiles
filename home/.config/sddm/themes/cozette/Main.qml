import QtQuick 2.0
import SddmComponents 2.0

// Same screen as the Plymouth LUKS prompt (/usr/share/plymouth/themes/splash):
// logo in the middle, entry box 40px below it, lock icon to its left and
// 7px bullets inside, Catppuccin Mocha. Positions and colours follow
// splash.script, so keep the two in step.
Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1e1e2e"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: password.forceActiveFocus()
  }

  Image {
    id: logo
    // The splash's own logo, so a new logo shows up here too.
    source: "file:///usr/share/plymouth/themes/splash/logo.png"
    x: Math.floor(root.width / 2 - width / 2)
    y: Math.floor(root.height / 2 - height / 2)
    smooth: false
    onStatusChanged: if (status === Image.Error) source = "logo.png"
  }

  Image {
    id: entry
    source: root.loginFailed ? "entry-failed.png" : "entry.png"
    x: Math.floor(root.width / 2 - width / 2)
    y: logo.y + logo.height + 40
  }

  Image {
    source: root.loginFailed ? "lock-failed.png" : "lock.png"
    height: Math.floor(entry.height * 0.8)
    width: Math.floor(84 * height / 96)
    x: entry.x - width - 15
    y: Math.floor(entry.y + entry.height / 2 - height / 2)
  }

  Repeater {
    model: Math.min(password.text.length, 21)

    Image {
      source: "bullet.png"
      width: 7
      height: 7
      x: entry.x + 20 + index * 12
      y: Math.floor(entry.y + entry.height / 2 - 3.5)
    }
  }

  // Only takes the keystrokes; the bullets above are what you see.
  TextInput {
    id: password
    anchors.fill: entry
    opacity: 0
    echoMode: TextInput.Password
    cursorDelegate: Item {}
    focus: true

    // Clearing the field after a failed login must not undo the red.
    onTextChanged: if (text.length > 0) root.loginFailed = false

    Keys.onPressed: {
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        sddm.login(root.currentUser, password.text, root.sessionIndex)
        event.accepted = true
      }
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
