import QtQuick
import QtQuick.Controls
import Quickshell
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  property var availableWidgets
  property var addWidgetToSection
  property var removeWidgetFromSection
  property var reorderWidgetInSection
  property var updateWidgetSettingsInSection
  property var moveWidgetBetweenSections

  signal openPluginSettings(var manifest)

  readonly property var sidePanels: Settings.data.bar.sidePanels

  function getSectionIcons() {
    return {
      "left": "arrow-bar-to-left",
      "right": "arrow-bar-to-right"
    };
  }

  NText {
    text: "Configure side panels and choose widgets shown on each side."
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    color: Color.mOnSurfaceVariant
  }

  NToggle {
    label: "Enable left side panel"
    description: "Show a hover-revealed side panel on the left screen edge."
    checked: sidePanels.leftEnabled
    onToggled: checked => sidePanels.leftEnabled = checked
  }

  NToggle {
    label: "Enable right side panel"
    description: "Show a hover-revealed side panel on the right screen edge."
    checked: sidePanels.rightEnabled
    onToggled: checked => sidePanels.rightEnabled = checked
  }

  NComboBox {
    label: "Panel width mode"
    description: "Auto fits to widget content or use a fixed width."
    model: [
      {"key": "auto", "name": "Auto"},
      {"key": "fixed", "name": "Fixed"}
    ]
    currentKey: sidePanels.widthMode
    onSelected: key => sidePanels.widthMode = key
  }

  NLabel {
    label: "Fixed width"
    description: "Used when width mode is fixed."
    visible: sidePanels.widthMode === "fixed"
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    visible: sidePanels.widthMode === "fixed"

    NSlider {
      id: fixedWidthSlider
      Layout.fillWidth: true
      from: 180
      to: 700
      stepSize: 1
      value: sidePanels.width
      onPressedChanged: {
        if (!pressed)
          sidePanels.width = Math.round(value);
      }
    }

    NText {
      text: Math.round(fixedWidthSlider.value) + "px"
      pointSize: Style.fontSizeM
      color: Color.mOnSurfaceVariant
    }
  }

  NLabel {
    label: "Edge trigger size"
    description: "How wide the hover activation strip is on each side."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NSlider {
      id: triggerSlider
      Layout.fillWidth: true
      from: 1
      to: 32
      stepSize: 1
      value: sidePanels.triggerSize
      onPressedChanged: {
        if (!pressed)
          sidePanels.triggerSize = Math.round(value);
      }
    }

    NText {
      text: Math.round(triggerSlider.value) + "px"
      pointSize: Style.fontSizeM
      color: Color.mOnSurfaceVariant
    }
  }

  NLabel {
    label: "Auto-hide delay"
    description: "Delay before panel hides after leaving its area."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NSlider {
      id: hideDelaySlider
      Layout.fillWidth: true
      from: 0
      to: 2000
      stepSize: 10
      value: sidePanels.hideDelay
      onPressedChanged: {
        if (!pressed)
          sidePanels.hideDelay = Math.round(value);
      }
    }

    NText {
      text: Math.round(hideDelaySlider.value) + "ms"
      pointSize: Style.fontSizeM
      color: Color.mOnSurfaceVariant
    }
  }

  NSectionEditor {
    sectionName: I18n.tr("positions.left")
    sectionId: "left"
    settingsDialogComponent: Qt.resolvedUrl(Quickshell.shellDir + "/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
    widgetRegistry: BarWidgetRegistry
    widgetModel: sidePanels.leftWidgets
    sectionIcons: root.getSectionIcons()
    availableWidgets: root.availableWidgets
    onAddWidget: (widgetId, section) => root.addWidgetToSection(widgetId, section)
    onRemoveWidget: (section, index) => root.removeWidgetFromSection(section, index)
    onReorderWidget: (section, fromIndex, toIndex) => root.reorderWidgetInSection(section, fromIndex, toIndex)
    onUpdateWidgetSettings: (section, index, settings) => root.updateWidgetSettingsInSection(section, index, settings)
    onMoveWidget: (fromSection, index, toSection) => root.moveWidgetBetweenSections(fromSection, index, toSection)
    onOpenPluginSettingsRequested: manifest => root.openPluginSettings(manifest)
  }

  NSectionEditor {
    sectionName: I18n.tr("positions.right")
    sectionId: "right"
    settingsDialogComponent: Qt.resolvedUrl(Quickshell.shellDir + "/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
    widgetRegistry: BarWidgetRegistry
    widgetModel: sidePanels.rightWidgets
    sectionIcons: root.getSectionIcons()
    availableWidgets: root.availableWidgets
    onAddWidget: (widgetId, section) => root.addWidgetToSection(widgetId, section)
    onRemoveWidget: (section, index) => root.removeWidgetFromSection(section, index)
    onReorderWidget: (section, fromIndex, toIndex) => root.reorderWidgetInSection(section, fromIndex, toIndex)
    onUpdateWidgetSettings: (section, index, settings) => root.updateWidgetSettingsInSection(section, index, settings)
    onMoveWidget: (fromSection, index, toSection) => root.moveWidgetBetweenSections(fromSection, index, toSection)
    onOpenPluginSettingsRequested: manifest => root.openPluginSettings(manifest)
  }
}
