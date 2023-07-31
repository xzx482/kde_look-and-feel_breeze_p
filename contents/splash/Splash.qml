/*
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQml 2.15
import QtQuick 2.8
import QtQuick.Window 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.workspace.components 2.0 as PW

import "../components"
import "../components/animation"

PlasmaCore.ColorScope {

    id: lockScreenUi
    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    property bool hadPrompt: false;

    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup



    MouseArea {
        id: lockScreenRoot

        property bool calledUnlock: false
        property bool uiVisible: true

        x: parent.x
        y: parent.y
        width: parent.width
        height: parent.height
        hoverEnabled: true
        drag.filterChildren: true





        WallpaperFader {
            id: wallpaperFader
            anchors.fill: parent
            state: lockScreenRoot.uiVisible ? "on" : "off"
            source: wallpaper
            mainStack: mainStack
            footer: footer
            clock: clock
        }






    Image {
        id: sceneImageBackground
        anchors.fill: parent
        sourceSize.width: parent.width
        sourceSize.height: parent.height
        //fillMode: Image.PreserveAspectCrop
        //smooth: true
        source: "bg.png"
        ColorOverlay {
            id: bg_black_col
            anchors.fill: parent
            color: "black"
            opacity: 0.5
            Behavior on opacity {
                NumberAnimation {
                    duration: PlasmaCore.Units.veryLongDuration * 2
                    easing.type: Easing.InOutQuint
                }
            }
        }
    }
    FastBlur {
        id: bg_blur
        source: sceneImageBackground
        anchors.fill: sceneImageBackground
        radius: 50
    }







        DropShadow {
            id: clockShadow
            anchors.fill: clock
            source: clock
            visible: true
            radius: 6
            samples: 14
            spread: 0.3
            color : "black" // shadows should always be black
            Behavior on opacity {
                OpacityAnimator {
                    duration: PlasmaCore.Units.veryLongDuration * 2
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Clock {
            id: clock
            property Item shadow: clockShadow
            visible: y > 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: (mainBlock.userList.y + mainStack.y)/2 - height/2
            Layout.alignment: Qt.AlignBaseline
        }

        ListModel {
            id: users

            Component.onCompleted: {
                users.append({
                    name: kscreenlocker_userName,
                    realName: kscreenlocker_userName,
                    icon: kscreenlocker_userImage,
                })
            }
        }

        StackView {
            id: mainStack
            anchors {
                left: parent.left
                right: parent.right
            }
            height: lockScreenRoot.height + PlasmaCore.Units.gridUnit * 3
            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            // this isn't implicit, otherwise items still get processed for the scenegraph
            visible: opacity > 0

            initialItem: MainBlock {
                id: mainBlock
                lockScreenUiVisible: lockScreenRoot.uiVisible

                showUserList: userList.y + mainStack.y > 0

                enabled: !graceLockTimer.running

                userListModel: users



                actionItems: [
                    ActionButton {
                        iconSource: "system-suspend"
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Sleep")
                        enabled: false
                    },
                    ActionButton {
                        iconSource: "system-reboot"
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Restart")
                        enabled: false
                    },
                    ActionButton {
                        iconSource: "system-shutdown"
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Shut Down")
                        enabled: false
                    },
                    ActionButton {
                        iconSource: "system-user-prompt"
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "For switching to a username and password prompt", "Other…")
                        enabled: false
                        visible: !userListComponent.showUsernamePrompt
                    }]

            }

        }

        Loader {
            id: inputPanel
            state: "hidden"
            enabled: false
            readonly property bool keyboardActive: item ? item.active : false
            anchors {
                left: parent.left
                right: parent.right
            }
            function showHide() {
                state = state == "hidden" ? "visible" : "hidden";
            }
            Component.onCompleted: {
                inputPanel.source = Qt.platform.pluginName.includes("wayland") ? "../components/VirtualKeyboard_wayland.qml" : "../components/VirtualKeyboard.qml"
            }

            onKeyboardActiveChanged: {
                if (keyboardActive) {
                    state = "visible";
                } else {
                    state = "hidden";
                }
            }
        }

        Loader {
            active: root.viewVisible
            enabled: false
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: PlasmaCore.Units.largeSpacing
            }
        }

        RowLayout {
            id: footer
            enabled: false
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: PlasmaCore.Units.smallSpacing
            }

            PlasmaComponents3.ToolButton {
                focusPolicy: Qt.TabFocus
                text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"

                visible: inputPanel.status == Loader.Ready
            }

            PlasmaComponents3.ToolButton {
                focusPolicy: Qt.TabFocus
                Accessible.description: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to change keyboard layout", "Switch layout")
                icon.name: "input-keyboard"

                PW.KeyboardLayoutSwitcher {
                    id: keyboardLayoutSwitcher

                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }

                text: keyboardLayoutSwitcher.layoutNames.longName
                onClicked: keyboardLayoutSwitcher.keyboardLayout.switchToNextLayout()

                visible: keyboardLayoutSwitcher.hasMultipleKeyboardLayouts
            }

            Item {
                Layout.fillWidth: true
            }

            Battery {}
        }
    }







    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            //match SDDM/lockscreen avatar positioning
            property real size: PlasmaCore.Units.gridUnit * 8

            anchors.centerIn: parent

            source: "images/plasma.svgz"

            sourceSize.width: size
            sourceSize.height: size
        }

        // TODO: port to PlasmaComponents3.BusyIndicator
        Image {
            id: busyIndicator
            //in the middle of the remaining space
            y: parent.height - (parent.height - logo.y) / 2 - height/2
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/busywidget.svgz"
            sourceSize.height: PlasmaCore.Units.gridUnit * 2
            sourceSize.width: PlasmaCore.Units.gridUnit * 2
            RotationAnimator on rotation {
                id: rotationAnimator
                from: 0
                to: 360
                // Not using a standard duration value because we don't want the
                // animation to spin faster or slower based on the user's animation
                // scaling preferences; it doesn't make sense in this context
                duration: 2000
                loops: Animation.Infinite
                // Don't want it to animate at all if the user has disabled animations
                running: PlasmaCore.Units.longDuration > 1
            }
        }
        Row {
            spacing: PlasmaCore.Units.smallSpacing*2
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: PlasmaCore.Units.gridUnit
            }
            Text {
                color: "#eff0f1"
                // Work around Qt bug where NativeRendering breaks for non-integer scale factors
                // https://bugreports.qt.io/browse/QTBUG-67007
                renderType: Screen.devicePixelRatio % 1 !== 0 ? Text.QtRendering : Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
                text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "This is the first text the user sees while starting in the splash screen, should be translated as something short, is a form that can be seen on a product. Plasma is the project name so shouldn't be translated.", "Plasma made by KDE")
            }
            Image {
                source: "images/kde.svgz"
                sourceSize.height: PlasmaCore.Units.gridUnit * 2
                sourceSize.width: PlasmaCore.Units.gridUnit * 2
            }
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: PlasmaCore.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }



    Timer {
        id: introAnimationTimer
        interval: 250
        onTriggered: {
            introAnimation.running = true;
        }
    }

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimationTimer.running=true;
            //introAnimation.running = true;
            wallpaperFader.alwaysShowClock=false;
            lockScreenRoot.uiVisible=false;
        } else if (stage == 5) {
            introAnimation.target = busyIndicator;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;
        }
    }

}


