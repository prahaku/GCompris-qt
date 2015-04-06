/* GCompris - GCComboBox.qml
 *
 * Copyright (C) 2015 Johnny Jazeix <jazeix@gmail.com>
 *
 * Authors:
 *   Johnny Jazeix <jazeix@gmail.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.2
import QtQuick.Controls 1.1
import GCompris 1.0

/**
 * A QML component unifying comboboxes in GCompris.
 * @ingroup components
 *
 * GCComboBox contains a combobox and a label.
 * When the combobox isn't active, it is displayed as a button containing the current value
 * and the combobox label (its description).
 * Once the button is clicked, the list of all available choices is displayed.
 * Also, above the list is the combobox label.
 *
 * Navigation can be done with keys and mouse/gestures.
 * As Qt comboboxes, you can either have a js Array or a Qml model as model.

 * GCComboBox should now be used wherever you'd use a QtQuick combobox. It has
 * been decided to implement comboboxes ourselves in GCompris because of
 * some integration problems on some OSes (native dialogs unavailable).
 */
Item {
    id: gccombobox
    focus: true

    width: button.width
    height: button.height

    /**
     * type:Item
     * Where the list containing all choices will be displayed.
     * Should be the dialogActivityConfig item if used on config.
     */
    property Item background

    /**
     * type:int
     * Current index of the combobox.
     */
    property int currentIndex: -1

    /**
     * type:string
     * Current text displayed in the combobox when inactive.
     */
    property string currentText


    /**
     * type:alias
     * Model for the list (user has to specify one).
     */
    property alias model: gridview.model

    /**
     * type:string
     * Text besides the combobox, used to describe what the combobox is for.
     */
    property string label
    
    /**
     * type:bool
     * Internal value.
     * If model is an js Array, we access data using modelData and [] else qml Model, we need to use model and get().
     */
    readonly property bool isModelArray: model.constructor === Array

    // start and stop trigs the animation
    signal start
    signal stop

    // emitted at stop animation end
    signal close

    onCurrentIndexChanged: {
        currentText = isModelArray ? model[currentIndex].text : (model && model.get(currentIndex) ? model.get(currentIndex).text : "")
    }

    /**
     * type:Flow
     * Combobox display when inactive: the button with current choice  and its label besides.
     */
    Flow {
        width: button.width+labelText.width+10
        spacing: 5 * ApplicationInfo.ratio
        Rectangle {
            id: button
            visible: true
            // Add radius to add some space between text and borders
            implicitWidth: Math.max(200, currentTextBox.width+radius)
            implicitHeight: 50 * ApplicationInfo.ratio
            border.width: 2
            border.color: "black"
            radius: 10
            gradient: Gradient {
                GradientStop { position: 0 ; color: mouseArea.pressed ? "#87ff5c" : "#ffe85c" }
                GradientStop { position: 1 ; color: mouseArea.pressed ? "#44ff00" : "#f8d600" }
            }
            // Current value of combobox
            GCText {
                id: currentTextBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: currentText
                fontSize: mediumSize
            }
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onReleased: {
                   popup.visible = true
                }
            }
        }

        GCText {
            id: labelText
            text: label
            fontSize: mediumSize
            wrapMode: Text.WordWrap
        }
    }
 
     /**
     * type:Item
     * Combobox display when active: header with the description and the gridview containing all the available choices.
     */
    Item {
        id: popup
        visible: false
        width: parent.width
        height: parent.height
        
        parent: background
        
        focus: visible

        // Forward event to activity if key pressed is not one of the handled key
        // (ctrl+F should still resize the window for example)
        Keys.onPressed: background.currentActivity.Keys.onPressed(event)

        Keys.onRightPressed: gridview.moveCurrentIndexRight();
        Keys.onLeftPressed: gridview.moveCurrentIndexLeft();
        Keys.onDownPressed: gridview.moveCurrentIndexDown();
        Keys.onUpPressed: gridview.moveCurrentIndexUp();

        Keys.onEscapePressed: {
            // Keep the old value
            discardChange();
            hidePopUpAndRestoreFocus();
        }
        Keys.onEnterPressed: {
            acceptChange();
            hidePopUpAndRestoreFocus();
        }
        Keys.onReturnPressed: {
            acceptChange();
            hidePopUpAndRestoreFocus();
        }

        Keys.onSpacePressed: {
            acceptChange();
            hidePopUpAndRestoreFocus();
        }

        // Don't accept the list value, restore previous value
        function discardChange() {
            if(isModelArray) {
                for(var i = 0 ; i < model.count ; ++ i) {
                    if(model[currentIndex].text === currentText) {
                        currentIndex = i;
                        break;
                    }
                }
            }
            else {
                for(var i = 0 ; i < model.length ; ++ i) {
                    if(model.get(currentIndex).text === currentText) {
                        currentIndex = i;
                        break;
                    }
                }
            }
            gridview.currentIndex = currentIndex;
        }

        // Accept the change. Updates the currentIndex and text of the button
        function acceptChange() {
            currentIndex = gridview.currentIndex;
            currentText = isModelArray ? model[currentIndex].text : (model && model.get(currentIndex) ? model.get(currentIndex).text : "")
        }

        function hidePopUpAndRestoreFocus() {
            popup.visible = false;
            // Restore focus on previous activity for keyboard input
            background.currentActivity.forceActiveFocus();
        }
        
        Rectangle {
            id: listBackground
            anchors.fill: parent
            radius: 10
            color: "grey"
            
            Rectangle {
                id : headerDescription
                width: gridview.width
                height: gridview.elementHeight
                GCText {
                    text: label
                    fontSize: mediumSize
                    wrapMode: Text.WordWrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                GCButtonCancel {
                    id: discardIcon
                    anchors.right: headerDescription.right
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        popup.acceptChange();
                        popup.hidePopUpAndRestoreFocus();
                    }
                }
            }
            //todo compute good size to have more columns if size screen is big enough
            property int cellSize: listBackground.width

            GridView {
                id: gridview
                readonly property int elementHeight: 40 * ApplicationInfo.ratio
                contentHeight: isModelArray ? elementHeight*model.count : elementHeight*model.length
                width: listBackground.width
                height: listBackground.height-headerDescription.height
                currentIndex: gccombobox.currentIndex
                flickableDirection: Flickable.VerticalFlick
                clip: true
                anchors.top: headerDescription.bottom
                cellWidth: listBackground.cellSize
                cellHeight: elementHeight

                delegate: Component {
                    Rectangle {
                        width: gridview.cellWidth
                        height: gridview.elementHeight
                        color: GridView.isCurrentItem ? "darkcyan" : "beige"
                        border.width: GridView.isCurrentItem ? 3 : 2
                        radius: 5
                        Image {
                            id: isSelectedIcon
                            visible: parent.GridView.isCurrentItem
                            source: "qrc:/gcompris/src/core/resource/apply.svg"
                            fillMode: Image.PreserveAspectFit
                            anchors.right: textValue.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 10
                            sourceSize.width: (gridview.elementHeight*0.8) * ApplicationInfo.ratio
                        }
                        GCText {
                            id: textValue
                            text: isModelArray ? modelData.text : model.text
                            anchors.centerIn: parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                currentIndex = index
                                popup.acceptChange();
                                popup.hidePopUpAndRestoreFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
