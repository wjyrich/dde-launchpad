// SPDX-FileCopyrightText: 2023 - 2026 UnionTech Software Technology Co., Ltd.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQml.Models 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import org.deepin.dtk 1.0
import org.deepin.dtk.private 1.0
import org.deepin.dtk 1.0 as D
import org.deepin.dtk.style 1.0 as DS

import org.deepin.launchpad 1.0
import org.deepin.launchpad.models 1.0
import 'windowed'

Control {
    id: root

    property var icons: undefined

    // TODO: When DciIcon changes the sourceSize, the icon will flash, It may be a bug of dciicon or qt?
    // So we give the max sourceSize and use scale to solve it.
    property int maxIconSize: 128
    property int maxIconSizeInFolder: 64
    readonly property string text: display.startsWith("internal/category/") ? getCategoryName(display.substring(18)) : display

    property string iconSource
    property bool dndEnabled: false
    property bool isDragHover: false
    readonly property bool isWindowedMode: LauncherController.currentFrame === "WindowedFrame"
    property alias displayFont: iconItemLabel.font
    property real iconScaleFactor: 1.0

    Accessible.name: iconItemLabel.text

    signal folderClicked()
    signal itemClicked()
    signal menuTriggered()

    Drag.dragType: Drag.Automatic

    states: State {
        name: "dragged";
        when: dragHandler.active
        // FIXME: When dragging finished, the position of the item is changed for unknown reason,
        //        so we use the state to reset the x and y here.
        PropertyChanges {
            target: dragHandler.target
            x: x
            y: y
        }
    }

    contentItem: Button {
        focusPolicy: Qt.NoFocus
        ColorSelector.pressed: false
        ColorSelector.family: D.Palette.CrystalColor
        flat: true

        // Rectangle {
        //     anchors.fill: parent
        //     color: "transparent"
        //     border.width: 2
        //     border.color: "blue"
        //     z: 999
        // }
        contentItem: Column {
            anchors.fill: parent

            Item {
                // actually just a top padding
                width: root.width
                height: isWindowedMode ? 7 : root.height / 9
            }

            Item {
                id: iconContainer
                width: parent.width / 2
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: dragHoverBackground
                    visible: root.isDragHover
                    anchors.centerIn: parent
                    width: (parent.width + 16) * root.iconScaleFactor
                    height: (parent.height + 16) * root.iconScaleFactor
                    radius: isWindowedMode ? 10 : 18
                    color: Qt.rgba(1, 1, 1, 0.25)
                }

                // Rectangle {
                //     anchors.fill: parent
                //     border.width: 1
                //     border.color: "red"
                // }

                Loader {
                    id: iconLoader
                    anchors.fill: parent
                    sourceComponent: root.icons !== undefined ? folderComponent : imageComponent
                    
                    // Rectangle {
                    //         anchors.fill: parent
                    //         color: "transparent"
                    //         border.width: 2
                    //         border.color: "green"
                    //     }
                    DragHandler {
                        id: dragHandler
                        target: root
                        acceptedButtons: Qt.LeftButton
                        enabled: root.dndEnabled
                        dragThreshold: 1
                        onActiveChanged: {
                            if (active) {
                                // We switch to use the `dndItem` to handle Drag event since that one will always exists.
                                // If we use the current item, then if the item that provides the drag attached property
                                // get destoryed (e.g. switch page or folder close caused destory), dropping at that moment
                                // will cause a crash.

                                // Item will be hidden by checking the dndItem.currentlyDraggedId property. We assign the value
                                // to that property here
                                dndItem.currentlyDraggedId = target.Drag.mimeData["text/x-dde-launcher-dnd-desktopId"]
                                dndItem.currentlyDraggedIconName = root.iconSource
                                dndItem.Drag.hotSpot = target.Drag.hotSpot
                                dndItem.Drag.mimeData = target.Drag.mimeData
                                dndItem.mergeSize = Math.min(iconLoader.width, iconLoader.height)

                                iconLoader.grabToImage(function(result) {
                                    dndItem.Drag.imageSource = result.url;
                                    dndItem.Drag.active = true
                                    dndItem.Drag.startDrag()
                                })
                            }
                        }
                    }
                }

                DciIcon {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom

                    name: "emblem_autostart"
                    visible: autoStart
                    sourceSize: Qt.size(16, 16)
                    palette: DTK.makeIconPalette(root.palette)
                    theme: ApplicationHelper.DarkType
                }

                Component {
                    id: folderComponent

                    Rectangle {
                        id: ddd
                        anchors.fill: parent
                        color: "#26FFFFFF"
                        radius: 12

                        property real itemWidth: (width - (3 * 8)) / 2
                        property real itemHeight: (height - (3 * 8)) / 2

                        function getItemX(index) {
                            let col = index % 2
                            let ret = (col + 1) * 8 + col * itemWidth
                            console.warn("getItemX for index", index, "itemWidth", itemWidth,
                                "ret", ret)
                            return ret
                        }

                        function getItemY(index) {
                            let row = Math.floor(index / 2)
                            let ret = (row + 1) * 8 + row * itemHeight
                            console.warn("getItemY for index", index, "itemHeight", itemHeight, "ret", ret)
                            return ret
                        }

                            Repeater {
                                model: icons

                                Item {

                                }

                                DciIcon {
                                    id: folderIcon

                                    x: ddd.getItemX(index)
                                    y: ddd.getItemY(index)

                                    width: ddd.itemWidth
                                    height: ddd.itemHeight

                                    name: modelData
                                    sourceSize: Qt.size(root.maxIconSize, root.maxIconSize)
                                    scale: (ddd.width / 2 / root.maxIconSize) * root.iconScaleFactor

                                    property real introScale: 1.0

                                    palette: DTK.makeIconPalette(root.palette)
                                    theme: ApplicationHelper.DarkType


                                    // 位移动画属性
                                    property real introTranslateX: 0
                                    property real introTranslateY: 0
                                    ParallelAnimation {
                                        id: iconIntroAnim

                                        NumberAnimation {
                                            target: folderIcon
                                            property: "scale"
                                            from: folderIcon.introScale; to: (ddd.width / 2 / root.maxIconSize) * root.iconScaleFactor
                                            duration: 800
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            target: folderIcon
                                            property: "x"
                                            from: folderIcon.introTranslateX; to: ddd.getItemX(index)
                                            duration: 800
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            target: folderIcon
                                            property: "y"
                                            from: folderIcon.introTranslateY; to: ddd.getItemY(index)
                                            duration: 800
                                            easing.type: Easing.InOutQuad
                                        }

                                        onFinished: {
                                            dndItem.mergeAnimPending = false
                                            dndItem.mergeAnimTargetIcon = ""
                                            dndItem.mergeAnimTargetIcon2 = ""
                                        }
                                    }

                                    Component.onCompleted: {
                                        if (dndItem.mergeAnimPending
                                            && modelData === dndItem.mergeAnimTargetIcon) {
                                            folderIcon.visible = false
                                            Qt.callLater(function() {
                                                let localPos = ddd.mapFromItem(null,
                                                    dndItem.mergeAnimStartX, dndItem.mergeAnimStartY)
                                                folderIcon.introTranslateX = localPos.x - folderIcon.width / 2
                                                folderIcon.introTranslateY = localPos.y - folderIcon.height / 2
                                                folderIcon.introScale = (iconContainer.width / root.maxIconSize) * root.iconScaleFactor
                                                console.warn("local:", localPos, "introTranslateX" ,dndItem.mergeAnimStartX, "introTranslateY", dndItem.mergeAnimStartY, "scale", folderIcon.scale)
                                                folderIcon.visible = true
                                                iconIntroAnim.start()
                                                testRect.x = localPos.x - testRect.width / 2
                                                testRect.y = localPos.y - testRect.height / 2
                                                testRect.z = 999
                                            })
                                        } else if (dndItem.mergeAnimPending
                                            && modelData === dndItem.mergeAnimTargetIcon2) {
                                            Qt.callLater(function() {
                                                folderIcon.introTranslateX = iconContainer.width / 2 - folderIcon.width / 2
                                                folderIcon.introTranslateY = iconContainer.height / 2 - folderIcon.height / 2
                                                folderIcon.introScale = (iconContainer.width / root.maxIconSize) * root.iconScaleFactor
                                                console.warn("===-=-=-=-=-=-", iconContainer.width, root.iconScaleFactor)
                                                iconIntroAnim.start()
                                            })
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: 4 - icons.length

                                Item {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft

                                    width: parent.width / 2
                                    height: parent.height / 2
                                }
                            }
                        // }
                    }
                }

                Component {
                    id: imageComponent

                    DciIcon {
                        objectName: "appIcon"
                        anchors.fill: parent
                        name: iconSource
                        sourceSize: Qt.size(root.maxIconSize, root.maxIconSize)
                        scale: (iconContainer.width / root.maxIconSize) * root.iconScaleFactor
                        palette: DTK.makeIconPalette(root.palette)
                        theme: ApplicationHelper.DarkType
                    }
                }
            }

            // as topMargin
            Item {
                width: 1
                height: isWindowedMode ? 4 : root.height / 10
            }

            Label {
                property bool singleRow: font.pixelSize > (isWindowedMode ? Helper.windowed.doubleRowMaxFontSize : Helper.fullscreen.doubleRowMaxFontSize)
                property bool isNewlyInstalled: model.lastLaunchedTime === 0 && model.installedTime !== 0
                id: iconItemLabel
                visible: !root.isDragHover
                text: isNewlyInstalled ? ("<font color='#669DFF' size='1' style='text-shadow: 0 0 1px rgba(255,255,255,0.1)'>●</font>&nbsp;&nbsp;" + root.text) : root.text
                textFormat: isNewlyInstalled ? Text.StyledText : Text.PlainText
                width: parent.width
                leftPadding: 2
                rightPadding: 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: singleRow ? Text.NoWrap : Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: singleRow ? 1 : 2
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                gesturePolicy: TapHandler.WithinBounds
                onTapped: {
                    root.menuTriggered()
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.WithinBounds
                onPressedChanged: {
                    if (pressed) {
                        root.Drag.hotSpot = mapToItem(iconLoader, point.pressPosition)
                    }
                }
                onTapped: {
                    if (model.itemType === ItemArrangementProxyModel.FolderItemType) {
                        root.folderClicked()
                    } else {
                        root.itemClicked()
                    }
                }
            }
        }
        ToolTip.text: root.text
        ToolTip.delay: 500
        ToolTip.visible: hovered && iconItemLabel.truncated
        background: ItemBackground {
            radius: isWindowedMode ? 8 : 18
            button: parent
        }
    }
    background: DebugBounding { }

    Keys.onSpacePressed: {
        if (model.itemType === ItemArrangementProxyModel.FolderItemType) {
            root.folderClicked()
        } else {
            root.itemClicked()
        }
    }

    Keys.onReturnPressed: {
        if (model.itemType === ItemArrangementProxyModel.FolderItemType) {
            root.folderClicked()
        } else {
            root.itemClicked()
        }
    }
}
