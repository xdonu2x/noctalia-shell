import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Panels.Settings.Tabs.Bar
import qs.Services.Noctalia
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  function _ensureSidePanelWidgets() {
    if (!Settings.data.bar.sidePanels) {
      return;
    }
    if (!Settings.data.bar.sidePanels.leftWidgets) {
      Settings.data.bar.sidePanels.leftWidgets = [];
    }
    if (!Settings.data.bar.sidePanels.rightWidgets) {
      Settings.data.bar.sidePanels.rightWidgets = [];
    }
  }

  function _addSidePanelWidgetToSection(widgetId, section) {
    _ensureSidePanelWidgets();

    var newWidget = {
      "id": widgetId
    };
    if (BarWidgetRegistry.widgetHasUserSettings(widgetId)) {
      var metadata = BarWidgetRegistry.widgetMetadata[widgetId];
      if (metadata) {
        Object.keys(metadata).forEach(function (key) {
          newWidget[key] = metadata[key];
        });
      }
    }

    var key = section + "Widgets";
    Settings.data.bar.sidePanels[key].push(newWidget);
    BarService.widgetsRevision++;
  }

  function _removeSidePanelWidgetFromSection(section, index) {
    _ensureSidePanelWidgets();

    var key = section + "Widgets";
    var widgets = Settings.data.bar.sidePanels[key] || [];
    if (index >= 0 && index < widgets.length) {
      var newArray = widgets.slice();
      newArray.splice(index, 1);
      Settings.data.bar.sidePanels[key] = newArray;
      BarService.widgetsRevision++;
    }
  }

  function _reorderSidePanelWidgetInSection(section, fromIndex, toIndex) {
    _ensureSidePanelWidgets();

    var key = section + "Widgets";
    var widgets = Settings.data.bar.sidePanels[key] || [];
    if (fromIndex >= 0 && fromIndex < widgets.length && toIndex >= 0 && toIndex < widgets.length) {
      var newArray = widgets.slice();
      var item = newArray[fromIndex];
      newArray.splice(fromIndex, 1);
      newArray.splice(toIndex, 0, item);
      Settings.data.bar.sidePanels[key] = newArray;
      BarService.widgetsRevision++;
    }
  }

  function _updateSidePanelWidgetSettingsInSection(section, index, settings) {
    _ensureSidePanelWidgets();

    var key = section + "Widgets";
    var widgets = Settings.data.bar.sidePanels[key] || [];
    if (index >= 0 && index < widgets.length) {
      widgets[index] = settings;
      Settings.data.bar.sidePanels[key] = widgets.slice();
    }
  }

  function _moveSidePanelWidgetBetweenSections(fromSection, index, toSection) {
    _ensureSidePanelWidgets();

    var fromKey = fromSection + "Widgets";
    var toKey = toSection + "Widgets";
    var fromWidgets = Settings.data.bar.sidePanels[fromKey] || [];
    var toWidgets = Settings.data.bar.sidePanels[toKey] || [];

    if (index >= 0 && index < fromWidgets.length) {
      var widget = fromWidgets[index];
      var sourceArray = fromWidgets.slice();
      sourceArray.splice(index, 1);
      var targetArray = toWidgets.slice();
      targetArray.push(widget);
      Settings.data.bar.sidePanels[fromKey] = sourceArray;
      Settings.data.bar.sidePanels[toKey] = targetArray;
      BarService.widgetsRevision++;
    }
  }

  function updateAvailableWidgetsModel() {
    availableWidgets.clear();
    const widgets = BarWidgetRegistry.getAvailableWidgets();
    widgets.forEach(entry => {
                      const isPlugin = BarWidgetRegistry.isPluginWidget(entry);
                      let displayName = entry;
                      if (isPlugin) {
                        const pluginId = entry.replace("plugin:", "");
                        const manifest = PluginRegistry.getPluginManifest(pluginId);
                        if (manifest && manifest.name) {
                          displayName = manifest.name;
                        } else {
                          displayName = pluginId;
                        }
                      }
                      availableWidgets.append({
                                                "key": entry,
                                                "name": displayName,
                                                "badges": isPlugin ? [{"icon": "plugin", "color": Color.mSecondary}] : []
                                              });
                    });
  }

  ListModel {
    id: availableWidgets
  }

  Component.onCompleted: updateAvailableWidgetsModel()

  Connections {
    target: BarWidgetRegistry
    function onPluginWidgetRegistryUpdated() {
      updateAvailableWidgetsModel();
    }
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      updateAvailableWidgetsModel();
    }
  }

  SidePanelsSubTab {
    availableWidgets: availableWidgets
    addWidgetToSection: root._addSidePanelWidgetToSection
    removeWidgetFromSection: root._removeSidePanelWidgetFromSection
    reorderWidgetInSection: root._reorderSidePanelWidgetInSection
    updateWidgetSettingsInSection: root._updateSidePanelWidgetSettingsInSection
    moveWidgetBetweenSections: root._moveSidePanelWidgetBetweenSections
    onOpenPluginSettings: manifest => pluginSettingsDialog.openPluginSettings(manifest)
  }

  NPluginSettingsPopup {
    id: pluginSettingsDialog
    parent: Overlay.overlay
    showToastOnSave: false
  }
}
