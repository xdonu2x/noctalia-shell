import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Noctalia
import qs.Services.UI

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

  readonly property var panelWidgets: {
    var widgets = Settings.getBarWidgetsForScreen(screen?.name);
    if (!widgets)
      return [];
    return isLeft ? (widgets.left || []) : (widgets.right || []);
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

  readonly property bool visiblePanel: panelEnabled && panelWidgets.length > 0

  property bool revealed: false

  property alias panelBody: panelBody
  property alias triggerZone: triggerZone

  readonly property real shownX: isLeft ? 0 : (parent ? parent.width - panelBody.width : 0)
  readonly property real hiddenX: isLeft ? -panelBody.width : (parent ? parent.width : 0)

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
    height: parent ? parent.height : 0
    x: root.revealed ? root.shownX : root.hiddenX
    y: 0

    color: Qt.alpha(Color.mSurface, 0.96)
    border.color: Color.mOutline
    border.width: 1
    radius: Style.radiusL

    topLeftRadius: root.isLeft ? 0 : radius
    bottomLeftRadius: root.isLeft ? 0 : radius
    topRightRadius: root.isRight ? 0 : radius
    bottomRightRadius: root.isRight ? 0 : radius

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
          model: root.panelWidgets

          delegate: Loader {
            id: widgetLoader
            required property var modelData
            required property int index

            readonly property var entry: modelData || {}
            readonly property string widgetId: entry.id || ""

            active: widgetId !== "" && BarWidgetRegistry.hasWidget(widgetId)
            sourceComponent: active ? BarWidgetRegistry.getWidget(widgetId) : null

            onLoaded: {
              if (!item)
                return;

              item.anchors = undefined;
              item.x = 0;
              item.y = 0;

              if (item.hasOwnProperty("screen")) {
                item.screen = root.screen;
              }

              if (item.hasOwnProperty("widgetId")) {
                item.widgetId = widgetId;
              }

              if (item.hasOwnProperty("section")) {
                item.section = root.isLeft ? "left" : "right";
              }

              if (item.hasOwnProperty("sectionWidgetIndex")) {
                item.sectionWidgetIndex = index;
              }

              if (item.hasOwnProperty("sectionWidgetsCount")) {
                item.sectionWidgetsCount = root.panelWidgets.length;
              }

              for (var key in entry) {
                if (key === "id")
                  continue;
                if (item.hasOwnProperty(key)) {
                  item[key] = entry[key];
                }
              }

              if (BarWidgetRegistry.isPluginWidget(widgetId)) {
                var pluginId = widgetId.replace("plugin:", "");
                var api = PluginService.getPluginAPI(pluginId);
                if (api && item.hasOwnProperty("pluginApi")) {
                  item.pluginApi = api;
                }
              }
            }
          }
        }
      }
    }
  }
}
