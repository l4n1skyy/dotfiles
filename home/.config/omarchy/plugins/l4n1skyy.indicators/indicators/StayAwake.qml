import QtQuick
import qs.Ui

BarIndicator {
  id: root

  readonly property var idleService: bar?.shell?.firstPartyServiceFor("omarchy.idle")

  active: idleService ? idleService.stayAwake : false
  activeText: "󰅶"
  inactiveText: "󰅶"
  activeTooltipText: "Stay Awake"
  inactiveTooltipText: "You Can Sleep Now"

  function toggle() {
    if (root.idleService) root.idleService.setIdleEnabled(root.idleService.stayAwake)
  }

  onPressed: function() { root.toggle() }
}
