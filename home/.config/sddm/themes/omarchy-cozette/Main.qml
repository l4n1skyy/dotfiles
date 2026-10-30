import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#18191a"

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

  Column {
    anchors.centerIn: parent
    spacing: 12

    Item {
      width: 400
      height: 50

      Text {
        anchors.fill: parent
        visible: password.text.length === 0 && !root.loginFailed
        text: "shoo, go away >:("
        color: "white"
        font.family: "CozetteVector"
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }

      TextInput {
        id: password
        anchors.fill: parent
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        echoMode: TextInput.Password
        font.family: "CozetteVector"
        font.pixelSize: 24
        font.letterSpacing: 5
        passwordCharacter: "."
        color: "white"
        selectionColor: "transparent"
        selectedTextColor: "transparent"
        cursorDelegate: Item {}
        focus: true

        onTextChanged: root.loginFailed = false

        Keys.onPressed: {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            sddm.login(root.currentUser, password.text, root.sessionIndex)
            event.accepted = true
          }
        }
      }
    }

    Text {
      visible: root.loginFailed
      text: "YOU SHALL NOT PASS D:<"
      color: "red"
      font.family: "CozetteVector"
      font.pixelSize: 18
      horizontalAlignment: Text.AlignHCenter
      width: 400
    }

  }

  Component.onCompleted: password.forceActiveFocus()
}
