import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Panels.Settings.Tabs.Bar
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  function _ensureSidePanelLists() {
    if (!Settings.data.bar.sidePanels) {
      return;
    }
    if (!Settings.data.bar.sidePanels.leftPanels) {
      Settings.data.bar.sidePanels.leftPanels = [];
    }
    if (!Settings.data.bar.sidePanels.rightPanels) {
      Settings.data.bar.sidePanels.rightPanels = [];
    }
  }

  function _addSidePanelToSection(panelId, section) {
    _ensureSidePanelLists();

    var panelEntry = {
      "id": panelId
    };

    var key = section + "Panels";
    Settings.data.bar.sidePanels[key].push(panelEntry);
    BarService.widgetsRevision++;
  }

  function _removeSidePanelFromSection(section, index) {
    _ensureSidePanelLists();

    var key = section + "Panels";
    var panels = Settings.data.bar.sidePanels[key] || [];
    if (index >= 0 && index < panels.length) {
      var newArray = panels.slice();
      newArray.splice(index, 1);
      Settings.data.bar.sidePanels[key] = newArray;
      BarService.widgetsRevision++;
    }
  }

  function _reorderSidePanelInSection(section, fromIndex, toIndex) {
    _ensureSidePanelLists();

    var key = section + "Panels";
    var panels = Settings.data.bar.sidePanels[key] || [];
    if (fromIndex >= 0 && fromIndex < panels.length && toIndex >= 0 && toIndex < panels.length) {
      var newArray = panels.slice();
      var item = newArray[fromIndex];
      newArray.splice(fromIndex, 1);
      newArray.splice(toIndex, 0, item);
      Settings.data.bar.sidePanels[key] = newArray;
      BarService.widgetsRevision++;
    }
  }

  function _updateSidePanelInSection(section, index, panelEntry) {
    _ensureSidePanelLists();

    var key = section + "Panels";
    var panels = Settings.data.bar.sidePanels[key] || [];
    if (index >= 0 && index < panels.length) {
      panels[index] = panelEntry;
      Settings.data.bar.sidePanels[key] = panels.slice();
    }
  }

  function _moveSidePanelBetweenSections(fromSection, index, toSection) {
    _ensureSidePanelLists();

    var fromKey = fromSection + "Panels";
    var toKey = toSection + "Panels";
    var fromPanels = Settings.data.bar.sidePanels[fromKey] || [];
    var toPanels = Settings.data.bar.sidePanels[toKey] || [];

    if (index >= 0 && index < fromPanels.length) {
      var panelEntry = fromPanels[index];
      var sourceArray = fromPanels.slice();
      sourceArray.splice(index, 1);
      var targetArray = toPanels.slice();
      targetArray.push(panelEntry);
      Settings.data.bar.sidePanels[fromKey] = sourceArray;
      Settings.data.bar.sidePanels[toKey] = targetArray;
      BarService.widgetsRevision++;
    }
  }

  function updateAvailablePanelsModel() {
    availablePanels.clear();

    var panels = [
      {"key": "audioPanel", "name": I18n.tr("panels.audio.title")},
      {"key": "batteryPanel", "name": I18n.tr("battery.battery")},
      {"key": "bluetoothPanel", "name": I18n.tr("common.bluetooth")},
      {"key": "brightnessPanel", "name": I18n.tr("panels.osd.types-brightness-label")},
      {"key": "clockPanel", "name": I18n.tr("common.calendar")},
      {"key": "controlCenterPanel", "name": I18n.tr("panels.control-center.title")},
      {"key": "launcherPanel", "name": I18n.tr("panels.launcher.title")},
      {"key": "mediaPlayerPanel", "name": I18n.tr("common.media")},
      {"key": "networkPanel", "name": I18n.tr("common.network")},
      {"key": "notificationHistoryPanel", "name": I18n.tr("panels.notifications.history-title")},
      {"key": "sessionMenuPanel", "name": I18n.tr("session-menu.title")},
      {"key": "settingsPanel", "name": I18n.tr("panels.general.title")},
      {"key": "wallpaperPanel", "name": I18n.tr("common.wallpaper")},
    ];

    for (var i = 0; i < panels.length; i++) {
      availablePanels.append(panels[i]);
    }
  }

  ListModel {
    id: availablePanels
  }

  Component.onCompleted: updateAvailablePanelsModel()

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      updateAvailablePanelsModel();
    }
  }

  SidePanelsSubTab {
    availableWidgets: availablePanels
    addPanelToSection: root._addSidePanelToSection
    removePanelFromSection: root._removeSidePanelFromSection
    reorderPanelInSection: root._reorderSidePanelInSection
    updatePanelInSection: root._updateSidePanelInSection
    movePanelBetweenSections: root._moveSidePanelBetweenSections
    onOpenPluginSettings: manifest => pluginSettingsDialog.openPluginSettings(manifest)
  }

  NPluginSettingsPopup {
    id: pluginSettingsDialog
    parent: Overlay.overlay
    showToastOnSave: false
  }
}
