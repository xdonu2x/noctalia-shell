import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Noctalia
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  // Helper functions to update arrays immutably
  function addMonitor(list, name) {
    const arr = (list || []).slice();
    if (!arr.includes(name))
      arr.push(name);
    return arr;
  }
  function removeMonitor(list, name) {
    return (list || []).filter(function (n) {
      return n !== name;
    });
  }

  // Signal functions for widgets sub-tab (global widgets only)
  function _addWidgetToSection(widgetId, section) {
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
    Settings.data.bar.widgets[section].push(newWidget);
    BarService.widgetsRevision++;
  }

  function _removeWidgetFromSection(section, index) {
    var widgets = Settings.data.bar.widgets;
    if (index >= 0 && index < widgets[section].length) {
      var newArray = widgets[section].slice();
      var removedWidgets = newArray.splice(index, 1);
      widgets[section] = newArray;
      BarService.widgetsRevision++;

      if (removedWidgets[0].id === "ControlCenter" && BarService.lookupWidget("ControlCenter") === undefined) {
        ToastService.showWarning(I18n.tr("toast.missing-control-center.label"), I18n.tr("toast.missing-control-center.description"), 6000);
      }
    }
  }

  function _reorderWidgetInSection(section, fromIndex, toIndex) {
    var widgets = Settings.data.bar.widgets;
    if (fromIndex >= 0 && fromIndex < widgets[section].length && toIndex >= 0 && toIndex < widgets[section].length) {
      var newArray = widgets[section].slice();
      var item = newArray[fromIndex];
      newArray.splice(fromIndex, 1);
      newArray.splice(toIndex, 0, item);
      widgets[section] = newArray;
      BarService.widgetsRevision++;
    }
  }

  // Note: _updateWidgetSettingsInSection does NOT increment revision
  // because it only changes settings, not widget structure
  function _updateWidgetSettingsInSection(section, index, settings) {
    Settings.data.bar.widgets[section][index] = settings;
  }

  function _moveWidgetBetweenSections(fromSection, index, toSection) {
    var widgets = Settings.data.bar.widgets;
    if (index >= 0 && index < widgets[fromSection].length) {
      var widget = widgets[fromSection][index];
      var sourceArray = widgets[fromSection].slice();
      sourceArray.splice(index, 1);
      widgets[fromSection] = sourceArray;
      var targetArray = widgets[toSection].slice();
      targetArray.push(widget);
      widgets[toSection] = targetArray;
      BarService.widgetsRevision++;
      Logger.d("BarTab", "_moveWidgetBetweenSections: revision now", BarService.widgetsRevision);
    }
  }


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

  function getWidgetLocations(widgetId) {
    if (!BarService)
      return [];
    const instances = BarService.getAllRegisteredWidgets();
    const locations = {};
    for (var i = 0; i < instances.length; i++) {
      if (instances[i].widgetId === widgetId) {
        const section = instances[i].section;
        if (section === "left")
          locations["arrow-bar-to-left"] = true;
        else if (section === "center")
          locations["layout-columns"] = true;
        else if (section === "right")
          locations["arrow-bar-to-right"] = true;
      }
    }
    return Object.keys(locations);
  }

  function createBadges(isPlugin, locations) {
    const badges = [];
    if (isPlugin) {
      badges.push({
                    "icon": "plugin",
                    "color": Color.mSecondary
                  });
    }
    locations.forEach(function (location) {
      badges.push({
                    "icon": location,
                    "color": Color.mOnSurfaceVariant
                  });
    });
    return badges;
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
                                                "badges": createBadges(isPlugin, getWidgetLocations(entry))
                                              });
                    });
  }

  ListModel {
    id: availableWidgets
  }

  Component.onCompleted: {
    updateAvailableWidgetsModel();
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      updateAvailableWidgetsModel();
    }
  }

  Connections {
    target: BarWidgetRegistry
    function onPluginWidgetRegistryUpdated() {
      updateAvailableWidgetsModel();
    }
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("common.appearance")
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      text: I18n.tr("common.widgets")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
    NTabButton {
      text: I18n.tr("common.monitors")
      tabIndex: 2
      checked: subTabBar.currentIndex === 2
    }
    NTabButton {
      text: "Side panels"
      tabIndex: 3
      checked: subTabBar.currentIndex === 3
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginS
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    AppearanceSubTab {}
    WidgetsSubTab {
      availableWidgets: availableWidgets
      addWidgetToSection: root._addWidgetToSection
      removeWidgetFromSection: root._removeWidgetFromSection
      reorderWidgetInSection: root._reorderWidgetInSection
      updateWidgetSettingsInSection: root._updateWidgetSettingsInSection
      moveWidgetBetweenSections: root._moveWidgetBetweenSections
      onOpenPluginSettings: manifest => pluginSettingsDialog.openPluginSettings(manifest)
    }
    MonitorsSubTab {
      addMonitor: root.addMonitor
      removeMonitor: root.removeMonitor
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
  }

  NPluginSettingsPopup {
    id: pluginSettingsDialog
    parent: Overlay.overlay
    showToastOnSave: false
  }
}
