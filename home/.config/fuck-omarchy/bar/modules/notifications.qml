import QtQuick
import qs.Ui

BarIconButton {
  id: root

  property string moduleName: "system.notifications"
  property var settings: ({})
  readonly property var notificationService: bar?.shell?.firstPartyServiceFor("fo.notifications")
  readonly property bool doNotDisturb: notificationService ? notificationService.doNotDisturb : false

  text: doNotDisturb ? "󰂛" : ""
  fontSize: 16
  horizontalMargin: 5
  tooltipText: doNotDisturb ? "Allow Notifications" : "Silence Notifications"

  onPressed: function(button) {
    if (button === Qt.LeftButton && notificationService)
      notificationService.setDoNotDisturb(!notificationService.doNotDisturb)
  }
}
