/*
    SPDX-FileCopyrightText: 2014 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.5
import QtQuick.Window 2.2
import org.kde.plasma.core 2.0 as PlasmaCore
import QtGraphicalEffects 1.0

Rectangle {
    id: root
    //color: "black"
    color: "#00000000"

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            //introAnimation.target = busyIndicator;
            introAnimation.target = content_other;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;

            bg_black_col.opacity=0;
            bg_blur.radius=0;

        }
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
        Behavior on radius {
            NumberAnimation {
                duration: PlasmaCore.Units.veryLongDuration * 2
                easing.type: Easing.InOutQuint
            }
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

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


        Item {
            id: content_other
            anchors.fill: parent
            opacity: 1

            Image {
                id: logo
                //match SDDM/lockscreen avatar positioning
                property real size: PlasmaCore.Units.gridUnit * 8

                anchors.centerIn: parent

                source: "images/plasma.svgz"

                sourceSize.width: size
                sourceSize.height: size
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
}
