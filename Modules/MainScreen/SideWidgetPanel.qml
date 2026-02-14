import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  required property ShellScreen screen
  required property string side // "left" or "right"

  readonly property bool isLeft: side === "left"
  readonly property bool isRight: side === "right"

  readonly property var settings: Settings.data.bar.sidePanels
  readonly property bool panelEnabled: {
    if (!settings)
      return true;
    return isLeft ? (settings?.leftEnabled ?? true) : (settings?.rightEnabled ?? true);
  }

  readonly property var panelEntries: {
    var _rev = BarService.widgetsRevision;

    var fromSidePanels = isLeft ? settings?.leftPanels : settings?.rightPanels;
    if (fromSidePanels && fromSidePanels.length !== undefined) {
      return fromSidePanels;
    }

    // Backward compatibility with older settings keys
    var fromLegacy = isLeft ? settings?.leftWidgets : settings?.rightWidgets;
    if (fromLegacy && fromLegacy.length !== undefined) {
      return fromLegacy;
    }

    return [];
  }

  readonly property real panelPadding: settings?.padding ?? Style.marginM
  readonly property real panelSpacing: settings?.spacing ?? Style.marginS
  readonly property int triggerSize: Math.max(1, settings?.triggerSize ?? 8)
  readonly property int hideDelay: Math.max(0, settings?.hideDelay ?? 250)
  readonly property int panelMinWidth: Math.max(120, settings?.minWidth ?? 220)
  readonly property int panelMaxWidth: Math.max(panelMinWidth, settings?.maxWidth ?? 520)
  readonly property bool useAutoWidth: (settings?.widthMode || "auto") === "auto"
  readonly property int configuredWidth: Math.max(panelMinWidth, settings?.width ?? 320)

  readonly property real computedPanelWidth: {
    var width = useAutoWidth ? (contentColumn.implicitWidth + panelPadding * 2) : configuredWidth;
    return Math.min(panelMaxWidth, Math.max(panelMinWidth, width));
  }

  readonly property bool visiblePanel: panelEnabled && panelEntries.length > 0

  property bool revealed: false

  property alias panelBody: panelBody
  property alias triggerZone: triggerZone

  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property bool barShouldShow: {
    if (!BarService.effectivelyVisible)
      return false;
    var monitors = Settings.data.bar.monitors || [];
    var screenName = screen?.name || "";
    return monitors.length === 0 || monitors.includes(screenName);
  }
  readonly property bool barFloating: Settings.data.bar.floating || false
  readonly property real barHeight: Style.getBarHeightForScreen(screen?.name)
  readonly property real barMarginH: barFloating ? Math.floor(Settings.data.bar.marginHorizontal || 0) : 0
  readonly property real barMarginV: barFloating ? Math.floor(Settings.data.bar.marginVertical || 0) : 0

  readonly property real insetTop: (barShouldShow && barPosition === "top") ? (barHeight + barMarginV) : 0
  readonly property real insetBottom: (barShouldShow && barPosition === "bottom") ? (barHeight + barMarginV) : 0
  readonly property real insetLeft: (barShouldShow && barPosition === "left") ? (barHeight + barMarginH) : 0
  readonly property real insetRight: (barShouldShow && barPosition === "right") ? (barHeight + barMarginH) : 0

  readonly property bool attachedToTopBar: insetTop > 0
  readonly property bool attachedToBottomBar: insetBottom > 0

  readonly property real shownX: isLeft ? insetLeft : (parent ? parent.width - insetRight - panelBody.width : 0)
  readonly property real hiddenX: isLeft ? (insetLeft - panelBody.width) : (parent ? parent.width - insetRight : 0)

  function panelName(panelId: string): string {
    switch (panelId) {
    case "audioPanel":
      return I18n.tr("panels.audio.title");
    case "batteryPanel":
      return I18n.tr("battery.battery");
    case "bluetoothPanel":
      return I18n.tr("common.bluetooth");
    case "brightnessPanel":
      return I18n.tr("panels.osd.types-brightness-label");
    case "clockPanel":
      return I18n.tr("common.calendar");
    case "controlCenterPanel":
      return I18n.tr("panels.control-center.title");
    case "launcherPanel":
      return I18n.tr("panels.launcher.title");
    case "mediaPlayerPanel":
      return I18n.tr("common.media");
    case "networkPanel":
      return I18n.tr("common.network");
    case "notificationHistoryPanel":
      return I18n.tr("panels.notifications.history-title");
    case "sessionMenuPanel":
      return I18n.tr("session-menu.title");
    case "settingsPanel":
      return I18n.tr("panels.general.title");
    case "wallpaperPanel":
      return I18n.tr("common.wallpaper");
    default:
      return panelId;
    }
  }

  function openPanel(panelId: string) {
    var panel = PanelService.getPanel(panelId, screen, true);
    if (panel && panel.toggle) {
      panel.toggle();
    }
  }

  function reveal() {
    if (!visiblePanel)
      return;
    hideTimer.stop();
    revealed = true;
  }

  function conceal() {
    if (!visiblePanel)
      return;
    hideTimer.restart();
  }

  function concealNow() {
    hideTimer.stop();
    revealed = false;
  }

  onVisiblePanelChanged: {
    if (!visiblePanel) {
      concealNow();
    }
  }

  Timer {
    id: hideTimer
    interval: hideDelay
    repeat: false
    onTriggered: {
      if (!triggerZone.containsMouse && !panelMouseArea.containsMouse) {
        root.revealed = false;
      }
    }
  }

  MouseArea {
    id: triggerZone
    visible: root.visiblePanel
    enabled: root.visiblePanel
    width: root.triggerSize
    anchors {
      top: parent.top
      bottom: parent.bottom
      left: root.isLeft ? parent.left : undefined
      right: root.isRight ? parent.right : undefined
    }
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onEntered: root.reveal()
    onExited: root.conceal()
    z: 60
  }

  Rectangle {
    id: panelBody
    visible: root.visiblePanel
    width: Math.round(root.computedPanelWidth)
    height: Math.max(0, (parent ? parent.height : 0) - root.insetTop - root.insetBottom)
    x: root.revealed ? root.shownX : root.hiddenX
    y: root.insetTop

    color: Qt.alpha(Color.mSurface, 0.96)
    border.color: Color.mOutline
    border.width: 1
    radius: Style.radiusL

    topLeftRadius: root.isLeft || root.attachedToTopBar ? 0 : radius
    bottomLeftRadius: root.isLeft || root.attachedToBottomBar ? 0 : radius
    topRightRadius: root.isRight || root.attachedToTopBar ? 0 : radius
    bottomRightRadius: root.isRight || root.attachedToBottomBar ? 0 : radius

    Behavior on x {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: panelMouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      onEntered: root.reveal()
      onExited: root.conceal()
      z: 1
    }

    Flickable {
      id: flick
      anchors.fill: parent
      anchors.margins: root.panelPadding
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      clip: true
      interactive: contentHeight > height

      ColumnLayout {
        id: contentColumn
        width: flick.width
        spacing: root.panelSpacing

        Repeater {
          model: root.panelEntries

          delegate: NButton {
            required property var modelData
            readonly property var entry: modelData || {}
            readonly property string panelId: entry.id || ""

            Layout.fillWidth: true
            enabled: panelId !== ""
            text: root.panelName(panelId)
            icon: "chevron-right"
            fontSize: Style.fontSizeM
            onClicked: root.openPanel(panelId)
          }
        }
      }
    }
  }
}
