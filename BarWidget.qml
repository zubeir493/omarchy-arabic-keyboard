import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui
import qs.Commons
import "LayoutModel.js" as Model

BarWidget {
  id: root
  moduleName: "zubeyr.keyboard-layout"

  property string keyboardName: ""
  property string typedKeyboardName: ""
  property int activeIndex: 0
  property var layouts: []
  property var catalog: ({})
  property bool refreshPending: false
  property bool opened: false
  property int selectedIndex: 0
  property bool hasReportedLayout: false
  property string lastReportedLayout: ""

  readonly property var activeLayout: layouts.length > activeIndex ? layouts[activeIndex] : null
  readonly property string activeLabel: activeLayout ? activeLayout.brief : ""

  function refresh() {
    if (devicesProc.running) {
      refreshPending = true
      return
    }
    refreshPending = false
    devicesProc.running = true
  }

  function open() {
    root.refresh()
    root.selectedIndex = root.activeIndex
    root.opened = true
  }

  function close() {
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function showLayoutOsd(layout) {
    if (!layout || !layout.description) return
    Quickshell.execDetached([
      "omarchy-shell",
      "osd",
      "show",
      JSON.stringify({
        icon: "keyboard",
        message: layout.description,
        duration: 1400
      })
    ])
  }

  function choose(index) {
    if (!root.keyboardName || !root.bar) return
    root.selectedIndex = index
    root.bar.run("hyprctl switchxkblayout " + Util.shellQuote(root.keyboardName) + " " + index)
    root.close()
    refreshTimer.restart()
  }

  function typedKeyboards(keyboards) {
    return keyboards.filter(function(keyboard) {
      return Model.isTypedKeyboard(keyboard.name)
    })
  }

  function updateFromDevices(listed) {
    var typed = root.typedKeyboards(listed)
    var keyboard = Model.selectKeyboard(typed, root.typedKeyboardName)
    if (!keyboard || !keyboard.active_keymap) return

    root.keyboardName = String(keyboard.name || "")
    root.activeIndex = Number(keyboard.active_layout_index || 0)
    root.layouts = Model.enabledLayouts(
      keyboard.layout,
      keyboard.variant,
      root.activeIndex,
      keyboard.active_keymap,
      root.catalog
    )

    if (!root.opened) root.selectedIndex = root.activeIndex

    var layout = root.activeLayout
    var layoutToken = root.keyboardName + "|" + root.activeIndex + "|" + (layout ? layout.description : "")
    if (!root.hasReportedLayout) {
      root.lastReportedLayout = layoutToken
      root.hasReportedLayout = true
    } else if (layoutToken !== root.lastReportedLayout) {
      root.lastReportedLayout = layoutToken
      root.showLayoutOsd(layout)
    }
  }

  Component.onCompleted: {
    catalogProc.running = true
    refresh()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return
      var name = String(event.name)
      if (name === "activelayout") {
        var named = Model.eventKeyboardName(event)
        if (named) root.typedKeyboardName = named
      }
      if (name.indexOf("activelayout") !== -1 || name === "configreloaded")
        root.refresh()
    }
  }

  Process {
    id: catalogProc
    command: ["xkbcli", "list", "--load-exotic"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.catalog = Model.layoutCatalog(text)
        root.refresh()
      }
    }
  }

  Process {
    id: devicesProc
    command: ["hyprctl", "-j", "devices"]
    onRunningChanged: {
      if (running) return
      if (root.refreshPending) root.refresh()
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var listed = JSON.parse(text || "{}").keyboards
          if (Array.isArray(listed)) root.updateFromDevices(listed)
        } catch (error) {
        }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 500
    onTriggered: root.refresh()
  }

  Timer {
    interval: 10000
    running: root.keyboardName !== ""
    repeat: true
    onTriggered: root.refresh()
  }

  visible: root.layouts.length > 1
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.activeLabel
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: root.activeLayout ? root.activeLayout.description : "Keyboard layouts"
    onPressed: function(buttonCode) {
      if (buttonCode !== Qt.LeftButton) return
      root.toggle()
    }
  }

  KeyboardPanel {
    id: layoutPanel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: layoutPanel.fittedContentWidth(Style.space(320))
    contentHeight: layoutPanel.fittedContentHeight(popupColumn.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dy === 0 || root.layouts.length === 0) return
        root.selectedIndex = (root.selectedIndex + dy + root.layouts.length) % root.layouts.length
      }
      onActivateRequested: root.choose(root.selectedIndex)
      onCloseRequested: root.close()

      Column {
        id: popupColumn
        width: parent.width
        spacing: 0

      Item {
        width: parent.width
        height: Style.space(52)

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(16)
          anchors.top: parent.top
          anchors.topMargin: Style.space(10)
          text: "Keyboard layouts"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(16)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(8)
          text: "Super + Space to switch"
          color: root.bar ? Qt.darker(root.bar.foreground, 1.5) : Qt.darker(Color.foreground, 1.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Flickable {
        width: parent.width
        height: Math.min(layoutChoices.implicitHeight, Style.space(440))
        contentHeight: layoutChoices.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: layoutChoices
          width: parent.width

          Repeater {
            model: root.layouts

            delegate: Rectangle {
              required property var modelData
              required property int index
              width: layoutChoices.width
              height: Style.space(48)
              color: mouse.containsMouse || modelData.index === root.selectedIndex
                ? (root.bar ? Qt.lighter(root.bar.background, 1.18) : Qt.lighter(Color.background, 1.18))
                : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(16)
                anchors.rightMargin: Style.space(14)
                spacing: Style.space(12)

                Text {
                  Layout.preferredWidth: Style.space(36)
                  text: modelData.brief
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  Layout.fillWidth: true
                  text: modelData.description
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }

                Text {
                  text: modelData.active ? "✓" : (modelData.index === root.selectedIndex ? "•" : "")
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.bodySmall
                }
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.choose(modelData.index)
              }
            }
          }
        }
      }
    }
  }
}
}
